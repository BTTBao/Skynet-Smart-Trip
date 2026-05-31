using System.Text.Json;

namespace SmartTrip.Application.DTOs.Payment;

public class PayOsWebhookDto
{
    public string Code { get; set; } = string.Empty;
    public string Desc { get; set; } = string.Empty;
    public bool Success { get; set; }
    public JsonElement Data { get; set; }
    public string Signature { get; set; } = string.Empty;
}
