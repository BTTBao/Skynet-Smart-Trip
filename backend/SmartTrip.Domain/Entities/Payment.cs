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

    public long? OrderCode { get; set; }

    public string? Description { get; set; }

    public string? CheckoutUrl { get; set; }

    public string? QrCode { get; set; }

    public string? PaymentLinkId { get; set; }

    public string? ReturnUrl { get; set; }

    public string? CancelUrl { get; set; }

    public string? MetadataJson { get; set; }

    public string? RawResponseJson { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Trip? Trip { get; set; }
}



