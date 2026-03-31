using SmartTrip.Application.DTOs.Auth;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.RefreshToken;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
using SmartTrip.Application.DTOs.Auth.VerifyEmail;

namespace SmartTrip.Application.Interfaces.Auth
{
    public interface IAuthService
    {
        Task<AuthResultDto> LoginAsync(LoginRequest request);
        Task<AuthResultDto> RegisterAsync(RegisterRequest request);
        Task ForgotPasswordAsync(ForgotPasswordRequest request);
        Task<bool> ResetPasswordAsync(ResetPasswordRequest request);
        Task<bool> VerifyEmailAsync(VerifyEmailRequest request);
        Task<AuthResultDto> RefreshTokenAsync(RefreshTokenRequest request);
        Task<bool> RevokeRefreshTokenAsync(string refreshToken);
    }
}
