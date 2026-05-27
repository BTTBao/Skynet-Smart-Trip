using System.Text.Json;

namespace SmartTrip.Application.DTOs.Payment;

public class CreatePaymentRequestDto
{
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public long OrderCode { get; set; }
    public string ReturnUrl { get; set; } = string.Empty;
    public string CancelUrl { get; set; } = string.Empty;
    public JsonElement? Metadata { get; set; }
}
