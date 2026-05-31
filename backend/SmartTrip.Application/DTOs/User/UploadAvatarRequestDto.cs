using Microsoft.AspNetCore.Http;

namespace SmartTrip.Application.DTOs.User;

public class UploadAvatarRequestDto
{
    public IFormFile? File { get; set; }
}
