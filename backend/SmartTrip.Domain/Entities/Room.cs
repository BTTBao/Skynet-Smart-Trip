using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Room
{
    public int Id { get; set; }

    public int? HotelId { get; set; }

    public string? RoomType { get; set; }

    public int? Capacity { get; set; }

    public decimal? PricePerNight { get; set; }

    public double? CommissionRate { get; set; }

    public int? AvailableQty { get; set; }

    public virtual Hotel? Hotel { get; set; }
}


