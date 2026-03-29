using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public class UserWallet
{
    public int Id { get; set; }

    public int? UserId { get; set; }

    public decimal? Balance { get; set; }

    public int? LoyaltyPoints { get; set; }

    public virtual User? User { get; set; }
}


