using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Notification
{
    public int NotiId { get; set; }

    public int? UserId { get; set; }

    public string? Title { get; set; }

    public string? Message { get; set; }

    public bool? IsRead { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual User? User { get; set; }
}
