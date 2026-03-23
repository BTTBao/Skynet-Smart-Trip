using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Invoice
{
    public int InvoiceId { get; set; }

    public int? TripId { get; set; }

    public string? InvoiceNumber { get; set; }

    public decimal? TaxAmount { get; set; }

    public string? PdfUrl { get; set; }

    public DateTime? IssuedAt { get; set; }

    public virtual Trip? Trip { get; set; }
}
