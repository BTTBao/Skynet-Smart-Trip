using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Payment;
using SmartTrip.Application.Interfaces.Payment;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/payments")]
public class PaymentController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(IPaymentService paymentService, ILogger<PaymentController> logger)
    {
        _paymentService = paymentService;
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
}
