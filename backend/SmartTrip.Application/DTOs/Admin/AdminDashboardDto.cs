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
    public string StartDate { get; set; } = string.Empty;
    public string EndDate { get; set; } = string.Empty;
    public List<AdminDashboardChartPointDto> ChartSeries { get; set; } = new();
    public List<AdminActivityFeedItemDto> ActivityFeed { get; set; } = new();
    public List<AdminRecentBookingDto> RecentBookings { get; set; } = new();
}

public class AdminDashboardChartPointDto
{
    public string Label { get; set; } = string.Empty;
    public decimal Revenue { get; set; }
    public decimal Profit { get; set; }
    public int Bookings { get; set; }
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

public class AdminActivityFeedItemDto
{
    public string Id { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string OccurredAt { get; set; } = string.Empty;
}
