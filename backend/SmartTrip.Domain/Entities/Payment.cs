using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Payment
{
    public int PaymentId { get; set; }

    public int? TripId { get; set; }

    public string? PaymentMethod { get; set; }

    public string? TransactionId { get; set; }

    public decimal? Amount { get; set; }

    public string? Status { get; set; }

    public DateTime? PaidAt { get; set; }

    public virtual Trip? Trip { get; set; }
}
