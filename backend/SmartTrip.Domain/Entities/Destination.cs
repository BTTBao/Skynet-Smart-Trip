using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Destination
{
    public int DestId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public string? CoverImageUrl { get; set; }

    public bool? IsHot { get; set; }

    public virtual ICollection<BlogPost> BlogPosts { get; set; } = new List<BlogPost>();

    public virtual ICollection<BusSchedule> BusScheduleFromDests { get; set; } = new List<BusSchedule>();

    public virtual ICollection<BusSchedule> BusScheduleToDests { get; set; } = new List<BusSchedule>();

    public virtual ICollection<Hotel> Hotels { get; set; } = new List<Hotel>();

    public virtual ICollection<Trip> Trips { get; set; } = new List<Trip>();
}
