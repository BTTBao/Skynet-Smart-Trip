using System.ComponentModel.DataAnnotations;

namespace SmartTrip.Application.DTOs.Auth.RefreshToken
{
    public class RefreshTokenRequest
    {
        [Required(ErrorMessage = "Refresh token là bắt buộc")]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
