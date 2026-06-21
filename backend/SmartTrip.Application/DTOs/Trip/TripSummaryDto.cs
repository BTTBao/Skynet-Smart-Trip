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

    public string ShareCode { get; set; } = string.Empty;

    public int? SharedFromTripId { get; set; }

    public DateOnly? StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public decimal? TotalAmount { get; set; }

    public decimal? TotalProfit { get; set; }

    public string Status { get; set; } = string.Empty;

    public DateTime? CreatedAt { get; set; }

    public int ItineraryCount { get; set; }

    public bool CanEdit { get; set; } = true;

    public bool CanSave { get; set; }

    /// When viewing a shared trip the user already saved, this is their local copy id.
    public int? SavedTripId { get; set; }

    /// True when an update removed all itineraries because the destination changed.
    public bool ItinerariesCleared { get; set; }
}
