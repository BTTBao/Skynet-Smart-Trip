using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.Interfaces.Notifications;

namespace SmartTrip.Infrastructure.Services.Notifications;

public class FcmPushService : IFcmPushService
{
    private const string FirebaseAppName = "SmartTripFcm";
    private static readonly object AppLock = new();
    private static FirebaseApp? _firebaseApp;

    private readonly IApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<FcmPushService> _logger;
    private bool _credentialsWarningLogged;

    public FcmPushService(
        IApplicationDbContext context,
        IConfiguration configuration,
        ILogger<FcmPushService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendToUserAsync(
        int userId,
        NotificationDto notification,
        CancellationToken cancellationToken = default)
    {
        if (userId <= 0)
        {
            return;
        }

        var tokens = await _context.UserFcmTokens
            .Where(item => item.UserId == userId && item.IsActive)
            .OrderByDescending(item => item.LastUsedAt ?? item.UpdatedAt)
            .ToListAsync(cancellationToken);

        if (tokens.Count == 0)
        {
            _logger.LogInformation(
                "Skip FCM push for user {UserId}: no active FCM tokens. NotificationId={NotificationId}",
                userId,
                notification.Id);
            return;
        }

        var messaging = TryGetMessaging();
        if (messaging == null)
        {
            return;
        }

        var message = new MulticastMessage
        {
            Tokens = tokens.Select(item => item.Token).ToList(),
            Notification = new FirebaseAdmin.Messaging.Notification
            {
                Title = notification.Title,
                Body = notification.Message
            },
            Data = BuildData(notification),
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = "smarttrip_notifications",
                    ClickAction = "FLUTTER_NOTIFICATION_CLICK"
                }
            }
        };

        try
        {
            var response = await messaging.SendEachForMulticastAsync(message, cancellationToken);
            var now = DateTime.UtcNow;
            var hasTokenUpdates = false;

            for (var i = 0; i < response.Responses.Count && i < tokens.Count; i++)
            {
                var sendResponse = response.Responses[i];
                var token = tokens[i];

                if (sendResponse.IsSuccess)
                {
                    token.LastUsedAt = now;
                    token.UpdatedAt = now;
                    hasTokenUpdates = true;
                    continue;
                }

                _logger.LogWarning(
                    sendResponse.Exception,
                    "FCM send failed for token {TokenId} and notification {NotificationId}",
                    token.Id,
                    notification.Id);

                if (sendResponse.Exception is FirebaseMessagingException exception &&
                    IsInvalidTokenError(exception))
                {
                    token.IsActive = false;
                    token.UpdatedAt = now;
                    hasTokenUpdates = true;
                }
            }

            if (hasTokenUpdates)
            {
                await _context.SaveChangesAsync(cancellationToken);
            }

            _logger.LogInformation(
                "FCM push sent for user {UserId}. NotificationId={NotificationId}, Success={SuccessCount}, Failure={FailureCount}",
                userId,
                notification.Id,
                response.SuccessCount,
                response.FailureCount);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "FCM send failed for user {UserId}", userId);
        }
    }

    private FirebaseMessaging? TryGetMessaging()
    {
        try
        {
            lock (AppLock)
            {
                _firebaseApp ??= FirebaseApp.Create(
                    new AppOptions { Credential = LoadCredential() },
                    FirebaseAppName);

                return FirebaseMessaging.GetMessaging(_firebaseApp);
            }
        }
        catch (Exception ex)
        {
            if (!_credentialsWarningLogged)
            {
                _credentialsWarningLogged = true;
                _logger.LogWarning(
                    ex,
                    "Firebase Admin credential is not configured. Set GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_SERVICE_ACCOUNT_PATH, or Firebase:ServiceAccountPath to enable FCM.");
            }

            return null;
        }
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
                _logger.LogInformation("Using Firebase Admin credential from {CredentialPath}", configuredPath);
                using var stream = File.OpenRead(configuredPath);
                return ServiceAccountCredential
                    .FromServiceAccountData(stream)
                    .ToGoogleCredential();
            }

            _logger.LogWarning("Firebase Admin credential path does not exist: {CredentialPath}", configuredPath);
        }

        return GoogleCredential.GetApplicationDefault();
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
                if (!string.Equals(name, key, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                return trimmed[(separatorIndex + 1)..].Trim();
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

    private static Dictionary<string, string> BuildData(NotificationDto notification)
    {
        var data = new Dictionary<string, string>
        {
            ["notificationId"] = notification.Id.ToString(),
            ["type"] = notification.Type,
            ["title"] = notification.Title,
            ["body"] = notification.Message,
            ["routeTarget"] = InferRouteTarget(notification)
        };

        if (!string.IsNullOrWhiteSpace(notification.ReferenceType))
        {
            data["relatedEntityType"] = notification.ReferenceType;
        }

        if (notification.ReferenceId.HasValue)
        {
            data["relatedEntityId"] = notification.ReferenceId.Value.ToString();
        }

        if (!string.IsNullOrWhiteSpace(notification.ActionUrl))
        {
            data["actionUrl"] = notification.ActionUrl;
        }

        return data;
    }

    private static string InferRouteTarget(NotificationDto notification)
    {
        var type = notification.Type.ToLowerInvariant();
        var referenceType = notification.ReferenceType?.ToLowerInvariant();

        if (type.StartsWith("explore") || referenceType == "explore_post")
        {
            return "explore_post_detail";
        }

        if (type.StartsWith("trip") ||
            type.StartsWith("booking") ||
            type.StartsWith("payment") ||
            referenceType is "trip" or "booking")
        {
            return "trip_detail";
        }

        return "notifications";
    }

    private static bool IsInvalidTokenError(FirebaseMessagingException exception)
    {
        var code = exception.MessagingErrorCode.ToString();
        return string.Equals(code, "Unregistered", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(code, "InvalidArgument", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(code, "SenderIdMismatch", StringComparison.OrdinalIgnoreCase);
    }
}
