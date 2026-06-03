using Microsoft.AspNetCore.Http;

namespace SmartTrip.Application.DTOs.User;

public class UploadIdentityCardPhotoRequestDto
{
    public IFormFile? File { get; set; }
}
