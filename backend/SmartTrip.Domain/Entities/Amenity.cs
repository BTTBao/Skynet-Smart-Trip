using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Amenity
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public string? IconUrl { get; set; }

    public virtual ICollection<Hotel> Hotels { get; set; } = new List<Hotel>();
}


