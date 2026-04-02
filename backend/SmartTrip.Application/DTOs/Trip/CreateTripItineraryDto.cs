namespace SmartTrip.Application.DTOs.Trip;

public class CreateTripItineraryDto
{
    public int DayNumber { get; set; }

    public string ServiceType { get; set; } = string.Empty;

    public int ServiceId { get; set; }

    public int Quantity { get; set; } = 1;

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }
}
