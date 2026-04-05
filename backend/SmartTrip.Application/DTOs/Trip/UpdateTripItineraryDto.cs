namespace SmartTrip.Application.DTOs.Trip;

public class UpdateTripItineraryDto
{
    public int? DayNumber { get; set; }

    public int? Quantity { get; set; }

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }
}
