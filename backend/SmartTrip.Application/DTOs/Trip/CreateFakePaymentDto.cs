namespace SmartTrip.Application.DTOs.Trip;

public class CreateFakePaymentDto
{
    public string PaymentMethod { get; set; } = "Momo";

    public decimal? Amount { get; set; }
}
