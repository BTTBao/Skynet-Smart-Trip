namespace SmartTrip.Application.Interfaces.Email
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string htmlMessage);
        Task SendWelcomeEmailAsync(string toEmail, string fullName);
        Task SendPasswordResetEmailAsync(string toEmail, string fullName, string resetLink);
        Task SendEmailVerificationAsync(string toEmail, string fullName, string otp);
    }
}
