namespace SmartTrip.Application.Interfaces.Storage;

public interface IImageStorageService
{
    Task<ImageStorageUploadResult> UploadImageAsync(
        Stream fileStream,
        string originalFileName,
        string contentType,
        string folder,
        CancellationToken cancellationToken = default);
}

public sealed class ImageStorageUploadResult
{
    public string ImageUrl { get; init; } = string.Empty;

    public string ImagePath { get; init; } = string.Empty;

    public string FileName { get; init; } = string.Empty;
}

public sealed class ImageStorageUnavailableException : InvalidOperationException
{
    public ImageStorageUnavailableException(string message, Exception? innerException = null)
        : base(message, innerException)
    {
    }
}
