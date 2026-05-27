using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Notification
{
    public int Id { get; set; }

    public int? UserId { get; set; }

    public string? Title { get; set; }

    public string? Message { get; set; }

    public string? Type { get; set; }

    public string? ReferenceType { get; set; }

    public int? ReferenceId { get; set; }

    public string? ActionUrl { get; set; }

    public bool? IsRead { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual User? User { get; set; }
}


