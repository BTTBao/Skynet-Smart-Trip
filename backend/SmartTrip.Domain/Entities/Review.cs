using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Review
{
    public int ReviewId { get; set; }

    public int? UserId { get; set; }

    public int? TripId { get; set; }

    public string? TargetType { get; set; }

    public int? TargetId { get; set; }

    public int? Rating { get; set; }

    public string? Comment { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Trip? Trip { get; set; }

    public virtual User? User { get; set; }
}
