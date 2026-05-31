using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using SmartTrip.Application.Interfaces.Email;
using System.Globalization;
using System.Net;

namespace SmartTrip.Application.Services.Email
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string htmlMessage)
        {
            try
            {
                var message = BuildMimeMessage(toEmail, subject, htmlMessage);
                await SendAsync(message);
                _logger.LogInformation("Email sent to {Email} | Subject: {Subject}", toEmail, subject);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send email to {Email}", toEmail);
                throw;
            }
        }

        public Task SendWelcomeEmailAsync(string toEmail, string fullName) =>
            SendEmailAsync(toEmail, "Chào mừng bạn đến với SmartTrip! 🌏", BuildWelcomeHtml(fullName));

        public Task SendPasswordResetEmailAsync(string toEmail, string fullName, string resetLink) =>
            SendEmailAsync(toEmail, "Đặt lại mật khẩu SmartTrip", BuildPasswordResetHtml(fullName, resetLink));

        public Task SendEmailVerificationAsync(string toEmail, string fullName, string otp) =>
            SendEmailAsync(toEmail, "Xác thực email SmartTrip", BuildEmailVerificationHtml(fullName, otp));

        public Task SendHotelBookingCreatedEmailAsync(string toEmail, string fullName, string bookingTitle, string travelWindow) =>
            SendEmailAsync(
                toEmail,
                "SmartTrip đã ghi nhận đặt phòng của bạn",
                BuildBusinessNotificationHtml(
                    "Đặt phòng đã được ghi nhận",
                    fullName,
                    "SmartTrip đã nhận thông tin đặt phòng của bạn. Chúng tôi sẽ tiếp tục cập nhật khi trạng thái booking thay đổi.",
                    [
                        ("Booking", bookingTitle),
                        ("Thời gian lưu trú", travelWindow),
                        ("Trạng thái", "Đang chờ xử lý")
                    ],
                    "Bạn có thể theo dõi chi tiết trong mục Chuyến đi của ứng dụng SmartTrip."));

        public Task SendPaymentSuccessEmailAsync(string toEmail, string fullName, string tripTitle, decimal amount, string? transactionId) =>
            SendEmailAsync(
                toEmail,
                "Thanh toán SmartTrip đã hoàn tất",
                BuildBusinessNotificationHtml(
                    "Thanh toán thành công",
                    fullName,
                    "Khoản thanh toán của bạn đã được ghi nhận thành công. Booking liên quan đã được cập nhật trạng thái.",
                    [
                        ("Chuyến đi", tripTitle),
                        ("Số tiền", FormatCurrency(amount)),
                        ("Mã giao dịch", string.IsNullOrWhiteSpace(transactionId) ? "Đang cập nhật" : transactionId)
                    ],
                    "Cảm ơn bạn đã sử dụng SmartTrip. Hãy kiểm tra lại lịch trình trước ngày khởi hành."));

        public Task SendPaymentFailedEmailAsync(string toEmail, string fullName, string tripTitle, string status) =>
            SendEmailAsync(
                toEmail,
                "Thanh toán SmartTrip chưa hoàn tất",
                BuildBusinessNotificationHtml(
                    "Thanh toán chưa hoàn tất",
                    fullName,
                    "Giao dịch thanh toán cho booking của bạn chưa hoàn tất. Booking vẫn được giữ theo trạng thái hiện tại nếu hệ thống còn cho phép.",
                    [
                        ("Chuyến đi", tripTitle),
                        ("Trạng thái thanh toán", status)
                    ],
                    "Bạn có thể mở lại booking trong ứng dụng để kiểm tra hoặc thử thanh toán lại."));

        public Task SendBookingStatusChangedEmailAsync(string toEmail, string fullName, string bookingTitle, string statusLabel, decimal? amount) =>
            SendEmailAsync(
                toEmail,
                "Cập nhật trạng thái booking SmartTrip",
                BuildBusinessNotificationHtml(
                    "Booking của bạn vừa được cập nhật",
                    fullName,
                    "SmartTrip đã cập nhật trạng thái booking của bạn.",
                    [
                        ("Booking", bookingTitle),
                        ("Trạng thái mới", statusLabel),
                        ("Giá trị booking", amount.HasValue ? FormatCurrency(amount.Value) : "Đang cập nhật")
                    ],
                    "Vui lòng mở ứng dụng để xem chi tiết mới nhất."));

        public Task SendPasswordChangedEmailAsync(string toEmail, string fullName) =>
            SendEmailAsync(
                toEmail,
                "Mật khẩu SmartTrip đã được thay đổi",
                BuildBusinessNotificationHtml(
                    "Mật khẩu đã được cập nhật",
                    fullName,
                    "Mật khẩu tài khoản SmartTrip của bạn vừa được thay đổi thành công.",
                    [
                        ("Tài khoản", toEmail),
                        ("Thời gian", DateTime.UtcNow.ToString("dd/MM/yyyy HH:mm 'UTC'", CultureInfo.InvariantCulture))
                    ],
                    "Nếu bạn không thực hiện thao tác này, hãy đặt lại mật khẩu ngay và liên hệ hỗ trợ SmartTrip."));

        public Task SendAccountStatusChangedEmailAsync(string toEmail, string fullName, bool isActive) =>
            SendEmailAsync(
                toEmail,
                isActive ? "Tài khoản SmartTrip đã được mở khóa" : "Tài khoản SmartTrip đã bị khóa",
                BuildBusinessNotificationHtml(
                    isActive ? "Tài khoản đã được mở khóa" : "Tài khoản đã bị khóa",
                    fullName,
                    isActive
                        ? "Tài khoản SmartTrip của bạn đã được mở lại. Bạn có thể tiếp tục đăng nhập và sử dụng dịch vụ."
                        : "Tài khoản SmartTrip của bạn đã tạm thời bị khóa bởi quản trị viên.",
                    [
                        ("Tài khoản", toEmail),
                        ("Trạng thái", isActive ? "Đang hoạt động" : "Đã khóa")
                    ],
                    isActive
                        ? "Cảm ơn bạn đã tiếp tục đồng hành cùng SmartTrip."
                        : "Nếu cần hỗ trợ, vui lòng liên hệ đội ngũ SmartTrip để được kiểm tra."));

        // ──────────────────────────────────────────────
        // Private helpers
        // ──────────────────────────────────────────────

        private MimeMessage BuildMimeMessage(string toEmail, string subject, string htmlBody)
        {
            var senderName = _configuration["EmailSettings:SenderName"] ?? "SmartTrip";
            var senderEmail = _configuration["EmailSettings:SenderEmail"]
                ?? throw new InvalidOperationException("Missing EmailSettings:SenderEmail");

            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(senderName, senderEmail));
            message.To.Add(MailboxAddress.Parse(toEmail));
            message.Subject = subject;
            message.Body = new TextPart("html") { Text = htmlBody };
            return message;
        }

        private async Task SendAsync(MimeMessage message)
        {
            var host = NormalizeConfigValue(_configuration["EmailSettings:SmtpHost"])
                ?? throw new InvalidOperationException("Missing EmailSettings:SmtpHost");
            var port = int.Parse(_configuration["EmailSettings:SmtpPort"] ?? "587");
            var timeoutSeconds = int.TryParse(_configuration["EmailSettings:TimeoutSeconds"], out var configuredTimeoutSeconds)
                ? Math.Clamp(configuredTimeoutSeconds, 3, 60)
                : 5;
            var username = NormalizeConfigValue(_configuration["EmailSettings:Username"])
                ?? throw new InvalidOperationException("Missing EmailSettings:Username");
            var password = NormalizeSecretValue(
                    _configuration["EmailSettings:Password"],
                    collapseSpaces: host.Contains("gmail", StringComparison.OrdinalIgnoreCase))
                ?? throw new InvalidOperationException("Missing EmailSettings:Password");
            var secureSocketOption = ResolveSecureSocketOption(port);

            using var client = new SmtpClient();
            client.Timeout = timeoutSeconds * 1000;

            _logger.LogInformation(
                "Connecting to SMTP {Host}:{Port} using {Security} with timeout {TimeoutSeconds}s",
                host,
                port,
                secureSocketOption,
                timeoutSeconds);

            await client.ConnectAsync(host, port, secureSocketOption);
            await client.AuthenticateAsync(username, password);
            await client.SendAsync(message);
            await client.DisconnectAsync(true);
        }

        private SecureSocketOptions ResolveSecureSocketOption(int port)
        {
            var configured = NormalizeConfigValue(_configuration["EmailSettings:SecureSocketOption"]);
            if (!string.IsNullOrWhiteSpace(configured) &&
                Enum.TryParse<SecureSocketOptions>(configured, true, out var parsed))
            {
                return parsed;
            }

            return port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
        }

        private static string? NormalizeConfigValue(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            return value.Trim().Trim('"');
        }

        private static string? NormalizeSecretValue(string? value, bool collapseSpaces = false)
        {
            var normalized = NormalizeConfigValue(value);
            if (normalized == null)
            {
                return null;
            }

            return collapseSpaces ? normalized.Replace(" ", string.Empty) : normalized;
        }

        private static string BuildBusinessNotificationHtml(
            string heading,
            string fullName,
            string intro,
            IReadOnlyList<(string Label, string Value)> details,
            string note)
        {
            var detailRows = string.Join(
                "",
                details.Select(item =>
                    "<tr>" +
                    $"<td style=\"padding:10px 0;color:#6b7280;width:38%;\">{Encode(item.Label)}</td>" +
                    $"<td style=\"padding:10px 0;color:#111827;font-weight:600;\">{Encode(item.Value)}</td>" +
                    "</tr>"));

            return WrapInBaseLayout(
                heading,
                $"<h2>{Encode(heading)}</h2>" +
                $"<p>Xin chào <strong>{Encode(fullName)}</strong>,</p>" +
                $"<p>{Encode(intro)}</p>" +
                "<table role=\"presentation\" cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;margin:22px 0;border-top:1px solid #e5e7eb;border-bottom:1px solid #e5e7eb;\">" +
                detailRows +
                "</table>" +
                $"<div class=\"note\">{Encode(note)}</div>");
        }

        private static string FormatCurrency(decimal amount) =>
            string.Format(CultureInfo.GetCultureInfo("vi-VN"), "{0:N0} đ", amount);

        private static string Encode(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);

        // ──────────────────────────────────────────────
        // HTML Templates (using string.Format to avoid CSS brace conflicts)
        // ──────────────────────────────────────────────

        private static readonly string BaseStyles =
            "body{margin:0;padding:0;background:#f4f6fb;font-family:'Segoe UI',Arial,sans-serif}" +
            ".wrapper{max-width:600px;margin:40px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08)}" +
            ".header{background:linear-gradient(135deg,#0f4c81 0%,#1a7ca1 100%);padding:32px 40px;text-align:center}" +
            ".header h1{margin:0;color:#fff;font-size:26px;letter-spacing:1px}" +
            ".header p{margin:4px 0 0;color:rgba(255,255,255,.75);font-size:13px}" +
            ".body{padding:36px 40px;color:#374151;line-height:1.7}" +
            ".body h2{margin-top:0;color:#0f4c81;font-size:20px}" +
            ".btn{display:inline-block;margin:24px 0;padding:14px 36px;background:linear-gradient(135deg,#0f4c81,#1a7ca1);color:#fff!important;text-decoration:none;border-radius:8px;font-size:15px;font-weight:600;letter-spacing:.5px}" +
            ".note{margin-top:20px;padding:14px 18px;background:#f0f7ff;border-left:4px solid #1a7ca1;border-radius:4px;font-size:13px;color:#555}" +
            ".footer{background:#f9fafb;padding:20px 40px;text-align:center;font-size:12px;color:#9ca3af;border-top:1px solid #e5e7eb}";

        private static string WrapInBaseLayout(string title, string content) =>
            "<!DOCTYPE html>" +
            "<html lang=\"vi\"><head>" +
            "<meta charset=\"UTF-8\"/>" +
            "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0\"/>" +
            $"<title>{title}</title>" +
            $"<style>{BaseStyles}</style>" +
            "</head><body>" +
            "<div class=\"wrapper\">" +
            "<div class=\"header\">" +
            "<h1>✈️ SmartTrip</h1>" +
            "<p>Hành trình thông minh — Trải nghiệm tuyệt vời</p>" +
            "</div>" +
            $"<div class=\"body\">{content}</div>" +
            "<div class=\"footer\">" +
            "© 2025 SmartTrip. Mọi quyền được bảo lưu.<br/>" +
            "Nếu bạn không thực hiện yêu cầu này, hãy bỏ qua email." +
            "</div>" +
            "</div></body></html>";

        private static string BuildWelcomeHtml(string fullName) =>
            WrapInBaseLayout("Chào mừng đến SmartTrip",
                $"<h2>Xin chào, {fullName}! 👋</h2>" +
                "<p>Chúc mừng bạn đã gia nhập cộng đồng <strong>SmartTrip</strong> — nền tảng đặt tour &amp; khám phá hành trình thông minh nhất Việt Nam.</p>" +
                "<p>Với SmartTrip, bạn có thể:</p>" +
                "<ul>" +
                "<li>🗺️ Lên kế hoạch chuyến đi thông minh với AI</li>" +
                "<li>🏨 Đặt khách sạn, vé xe với giá tốt nhất</li>" +
                "<li>⭐ Chia sẻ trải nghiệm và đọc review thực tế</li>" +
                "</ul>" +
                "<p>Hãy bắt đầu hành trình đầu tiên của bạn ngay hôm nay!</p>" +
                "<div class=\"note\">Nếu bạn có bất kỳ câu hỏi nào, hãy liên hệ với chúng tôi qua support@smarttrip.vn</div>");

        private static string BuildPasswordResetHtml(string fullName, string resetLink) =>
            WrapInBaseLayout("Đặt lại mật khẩu",
                $"<h2>Đặt lại mật khẩu 🔑</h2>" +
                $"<p>Xin chào <strong>{fullName}</strong>,</p>" +
                "<p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản SmartTrip của bạn. Nhấn vào nút bên dưới để tiếp tục:</p>" +
                $"<a href=\"{resetLink}\" class=\"btn\">Đặt lại mật khẩu</a>" +
                "<div class=\"note\">⚠️ Link này sẽ hết hạn sau <strong>15 phút</strong>.<br/>" +
                "Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này — tài khoản của bạn vẫn an toàn.</div>" +
                $"<p style=\"margin-top:20px;font-size:13px;color:#6b7280;\">Hoặc copy link sau vào trình duyệt:<br/>" +
                $"<span style=\"color:#0f4c81;word-break:break-all;\">{resetLink}</span></p>");

        private static string BuildEmailVerificationHtml(string fullName, string otp) =>
            WrapInBaseLayout("Xác thực email",
                $"<h2>Xác thực địa chỉ email ✉️</h2>" +
                $"<p>Xin chào <strong>{fullName}</strong>,</p>" +
                "<p>Cảm ơn bạn đã đăng ký tài khoản SmartTrip! Để hoàn tất quá trình đăng ký, vui lòng sử dụng mã OTP gồm 6 chữ số dưới đây:</p>" +
                $"<div style=\"text-align:center; padding: 20px; font-size: 32px; font-weight: bold; letter-spacing: 12px; color: #1a7ca1; background: #f0f7ff; border-radius: 8px; margin: 24px 0;\">{otp}</div>" +
                "<div class=\"note\">⏱️ Mã OTP này sẽ hết hạn sau <strong>15 phút</strong>.<br/>" +
                "Nếu bạn không tạo tài khoản SmartTrip, hãy bỏ qua email này.</div>");
    }
}
