namespace SmartTrip.Application.Interfaces.Email
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string htmlMessage);
        Task SendWelcomeEmailAsync(string toEmail, string fullName);
        Task SendPasswordResetEmailAsync(string toEmail, string fullName, string resetLink);
        Task SendEmailVerificationAsync(string toEmail, string fullName, string otp);
        Task SendBookingConfirmationEmailAsync(
            string toEmail, 
            string fullName, 
            string bookingCode, 
            string hotelName, 
            string dateRange, 
            string roomInfo, 
            string totalPrice, 
            string paymentMethod);
        Task SendHotelBookingCreatedEmailAsync(string toEmail, string fullName, string bookingTitle, string travelWindow);
        Task SendPaymentSuccessEmailAsync(string toEmail, string fullName, string tripTitle, decimal amount, string? transactionId);
        Task SendPaymentFailedEmailAsync(string toEmail, string fullName, string tripTitle, string status);
        Task SendBookingStatusChangedEmailAsync(string toEmail, string fullName, string bookingTitle, string statusLabel, decimal? amount);
        Task SendPasswordChangedEmailAsync(string toEmail, string fullName);
        Task SendAccountStatusChangedEmailAsync(string toEmail, string fullName, bool isActive);
    }
}
