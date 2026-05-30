using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class BusCompany
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public string? Hotline { get; set; }

    public string? LogoUrl { get; set; }

    public virtual ICollection<BusSchedule> BusSchedules { get; set; } = new List<BusSchedule>();
}


