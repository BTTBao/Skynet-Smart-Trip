using SmartTrip.Application.DTOs.Payment;

namespace SmartTrip.Application.Interfaces.Payment;

public interface IPaymentService
{
    Task<PaymentResultDto> CreatePaymentAsync(CreatePaymentRequestDto request, CancellationToken cancellationToken = default);
    Task<PaymentResultDto> CreateVnPayPaymentAsync(
        CreateVnPayPaymentRequestDto request,
        string ipAddress,
        CancellationToken cancellationToken = default);
    Task<PaymentResultDto?> GetPaymentStatusAsync(long orderCode, CancellationToken cancellationToken = default);
    Task<PaymentResultDto?> GetPaymentStatusByIdAsync(int paymentId, CancellationToken cancellationToken = default);
    Task<PaymentResultDto?> HandlePayOsWebhookAsync(PayOsWebhookDto webhook, CancellationToken cancellationToken = default);
    Task<VnPayIpnResponseDto> HandleVnPayIpnAsync(
        IReadOnlyDictionary<string, string> queryParameters,
        CancellationToken cancellationToken = default);
    Task<VnPayReturnResultDto> HandleVnPayReturnAsync(
        IReadOnlyDictionary<string, string> queryParameters,
        CancellationToken cancellationToken = default);
    bool VerifyPayOsWebhook(PayOsWebhookDto webhook);
    Task<PayoutResultDto> CreatePayoutAsync(CreatePayoutRequestDto request, CancellationToken cancellationToken = default);
}
