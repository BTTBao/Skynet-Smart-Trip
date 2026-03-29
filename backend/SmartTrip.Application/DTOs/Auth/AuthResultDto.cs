namespace SmartTrip.Application.DTOs.Auth
{
    public class AuthResultDto
    {
        public bool IsSuccess { get; set; }
        public string Token { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
        public int ExpiresIn { get; set; } 
    }
}
