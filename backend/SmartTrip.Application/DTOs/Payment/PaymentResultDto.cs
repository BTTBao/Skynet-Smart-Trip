namespace SmartTrip.Application.DTOs.Payment;

public class PaymentResultDto
{
    public int PaymentId { get; set; }
    public long? OrderCode { get; set; }
    public string? CheckoutUrl { get; set; }
    public string? PaymentLink { get; set; }
    public string? QrCode { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? PaidAt { get; set; }
    public string? Message { get; set; }
    public string? ProviderResponseCode { get; set; }
    public string? ProviderTransactionStatus { get; set; }
    public string? RawResponse { get; set; }
}
