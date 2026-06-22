namespace SmartTrip.Application.DTOs.Payment;

public class CreatePayoutRequestDto
{
    public decimal Amount { get; set; }
    public string BankCode { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string AccountName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class PayoutResultDto
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
}
