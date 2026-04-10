using System;
using System.Collections.Generic;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminDashboardDto
{
    public decimal TotalRevenue { get; set; }
    public decimal TotalProfit { get; set; }
    public int TotalUsers { get; set; }
    public int NewUsersToday { get; set; }
    public int ActiveTrips { get; set; }
    public List<AdminRecentBookingDto> RecentBookings { get; set; } = new();
}

public class AdminRecentBookingDto
{
    public string Id { get; set; } = string.Empty;
    public string Initials { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string Amount { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
