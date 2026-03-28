using SmartTrip.Application.DTOs.Auth;

namespace SmartTrip.Application.Interfaces.Auth
{
    public interface IAuthService
    {
        Task<AuthResultDto> LoginAsync(LoginRequestDto request);
        Task<AuthResultDto> RegisterAsync(RegisterRequestDto request);
        Task<bool> ForgotPasswordAsync(ForgotPasswordRequestDto request);
        Task<bool> ResetPasswordAsync(ResetPasswordRequestDto request);
    }
}
