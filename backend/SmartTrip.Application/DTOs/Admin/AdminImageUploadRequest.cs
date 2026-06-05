using Microsoft.AspNetCore.Http;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminImageUploadRequest
{
    public IFormFile? File { get; set; }
}
