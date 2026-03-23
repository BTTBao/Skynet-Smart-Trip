using System;
using System.Collections.Generic;

namespace SmartTrip.Domain.Entities;

public partial class UserWallet
{
    public int WalletId { get; set; }

    public int? UserId { get; set; }

    public decimal? Balance { get; set; }

    public int? LoyaltyPoints { get; set; }

    public virtual User? User { get; set; }
}
