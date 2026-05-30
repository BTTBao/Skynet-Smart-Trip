using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Promotion
{
    public int Id { get; set; }

    public string? Code { get; set; }

    public double? DiscountPercent { get; set; }

    public decimal? MaxDiscountAmount { get; set; }

    public DateTime? ValidUntil { get; set; }

    public int? UsageLimit { get; set; }

    public int? UsedCount { get; set; }
}


