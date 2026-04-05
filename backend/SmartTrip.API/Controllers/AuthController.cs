using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.RefreshToken;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
using SmartTrip.Application.DTOs.Auth.VerifyEmail;
using SmartTrip.Application.Interfaces.Auth;
using System.Security.Claims;

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

        /// <summary>Đăng nhập — trả về access token + refresh token</summary>
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var result = await _authService.LoginAsync(request);

            if (!result.IsSuccess)
                return Unauthorized(new { success = false, message = result.ErrorMessage });

            return Ok(new LoginResponse
            {
                AccessToken = result.AccessToken,
                RefreshToken = result.RefreshToken,
                ExpiresIn = result.ExpiresIn
            });
        }

        /// <summary>Đăng ký tài khoản mới — gửi email xác thực</summary>
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var result = await _authService.RegisterAsync(request);

            if (!result.IsSuccess)
                return BadRequest(new { success = false, message = result.ErrorMessage });

            return StatusCode(StatusCodes.Status201Created, new
            {
                success = true,
                message = "Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản."
            });
        }

        /// <summary>Xác thực email qua OTP sau khi đăng ký</summary>
        [HttpPost("verify-email")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Otp))
                return BadRequest(new { success = false, message = "Email v mã OTP không h?p l?." });

            var success = await _authService.VerifyEmailAsync(request);

            if (!success)
                return BadRequest(new { success = false, message = "Mã OTP không hợp lệ hoặc đã hết hạn." });

            return Ok(new { success = true, message = "Email đã được xác thực thành công! Bạn có thể bắt đầu sử dụng." });
        }

        /// <summary>Yêu cầu đặt lại mật khẩu — gửi email reset link</summary>
        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _authService.ForgotPasswordAsync(request);

            // Always return 200 to prevent email enumeration
            return Ok(new { success = true, message = "Nếu email tồn tại trong hệ thống, một liên kết đặt lại mật khẩu sẽ được gửi đến hòm thư của bạn." });
        }

        /// <summary>Đặt lại mật khẩu bằng token từ email</summary>
        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            var success = await _authService.ResetPasswordAsync(request);

            if (!success)
                return BadRequest(new { success = false, message = "Token đặt lại mật khẩu không hợp lệ hoặc đã hết hạn (15 phút)." });

            return Ok(new { success = true, message = "Mật khẩu đã được thay đổi thành công! Vui lòng đăng nhập lại." });
        }

        /// <summary>Làm mới access token bằng refresh token</summary>
        [HttpPost("refresh-token")]
        [AllowAnonymous]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            var result = await _authService.RefreshTokenAsync(request);

            if (!result.IsSuccess)
                return Unauthorized(new { success = false, message = result.ErrorMessage });

            return Ok(new LoginResponse
            {
                AccessToken = result.AccessToken,
                RefreshToken = result.RefreshToken,
                ExpiresIn = result.ExpiresIn
            });
        }

        /// <summary>Đăng xuất — thu hồi refresh token</summary>
        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            await _authService.RevokeRefreshTokenAsync(request.RefreshToken);
            return Ok(new { success = true, message = "Đăng xuất thành công." });
        }

        /// <summary>Lấy thông tin người dùng hiện tại</summary>
        [HttpGet("me")]
        [Authorize]
        public IActionResult GetProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var email = User.FindFirstValue(ClaimTypes.Email);
            var role = User.FindFirstValue(ClaimTypes.Role);
            var fullName = User.FindFirstValue("fullName");

            return Ok(new
            {
                success = true,
                data = new { userId, email, fullName, role }
            });
        }
    }
}
