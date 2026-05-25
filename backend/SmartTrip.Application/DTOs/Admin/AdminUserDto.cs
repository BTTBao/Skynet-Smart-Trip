using System;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminUserDto
{
    public int Id { get; set; }
    public string DisplayId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string JoinDate { get; set; } = string.Empty;
    public string LastLoginAt { get; set; } = string.Empty;
    public string Role { get; set; } = "customer";
    public string Status { get; set; } = "active";
    public string AvatarBg { get; set; } = "bg-primary-container/20";
}

public class AdminCreateUserRequest
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = "customer";
    public bool IsActive { get; set; } = true;
}

public class AdminUpdateUserRequest
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = "customer";
    public bool IsActive { get; set; } = true;
}

public class AdminUpdateUserStatusRequest
{
    public bool IsActive { get; set; }
}

public class AdminUserPasswordResetDto
{
    public string ResetLink { get; set; } = string.Empty;
    public bool EmailSent { get; set; }
}

public class AdminUserStatsDto
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int NewUsers { get; set; }
    public int BlockedUsers { get; set; }
    public List<AdminUserDto> Users { get; set; } = new();
}
