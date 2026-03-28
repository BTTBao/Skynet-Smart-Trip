using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.API.Requests;
using SmartTrip.Application.DTOs.Auth;
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
            var loginDto = new LoginRequestDto
            {
                Email = request.Email,
                Password = request.Password
            };

            var result = await _authService.LoginAsync(loginDto);

            if (!result.IsSuccess)
            {
                return Unauthorized(new { message = result.ErrorMessage });
            }

            return Ok(new
            {
                access_token = result.Token,
                token_type = "Bearer",
                expires_in = result.ExpiresIn
            });
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var registerDto = new RegisterRequestDto
            {
                Email = request.Email,
                Password = request.Password,
                FullName = request.FullName,
                Phone = request.Phone
            };

            var result = await _authService.RegisterAsync(registerDto);

            if (!result.IsSuccess)
            {
                return BadRequest(new { message = result.ErrorMessage });
            }

            return Ok(new { message = "Đăng ký thành công. Vui lòng đăng nhập." });
        }

        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            var forgotPasswordDto = new ForgotPasswordRequestDto
            {
                Email = request.Email
            };

            await _authService.ForgotPasswordAsync(forgotPasswordDto);

            return Ok(new { message = "Nếu email hợp lệ, một liên kết sẽ được gửi đến hòm thư của bạn." });
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            var resetPasswordDto = new ResetPasswordRequestDto
            {
                Email = request.Email,
                Token = request.Token,
                NewPassword = request.NewPassword
            };

            var success = await _authService.ResetPasswordAsync(resetPasswordDto);

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
