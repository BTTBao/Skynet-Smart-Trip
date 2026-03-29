using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Payment
{
    public int Id { get; set; }

    public int? TripId { get; set; }

    public PaymentMethod? PaymentMethod { get; set; }

    public string? TransactionId { get; set; }

    public decimal? Amount { get; set; }

    public PaymentStatus? Status { get; set; }

    public DateTime? PaidAt { get; set; }

    public virtual Trip? Trip { get; set; }
}



