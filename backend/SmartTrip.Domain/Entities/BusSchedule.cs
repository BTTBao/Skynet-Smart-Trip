using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class BusSchedule
{
    public int ScheduleId { get; set; }

    public int? CompanyId { get; set; }

    public int? FromDestId { get; set; }

    public int? ToDestId { get; set; }

    public DateTime? DepartureTime { get; set; }

    public DateTime? ArrivalTime { get; set; }

    public decimal? Price { get; set; }

    public double? CommissionRate { get; set; }

    public int? TotalSeats { get; set; }

    public virtual BusCompany? Company { get; set; }

    public virtual Destination? FromDest { get; set; }

    public virtual ICollection<Seat> Seats { get; set; } = new List<Seat>();

    public virtual Destination? ToDest { get; set; }
}
