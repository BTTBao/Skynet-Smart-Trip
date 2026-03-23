using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Promotion
{
    public int PromoId { get; set; }

    public string? Code { get; set; }

    public double? DiscountPercent { get; set; }

    public decimal? MaxDiscountAmount { get; set; }

    public DateTime? ValidUntil { get; set; }

    public int? UsageLimit { get; set; }

    public int? UsedCount { get; set; }
}
