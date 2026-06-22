namespace SmartTrip.Application.DTOs.Payment;

public class CreateWalletDepositRequestDto
{
    public decimal Amount { get; set; }
    public string Locale { get; set; } = "vn";
}
