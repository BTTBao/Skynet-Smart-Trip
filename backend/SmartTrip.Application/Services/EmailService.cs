using Microsoft.Extensions.Logging;
using SmartTrip.Application.Interfaces.Email;

namespace SmartTrip.Application.Services
{
    public class EmailService : IEmailService
    {
        private readonly ILogger<EmailService> _logger;

        public EmailService(ILogger<EmailService> logger)
        {
            _logger = logger;
        }

        public Task SendEmailAsync(string toEmail, string subject, string htmlMessage)
        {
            _logger.LogInformation("[EMAIL] To: {To} | Subject: {Subject} | Body: {Body}",
            toEmail, subject, htmlMessage);

            return Task.CompletedTask;
        }
    }
}
