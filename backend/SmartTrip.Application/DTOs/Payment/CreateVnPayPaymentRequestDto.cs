using System.Text.Json;

namespace SmartTrip.Application.DTOs.Payment;

public class CreateVnPayPaymentRequestDto
{
    public decimal Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Locale { get; set; } = "vn";
    public JsonElement? Metadata { get; set; }
}
