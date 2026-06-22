using Google;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Storage.v1.Data;
using Google.Cloud.Storage.V1;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.Interfaces.Storage;
using System.Text.Json;

namespace SmartTrip.Infrastructure.Services.Storage;

public sealed class FirebaseImageStorageService : IImageStorageService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<FirebaseImageStorageService> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IWebHostEnvironment _webHostEnvironment;
    private readonly Lazy<StorageClient> _storageClient;

    public FirebaseImageStorageService(
        IConfiguration configuration,
        IHttpContextAccessor httpContextAccessor,
        IWebHostEnvironment webHostEnvironment,
        ILogger<FirebaseImageStorageService> logger)
    {
        _configuration = configuration;
        _httpContextAccessor = httpContextAccessor;
        _webHostEnvironment = webHostEnvironment;
        _logger = logger;
        _storageClient = new Lazy<StorageClient>(CreateStorageClient);
    }

    public async Task<ImageStorageUploadResult> UploadImageAsync(
        Stream fileStream,
        string originalFileName,
        string contentType,
        string folder,
        CancellationToken cancellationToken = default)
    {
        var shouldFallbackToLocalStorage = ShouldFallbackToLocalStorage();
        var buckets = ResolveStorageBuckets();
        var extension = Path.GetExtension(originalFileName);
        var safeExtension = string.IsNullOrWhiteSpace(extension) ? ".jpg" : extension.ToLowerInvariant();
        var fileName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}{safeExtension}";
        var imagePath = $"{NormalizeFolder(folder)}/{fileName}";
        var downloadToken = Guid.NewGuid().ToString("D");
        await using var uploadStream = await CreateReplayableStreamAsync(fileStream, cancellationToken);

        if (buckets.Count == 0)
        {
            if (shouldFallbackToLocalStorage)
            {
                _logger.LogWarning(
                    "Firebase Storage bucket is not configured. Falling back to local image storage for {FileName}.",
                    originalFileName);

                uploadStream.Position = 0;
                return await UploadToLocalStorageAsync(
                    uploadStream,
                    fileName,
                    folder,
                    cancellationToken);
            }

            throw new ImageStorageUnavailableException(
                "Firebase Storage bucket is not configured. Set Firebase:StorageBucket or FIREBASE_STORAGE_BUCKET.");
        }

        GoogleApiException? lastNotFoundException = null;

        foreach (var bucket in buckets)
        {
            uploadStream.Position = 0;

            var destination = new Google.Apis.Storage.v1.Data.Object
            {
                Bucket = bucket,
                Name = imagePath,
                ContentType = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType,
                Metadata = new Dictionary<string, string>
                {
                    ["firebaseStorageDownloadTokens"] = downloadToken
                }
            };

            try
            {
                await _storageClient.Value.UploadObjectAsync(
                    destination,
                    uploadStream,
                    cancellationToken: cancellationToken);

                return new ImageStorageUploadResult
                {
                    ImageUrl = BuildFirebaseDownloadUrl(bucket, imagePath, downloadToken),
                    ImagePath = imagePath,
                    FileName = fileName
                };
            }
            catch (GoogleApiException ex) when (IsBucketNotFound(ex))
            {
                lastNotFoundException = ex;
                _logger.LogDebug(
                    "Firebase Storage bucket {Bucket} was not found while uploading {FileName}.",
                    bucket,
                    originalFileName);
            }
            catch (GoogleApiException ex)
            {
                throw CreateStorageUnavailableException(ex, buckets);
            }
        }

        if (shouldFallbackToLocalStorage)
        {
            _logger.LogWarning(
                "No Firebase Storage bucket was found for project {ProjectId}. Falling back to local image storage. Tried: {Buckets}.",
                ResolveProjectId() ?? "(unknown)",
                string.Join(", ", buckets));

            uploadStream.Position = 0;
            return await UploadToLocalStorageAsync(
                uploadStream,
                fileName,
                folder,
                cancellationToken);
        }

        throw CreateMissingBucketException(buckets, lastNotFoundException);
    }

    private StorageClient CreateStorageClient()
    {
        var credential = LoadCredential();
        return StorageClient.Create(credential);
    }

    private IReadOnlyList<string> ResolveStorageBuckets()
    {
        var buckets = new List<string>();
        var configuredBucket = NormalizeBucketName(
            _configuration["Firebase:StorageBucket"]
            ?? Environment.GetEnvironmentVariable("FIREBASE_STORAGE_BUCKET")
            ?? ReadEnvValue("FIREBASE_STORAGE_BUCKET"));

        AddBucketCandidate(buckets, configuredBucket);
        AddBucketCandidate(buckets, GetAlternateBucketName(configuredBucket));

        var projectId = ResolveProjectId();
        if (!string.IsNullOrWhiteSpace(projectId))
        {
            AddBucketCandidate(buckets, $"{projectId}.firebasestorage.app");
            AddBucketCandidate(buckets, $"{projectId}.appspot.com");
        }

        return buckets;
    }

    private GoogleCredential LoadCredential()
    {
        var configuredPath = NormalizeCredentialPath(
            _configuration["Firebase:ServiceAccountPath"]
            ?? Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_PATH")
            ?? Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")
            ?? ReadEnvValue("FIREBASE_SERVICE_ACCOUNT_PATH")
            ?? ReadEnvValue("GOOGLE_APPLICATION_CREDENTIALS"));

        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            if (File.Exists(configuredPath))
            {
                _logger.LogInformation("Using Firebase Storage credential from {CredentialPath}", configuredPath);
                using var stream = File.OpenRead(configuredPath);
                return ServiceAccountCredential
                    .FromServiceAccountData(stream)
                    .ToGoogleCredential();
            }

            _logger.LogWarning("Firebase Storage credential path does not exist: {CredentialPath}", configuredPath);
        }

        return GoogleCredential.GetApplicationDefault();
    }

    private static string NormalizeFolder(string folder)
    {
        var normalized = folder
            .Replace('\\', '/')
            .Trim('/')
            .Split('/', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        if (normalized.Length == 0)
        {
            return "uploads";
        }

        return string.Join('/', normalized);
    }

    private static string BuildFirebaseDownloadUrl(string bucket, string imagePath, string token)
    {
        return $"https://firebasestorage.googleapis.com/v0/b/{Uri.EscapeDataString(bucket)}/o/{Uri.EscapeDataString(imagePath)}?alt=media&token={Uri.EscapeDataString(token)}";
    }

    private async Task<ImageStorageUploadResult> UploadToLocalStorageAsync(
        Stream fileStream,
        string fileName,
        string folder,
        CancellationToken cancellationToken)
    {
        var normalizedFolder = NormalizeFolder(folder);
        var relativePath = $"uploads/{normalizedFolder}/{fileName}";
        var relativePathSegments = relativePath.Split('/', StringSplitOptions.RemoveEmptyEntries);
        var webRootPath = ResolveWebRootPath();
        var absolutePath = Path.Combine(webRootPath, Path.Combine(relativePathSegments));
        var directoryPath = Path.GetDirectoryName(absolutePath)
            ?? throw new InvalidOperationException("Unable to resolve local upload directory.");

        Directory.CreateDirectory(directoryPath);

        await using (var destination = new FileStream(absolutePath, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            await fileStream.CopyToAsync(destination, cancellationToken);
        }

        var imageUrl = BuildLocalFileUrl(relativePath);
        return new ImageStorageUploadResult
        {
            ImageUrl = imageUrl,
            ImagePath = relativePath,
            FileName = fileName
        };
    }

    private ImageStorageUnavailableException CreateMissingBucketException(
        IReadOnlyList<string> buckets,
        GoogleApiException? innerException)
    {
        var configuredProjectId = ResolveProjectId();
        var attemptedBuckets = string.Join(", ", buckets);
        var projectHint = string.IsNullOrWhiteSpace(configuredProjectId)
            ? string.Empty
            : $" for project '{configuredProjectId}'";

        return new ImageStorageUnavailableException(
            $"No Firebase Storage bucket was found{projectHint}. Tried: {attemptedBuckets}. " +
            "Verify Cloud Storage for Firebase is enabled and set Firebase:StorageBucket or FIREBASE_STORAGE_BUCKET to the bucket shown in Firebase console.",
            innerException);
    }

    private ImageStorageUnavailableException CreateStorageUnavailableException(
        GoogleApiException innerException,
        IReadOnlyList<string> buckets)
    {
        var attemptedBuckets = string.Join(", ", buckets);

        return new ImageStorageUnavailableException(
            $"Unable to upload image to Firebase Storage. Checked bucket(s): {attemptedBuckets}. " +
            "Verify the service account has access to the configured bucket and that Cloud Storage for Firebase is enabled.",
            innerException);
    }

    private bool ShouldFallbackToLocalStorage()
    {
        var configuredValue =
            _configuration["Storage:UseLocalFallback"]
            ?? Environment.GetEnvironmentVariable("USE_LOCAL_IMAGE_STORAGE_FALLBACK")
            ?? ReadEnvValue("USE_LOCAL_IMAGE_STORAGE_FALLBACK");

        if (bool.TryParse(configuredValue, out var parsed))
        {
            return parsed;
        }

        return _webHostEnvironment.IsDevelopment();
    }

    private string ResolveWebRootPath()
    {
        if (!string.IsNullOrWhiteSpace(_webHostEnvironment.WebRootPath))
        {
            return _webHostEnvironment.WebRootPath;
        }

        var webRootPath = Path.Combine(_webHostEnvironment.ContentRootPath, "wwwroot");
        Directory.CreateDirectory(webRootPath);
        return webRootPath;
    }

    private string BuildLocalFileUrl(string relativePath)
    {
        var normalizedRelativePath = relativePath.Replace('\\', '/').TrimStart('/');
        var request = _httpContextAccessor.HttpContext?.Request;

        if (request is not null && request.Host.HasValue)
        {
            return $"{request.Scheme}://{request.Host}/{normalizedRelativePath}";
        }

        var configuredUrls = _configuration["Urls"];
        if (!string.IsNullOrWhiteSpace(configuredUrls))
        {
            var firstUrl = configuredUrls
                .Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .FirstOrDefault();

            if (!string.IsNullOrWhiteSpace(firstUrl))
            {
                return $"{firstUrl.TrimEnd('/')}/{normalizedRelativePath}";
            }
        }

        return $"/{normalizedRelativePath}";
    }

    private string? ResolveProjectId()
    {
        var projectId =
            _configuration["Firebase:ProjectId"]
            ?? Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID")
            ?? Environment.GetEnvironmentVariable("GOOGLE_CLOUD_PROJECT")
            ?? Environment.GetEnvironmentVariable("GCLOUD_PROJECT")
            ?? ReadEnvValue("FIREBASE_PROJECT_ID")
            ?? ReadEnvValue("GOOGLE_CLOUD_PROJECT")
            ?? ReadEnvValue("GCLOUD_PROJECT");

        if (!string.IsNullOrWhiteSpace(projectId))
        {
            return projectId.Trim();
        }

        var configuredPath = NormalizeCredentialPath(
            _configuration["Firebase:ServiceAccountPath"]
            ?? Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_PATH")
            ?? Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")
            ?? ReadEnvValue("FIREBASE_SERVICE_ACCOUNT_PATH")
            ?? ReadEnvValue("GOOGLE_APPLICATION_CREDENTIALS"));

        if (string.IsNullOrWhiteSpace(configuredPath) || !File.Exists(configuredPath))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(configuredPath));
            if (document.RootElement.TryGetProperty("project_id", out var projectIdElement))
            {
                return projectIdElement.GetString()?.Trim();
            }
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Unable to parse Firebase service account file at {CredentialPath}.", configuredPath);
        }
        catch (IOException ex)
        {
            _logger.LogWarning(ex, "Unable to read Firebase service account file at {CredentialPath}.", configuredPath);
        }

        return null;
    }

    private static void AddBucketCandidate(ICollection<string> buckets, string? bucket)
    {
        if (string.IsNullOrWhiteSpace(bucket))
        {
            return;
        }

        if (!buckets.Contains(bucket, StringComparer.OrdinalIgnoreCase))
        {
            buckets.Add(bucket);
        }
    }

    private static string? NormalizeBucketName(string? bucket)
    {
        if (string.IsNullOrWhiteSpace(bucket))
        {
            return null;
        }

        var normalized = bucket.Trim();
        if (normalized.StartsWith("gs://", StringComparison.OrdinalIgnoreCase))
        {
            normalized = normalized[5..];
        }

        var slashIndex = normalized.IndexOf('/');
        if (slashIndex >= 0)
        {
            normalized = normalized[..slashIndex];
        }

        return normalized.Trim();
    }

    private static string? GetAlternateBucketName(string? bucket)
    {
        if (string.IsNullOrWhiteSpace(bucket))
        {
            return null;
        }

        if (bucket.EndsWith(".firebasestorage.app", StringComparison.OrdinalIgnoreCase))
        {
            return $"{bucket[..^".firebasestorage.app".Length]}.appspot.com";
        }

        if (bucket.EndsWith(".appspot.com", StringComparison.OrdinalIgnoreCase))
        {
            return $"{bucket[..^".appspot.com".Length]}.firebasestorage.app";
        }

        return null;
    }

    private static bool IsBucketNotFound(GoogleApiException exception)
    {
        return exception.HttpStatusCode == System.Net.HttpStatusCode.NotFound;
    }

    private static async Task<MemoryStream> CreateReplayableStreamAsync(
        Stream source,
        CancellationToken cancellationToken)
    {
        var memoryStream = new MemoryStream();
        await source.CopyToAsync(memoryStream, cancellationToken);
        memoryStream.Position = 0;
        return memoryStream;
    }

    private static string? ReadEnvValue(string key)
    {
        foreach (var envPath in EnumerateEnvFiles())
        {
            foreach (var line in File.ReadLines(envPath))
            {
                var trimmed = line.Trim();
                if (trimmed.Length == 0 || trimmed.StartsWith('#'))
                {
                    continue;
                }

                var separatorIndex = trimmed.IndexOf('=');
                if (separatorIndex <= 0)
                {
                    continue;
                }

                var name = trimmed[..separatorIndex].Trim();
                if (string.Equals(name, key, StringComparison.OrdinalIgnoreCase))
                {
                    return trimmed[(separatorIndex + 1)..].Trim();
                }
            }
        }

        return null;
    }

    private static IEnumerable<string> EnumerateEnvFiles()
    {
        var visited = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var directories = new[]
        {
            Directory.GetCurrentDirectory(),
            AppContext.BaseDirectory
        };

        foreach (var startDirectory in directories)
        {
            var directory = new DirectoryInfo(startDirectory);
            while (directory is not null)
            {
                var envPath = Path.Combine(directory.FullName, ".env");
                if (visited.Add(envPath) && File.Exists(envPath))
                {
                    yield return envPath;
                }

                directory = directory.Parent;
            }
        }
    }

    private static string? NormalizeCredentialPath(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return Environment.ExpandEnvironmentVariables(value.Trim().Trim('"', '\''));
    }
}
