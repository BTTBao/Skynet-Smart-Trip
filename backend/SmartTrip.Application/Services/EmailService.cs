using SmartTrip.Application.Interfaces.Email;
using System.Diagnostics;

namespace SmartTrip.Application.Services
{
    public class EmailService : IEmailService
    {
        public Task SendEmailAsync(string toEmail, string subject, string htmlMessage)
        {
            Debug.WriteLine($"[EMAIL SENT to {toEmail}]: Subject: {subject} | Content: {htmlMessage}");
            return Task.CompletedTask;
        }
    }
}
