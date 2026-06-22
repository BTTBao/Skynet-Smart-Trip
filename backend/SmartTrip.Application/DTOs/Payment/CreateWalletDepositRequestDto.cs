namespace SmartTrip.Application.DTOs.Payment;

public class CreateWalletDepositRequestDto
{
    public decimal Amount { get; set; }
    public string Locale { get; set; } = "vn";
    public string PaymentMethod { get; set; } = "VNPAY";
    
    // For PayOS
    public long? OrderCode { get; set; }
    public string? ReturnUrl { get; set; }
    public string? CancelUrl { get; set; }
}
