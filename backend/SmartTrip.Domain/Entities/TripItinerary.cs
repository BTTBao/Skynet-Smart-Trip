using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class TripItinerary
{
    public int ItineraryId { get; set; }

    public int? TripId { get; set; }

    public int? DayNumber { get; set; }

    public string? ServiceType { get; set; }

    public int? ServiceId { get; set; }

    public int? Quantity { get; set; }

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }

    public virtual Trip? Trip { get; set; }
}
