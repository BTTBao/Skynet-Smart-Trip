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
        if (userId == null) return Unauthorized();

        var profile = await _userService.GetUserProfileAsync(userId.Value);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [Authorize]
    [HttpGet("me/activity-history")]
    public async Task<IActionResult> GetCurrentActivityHistory()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        var history = await _userService.GetActivityHistoryAsync(userId.Value);
        if (history == null) return NotFound();
        return Ok(history);
    }

    [Authorize]
    [HttpPut("me")]
    [HttpPatch("me")]
    public async Task<IActionResult> UpdateCurrentProfile([FromBody] UserDto userDto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        return await UpdateProfile(userId.Value, userDto);
    }

    [Authorize]
    [HttpPost("me/upload-avatar")]
    public async Task<IActionResult> UploadCurrentAvatar(IFormFile file)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        return await UploadAvatar(userId.Value, file);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProfile(int id)
    {
        var profile = await _userService.GetUserProfileAsync(id);
        if (profile == null) return NotFound();
        return Ok(profile);
    }

    [HttpGet("{id}/activity-history")]
    public async Task<IActionResult> GetActivityHistory(int id)
    {
        var history = await _userService.GetActivityHistoryAsync(id);
        if (history == null) return NotFound();
        return Ok(history);
    }

    [HttpPut("{id}")]
    [HttpPatch("{id}")]
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UserDto userDto)
    {
        if (userDto == null)
            return BadRequest("Du lieu cap nhat khong hop le");

        if (string.IsNullOrWhiteSpace(userDto.Name))
            return BadRequest("Ten nguoi dung khong duoc de trong");

        var result = await _userService.UpdateUserProfileAsync(id, userDto);
        if (!result) return BadRequest("Không thể cập nhật hồ sơ");
        return Ok(new { message = "Cập nhật thành công" });
    }

    [HttpPost("{id}/upload-avatar")]
    public async Task<IActionResult> UploadAvatar(int id, IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("Vui lòng chọn ảnh");

        var avatarUrl = await _userService.UploadAvatarAsync(id, file);
        if (avatarUrl == null) return NotFound("Người dùng không tồn tại");

        return Ok(new { avatarUrl });
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
