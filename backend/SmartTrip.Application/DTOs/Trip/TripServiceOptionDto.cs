namespace SmartTrip.Application.DTOs.Trip;

public class TripServiceOptionDto
{
    public int ServiceId { get; set; }

    public string ServiceType { get; set; } = string.Empty;

    public string Title { get; set; } = string.Empty;

    public string? Subtitle { get; set; }

    public decimal? DefaultPrice { get; set; }

    public double? DefaultCommissionRate { get; set; }
}
