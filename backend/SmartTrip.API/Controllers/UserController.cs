using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;

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

    [HttpGet("{id}")]
    public async Task<IActionResult> GetProfile(int id)
    {
        var profile = await _userService.GetUserProfileAsync(id);
        if (profile == null) return NotFound();
        return Ok(profile);
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
}
