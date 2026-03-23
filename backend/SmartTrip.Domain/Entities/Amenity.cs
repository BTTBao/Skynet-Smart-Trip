using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Amenity
{
    public int AmenityId { get; set; }

    public string? Name { get; set; }

    public string? IconUrl { get; set; }

    public virtual ICollection<Hotel> Hotels { get; set; } = new List<Hotel>();
}
