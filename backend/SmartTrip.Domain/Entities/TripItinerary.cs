using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class TripItinerary
{
    public int Id { get; set; }

    public int? TripId { get; set; }

    public int? DayNumber { get; set; }

    public TripServiceType? ServiceType { get; set; }

    public int? ServiceId { get; set; }

    public int? Quantity { get; set; }

    public decimal? BookedPrice { get; set; }

    public double? BookedCommissionRate { get; set; }

    public virtual Trip? Trip { get; set; }
}



