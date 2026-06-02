using System.Globalization;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SmartTrip.Application.Configurations;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.DTOs.Payment;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Application.Interfaces.Payment;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Payment;

public class PayOsPaymentService : IPaymentService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly IApplicationDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly PayOsSettings _settings;
    private readonly INotificationService _notificationService;
    private readonly IEmailService _emailService;
    private readonly ILogger<PayOsPaymentService> _logger;

    public PayOsPaymentService(
        IApplicationDbContext context,
        HttpClient httpClient,
        IOptions<PayOsSettings> options,
        INotificationService notificationService,
        IEmailService emailService,
        ILogger<PayOsPaymentService> logger)
    {
        _context = context;
        _httpClient = httpClient;
        _settings = options.Value;
        _notificationService = notificationService;
        _emailService = emailService;
        _logger = logger;
    }

    // Creates a local pending payment, then asks PayOS for a checkout link/QR.
    public async Task<PaymentResultDto> CreatePaymentAsync(CreatePaymentRequestDto request, CancellationToken cancellationToken = default)
    {
        ValidateCreatePaymentRequest(request);
        EnsurePayOsConfigured();

        var existingPayment = await _context.Payments
            .AsNoTracking()
            .FirstOrDefaultAsync(payment => payment.OrderCode == request.OrderCode, cancellationToken);

        if (existingPayment != null)
        {
            if (existingPayment.Status is PaymentStatus.Failed or PaymentStatus.Cancelled or PaymentStatus.Expired)
            {
                throw new InvalidOperationException(
                    $"Payment orderCode {request.OrderCode} already exists with status {NormalizeStatus(existingPayment.Status)}. Generate a new orderCode to retry payment.");
            }

            return MapPayment(existingPayment);
        }

        var now = DateTime.UtcNow;
        var tripId = TryGetTripId(request.Metadata);
        var payment = new SmartTrip.Domain.Entities.Payment
        {
            TripId = tripId,
            Amount = request.Amount,
            OrderCode = request.OrderCode,
            Description = request.Description.Trim(),
            ReturnUrl = request.ReturnUrl.Trim(),
            CancelUrl = request.CancelUrl.Trim(),
            MetadataJson = request.Metadata.HasValue ? request.Metadata.Value.GetRawText() : null,
            PaymentMethod = PaymentMethod.PayOS,
            Status = PaymentStatus.Pending,
            PaidAt = null,
            CreatedAt = now,
            UpdatedAt = now
        };

        _context.Payments.Add(payment);
        await _context.SaveChangesAsync(cancellationToken);

        try
        {
            var amount = ToPayOsAmount(request.Amount);
            var signature = CreatePaymentRequestSignature(amount, request.CancelUrl, request.Description, request.OrderCode, request.ReturnUrl);
            var payOsRequest = new
            {
                orderCode = request.OrderCode,
                amount,
                description = request.Description.Trim(),
                returnUrl = request.ReturnUrl.Trim(),
                cancelUrl = request.CancelUrl.Trim(),
                signature
            };

            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "/v2/payment-requests")
            {
                Content = JsonContent.Create(payOsRequest, options: JsonOptions)
            };
            httpRequest.Headers.Add("x-client-id", _settings.ClientId);
            httpRequest.Headers.Add("x-api-key", _settings.ApiKey);

            using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
            var rawResponse = await response.Content.ReadAsStringAsync(cancellationToken);

            payment.RawResponseJson = rawResponse;
            payment.UpdatedAt = DateTime.UtcNow;

            if (!response.IsSuccessStatusCode)
            {
                payment.Status = PaymentStatus.Failed;
                await _context.SaveChangesAsync(cancellationToken);
                _logger.LogError("PayOS create payment failed. StatusCode: {StatusCode}. Body: {Body}", response.StatusCode, rawResponse);
                throw new InvalidOperationException("PayOS create payment request failed.");
            }

            using var document = JsonDocument.Parse(rawResponse);
            var root = document.RootElement;
            var code = root.TryGetProperty("code", out var codeElement) ? codeElement.GetString() : null;
            if (!string.Equals(code, "00", StringComparison.OrdinalIgnoreCase))
            {
                payment.Status = PaymentStatus.Failed;
                await _context.SaveChangesAsync(cancellationToken);
                var desc = root.TryGetProperty("desc", out var descElement) ? descElement.GetString() : "Unknown PayOS error";
                _logger.LogError("PayOS returned an error. Code: {Code}. Description: {Description}", code, desc);
                throw new InvalidOperationException($"PayOS error: {desc}");
            }

            if (root.TryGetProperty("data", out var data))
            {
                payment.CheckoutUrl = GetString(data, "checkoutUrl");
                payment.QrCode = GetString(data, "qrCode");
                payment.PaymentLinkId = GetString(data, "paymentLinkId");
                payment.TransactionId = payment.PaymentLinkId;
            }

            await _context.SaveChangesAsync(cancellationToken);
            return MapPayment(payment);
        }
        catch (Exception ex) when (ex is not InvalidOperationException)
        {
            payment.Status = PaymentStatus.Failed;
            payment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(cancellationToken);
            _logger.LogError(ex, "Unexpected error while creating PayOS payment for orderCode {OrderCode}", request.OrderCode);
            throw;
        }
    }

    public async Task<PaymentResultDto?> GetPaymentStatusAsync(long orderCode, CancellationToken cancellationToken = default)
    {
        var payment = await _context.Payments
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.OrderCode == orderCode, cancellationToken);

        return payment == null ? null : MapPayment(payment);
    }

    public async Task<PaymentResultDto?> GetPaymentStatusByIdAsync(int paymentId, CancellationToken cancellationToken = default)
    {
        var payment = await _context.Payments
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.Id == paymentId, cancellationToken);

        return payment == null ? null : MapPayment(payment);
    }

    // Verifies PayOS signature and updates the payment once; repeated paid webhooks are ignored.
    public async Task<PaymentResultDto?> HandlePayOsWebhookAsync(PayOsWebhookDto webhook, CancellationToken cancellationToken = default)
    {
        if (!VerifyPayOsWebhook(webhook))
        {
            _logger.LogWarning("PayOS webhook signature verification failed.");
            throw new InvalidOperationException("Invalid PayOS webhook signature.");
        }

        var orderCode = GetLong(webhook.Data, "orderCode");
        if (!orderCode.HasValue)
        {
            _logger.LogWarning("PayOS webhook missing orderCode. Payload: {Payload}", JsonSerializer.Serialize(webhook, JsonOptions));
            return null;
        }

        var payment = await _context.Payments
            .Include(item => item.Trip)
                .ThenInclude(trip => trip!.User)
            .FirstOrDefaultAsync(item => item.OrderCode == orderCode.Value, cancellationToken);

        if (payment == null)
        {
            _logger.LogWarning("PayOS webhook references unknown orderCode {OrderCode}", orderCode.Value);
            return null;
        }

        if (payment.Status == PaymentStatus.Paid)
        {
            return MapPayment(payment);
        }

        var webhookStatus = ResolveWebhookStatus(webhook);
        payment.Status = webhookStatus;
        payment.RawResponseJson = JsonSerializer.Serialize(webhook, JsonOptions);
        payment.PaymentLinkId ??= GetString(webhook.Data, "paymentLinkId");
        payment.TransactionId = GetString(webhook.Data, "reference") ?? payment.PaymentLinkId ?? payment.TransactionId;
        payment.UpdatedAt = DateTime.UtcNow;

        if (webhookStatus == PaymentStatus.Paid)
        {
            payment.PaidAt = ParsePayOsDateTime(GetString(webhook.Data, "transactionDateTime")) ?? DateTime.UtcNow;
            if (payment.TripId.HasValue)
            {
                var trip = await _context.Trips
                    .FirstOrDefaultAsync(item => item.Id == payment.TripId.Value, cancellationToken);
                if (trip != null && trip.Status != TripStatus.Cancelled)
                {
                    trip.Status = TripStatus.Paid;
                }

                await MarkBusSeatsBookedAsync(payment, cancellationToken);
            }
        }

        await _context.SaveChangesAsync(cancellationToken);

        if (webhookStatus == PaymentStatus.Paid)
        {
            await NotifyPaymentSucceededAsync(payment, cancellationToken);
            await SendPaymentSucceededEmailAsync(payment, cancellationToken);
        }
        else if (webhookStatus is PaymentStatus.Failed or PaymentStatus.Cancelled or PaymentStatus.Expired)
        {
            await NotifyPaymentFailedAsync(payment, webhookStatus, cancellationToken);
            await SendPaymentFailedEmailAsync(payment, webhookStatus, cancellationToken);
        }

        return MapPayment(payment);
    }

    public bool VerifyPayOsWebhook(PayOsWebhookDto webhook)
    {
        if (string.IsNullOrWhiteSpace(webhook.Signature) || webhook.Data.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            return false;
        }

        var signedData = BuildSortedDataString(webhook.Data);
        var expectedSignature = HmacSha256Hex(_settings.ChecksumKey, signedData);
        return FixedTimeEquals(expectedSignature, webhook.Signature);
    }

    private static void ValidateCreatePaymentRequest(CreatePaymentRequestDto request)
    {
        if (request.Amount <= 0)
        {
            throw new ArgumentException("Amount must be greater than 0.");
        }

        _ = ToPayOsAmount(request.Amount);

        if (request.OrderCode <= 0)
        {
            throw new ArgumentException("OrderCode must be greater than 0.");
        }

        if (string.IsNullOrWhiteSpace(request.Description))
        {
            throw new ArgumentException("Description is required.");
        }

        if (!Uri.TryCreate(request.ReturnUrl, UriKind.Absolute, out _))
        {
            throw new ArgumentException("ReturnUrl must be an absolute URL.");
        }

        if (!Uri.TryCreate(request.CancelUrl, UriKind.Absolute, out _))
        {
            throw new ArgumentException("CancelUrl must be an absolute URL.");
        }
    }

    private static int? TryGetTripId(JsonElement? metadata)
    {
        if (!metadata.HasValue || metadata.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            return null;
        }

        var data = metadata.Value;
        if (!data.TryGetProperty("tripId", out var tripIdElement) &&
            !data.TryGetProperty("TripId", out tripIdElement))
        {
            return null;
        }

        if (tripIdElement.ValueKind == JsonValueKind.Number && tripIdElement.TryGetInt32(out var tripId))
        {
            return tripId > 0 ? tripId : null;
        }

        return int.TryParse(tripIdElement.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsedTripId) &&
               parsedTripId > 0
            ? parsedTripId
            : null;
    }

    private async Task MarkBusSeatsBookedAsync(SmartTrip.Domain.Entities.Payment payment, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(payment.MetadataJson))
        {
            return;
        }

        using var document = JsonDocument.Parse(payment.MetadataJson);
        var metadata = document.RootElement;
        var type = GetString(metadata, "type");
        if (!string.Equals(type, "BUS", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var scheduleId = GetInt(metadata, "scheduleId");
        if (!scheduleId.HasValue || !metadata.TryGetProperty("selectedSeats", out var seatsElement) ||
            seatsElement.ValueKind != JsonValueKind.Array)
        {
            return;
        }

        var selectedSeats = seatsElement
            .EnumerateArray()
            .Select(item => item.GetString())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .ToList();

        if (selectedSeats.Count == 0)
        {
            return;
        }

        var seats = await _context.Seats
            .Where(item => item.ScheduleId == scheduleId.Value &&
                           item.SeatNumber != null &&
                           selectedSeats.Contains(item.SeatNumber))
            .ToListAsync(cancellationToken);

        foreach (var seat in seats)
        {
            seat.Status = SeatStatus.Booked;
        }
    }

    private void EnsurePayOsConfigured()
    {
        if (string.IsNullOrWhiteSpace(_settings.ClientId) ||
            string.IsNullOrWhiteSpace(_settings.ApiKey) ||
            string.IsNullOrWhiteSpace(_settings.ChecksumKey))
        {
            throw new InvalidOperationException("PayOS configuration is missing.");
        }
    }

    private string CreatePaymentRequestSignature(long amount, string cancelUrl, string description, long orderCode, string returnUrl)
    {
        var data = $"amount={amount}&cancelUrl={cancelUrl.Trim()}&description={description.Trim()}&orderCode={orderCode}&returnUrl={returnUrl.Trim()}";
        return HmacSha256Hex(_settings.ChecksumKey, data);
    }

    private static string BuildSortedDataString(JsonElement data)
    {
        return string.Join("&", data.EnumerateObject()
            .OrderBy(property => property.Name, StringComparer.Ordinal)
            .Select(property => $"{property.Name}={JsonElementToSignatureValue(property.Value)}"));
    }

    private static string JsonElementToSignatureValue(JsonElement value)
    {
        return value.ValueKind switch
        {
            JsonValueKind.Null or JsonValueKind.Undefined => string.Empty,
            JsonValueKind.String => value.GetString() ?? string.Empty,
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => value.GetRawText()
        };
    }

    private static long ToPayOsAmount(decimal amount)
    {
        if (decimal.Truncate(amount) != amount)
        {
            throw new ArgumentException("Amount must be an integer VND value.");
        }

        return decimal.ToInt64(amount);
    }

    private static string HmacSha256Hex(string key, string data)
    {
        var keyBytes = Encoding.UTF8.GetBytes(key);
        var dataBytes = Encoding.UTF8.GetBytes(data);
        using var hmac = new HMACSHA256(keyBytes);
        return Convert.ToHexString(hmac.ComputeHash(dataBytes)).ToLowerInvariant();
    }

    private static bool FixedTimeEquals(string expected, string actual)
    {
        var expectedBytes = Encoding.UTF8.GetBytes(expected);
        var actualBytes = Encoding.UTF8.GetBytes(actual.ToLowerInvariant());
        return expectedBytes.Length == actualBytes.Length && CryptographicOperations.FixedTimeEquals(expectedBytes, actualBytes);
    }

    private static PaymentStatus ResolveWebhookStatus(PayOsWebhookDto webhook)
    {
        var dataCode = GetString(webhook.Data, "code");
        var dataStatus = GetString(webhook.Data, "status");
        var text = $"{webhook.Code} {webhook.Desc} {dataCode} {dataStatus}".ToUpperInvariant();

        if (webhook.Success && string.Equals(webhook.Code, "00", StringComparison.OrdinalIgnoreCase) &&
            string.Equals(dataCode, "00", StringComparison.OrdinalIgnoreCase))
        {
            return PaymentStatus.Paid;
        }

        if (text.Contains("CANCEL"))
        {
            return PaymentStatus.Cancelled;
        }

        if (text.Contains("EXPIRED"))
        {
            return PaymentStatus.Expired;
        }

        return PaymentStatus.Failed;
    }

    private static PaymentResultDto MapPayment(SmartTrip.Domain.Entities.Payment payment)
    {
        return new PaymentResultDto
        {
            PaymentId = payment.Id,
            OrderCode = payment.OrderCode,
            CheckoutUrl = payment.CheckoutUrl,
            PaymentLink = payment.CheckoutUrl,
            QrCode = payment.QrCode,
            Status = NormalizeStatus(payment.Status),
            PaidAt = payment.PaidAt,
            RawResponse = payment.RawResponseJson
        };
    }

    private static string NormalizeStatus(PaymentStatus? status)
    {
        return status switch
        {
            PaymentStatus.Pending => "PENDING",
            PaymentStatus.Paid => "PAID",
            PaymentStatus.Cancelled => "CANCELLED",
            PaymentStatus.Failed => "FAILED",
            PaymentStatus.Expired => "EXPIRED",
            PaymentStatus.Refunded => "REFUNDED",
            _ => "PENDING"
        };
    }

    private static int? ExtractTripId(JsonElement? metadata)
    {
        if (!metadata.HasValue || metadata.Value.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            return null;
        }

        if (!metadata.Value.TryGetProperty("tripId", out var value))
        {
            return null;
        }

        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var tripId))
        {
            return tripId;
        }

        return int.TryParse(value.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private async Task NotifyPaymentSucceededAsync(SmartTrip.Domain.Entities.Payment payment, CancellationToken cancellationToken)
    {
        await TryCreateNotificationAsync(payment, new CreateNotificationDto
        {
            UserId = payment.Trip?.UserId ?? 0,
            Title = "Thanh toán thành công",
            Message = $"Thanh toán cho \"{payment.Trip?.Title ?? payment.Description ?? "booking"}\" đã hoàn tất.",
            Type = "payment.succeeded",
            ReferenceType = "payment",
            ReferenceId = payment.Id,
            ActionUrl = payment.TripId.HasValue ? $"/trips/{payment.TripId.Value}" : null
        }, cancellationToken);
    }

    private async Task NotifyPaymentFailedAsync(SmartTrip.Domain.Entities.Payment payment, PaymentStatus status, CancellationToken cancellationToken)
    {
        await TryCreateNotificationAsync(payment, new CreateNotificationDto
        {
            UserId = payment.Trip?.UserId ?? 0,
            Title = "Thanh toán chưa hoàn tất",
            Message = $"Thanh toán cho \"{payment.Trip?.Title ?? payment.Description ?? "booking"}\" đang ở trạng thái {NormalizeStatus(status)}.",
            Type = "payment.failed",
            ReferenceType = "payment",
            ReferenceId = payment.Id,
            ActionUrl = payment.TripId.HasValue ? $"/trips/{payment.TripId.Value}" : null
        }, cancellationToken);
    }

    private async Task TryCreateNotificationAsync(
        SmartTrip.Domain.Entities.Payment payment,
        CreateNotificationDto notification,
        CancellationToken cancellationToken)
    {
        if (notification.UserId <= 0)
        {
            return;
        }

        try
        {
            await _notificationService.CreateAsync(notification, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create payment notification for payment {PaymentId}", payment.Id);
        }
    }

    private async Task SendPaymentSucceededEmailAsync(SmartTrip.Domain.Entities.Payment payment, CancellationToken cancellationToken)
    {
        try
        {
            var user = payment.Trip?.User;
            if (user == null || !await _notificationService.AreEmailNotificationsEnabledAsync(user.Id, cancellationToken))
            {
                return;
            }

            if (!string.IsNullOrWhiteSpace(payment.MetadataJson))
            {
                try
                {
                    using var document = JsonDocument.Parse(payment.MetadataJson);
                    var metadata = document.RootElement;
                    var type = GetString(metadata, "type");
                    if (string.Equals(type, "BUS", StringComparison.OrdinalIgnoreCase))
                    {
                        var scheduleId = GetInt(metadata, "scheduleId");
                        if (scheduleId.HasValue)
                        {
                            var schedule = await _context.BusSchedules
                                .Include(s => s.Company)
                                .Include(s => s.FromDest)
                                .Include(s => s.ToDest)
                                .FirstOrDefaultAsync(s => s.Id == scheduleId.Value, cancellationToken);

                            if (schedule != null)
                            {
                                var bookingCode = $"SKN-{payment.Id.ToString().PadLeft(4, '0')}";
                                var selectedSeats = "";
                                if (metadata.TryGetProperty("selectedSeats", out var seatsElement) && seatsElement.ValueKind == JsonValueKind.Array)
                                {
                                    selectedSeats = string.Join(", ", seatsElement.EnumerateArray()
                                        .Select(item => item.GetString())
                                        .Where(item => !string.IsNullOrWhiteSpace(item)));
                                }

                                var departureStr = schedule.DepartureTime?.ToString("HH:mm dd/MM/yyyy") ?? "";
                                var arrivalStr = schedule.ArrivalTime?.ToString("HH:mm dd/MM/yyyy") ?? "";
                                var priceStr = string.Format(CultureInfo.GetCultureInfo("vi-VN"), "{0:N0} đ", payment.Amount ?? 0m);

                                await _emailService.SendBusBookingConfirmationEmailAsync(
                                    user.Email,
                                    user.FullName ?? user.Email,
                                    bookingCode,
                                    schedule.Company?.Name ?? "SmartTrip Express",
                                    schedule.FromDest?.Name ?? "",
                                    schedule.ToDest?.Name ?? "",
                                    departureStr,
                                    arrivalStr,
                                    selectedSeats,
                                    priceStr);
                                return;
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to parse metadata or fetch bus schedule details for payment {PaymentId}. Falling back to general success email.", payment.Id);
                }
            }

            await _emailService.SendPaymentSuccessEmailAsync(
                user.Email,
                user.FullName ?? user.Email,
                payment.Trip?.Title ?? payment.Description ?? "Booking SmartTrip",
                payment.Amount ?? 0m,
                payment.TransactionId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send payment success email for payment {PaymentId}", payment.Id);
        }
    }

    private async Task SendPaymentFailedEmailAsync(SmartTrip.Domain.Entities.Payment payment, PaymentStatus status, CancellationToken cancellationToken)
    {
        try
        {
            var user = payment.Trip?.User;
            if (user == null || !await _notificationService.AreEmailNotificationsEnabledAsync(user.Id, cancellationToken))
            {
                return;
            }

            await _emailService.SendPaymentFailedEmailAsync(
                user.Email,
                user.FullName ?? user.Email,
                payment.Trip?.Title ?? payment.Description ?? "Booking SmartTrip",
                NormalizeStatus(status));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send payment failed email for payment {PaymentId}", payment.Id);
        }
    }

    private static string? GetString(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var value) || value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
        {
            return null;
        }

        return value.ValueKind == JsonValueKind.String ? value.GetString() : value.GetRawText();
    }

    private static long? GetLong(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var value))
        {
            return null;
        }

        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt64(out var number))
        {
            return number;
        }

        return long.TryParse(value.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private static int? GetInt(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var value))
        {
            return null;
        }

        if (value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var number))
        {
            return number;
        }

        return int.TryParse(value.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private static DateTime? ParsePayOsDateTime(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal, out var parsed)
            ? parsed
            : null;
    }
}

