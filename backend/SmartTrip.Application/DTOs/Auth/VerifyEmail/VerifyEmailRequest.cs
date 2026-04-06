using System.ComponentModel.DataAnnotations;

namespace SmartTrip.Application.DTOs.Auth.VerifyEmail
{
    public class VerifyEmailRequest
    {
        [Required(ErrorMessage = "Email l b?t bu?c")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mã OTP l b?t bu?c")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã OTP phải gồm 6 chữ số")]
        public string Otp { get; set; } = string.Empty;
    }
}
