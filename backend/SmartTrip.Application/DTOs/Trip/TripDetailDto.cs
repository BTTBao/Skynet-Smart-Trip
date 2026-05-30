namespace SmartTrip.Application.DTOs.Trip;

public class TripDetailDto : TripSummaryDto
{
    public List<TripItineraryDto> Itineraries { get; set; } = [];
}
