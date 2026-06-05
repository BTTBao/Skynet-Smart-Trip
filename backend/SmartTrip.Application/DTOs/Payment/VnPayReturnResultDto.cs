namespace SmartTrip.Application.DTOs.Payment;

public class VnPayReturnResultDto
{
    public int? PaymentId { get; set; }
    public long? OrderCode { get; set; }
    public string Status { get; set; } = "PENDING";
    public string ResponseCode { get; set; } = string.Empty;
    public string TransactionStatus { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public bool SignatureValid { get; set; }
}
