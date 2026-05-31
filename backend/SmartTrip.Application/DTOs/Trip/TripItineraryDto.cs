namespace SmartTrip.Application.DTOs.Trip;

public class TripItineraryDto
{
    public int ItineraryId { get; set; }

    public int DayNumber { get; set; }

    public string ServiceType { get; set; } = string.Empty;

    public int? ServiceId { get; set; }

    public string ServiceName { get; set; } = string.Empty;

    public string? ServiceSubtitle { get; set; }

    public int Quantity { get; set; }

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }

    public DateOnly? ServiceDate { get; set; }

    public TimeOnly? DepartureTime { get; set; }

    public string? ServiceAddress { get; set; }
}
