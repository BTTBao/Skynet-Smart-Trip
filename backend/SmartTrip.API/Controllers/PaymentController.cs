using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Payment;
using SmartTrip.Application.Interfaces.Payment;
using System.Net;
using System.Security.Claims;
using System.Text.Json;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/payments")]
public class PaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(
        IPaymentService paymentService,
        ApplicationDbContext context,
        ILogger<PaymentController> logger)
    {
        _paymentService = paymentService;
        _context = context;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> CreatePayment([FromBody] CreatePaymentRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.CreatePaymentAsync(request, cancellationToken);
            return Ok(payment);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Unable to create payment for orderCode {OrderCode}", request.OrderCode);
            return StatusCode(StatusCodes.Status502BadGateway, new { message = ex.Message });
        }
    }

    [HttpGet("{paymentId:int}")]
    public async Task<IActionResult> GetPaymentById(int paymentId, CancellationToken cancellationToken)
    {
        var payment = await _paymentService.GetPaymentStatusByIdAsync(paymentId, cancellationToken);
        return payment == null ? NotFound(new { message = $"Payment {paymentId} was not found." }) : Ok(payment);
    }

    [HttpGet("{paymentId:int}/status")]
    public async Task<IActionResult> GetPaymentStatusById(int paymentId, CancellationToken cancellationToken)
    {
        var payment = await _paymentService.GetPaymentStatusByIdAsync(paymentId, cancellationToken);
        return payment == null ? NotFound(new { message = $"Payment {paymentId} was not found." }) : Ok(payment);
    }

    [HttpGet("order/{orderCode:long}")]
    public async Task<IActionResult> GetPaymentByOrderCode(long orderCode, CancellationToken cancellationToken)
    {
        var payment = await _paymentService.GetPaymentStatusAsync(orderCode, cancellationToken);
        return payment == null ? NotFound(new { message = $"Payment orderCode {orderCode} was not found." }) : Ok(payment);
    }

    [AllowAnonymous]
    [HttpPost("payos/webhook")]
    public async Task<IActionResult> PayOsWebhook([FromBody] PayOsWebhookDto webhook, CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.HandlePayOsWebhookAsync(webhook, cancellationToken);
            return Ok(new { success = true, payment });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Rejected PayOS webhook.");
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [AllowAnonymous]
    [HttpGet("payos/return")]
    public async Task<IActionResult> PayOsReturn([FromQuery] long orderCode, CancellationToken cancellationToken)
    {
        var payment = await _paymentService.GetPaymentStatusAsync(orderCode, cancellationToken);
        return payment == null ? NotFound(new { message = $"Payment orderCode {orderCode} was not found." }) : Ok(payment);
    }
    
    [AllowAnonymous]
    [HttpGet("payos/cancel")]
    public async Task<IActionResult> PayOsCancel([FromQuery] long orderCode, CancellationToken cancellationToken)
    {
        var payment = await _paymentService.GetPaymentStatusAsync(orderCode, cancellationToken);
        return payment == null ? NotFound(new { message = $"Payment orderCode {orderCode} was not found." }) : Ok(payment);
    }

    [HttpPost("vnpay/create")]
    public async Task<IActionResult> CreateVnPayPayment(
        [FromBody] CreateVnPayPaymentRequestDto request,
        CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.CreateVnPayPaymentAsync(
                request,
                ResolveClientIpAddress(),
                cancellationToken);
            return Ok(payment);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Unable to create VNPAY payment.");
            return StatusCode(StatusCodes.Status502BadGateway, new { message = ex.Message });
        }
    }

    [AllowAnonymous]
    [HttpGet("vnpay/ipn")]
    public async Task<IActionResult> VnPayIpn(CancellationToken cancellationToken)
    {
        var response = await _paymentService.HandleVnPayIpnAsync(ToQueryDictionary(), cancellationToken);
        return Ok(response);
    }

    [AllowAnonymous]
    [HttpGet("vnpay/return")]
    public async Task<IActionResult> VnPayReturn(CancellationToken cancellationToken)
    {
        var result = await _paymentService.HandleVnPayReturnAsync(ToQueryDictionary(), cancellationToken);
        return Content(BuildVnPayReturnHtml(result), "text/html");
    }

    private IReadOnlyDictionary<string, string> ToQueryDictionary()
    {
        return Request.Query.ToDictionary(
            item => item.Key,
            item => item.Value.ToString(),
            StringComparer.Ordinal);
    }

    private string ResolveClientIpAddress()
    {
        var forwardedFor = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(forwardedFor))
        {
            var ip = forwardedFor.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(ip))
            {
                return ip;
            }
        }

        return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";
    }

    private static string BuildVnPayReturnHtml(VnPayReturnResultDto result)
    {
        var title = result.IsSuccess ? "Thanh toán VNPAY thành công" : "Kết quả thanh toán VNPAY";
        var subtitle = result.IsSuccess
            ? "Giao dịch đã được ghi nhận"
            : "SmartTrip đã nhận phản hồi từ VNPAY";
        var nextAction = result.IsSuccess
            ? "Quay lại ứng dụng SmartTrip và bấm kiểm tra thanh toán để đồng bộ đơn đặt chỗ."
            : "Nếu giao dịch chưa hoàn tất, bạn có thể quay lại ứng dụng SmartTrip để thử lại hoặc kiểm tra trạng thái.";
        var heading = WebUtility.HtmlEncode(title);
        var eyebrow = WebUtility.HtmlEncode(subtitle);
        var message = WebUtility.HtmlEncode(result.Message);
        var instruction = WebUtility.HtmlEncode(nextAction);
        var status = WebUtility.HtmlEncode(result.Status);
        var orderCode = WebUtility.HtmlEncode(result.OrderCode?.ToString() ?? "-");
        var responseCode = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(result.ResponseCode) ? "-" : result.ResponseCode);
        var transactionStatus = WebUtility.HtmlEncode(string.IsNullOrWhiteSpace(result.TransactionStatus) ? "-" : result.TransactionStatus);
        var stateClass = result.IsSuccess ? "success" : "warning";
        var icon = result.IsSuccess ? "✓" : "!";

        return $$"""
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{heading}}</title>
  <style>
    :root {
      --ink: #07162f;
      --muted: #657188;
      --line: #e4ebf5;
      --surface: rgba(255, 255, 255, .86);
      --success: #16a05d;
      --success-soft: #ddffeb;
      --warning: #d86b1d;
      --warning-soft: #fff1dc;
      --blue: #0a57c8;
    }

    * { box-sizing: border-box; }

    body {
      min-height: 100vh;
      margin: 0;
      padding: 28px;
      color: var(--ink);
      font-family: "Libre Franklin", "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at 12% 14%, rgba(22, 160, 93, .22), transparent 28%),
        radial-gradient(circle at 82% 12%, rgba(10, 87, 200, .20), transparent 30%),
        linear-gradient(135deg, #f8fbff 0%, #eef4fb 48%, #f8fbff 100%);
    }

    .shell {
      width: min(760px, 100%);
      margin: 34px auto;
      position: relative;
    }

    .shell::before {
      content: "";
      position: absolute;
      inset: -24px 34px auto auto;
      width: 138px;
      height: 138px;
      border-radius: 999px;
      background: linear-gradient(135deg, rgba(10, 87, 200, .18), rgba(22, 160, 93, .24));
      filter: blur(8px);
      z-index: 0;
    }

    .card {
      position: relative;
      z-index: 1;
      overflow: hidden;
      border: 1px solid rgba(255, 255, 255, .82);
      border-radius: 32px;
      background: var(--surface);
      box-shadow: 0 30px 80px rgba(7, 22, 47, .14);
      backdrop-filter: blur(18px);
    }

    .hero {
      padding: 34px;
      display: grid;
      grid-template-columns: auto 1fr;
      gap: 22px;
      align-items: center;
      background:
        linear-gradient(120deg, rgba(255,255,255,.96), rgba(255,255,255,.70)),
        radial-gradient(circle at 88% 20%, rgba(22,160,93,.18), transparent 28%);
    }

    .mark {
      width: 76px;
      height: 76px;
      display: grid;
      place-items: center;
      border-radius: 24px;
      font-size: 42px;
      font-weight: 900;
      color: #fff;
      box-shadow: 0 18px 35px rgba(22, 160, 93, .25);
    }

    .success .mark { background: linear-gradient(135deg, #10b96e, #087746); }
    .warning .mark { background: linear-gradient(135deg, #f18936, #b94b19); }

    .badge {
      width: fit-content;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 13px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 800;
      letter-spacing: .04em;
      text-transform: uppercase;
    }

    .success .badge { color: var(--success); background: var(--success-soft); }
    .warning .badge { color: var(--warning); background: var(--warning-soft); }

    h1 {
      margin: 14px 0 8px;
      font-size: clamp(28px, 5vw, 42px);
      line-height: 1.08;
      letter-spacing: -.04em;
    }

    .eyebrow {
      margin: 0;
      color: var(--blue);
      font-size: 15px;
      font-weight: 800;
    }

    .content {
      padding: 0 34px 34px;
    }

    .message {
      margin: 0;
      padding: 24px 0;
      color: #23314f;
      font-size: 17px;
      line-height: 1.7;
      border-top: 1px solid var(--line);
    }

    .guide {
      margin: 0 0 22px;
      padding: 16px 18px;
      border-radius: 20px;
      color: #33415f;
      background: #f4f8ff;
      line-height: 1.6;
    }

    .meta {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
    }

    .meta-item {
      padding: 16px;
      border: 1px solid var(--line);
      border-radius: 18px;
      background: rgba(255, 255, 255, .78);
    }

    .label {
      display: block;
      margin-bottom: 8px;
      color: var(--muted);
      font-size: 12px;
      font-weight: 800;
      letter-spacing: .03em;
      text-transform: uppercase;
    }

    .value {
      overflow-wrap: anywhere;
      font-size: 16px;
      font-weight: 800;
    }

    .footer {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      margin-top: 22px;
      color: var(--muted);
      font-size: 13px;
    }

    .brand {
      font-weight: 900;
      color: var(--ink);
    }

    @media (max-width: 640px) {
      body { padding: 16px; }
      .shell { margin: 12px auto; }
      .hero {
        grid-template-columns: 1fr;
        padding: 26px;
      }
      .mark {
        width: 68px;
        height: 68px;
        border-radius: 22px;
      }
      .content { padding: 0 24px 26px; }
      .meta { grid-template-columns: 1fr; }
      .footer {
        align-items: flex-start;
        flex-direction: column;
      }
    }
  </style>
</head>
<body>
  <main class="shell {{stateClass}}">
    <section class="card">
      <div class="hero">
        <div class="mark" aria-hidden="true">{{icon}}</div>
        <div>
          <div class="badge">{{status}}</div>
          <h1>{{heading}}</h1>
          <p class="eyebrow">{{eyebrow}}</p>
        </div>
      </div>
      <div class="content">
        <p class="message">{{message}}</p>
        <p class="guide">{{instruction}}</p>
        <div class="meta" aria-label="Thông tin giao dịch">
          <div class="meta-item">
            <span class="label">Mã giao dịch</span>
            <span class="value">{{orderCode}}</span>
          </div>
          <div class="meta-item">
            <span class="label">Mã phản hồi</span>
            <span class="value">{{responseCode}}</span>
          </div>
          <div class="meta-item">
            <span class="label">Trạng thái VNPAY</span>
            <span class="value">{{transactionStatus}}</span>
          </div>
        </div>
        <div class="footer">
          <span><span class="brand">SmartTrip</span> sẽ đồng bộ đơn sau khi bạn kiểm tra trong ứng dụng.</span>
          <span>Powered by VNPAY</span>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
""";
    }

    [HttpPost("wallet/deposit")]
    public async Task<IActionResult> CreateWalletDeposit([FromBody] CreateWalletDepositRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (request.Amount <= 0)
            {
                return BadRequest(new { message = "Số tiền nạp phải lớn hơn 0." });
            }

            var metadataJson = $"{{\"userId\":{userId},\"type\":\"wallet_deposit\"}}";
            var metadataElement = JsonSerializer.Deserialize<JsonElement>(metadataJson);

            if (request.PaymentMethod?.ToUpper() == "PAYOS")
            {
                if (request.OrderCode == null || string.IsNullOrEmpty(request.ReturnUrl) || string.IsNullOrEmpty(request.CancelUrl))
                {
                    return BadRequest(new { message = "Thiếu thông tin OrderCode, ReturnUrl hoặc CancelUrl cho PayOS." });
                }

                var payOsRequest = new CreatePaymentRequestDto
                {
                    Amount = request.Amount,
                    Description = $"Nap tien vao vi SmartTrip (User #{userId})",
                    OrderCode = request.OrderCode.Value,
                    ReturnUrl = request.ReturnUrl,
                    CancelUrl = request.CancelUrl,
                    Metadata = metadataElement
                };

                var payment = await _paymentService.CreatePaymentAsync(payOsRequest, cancellationToken);
                return Ok(payment);
            }
            else
            {
                // Mặc định là VNPAY
                var vnpayRequest = new CreateVnPayPaymentRequestDto
                {
                    Amount = request.Amount,
                    Description = $"Nap tien vao vi SmartTrip (User #{userId})",
                    Locale = request.Locale,
                    Metadata = metadataElement
                };

                var payment = await _paymentService.CreateVnPayPaymentAsync(
                    vnpayRequest,
                    ResolveClientIpAddress(),
                    cancellationToken);

                return Ok(payment);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi tạo yêu cầu nạp tiền vào ví.");
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("wallet/deposit/simulate")]
    public async Task<IActionResult> SimulateWalletDeposit([FromBody] CreateWalletDepositRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var env = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            if (env != "Development")
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { message = "Endpoint này chỉ khả dụng trong môi trường Development." });
            }

            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (request.Amount <= 0)
            {
                return BadRequest(new { message = "Số tiền nạp phải lớn hơn 0." });
            }

            var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == userId.Value, cancellationToken);
            if (wallet == null)
            {
                wallet = new UserWallet
                {
                    UserId = userId.Value,
                    Balance = 0,
                    LoyaltyPoints = 0
                };
                _context.UserWallets.Add(wallet);
            }
            wallet.Balance = (wallet.Balance ?? 0m) + request.Amount;

            var depositPayment = new Payment
            {
                Amount = request.Amount,
                PaymentMethod = PaymentMethod.Wallet,
                Status = PaymentStatus.Paid,
                TransactionId = $"DEMO-{userId}-{DateTime.UtcNow:yyyyMMddHHmmss}",
                Description = $"Nạp tiền demo vào ví: +{request.Amount:N0}đ",
                PaidAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.Payments.Add(depositPayment);

            await _context.SaveChangesAsync(cancellationToken);

            return Ok(new { message = "Nạp tiền demo thành công.", remainingBalance = wallet.Balance });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi nạp tiền demo.");
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("wallet/withdraw")]
    public async Task<IActionResult> WithdrawFromWallet([FromBody] WalletWithdrawRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (request.Amount <= 0)
            {
                return BadRequest(new { message = "Số tiền rút phải lớn hơn 0." });
            }

            var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == userId.Value);
            if (wallet == null || (wallet.Balance ?? 0m) < request.Amount)
            {
                return BadRequest(new { message = "Số dư ví không đủ để thực hiện giao dịch." });
            }

            var payoutRequest = new CreatePayoutRequestDto
            {
                Amount = request.Amount,
                BankCode = request.BankName, // Frontend will send BankCode here
                AccountNumber = request.AccountNumber,
                AccountName = request.AccountName,
                Description = $"Rut tien SmartTrip - {request.AccountNumber}"
            };

            var payoutResult = await _paymentService.CreatePayoutAsync(payoutRequest);

            if (!payoutResult.Success)
            {
                return BadRequest(new { message = $"Chi hộ thất bại: {payoutResult.Message}" });
            }

            wallet.Balance -= request.Amount;

            var withdrawalPayment = new Payment
            {
                Amount = -request.Amount,
                PaymentMethod = PaymentMethod.BankTransfer,
                Status = PaymentStatus.Paid,
                TransactionId = string.IsNullOrEmpty(payoutResult.TransactionId) ? $"WITHDRAW-{userId}-{DateTime.UtcNow:yyyyMMddHHmmss}" : payoutResult.TransactionId,
                Description = $"Rút tiền về tài khoản: {request.BankName} - {request.AccountNumber}",
                PaidAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.Payments.Add(withdrawalPayment);

            await _context.SaveChangesAsync(cancellationToken);

            return Ok(new { message = payoutResult.Message ?? "Rút tiền thành công.", remainingBalance = wallet.Balance });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xử lý rút tiền.");
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("wallet/pay")]
    public async Task<IActionResult> PayWithWallet([FromBody] WalletPayRequestDto request)
    {
        try
        {
            var userId = GetCurrentUserId();
            if (userId == null) return Unauthorized();

            if (request.Amount <= 0)
            {
                return BadRequest(new { message = "Số tiền thanh toán phải lớn hơn 0." });
            }

            var trip = await _context.Trips
                .Include(t => t.User)
                .Include(t => t.TripItineraries)
                .Include(t => t.Payments)
                .FirstOrDefaultAsync(t => t.Id == request.TripId && t.UserId == userId.Value);

            if (trip == null)
            {
                return NotFound(new { message = "Không tìm thấy chuyến đi." });
            }

            if (trip.Status == TripStatus.Paid)
            {
                return BadRequest(new { message = "Chuyến đi này đã được thanh toán đầy đủ." });
            }

            var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == userId.Value);
            if (wallet == null || (wallet.Balance ?? 0m) < request.Amount)
            {
                return BadRequest(new { message = "Số dư ví không đủ để thực hiện giao dịch." });
            }

            // Deduct coins if used
            if (request.UsedCoins.HasValue && request.UsedCoins.Value > 0)
            {
                var availableCoins = wallet.LoyaltyPoints ?? 0;
                if (availableCoins < request.UsedCoins.Value)
                {
                    return BadRequest(new { message = "Số dư xu không đủ để thực hiện giao dịch." });
                }
                wallet.LoyaltyPoints = availableCoins - request.UsedCoins.Value;
            }

            // Deduct wallet balance
            wallet.Balance -= request.Amount;

            // Reward loyalty points (1% of actual paid cash amount)
            int earnedCoins = (int)(request.Amount / 100000m);
            if (earnedCoins > 0)
            {
                wallet.LoyaltyPoints = (wallet.LoyaltyPoints ?? 0) + earnedCoins;
            }

            // Log the payment
            var payment = new Payment
            {
                TripId = request.TripId,
                Amount = request.Amount,
                PaymentMethod = PaymentMethod.Wallet,
                Status = PaymentStatus.Paid,
                TransactionId = $"WALLET-{request.TripId}-{DateTime.UtcNow:yyyyMMddHHmmss}",
                Description = request.IsDeposit ? $"Thanh toán đặt cọc chuyến đi #{request.TripId}" : $"Thanh toán chuyến đi #{request.TripId}",
                PaidAt = DateTime.UtcNow,
                MetadataJson = request.UsedCoins.HasValue && request.UsedCoins.Value > 0
                    ? $"{{\"usedCoins\": {request.UsedCoins.Value}}}"
                    : null,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _context.Payments.Add(payment);

            var totalPaidSoFar = trip.Payments
                .Where(p => p.Status == PaymentStatus.Paid)
                .Sum(p => p.Amount ?? 0m) + request.Amount;
            var totalRequired = trip.TotalAmount ?? 0m;
            var isFullyPaid = totalPaidSoFar >= totalRequired;

            if (trip.Status != TripStatus.BookingOnly)
            {
                trip.Status = TripStatus.Paid;
            }
            
            // Generate Invoice if fully paid
            if (isFullyPaid)
            {
                var invoice = new Invoice
                {
                    TripId = request.TripId,
                    InvoiceNumber = $"INV-{DateTime.UtcNow:yyyyMMdd}-{request.TripId:D6}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}",
                    TaxAmount = 0,
                    IssuedAt = DateTime.UtcNow
                };
                _context.Invoices.Add(invoice);
            }

            // If it is a BUS booking, lock/book the seats
            var busItinerary = trip.TripItineraries.FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
            if (busItinerary != null && busItinerary.ServiceId.HasValue && !string.IsNullOrEmpty(busItinerary.SelectedSeats))
            {
                var seatNumbers = busItinerary.SelectedSeats.Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(s => s.Trim())
                    .ToList();
                var seats = await _context.Seats
                    .Where(s => s.ScheduleId == busItinerary.ServiceId.Value && s.SeatNumber != null && seatNumbers.Contains(s.SeatNumber))
                    .ToListAsync();
                foreach (var seat in seats)
                {
                    seat.Status = SeatStatus.Booked;
                }
            }

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Thanh toán qua ví thành công.", remainingBalance = wallet.Balance });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi thanh toán bằng ví.");
            return BadRequest(new { message = ex.Message });
        }
    }

    private int? GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        return int.TryParse(rawUserId, out var userId) ? userId : null;
    }
}
