using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.API.Utilities;
using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.Storage;
using SmartTrip.Application.Interfaces.User;
using System.Security.Claims;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly IImageStorageService _imageStorageService;

    public UserController(IUserService userService, IImageStorageService imageStorageService)
    {
        _userService = userService;
        _imageStorageService = imageStorageService;
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentProfile()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var profile = await _userService.GetUserProfileAsync(userId.Value);
        if (profile == null)
        {
            return NotFound();
        }

        return Ok(profile);
    }

    [Authorize]
    [HttpGet("me/activity-history")]
    public async Task<IActionResult> GetCurrentActivityHistory()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var history = await _userService.GetActivityHistoryAsync(userId.Value);
        if (history == null)
        {
            return NotFound();
        }

        return Ok(history);
    }

    [Authorize]
    [HttpPut("me")]
    [HttpPatch("me")]
    public async Task<IActionResult> UpdateCurrentProfile([FromBody] UpdateUserProfileRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UpdateProfile(userId.Value, request);
    }

    [Authorize]
    [Consumes("multipart/form-data")]
    [HttpPost("me/upload-avatar")]
    // public async Task<IActionResult> UploadCurrentAvatar(IFormFile file)
    public async Task<IActionResult> UploadCurrentAvatar([FromForm] UploadAvatarRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UploadAvatar(userId.Value, request);
    }

    [Authorize]
    [Consumes("multipart/form-data")]
    [HttpPost("me/upload-identity-card")]
    public async Task<IActionResult> UploadCurrentIdentityCardPhoto([FromForm] UploadIdentityCardPhotoRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UploadIdentityCardPhoto(userId.Value, request);
    }

    [Authorize]
    [HttpPut("me/avatar-url")]
    [HttpPatch("me/avatar-url")]
    public async Task<IActionResult> UpdateCurrentAvatarUrl([FromBody] UpdateUserImageUrlRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UpdateAvatarUrl(userId.Value, request);
    }

    [Authorize]
    [HttpPut("me/identity-card-photo-url")]
    [HttpPatch("me/identity-card-photo-url")]
    public async Task<IActionResult> UpdateCurrentIdentityCardPhotoUrl([FromBody] UpdateUserImageUrlRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UpdateIdentityCardPhotoUrl(userId.Value, request);
    }

    [Authorize]
    [HttpGet("me/favorites")]
    public async Task<IActionResult> GetCurrentFavorites()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var favorites = await _userService.GetFavoritesAsync(userId.Value);
        return Ok(favorites);
    }

    [Authorize]
    [HttpPost("me/favorites")]
    public async Task<IActionResult> AddCurrentFavorite([FromBody] CreateFavoriteRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        if (request == null || string.IsNullOrWhiteSpace(request.ItemType) || request.ItemId <= 0)
        {
            return BadRequest("Du lieu yeu thich khong hop le");
        }

        var favorite = await _userService.AddFavoriteAsync(userId.Value, request);
        if (favorite == null)
        {
            return BadRequest("Khong the them muc yeu thich");
        }

        return Ok(favorite);
    }

    [Authorize]
    [HttpDelete("me/favorites/{wishId:int}")]
    public async Task<IActionResult> RemoveCurrentFavorite(int wishId)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var removed = await _userService.RemoveFavoriteAsync(userId.Value, wishId);
        if (!removed)
        {
            return NotFound("Khong tim thay muc yeu thich");
        }

        return Ok(new { message = "Da xoa muc yeu thich" });
    }

    [Authorize]
    [HttpGet("me/settings")]
    public async Task<IActionResult> GetCurrentSettings()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var settings = await _userService.GetUserSettingsAsync(userId.Value);
        if (settings == null)
        {
            return NotFound();
        }

        return Ok(settings);
    }

    [Authorize]
    [HttpPut("me/settings")]
    public async Task<IActionResult> UpdateCurrentSettings([FromBody] UpdateUserSettingsDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        if (request == null)
        {
            return BadRequest("Du lieu cai dat khong hop le");
        }

        if (string.IsNullOrWhiteSpace(request.Language))
        {
            return BadRequest("Ngon ngu khong duoc de trong");
        }

        if (string.IsNullOrWhiteSpace(request.Currency))
        {
            return BadRequest("Don vi tien te khong duoc de trong");
        }

        var settings = await _userService.UpdateUserSettingsAsync(userId.Value, request);
        if (settings == null)
        {
            return NotFound();
        }

        return Ok(settings);
    }

    [Authorize]
    [HttpPost("me/change-password")]
    public async Task<IActionResult> ChangeCurrentPassword([FromBody] ChangePasswordRequestDto request)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        if (request == null)
        {
            return BadRequest("Du lieu doi mat khau khong hop le");
        }

        var result = await _userService.ChangePasswordAsync(userId.Value, request);
        if (!result.Success)
        {
            return BadRequest(result.Message);
        }

        return Ok(new { message = result.Message });
    }

    [Authorize]
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetProfile(int id)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        var profile = await _userService.GetUserProfileAsync(id);
        if (profile == null)
        {
            return NotFound();
        }

        return Ok(profile);
    }

    [Authorize]
    [HttpGet("{id:int}/activity-history")]
    public async Task<IActionResult> GetActivityHistory(int id)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        var history = await _userService.GetActivityHistoryAsync(id);
        if (history == null)
        {
            return NotFound();
        }

        return Ok(history);
    }

    [Authorize]
    [HttpPut("{id:int}")]
    [HttpPatch("{id:int}")]
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UpdateUserProfileRequestDto request)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        if (request == null)
        {
            return BadRequest("Du lieu cap nhat khong hop le");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest("Ten nguoi dung khong duoc de trong");
        }

        var phone = request.Phone?.Trim();
        if (string.IsNullOrWhiteSpace(phone) ||
            phone.Length < 10 ||
            phone.Length > 11 ||
            !phone.All(char.IsDigit))
        {
            return BadRequest("So dien thoai khong hop le");
        }

        if (string.IsNullOrWhiteSpace(request.BirthDate) ||
            !DateTime.TryParse(request.BirthDate, out var birthDate) ||
            birthDate.Date >= DateTime.UtcNow.Date)
        {
            return BadRequest("Ngay sinh khong hop le");
        }

        var identityNumber = request.IdentityNumber?.Trim();
        if (string.IsNullOrWhiteSpace(identityNumber) ||
            (identityNumber.Length != 9 && identityNumber.Length != 12 ||
             !identityNumber.All(char.IsDigit)))
        {
            return BadRequest("So can cuoc cong dan khong hop le (phai co 9 hoac 12 so)");
        }

        bool updated;
        try
        {
            updated = await _userService.UpdateUserProfileAsync(id, request);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        if (!updated)
        {
            return BadRequest("Khong the cap nhat ho so");
        }

        var profile = await _userService.GetUserProfileAsync(id);
        if (profile == null)
        {
            return NotFound();
        }

        return Ok(profile);
    }

    [Authorize]
    [Consumes("multipart/form-data")]
    [HttpPost("{id:int}/upload-avatar")]
    // public async Task<IActionResult> UploadAvatar(int id, IFormFile file)
    public async Task<IActionResult> UploadAvatar(int id, [FromForm] UploadAvatarRequestDto request)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        var file = request.File;
        if (file == null || file.Length == 0)
        {
            return BadRequest("Vui long chon anh");
        }

        if (file.Length > 5 * 1024 * 1024)
        {
            return BadRequest("Anh dai dien khong duoc vuot qua 5MB");
        }

        await using var stream = file.OpenReadStream();
        if (!ImageUploadValidation.TryValidateImageStream(stream, file.FileName, out var errorMessage, out var resolvedContentType))
        {
            return BadRequest(TranslateImageValidationMessage(errorMessage));
        }

        var upload = await _imageStorageService.UploadImageAsync(
            stream,
            file.FileName,
            resolvedContentType ?? file.ContentType,
            $"users/{id}/avatars",
            HttpContext.RequestAborted);

        var avatarUrl = await _userService.UpdateAvatarUrlAsync(id, upload.ImageUrl);
        if (avatarUrl == null)
        {
            return NotFound("Nguoi dung khong ton tai");
        }

        return Ok(new { avatarUrl, imageUrl = avatarUrl, imagePath = upload.ImagePath, fileName = upload.FileName });
    }

    [Authorize]
    [HttpPut("{id:int}/avatar-url")]
    [HttpPatch("{id:int}/avatar-url")]
    public async Task<IActionResult> UpdateAvatarUrl(int id, [FromBody] UpdateUserImageUrlRequestDto request)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        if (request == null || string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest("Duong dan anh khong hop le");
        }

        try
        {
            var avatarUrl = await _userService.UpdateAvatarUrlAsync(id, request.ImageUrl);
            return avatarUrl == null
                ? NotFound("Nguoi dung khong ton tai")
                : Ok(new { avatarUrl, imageUrl = avatarUrl });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize]
    [Consumes("multipart/form-data")]
    [HttpPost("{id:int}/upload-identity-card")]
    public async Task<IActionResult> UploadIdentityCardPhoto(int id, [FromForm] UploadIdentityCardPhotoRequestDto request)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        var file = request.File;
        if (file == null || file.Length == 0)
        {
            return BadRequest("Vui long chon anh");
        }

        if (file.Length > 5 * 1024 * 1024)
        {
            return BadRequest("Anh mat truoc CCCD khong duoc vuot qua 5MB");
        }

        await using var stream = file.OpenReadStream();
        if (!ImageUploadValidation.TryValidateImageStream(stream, file.FileName, out var errorMessage, out var resolvedContentType))
        {
            return BadRequest(TranslateImageValidationMessage(errorMessage));
        }

        var upload = await _imageStorageService.UploadImageAsync(
            stream,
            file.FileName,
            resolvedContentType ?? file.ContentType,
            $"users/{id}/identity-cards",
            HttpContext.RequestAborted);

        var identityCardPhotoUrl = await _userService.UpdateIdentityCardPhotoUrlAsync(id, upload.ImageUrl);
        if (identityCardPhotoUrl == null)
        {
            return NotFound("Nguoi dung khong ton tai");
        }

        return Ok(new { identityCardPhotoUrl, imageUrl = identityCardPhotoUrl, imagePath = upload.ImagePath, fileName = upload.FileName });
    }

    [Authorize]
    [HttpPut("{id:int}/identity-card-photo-url")]
    [HttpPatch("{id:int}/identity-card-photo-url")]
    public async Task<IActionResult> UpdateIdentityCardPhotoUrl(int id, [FromBody] UpdateUserImageUrlRequestDto request)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        if (request == null || string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest("Duong dan anh khong hop le");
        }

        try
        {
            var identityCardPhotoUrl = await _userService.UpdateIdentityCardPhotoUrlAsync(id, request.ImageUrl);
            return identityCardPhotoUrl == null
                ? NotFound("Nguoi dung khong ton tai")
                : Ok(new { identityCardPhotoUrl, imageUrl = identityCardPhotoUrl });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    private IActionResult? EnsureCurrentUserAccess(int userId)
    {
        var currentUserId = GetCurrentUserId();
        if (currentUserId == null)
        {
            return Unauthorized();
        }

        if (currentUserId.Value != userId)
        {
            return Forbid();
        }

        return null;
    }

    private int? GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        return int.TryParse(rawUserId, out var userId) ? userId : null;
    }

    private static string TranslateImageValidationMessage(string? errorMessage)
    {
        return errorMessage switch
        {
            "Only JPG, PNG, or WEBP images are supported." => "Chi ho tro anh JPG, PNG hoac WEBP",
            "The uploaded file is not a valid JPG, PNG, or WEBP image." => "File tai len khong phai la anh hop le",
            "The uploaded file extension does not match its actual image format." => "Dinh dang tep khong khop voi noi dung anh",
            _ => "File tai len khong phai la anh hop le"
        };
    }
}
