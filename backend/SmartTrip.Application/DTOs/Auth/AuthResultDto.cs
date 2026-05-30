namespace SmartTrip.Application.DTOs.Auth
{
    public class AuthResultDto
    {
        public bool IsSuccess { get; set; }
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public int ExpiresIn { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;

        // Keep backwards-compat alias
        public string Token => AccessToken;
    }
}
