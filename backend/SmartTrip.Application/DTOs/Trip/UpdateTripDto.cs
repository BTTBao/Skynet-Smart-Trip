namespace SmartTrip.Application.DTOs.Trip;

public class UpdateTripDto
{
    public string? Title { get; set; }

    public int? DestinationId { get; set; }

    public string? DestinationName { get; set; }

    public DateOnly? StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public string? Status { get; set; }
}
