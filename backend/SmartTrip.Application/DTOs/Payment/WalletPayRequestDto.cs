namespace SmartTrip.Application.DTOs.Payment;

public class WalletPayRequestDto
{
    public int TripId { get; set; }
    public decimal Amount { get; set; }
    public bool IsDeposit { get; set; }
    public int? UsedCoins { get; set; }
}
