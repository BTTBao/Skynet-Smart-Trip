namespace SmartTrip.Application.DTOs.User;

public class UserDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? AvatarUrl { get; set; }
    public bool IsEmailVerified { get; set; }
    public string MemberTier { get; set; } = "Member";
    public int TripsCount { get; set; }
    public int Coins { get; set; }
    public int Vouchers { get; set; }
    public string? BirthDate { get; set; }
}
