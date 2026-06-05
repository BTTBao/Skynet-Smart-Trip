using Microsoft.AspNetCore.Http;

namespace SmartTrip.API.Utilities;

public static class ImageUploadValidation
{
    private static readonly Dictionary<string, string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        [".jpg"] = "image/jpeg",
        [".jpeg"] = "image/jpeg",
        [".png"] = "image/png",
        [".webp"] = "image/webp"
    };

    public static bool TryValidateImageFile(
        IFormFile? file,
        out string? errorMessage,
        out string? resolvedContentType)
    {
        errorMessage = null;
        resolvedContentType = null;

        if (file == null || file.Length == 0)
        {
            errorMessage = "Image file is required.";
            return false;
        }

        var extension = Path.GetExtension(file.FileName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.TryGetValue(extension, out var expectedContentType))
        {
            errorMessage = "Only JPG, PNG, or WEBP images are supported.";
            return false;
        }

        using var stream = file.OpenReadStream();
        var detectedContentType = DetectContentType(stream);
        if (detectedContentType == null)
        {
            errorMessage = "The uploaded file is not a valid JPG, PNG, or WEBP image.";
            return false;
        }

        if (!string.Equals(detectedContentType, expectedContentType, StringComparison.OrdinalIgnoreCase))
        {
            errorMessage = "The uploaded file extension does not match its actual image format.";
            return false;
        }

        resolvedContentType = detectedContentType;
        return true;
    }

    public static bool TryValidateImageStream(
        Stream stream,
        string fileName,
        out string? errorMessage,
        out string? resolvedContentType)
    {
        errorMessage = null;
        resolvedContentType = null;

        var extension = Path.GetExtension(fileName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.TryGetValue(extension, out var expectedContentType))
        {
            errorMessage = "Only JPG, PNG, or WEBP images are supported.";
            return false;
        }

        var detectedContentType = DetectContentType(stream);
        if (detectedContentType == null)
        {
            errorMessage = "The uploaded file is not a valid JPG, PNG, or WEBP image.";
            return false;
        }

        if (!string.Equals(detectedContentType, expectedContentType, StringComparison.OrdinalIgnoreCase))
        {
            errorMessage = "The uploaded file extension does not match its actual image format.";
            return false;
        }

        resolvedContentType = detectedContentType;
        return true;
    }

    public static string GetAllowedFormatsMessage() => "Only JPG, PNG, or WEBP images are supported.";

    private static string? DetectContentType(Stream stream)
    {
        Span<byte> header = stackalloc byte[12];
        var originalPosition = stream.CanSeek ? stream.Position : 0;
        var bytesRead = stream.Read(header);

        if (stream.CanSeek)
        {
            stream.Position = originalPosition;
        }

        if (bytesRead >= 3 &&
            header[0] == 0xFF &&
            header[1] == 0xD8 &&
            header[2] == 0xFF)
        {
            return "image/jpeg";
        }

        if (bytesRead >= 8 &&
            header[0] == 0x89 &&
            header[1] == 0x50 &&
            header[2] == 0x4E &&
            header[3] == 0x47 &&
            header[4] == 0x0D &&
            header[5] == 0x0A &&
            header[6] == 0x1A &&
            header[7] == 0x0A)
        {
            return "image/png";
        }

        if (bytesRead >= 12 &&
            header[0] == 0x52 &&
            header[1] == 0x49 &&
            header[2] == 0x46 &&
            header[3] == 0x46 &&
            header[8] == 0x57 &&
            header[9] == 0x45 &&
            header[10] == 0x42 &&
            header[11] == 0x50)
        {
            return "image/webp";
        }

        return null;
    }
}
