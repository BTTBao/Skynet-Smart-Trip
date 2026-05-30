using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Seat
{
    public int Id { get; set; }

    public int? ScheduleId { get; set; }

    public string? SeatNumber { get; set; }

    public SeatStatus? Status { get; set; }

    public virtual BusSchedule? Schedule { get; set; }
}



