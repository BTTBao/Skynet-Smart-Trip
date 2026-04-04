using System;

namespace SmartTrip.Domain.Entities;

public class UserPreference
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string PreferenceKey { get; set; } = null!;
    public string PreferenceValue { get; set; } = null!;
    public DateTime UpdatedAt { get; set; }

    public virtual User? User { get; set; }
}
