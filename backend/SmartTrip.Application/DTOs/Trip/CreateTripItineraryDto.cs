namespace SmartTrip.Application.DTOs.Trip;

public class CreateTripItineraryDto
{
    public int DayNumber { get; set; }

    public string ServiceType { get; set; } = string.Empty;

    public int ServiceId { get; set; }

    public int Quantity { get; set; } = 1;

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }

    public DateOnly? ServiceDate { get; set; }

    public DateOnly? HotelCheckOutDate { get; set; }

    public TimeOnly? DepartureTime { get; set; }

    public string? ServiceAddress { get; set; }

    public string? SelectedSeats { get; set; }

    public int AdultCount { get; set; } = 1;

    public int ChildCount { get; set; }

    public int InfantCount { get; set; }
}
