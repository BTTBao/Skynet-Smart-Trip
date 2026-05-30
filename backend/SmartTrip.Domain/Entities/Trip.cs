using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Trip
{
    public int Id { get; set; }

    public int? UserId { get; set; }

    public int? DestinationId { get; set; }

    public string? Title { get; set; }

    public DateOnly? StartDate { get; set; }

    public DateOnly? EndDate { get; set; }

    public decimal? TotalAmount { get; set; }

    public decimal? TotalProfit { get; set; }

    public TripStatus? Status { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Destination? Destination { get; set; }

    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<TripItinerary> TripItineraries { get; set; } = new List<TripItinerary>();

    public virtual User? User { get; set; }
}



