using System.ComponentModel.DataAnnotations;

namespace SmartTrip.Application.DTOs.Auth.Login
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "Email là bắt buộc")]
        [RegularExpression(
            @"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
            ErrorMessage = "Email không hợp lệ"
        )]
        public string Email { get; set; } = string.Empty;
        [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
        [MinLength(8, ErrorMessage = "Mật khẩu tối thiểu 8 ký tự")]
        public string Password { get; set; } = string.Empty;
    }
}
