using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
using SmartTrip.Application.Interfaces.Auth;

namespace SmartTrip.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var result = await _authService.LoginAsync(request);

            if (!result.IsSuccess)
            {
                return Unauthorized(new { message = result.ErrorMessage });
            }

            var response = new LoginResponse
            {
                AccessToken = result.Token,
                ExpiresIn = result.ExpiresIn
            };

            return Ok(response);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var result = await _authService.RegisterAsync(request);

            if (!result.IsSuccess)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            var response = new RegisterResponse
            {
                Message = "Đăng ký thành công. Vui lòng đăng nhập."
            };

            return StatusCode(StatusCodes.Status201Created, response);
        }

        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _authService.ForgotPasswordAsync(request);

            return Ok(new { message = "Nếu email hợp lệ, một liên kết sẽ được gửi đến hòm thư của bạn." });
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            var success = await _authService.ResetPasswordAsync(request);

            if (!success)
                return BadRequest(new { message = "Yêu cầu đặt lại mật khẩu không hợp lệ hoặc đã hết hạn." });

            return Ok(new { message = "Mật khẩu đã được thay đổi thành công!" });
        }

        [HttpGet("me")]
        [Authorize]
        public IActionResult GetProfile()
        {
            var email = User.Claims.FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.Email)?.Value;

            return Ok(new
            {
                Message = "Bạn đã truy cập thành công API được bảo vệ!",
                Email = email
            });
        }
    }
}
