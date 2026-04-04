namespace SmartTrip.Application.DTOs.Trip;

public class CreateTripDto
{
    public int UserId { get; set; }

    public int? DestinationId { get; set; }

    public string? DestinationName { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public string? Status { get; set; }
}
