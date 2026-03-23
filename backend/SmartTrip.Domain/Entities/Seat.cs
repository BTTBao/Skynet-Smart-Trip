using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Seat
{
    public int SeatId { get; set; }

    public int? ScheduleId { get; set; }

    public string? SeatNumber { get; set; }

    public string? Status { get; set; }

    public virtual BusSchedule? Schedule { get; set; }
}
