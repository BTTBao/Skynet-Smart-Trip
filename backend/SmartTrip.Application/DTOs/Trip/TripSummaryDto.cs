namespace SmartTrip.Application.DTOs.Trip;

public class TripSummaryDto
{
    public int TripId { get; set; }

    public int? UserId { get; set; }

    public int? DestinationId { get; set; }

    public string? DestinationName { get; set; }

    public string? DestinationDescription { get; set; }

    public string? DestinationCoverImageUrl { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateOnly? StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public decimal? TotalAmount { get; set; }

    public decimal? TotalProfit { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime? CreatedAt { get; set; }

    public int ItineraryCount { get; set; }
}
