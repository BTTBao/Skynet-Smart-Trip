namespace SmartTrip.Application.DTOs.User;

public class UserDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? AvatarUrl { get; set; }
    public string MemberTier { get; set; } = "Gold Member";
    public int TripsCount { get; set; } = 12;
    public int Coins { get; set; } = 450;
    public int Vouchers { get; set; } = 15;
    public string? BirthDate { get; set; }
}
