using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class Wishlist
{
    public int WishId { get; set; }

    public int? UserId { get; set; }

    public WishlistItemType? ItemType { get; set; }

    public int? ItemId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual User? User { get; set; }
}



