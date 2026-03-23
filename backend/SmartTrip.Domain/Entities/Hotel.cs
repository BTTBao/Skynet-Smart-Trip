using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class Hotel
{
    public int HotelId { get; set; }

    public int? DestinationId { get; set; }

    public string Name { get; set; } = null!;

    public string? Address { get; set; }

    public int? StarRating { get; set; }

    public string? Description { get; set; }

    public bool? IsAvailable { get; set; }

    public virtual Destination? Destination { get; set; }

    public virtual ICollection<Room> Rooms { get; set; } = new List<Room>();

    public virtual ICollection<Amenity> Amenities { get; set; } = new List<Amenity>();
}
