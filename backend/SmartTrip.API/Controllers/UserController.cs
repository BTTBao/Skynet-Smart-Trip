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
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UserDto userDto)
    {
        var result = await _userService.UpdateUserProfileAsync(id, userDto);
        if (!result) return BadRequest("Không thể cập nhật hồ sơ");
        return Ok(new { message = "Cập nhật thành công" });
    }
}
