using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using System.Security.Claims;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;

    public UserController(IUserService userService)
    {
        _userService = userService;
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
    [HttpPost("me/upload-avatar")]
    public async Task<IActionResult> UploadCurrentAvatar(IFormFile file)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        return await UploadAvatar(userId.Value, file);
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

        if (!string.IsNullOrWhiteSpace(request.Phone) && request.Phone.Trim().Length < 10)
        {
            return BadRequest("So dien thoai khong hop le");
        }

        if (!string.IsNullOrWhiteSpace(request.BirthDate) &&
            !DateTime.TryParse(request.BirthDate, out _))
        {
            return BadRequest("Ngay sinh khong hop le");
        }

        var updated = await _userService.UpdateUserProfileAsync(id, request);
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
    [HttpPost("{id:int}/upload-avatar")]
    public async Task<IActionResult> UploadAvatar(int id, IFormFile file)
    {
        var accessResult = EnsureCurrentUserAccess(id);
        if (accessResult != null)
        {
            return accessResult;
        }

        if (file == null || file.Length == 0)
        {
            return BadRequest("Vui long chon anh");
        }

        if (file.Length > 5 * 1024 * 1024)
        {
            return BadRequest("Anh dai dien khong duoc vuot qua 5MB");
        }

        var extension = Path.GetExtension(file.FileName);
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (string.IsNullOrWhiteSpace(extension) ||
            !allowedExtensions.Contains(extension, StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest("Chi ho tro anh JPG, PNG hoac WEBP");
        }

        if (string.IsNullOrWhiteSpace(file.ContentType) ||
            !file.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest("File tai len khong phai la anh hop le");
        }

        var avatarUrl = await _userService.UploadAvatarAsync(id, file);
        if (avatarUrl == null)
        {
            return NotFound("Nguoi dung khong ton tai");
        }

        return Ok(new { avatarUrl });
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
}
