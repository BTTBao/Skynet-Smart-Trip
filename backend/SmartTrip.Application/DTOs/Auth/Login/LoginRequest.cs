using System.ComponentModel.DataAnnotations;

namespace SmartTrip.Application.DTOs.Auth.Login
{
    public class LoginRequest
    {
        /// Email hoặc tên đăng nhập
        [Required(ErrorMessage = "Email hoặc tên đăng nhập là bắt buộc")]
        public string Identifier { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
        public string Password { get; set; } = string.Empty;
    }
}
