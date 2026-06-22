using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminImageUploadRequest
{
    [FromForm(Name = "file")]
    public IFormFile? File { get; set; }
}
