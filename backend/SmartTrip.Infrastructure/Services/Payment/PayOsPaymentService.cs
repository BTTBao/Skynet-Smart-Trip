using System.Globalization;
using System.Net.Http.Json;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
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
    private static readonly RandomNumberGenerator Random = RandomNumberGenerator.Create();

    private readonly IApplicationDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly PayOsSettings _settings;
    private readonly VnPaySettings _vnPaySettings;
    private readonly INotificationService _notificationService;
    private readonly IEmailService _emailService;
    private readonly ILogger<PayOsPaymentService> _logger;

    public PayOsPaymentService(
        IApplicationDbContext context,
        HttpClient httpClient,
        IOptions<PayOsSettings> options,
        IOptions<VnPaySettings> vnPayOptions,
        INotificationService notificationService,
        IEmailService emailService,
        ILogger<PayOsPaymentService> logger)
    {
        _context = context;
        _httpClient = httpClient;
        _settings = options.Value;
        _vnPaySettings = vnPayOptions.Value;
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

    // Creates a local pending payment, generates a unique vnp_TxnRef, and returns the signed VNPAY checkout URL.
    public async Task<PaymentResultDto> CreateVnPayPaymentAsync(
        CreateVnPayPaymentRequestDto request,
        string ipAddress,
        CancellationToken cancellationToken = default)
    {
        ValidateCreateVnPayPaymentRequest(request);
        EnsureVnPayConfigured();

        var now = DateTime.UtcNow;
        var gatewayNow = GetVnPayGatewayNow();
        var orderCode = await GenerateUniqueOrderCodeAsync(cancellationToken);
        var tripId = TryGetTripId(request.Metadata);
        var sanitizedDescription = SanitizeVnPayOrderInfo(request.Description);
        var locale = string.IsNullOrWhiteSpace(request.Locale) ? _vnPaySettings.Locale : request.Locale.Trim().ToLowerInvariant();
        var payment = new SmartTrip.Domain.Entities.Payment
        {
            TripId = tripId,
            Amount = decimal.Truncate(request.Amount),
            OrderCode = orderCode,
            Description = sanitizedDescription,
            ReturnUrl = _vnPaySettings.ReturnUrl.Trim(),
            CancelUrl = _vnPaySettings.ReturnUrl.Trim(),
            MetadataJson = request.Metadata.HasValue ? request.Metadata.Value.GetRawText() : null,
            PaymentMethod = PaymentMethod.Vnpay,
            Status = PaymentStatus.Pending,
            CreatedAt = now,
            UpdatedAt = now
        };

        var createDate = gatewayNow.ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture);
        var expireDate = gatewayNow.AddMinutes(Math.Max(1, _vnPaySettings.ExpireMinutes))
            .ToString("yyyyMMddHHmmss", CultureInfo.InvariantCulture);
        var amount = ToVnPayAmount(request.Amount);
        var parameters = new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["vnp_Version"] = _vnPaySettings.Version,
            ["vnp_Command"] = _vnPaySettings.Command,
            ["vnp_TmnCode"] = _vnPaySettings.TmnCode,
            ["vnp_Amount"] = amount.ToString(CultureInfo.InvariantCulture),
            ["vnp_CreateDate"] = createDate,
            ["vnp_ExpireDate"] = expireDate,
            ["vnp_CurrCode"] = _vnPaySettings.CurrCode,
            ["vnp_IpAddr"] = SanitizeIpAddress(ipAddress),
            ["vnp_Locale"] = locale,
            ["vnp_OrderInfo"] = sanitizedDescription,
            ["vnp_OrderType"] = _vnPaySettings.OrderType,
            ["vnp_ReturnUrl"] = _vnPaySettings.ReturnUrl.Trim(),
            ["vnp_TxnRef"] = orderCode.ToString(CultureInfo.InvariantCulture)
        };

        var secureHash = CreateVnPaySecureHash(parameters);
        var queryString = BuildVnPayQueryString(parameters);
        var paymentUrl = $"{_vnPaySettings.PaymentUrl.Trim()}?{queryString}&vnp_SecureHash={secureHash}";

        payment.CheckoutUrl = paymentUrl;
        payment.RawResponseJson = JsonSerializer.Serialize(new
        {
            Provider = "VNPAY",
            PaymentUrl = paymentUrl,
            Parameters = parameters
        }, JsonOptions);

        _context.Payments.Add(payment);
        await _context.SaveChangesAsync(cancellationToken);

        return MapPayment(payment);
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

    public async Task<VnPayIpnResponseDto> HandleVnPayIpnAsync(
        IReadOnlyDictionary<string, string> queryParameters,
        CancellationToken cancellationToken = default)
    {
        if (queryParameters.Count == 0)
        {
            return new VnPayIpnResponseDto { RspCode = "99", Message = "Invalid request" };
        }

        if (!TryValidateVnPaySignature(queryParameters, out var normalizedQuery))
        {
            _logger.LogWarning("VNPAY IPN signature verification failed.");
            return new VnPayIpnResponseDto { RspCode = "97", Message = "Invalid signature" };
        }

        var orderCode = GetLong(normalizedQuery, "vnp_TxnRef");
        if (!orderCode.HasValue)
        {
            return new VnPayIpnResponseDto { RspCode = "99", Message = "Invalid request" };
        }

        var payment = await _context.Payments
            .Include(item => item.Trip)
                .ThenInclude(trip => trip!.User)
            .FirstOrDefaultAsync(item => item.OrderCode == orderCode.Value, cancellationToken);

        if (payment == null)
        {
            _logger.LogWarning("VNPAY IPN references unknown orderCode {OrderCode}", orderCode.Value);
            return new VnPayIpnResponseDto { RspCode = "01", Message = "Order not found" };
        }

        if (!HasMatchingVnPayAmount(payment, normalizedQuery))
        {
            _logger.LogWarning(
                "VNPAY IPN amount mismatch for payment {PaymentId}. Expected {ExpectedAmount}, actual {ActualAmount}",
                payment.Id,
                payment.Amount.HasValue ? ToVnPayAmount(payment.Amount.Value) : 0L,
                GetLong(normalizedQuery, "vnp_Amount") ?? 0L);
            return new VnPayIpnResponseDto { RspCode = "04", Message = "Invalid amount" };
        }

        if (payment.Status is not null and not PaymentStatus.Pending)
        {
            return new VnPayIpnResponseDto { RspCode = "02", Message = "Order already confirmed" };
        }

        await ApplyVnPayResultAsync(payment, normalizedQuery, cancellationToken);

        return new VnPayIpnResponseDto { RspCode = "00", Message = "Confirm Success" };
    }

    public async Task<VnPayReturnResultDto> HandleVnPayReturnAsync(
        IReadOnlyDictionary<string, string> queryParameters,
        CancellationToken cancellationToken = default)
    {
        if (queryParameters.Count == 0)
        {
            return new VnPayReturnResultDto
            {
                Status = NormalizeStatus(PaymentStatus.Pending),
                Message = "VNPAY did not send any payment data.",
                SignatureValid = false
            };
        }

        var signatureValid = TryValidateVnPaySignature(queryParameters, out var normalizedQuery);
        var orderCode = GetLong(signatureValid ? normalizedQuery : queryParameters, "vnp_TxnRef");
        var payment = orderCode.HasValue
            ? await _context.Payments
                .FirstOrDefaultAsync(item => item.OrderCode == orderCode.Value, cancellationToken)
            : null;

        if (!signatureValid)
        {
            return new VnPayReturnResultDto
            {
                PaymentId = payment?.Id,
                OrderCode = orderCode,
                Status = NormalizeStatus(PaymentStatus.InvalidSignature),
                ResponseCode = GetString(queryParameters, "vnp_ResponseCode") ?? string.Empty,
                TransactionStatus = GetString(queryParameters, "vnp_TransactionStatus") ?? string.Empty,
                Message = "Chu ky thanh toan VNPAY khong hop le.",
                SignatureValid = false
            };
        }

        var responseCode = GetString(normalizedQuery, "vnp_ResponseCode") ?? string.Empty;
        var transactionStatus = GetString(normalizedQuery, "vnp_TransactionStatus") ?? string.Empty;

        if (payment == null)
        {
            return new VnPayReturnResultDto
            {
                OrderCode = orderCode,
                Status = NormalizeStatus(PaymentStatus.Failed),
                ResponseCode = responseCode,
                TransactionStatus = transactionStatus,
                Message = "Khong tim thay giao dich de doi chieu. Hay quay lai ung dung de kiem tra.",
                SignatureValid = true
            };
        }

        if (payment.Status is null or PaymentStatus.Pending)
        {
            if (HasMatchingVnPayAmount(payment, normalizedQuery))
            {
                await LoadPaymentRelationsAsync(payment, cancellationToken);
                await ApplyVnPayResultAsync(payment, normalizedQuery, cancellationToken);
            }
            else
            {
                _logger.LogWarning(
                    "VNPAY return amount mismatch for payment {PaymentId}. Expected {ExpectedAmount}, actual {ActualAmount}",
                    payment.Id,
                    payment.Amount.HasValue ? ToVnPayAmount(payment.Amount.Value) : 0L,
                    GetLong(normalizedQuery, "vnp_Amount") ?? 0L);
            }
        }

        var displayStatus = payment.Status ?? ResolveVnPayStatus(normalizedQuery);
        return new VnPayReturnResultDto
        {
            PaymentId = payment.Id,
            OrderCode = payment.OrderCode,
            Status = NormalizeStatus(displayStatus),
            ResponseCode = responseCode,
            TransactionStatus = transactionStatus,
            Message = BuildVnPayReturnMessage(displayStatus, responseCode, transactionStatus),
            IsSuccess = displayStatus == PaymentStatus.Paid,
            SignatureValid = true
        };
    }

    private bool HasMatchingVnPayAmount(
        SmartTrip.Domain.Entities.Payment payment,
        IReadOnlyDictionary<string, string> queryParameters)
    {
        var expectedAmount = payment.Amount.HasValue ? ToVnPayAmount(payment.Amount.Value) : 0L;
        var actualAmount = GetLong(queryParameters, "vnp_Amount") ?? 0L;
        return expectedAmount == actualAmount;
    }

    private async Task LoadPaymentRelationsAsync(
        SmartTrip.Domain.Entities.Payment payment,
        CancellationToken cancellationToken)
    {
        if (payment.Trip?.User != null || !payment.TripId.HasValue)
        {
            return;
        }

        payment.Trip ??= await _context.Trips
            .FirstOrDefaultAsync(item => item.Id == payment.TripId.Value, cancellationToken);

        if (payment.Trip != null && payment.Trip.User == null)
        {
            payment.Trip.User = await _context.Users
                .FirstOrDefaultAsync(item => item.Id == payment.Trip.UserId, cancellationToken);
        }
    }

    private async Task ApplyVnPayResultAsync(
        SmartTrip.Domain.Entities.Payment payment,
        IReadOnlyDictionary<string, string> normalizedQuery,
        CancellationToken cancellationToken)
    {
        var nextStatus = ResolveVnPayStatus(normalizedQuery);
        payment.Status = nextStatus;
        payment.TransactionId = GetString(normalizedQuery, "vnp_TransactionNo") ?? payment.TransactionId;
        payment.PaymentLinkId = GetString(normalizedQuery, "vnp_BankTranNo") ?? payment.PaymentLinkId;
        payment.RawResponseJson = JsonSerializer.Serialize(normalizedQuery, JsonOptions);
        payment.UpdatedAt = DateTime.UtcNow;

        if (nextStatus == PaymentStatus.Paid)
        {
            payment.PaidAt = ParseVnPayDateTime(GetString(normalizedQuery, "vnp_PayDate")) ?? DateTime.UtcNow;
            if (payment.TripId.HasValue)
            {
                var trip = payment.Trip ?? await _context.Trips
                    .FirstOrDefaultAsync(item => item.Id == payment.TripId.Value, cancellationToken);
                if (trip != null && trip.Status != TripStatus.Cancelled)
                {
                    trip.Status = TripStatus.Paid;
                }

                await MarkBusSeatsBookedAsync(payment, cancellationToken);
            }
        }

        await _context.SaveChangesAsync(cancellationToken);

        if (nextStatus == PaymentStatus.Paid)
        {
            await NotifyPaymentSucceededAsync(payment, cancellationToken);
            await SendPaymentSucceededEmailAsync(payment, cancellationToken);
        }
        else if (nextStatus is PaymentStatus.Failed or PaymentStatus.Cancelled or PaymentStatus.Expired)
        {
            await NotifyPaymentFailedAsync(payment, nextStatus, cancellationToken);
            await SendPaymentFailedEmailAsync(payment, nextStatus, cancellationToken);
        }
    }

    private static void ValidateCreateVnPayPaymentRequest(CreateVnPayPaymentRequestDto request)
    {
        if (request.Amount <= 0)
        {
            throw new ArgumentException("Amount must be greater than 0.");
        }

        _ = ToVnPayAmount(request.Amount);

        if (string.IsNullOrWhiteSpace(request.Description))
        {
            throw new ArgumentException("Description is required.");
        }
    }

    private async Task<long> GenerateUniqueOrderCodeAsync(CancellationToken cancellationToken)
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var candidate = CreateOrderCodeCandidate();
            var exists = await _context.Payments
                .AsNoTracking()
                .AnyAsync(payment => payment.OrderCode == candidate, cancellationToken);
            if (!exists)
            {
                return candidate;
            }
        }

        throw new InvalidOperationException("Unable to generate a unique payment reference for VNPAY.");
    }

    private static long CreateOrderCodeCandidate()
    {
        Span<byte> randomBytes = stackalloc byte[2];
        Random.GetBytes(randomBytes);
        var suffix = BitConverter.ToUInt16(randomBytes) % 900 + 100;
        return checked(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000L + suffix);
    }

    private static DateTime GetVnPayGatewayNow()
    {
        var utcNow = DateTime.UtcNow;
        foreach (var timeZoneId in new[] { "SE Asia Standard Time", "Asia/Ho_Chi_Minh" })
        {
            try
            {
                var timeZone = TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
                return TimeZoneInfo.ConvertTimeFromUtc(utcNow, timeZone);
            }
            catch (TimeZoneNotFoundException)
            {
            }
            catch (InvalidTimeZoneException)
            {
            }
        }

        return utcNow.AddHours(7);
    }

    private void EnsureVnPayConfigured()
    {
        if (string.IsNullOrWhiteSpace(_vnPaySettings.TmnCode) ||
            string.IsNullOrWhiteSpace(_vnPaySettings.HashSecret) ||
            string.IsNullOrWhiteSpace(_vnPaySettings.PaymentUrl) ||
            string.IsNullOrWhiteSpace(_vnPaySettings.ReturnUrl) ||
            string.IsNullOrWhiteSpace(_vnPaySettings.IpnUrl))
        {
            throw new InvalidOperationException("VNPAY configuration is missing.");
        }
    }

    private static string SanitizeVnPayOrderInfo(string description)
    {
        var sanitized = description.Trim();
        sanitized = new string(sanitized.Where(ch => char.IsLetterOrDigit(ch) || char.IsWhiteSpace(ch) || ch is '-' or '_' or '.' or ':' or '/').ToArray());
        return string.IsNullOrWhiteSpace(sanitized) ? "Thanh toan SmartTrip" : sanitized[..Math.Min(sanitized.Length, 255)];
    }

    private static string SanitizeIpAddress(string ipAddress)
    {
        if (string.IsNullOrWhiteSpace(ipAddress))
        {
            return "127.0.0.1";
        }

        if (IPAddress.TryParse(ipAddress, out var parsedIpAddress))
        {
            if (IPAddress.IsLoopback(parsedIpAddress))
            {
                return GetPreferredVnPayIpAddress();
            }

            if (parsedIpAddress.IsIPv4MappedToIPv6)
            {
                return parsedIpAddress.MapToIPv4().ToString();
            }

            if (parsedIpAddress.AddressFamily == AddressFamily.InterNetwork)
            {
                return parsedIpAddress.ToString();
            }
        }

        if (ipAddress.StartsWith("::ffff:", StringComparison.OrdinalIgnoreCase))
        {
            return ipAddress[7..];
        }

        return GetPreferredVnPayIpAddress();
    }

    private static string GetPreferredVnPayIpAddress()
    {
        try
        {
            foreach (var networkInterface in NetworkInterface.GetAllNetworkInterfaces())
            {
                if (networkInterface.OperationalStatus != OperationalStatus.Up)
                {
                    continue;
                }

                if (networkInterface.NetworkInterfaceType is NetworkInterfaceType.Loopback or NetworkInterfaceType.Tunnel)
                {
                    continue;
                }

                var properties = networkInterface.GetIPProperties();
                if (properties.GatewayAddresses.Count == 0)
                {
                    continue;
                }

                foreach (var unicastAddress in properties.UnicastAddresses)
                {
                    if (unicastAddress.Address.AddressFamily == AddressFamily.InterNetwork &&
                        !IPAddress.IsLoopback(unicastAddress.Address))
                    {
                        return unicastAddress.Address.ToString();
                    }
                }
            }
        }
        catch
        {
        }

        return "127.0.0.1";
    }

    private static long ToVnPayAmount(decimal amount)
    {
        if (decimal.Truncate(amount) != amount)
        {
            throw new ArgumentException("Amount must be an integer VND value.");
        }

        return decimal.ToInt64(amount * 100m);
    }

    private string CreateVnPaySecureHash(SortedDictionary<string, string> parameters)
    {
        // VNPAY signs the URL-encoded, alphabetically sorted query string with HMAC SHA512.
        var hashData = BuildVnPayQueryString(parameters);
        return HmacSha512Hex(_vnPaySettings.HashSecret, hashData);
    }

    private static string BuildVnPayQueryString(IEnumerable<KeyValuePair<string, string>> parameters)
    {
        return string.Join("&", parameters
            .Where(item => !string.IsNullOrWhiteSpace(item.Value))
            .Select(item => $"{WebUtility.UrlEncode(item.Key)}={WebUtility.UrlEncode(item.Value)}"));
    }

    private bool TryValidateVnPaySignature(
        IReadOnlyDictionary<string, string> queryParameters,
        out SortedDictionary<string, string> normalizedQuery)
    {
        normalizedQuery = new SortedDictionary<string, string>(StringComparer.Ordinal);
        string? actualSignature = null;

        foreach (var pair in queryParameters)
        {
            if (string.Equals(pair.Key, "vnp_SecureHash", StringComparison.OrdinalIgnoreCase))
            {
                actualSignature = pair.Value;
                continue;
            }

            if (string.Equals(pair.Key, "vnp_SecureHashType", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (string.IsNullOrWhiteSpace(pair.Value))
            {
                continue;
            }

            normalizedQuery[pair.Key] = pair.Value.Trim();
        }

        if (string.IsNullOrWhiteSpace(actualSignature))
        {
            return false;
        }

        var expectedSignature = HmacSha512Hex(_vnPaySettings.HashSecret, BuildVnPayQueryString(normalizedQuery));
        return FixedTimeEquals(expectedSignature, actualSignature);
    }

    private static PaymentStatus ResolveVnPayStatus(IReadOnlyDictionary<string, string> query)
    {
        var responseCode = GetString(query, "vnp_ResponseCode");
        var transactionStatus = GetString(query, "vnp_TransactionStatus");

        if (string.Equals(responseCode, "00", StringComparison.OrdinalIgnoreCase) &&
            string.Equals(transactionStatus, "00", StringComparison.OrdinalIgnoreCase))
        {
            return PaymentStatus.Paid;
        }

        if (string.Equals(responseCode, "24", StringComparison.OrdinalIgnoreCase))
        {
            return PaymentStatus.Cancelled;
        }

        if (string.Equals(responseCode, "11", StringComparison.OrdinalIgnoreCase))
        {
            return PaymentStatus.Expired;
        }

        return PaymentStatus.Failed;
    }

    private static string BuildVnPayReturnMessage(
        PaymentStatus status,
        string? responseCode,
        string? transactionStatus = null)
    {
        return status switch
        {
            PaymentStatus.Paid => "VNPAY da ghi nhan thanh toan thanh cong.",
            PaymentStatus.Cancelled => "Ban da huy giao dich tren VNPAY.",
            PaymentStatus.Expired => "Phien thanh toan da het han. Vui long thuc hien lai giao dich.",
            PaymentStatus.InvalidSignature => "Phan hoi tu VNPAY khong hop le.",
            _ => DescribeVnPayFailure(responseCode, transactionStatus)
        };
    }

    private static string DescribeVnPayFailure(string? responseCode, string? transactionStatus = null)
    {
        var code = string.IsNullOrWhiteSpace(responseCode) ? transactionStatus : responseCode;
        return code switch
        {
            "07" => "Giao dich bi tam dung de ra soat boi VNPAY. Vui long thu lai sau hoac dung phuong thuc khac.",
            "09" => "The hoac tai khoan chua dang ky Internet Banking.",
            "10" => "Thong tin xac thuc khong chinh xac qua so lan cho phep.",
            "11" => "Phien thanh toan da het han. Vui long thuc hien lai giao dich.",
            "12" => "The hoac tai khoan dang bi khoa.",
            "13" => "Sai ma OTP. Vui long thu lai.",
            "24" => "Ban da huy giao dich tren VNPAY.",
            "51" => "Tai khoan khong du so du de thanh toan.",
            "65" => "Tai khoan da vuot han muc giao dich trong ngay.",
            "75" => "Ngan hang thanh toan dang bao tri.",
            "79" => "Nhap sai mat khau thanh toan qua so lan cho phep.",
            _ => "Thanh toan chua thanh cong. Vui long quay lai ung dung de kiem tra chi tiet."
        };
    }

    private static string HmacSha512Hex(string key, string data)
    {
        var keyBytes = Encoding.UTF8.GetBytes(key);
        var dataBytes = Encoding.UTF8.GetBytes(data);
        using var hmac = new HMACSHA512(keyBytes);
        return Convert.ToHexString(hmac.ComputeHash(dataBytes)).ToLowerInvariant();
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
        var responseCode = default(string);
        var transactionStatus = default(string);
        if (!string.IsNullOrWhiteSpace(payment.RawResponseJson) &&
            TryExtractVnPayCallbackMetadata(payment.RawResponseJson, out var extractedResponseCode, out var extractedTransactionStatus))
        {
            responseCode = extractedResponseCode;
            transactionStatus = extractedTransactionStatus;
        }

        return new PaymentResultDto
        {
            PaymentId = payment.Id,
            OrderCode = payment.OrderCode,
            CheckoutUrl = payment.CheckoutUrl,
            PaymentLink = payment.CheckoutUrl,
            QrCode = payment.QrCode,
            Status = NormalizeStatus(payment.Status),
            PaidAt = payment.PaidAt,
            Message = payment.Status is PaymentStatus.Failed or PaymentStatus.Cancelled or PaymentStatus.Expired
                ? BuildVnPayReturnMessage(payment.Status.Value, responseCode, transactionStatus)
                : null,
            ProviderResponseCode = responseCode,
            ProviderTransactionStatus = transactionStatus,
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
            PaymentStatus.InvalidSignature => "INVALID_SIGNATURE",
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
                                var bookingCode = $"SKN-{payment.TripId.GetValueOrDefault():D6}";
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

    private static string? GetString(IReadOnlyDictionary<string, string> values, string key)
    {
        return values.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value)
            ? value
            : null;
    }

    private static bool TryExtractVnPayCallbackMetadata(
        string rawResponseJson,
        out string? responseCode,
        out string? transactionStatus)
    {
        responseCode = null;
        transactionStatus = null;

        try
        {
            using var document = JsonDocument.Parse(rawResponseJson);
            var root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object)
            {
                return false;
            }

            responseCode = GetString(root, "vnp_ResponseCode");
            transactionStatus = GetString(root, "vnp_TransactionStatus");
            return !string.IsNullOrWhiteSpace(responseCode) || !string.IsNullOrWhiteSpace(transactionStatus);
        }
        catch (JsonException)
        {
            return false;
        }
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

    private static long? GetLong(IReadOnlyDictionary<string, string> values, string key)
    {
        return values.TryGetValue(key, out var value) &&
               long.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
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

    private static DateTime? ParseVnPayDateTime(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return DateTime.TryParseExact(
            value,
            "yyyyMMddHHmmss",
            CultureInfo.InvariantCulture,
            DateTimeStyles.AssumeUniversal | DateTimeStyles.AdjustToUniversal,
            out var parsed)
            ? parsed
            : null;
    }
}

