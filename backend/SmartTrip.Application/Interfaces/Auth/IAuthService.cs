using SmartTrip.Application.DTOs.Auth;
using SmartTrip.Application.DTOs.Auth.ForgotPassword;
using SmartTrip.Application.DTOs.Auth.Login;
using SmartTrip.Application.DTOs.Auth.Register;
using SmartTrip.Application.DTOs.Auth.ResetPassword;
namespace SmartTrip.Application.Interfaces.Auth
{
    public interface IAuthService
    {
        Task<AuthResultDto> LoginAsync(LoginRequest request);
        Task<AuthResultDto> RegisterAsync(RegisterRequest request);
        Task<bool> ForgotPasswordAsync(ForgotPasswordRequest request);
        Task<bool> ResetPasswordAsync(ResetPasswordRequest request);
    }
}
