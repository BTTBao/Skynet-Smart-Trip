using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Application.Interfaces.Admin;
using SmartTrip.Application.Interfaces;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Admin;

public class AdminService : IAdminService
{
    private readonly IApplicationDbContext _context;

    public AdminService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<AdminDashboardDto> GetDashboardStatsAsync()
    {
        // Total Users
        var totalUsers = await _context.Users.CountAsync();
        
        // New Users Today
        var today = DateTime.UtcNow.Date;
        var newUsersToday = await _context.Users
            .Where(u => u.CreatedAt >= today)
            .CountAsync();

        // Total Revenue and Profit from Paid trips
        var paidTrips = await _context.Trips
            .Where(t => t.Status == TripStatus.Paid)
            .ToListAsync();
            
        var totalRevenue = paidTrips.Sum(t => t.TotalAmount.GetValueOrDefault(0m));
        var totalProfit = paidTrips.Sum(t => t.TotalProfit.GetValueOrDefault(0m));

        // Active Trips (Ongoing / InProgress)
        var activeTrips = await _context.Trips
            .Where(t => t.Status == TripStatus.Pending || t.Status == TripStatus.Paid)
            .CountAsync();

        // Recent Bookings (Last 5 trips regardless of status)
        var recentTrips = await _context.Trips
            .Include(t => t.User)
            .Include(t => t.Destination)
            .OrderByDescending(t => t.CreatedAt)
            .Take(5)
            .ToListAsync();

        var recentBookings = recentTrips.Select(t => new AdminRecentBookingDto
        {
            Id = $"#SK-{t.Id:D5}",
            Initials = GetInitials(t.User?.FullName ?? "Unknown"),
            Name = t.User?.FullName ?? "Khách vãng lai",
            Destination = t.Destination?.Name ?? "Chưa xác định",
            Amount = $"{t.TotalAmount.GetValueOrDefault(0m):N0}₫",
            Status = MapStatus(t.Status)
        }).ToList();

        return new AdminDashboardDto
        {
            TotalRevenue = totalRevenue,
            TotalProfit = totalProfit,
            TotalUsers = totalUsers,
            NewUsersToday = newUsersToday,
            ActiveTrips = activeTrips,
            RecentBookings = recentBookings
        };
    }

    public async Task<AdminUserStatsDto> GetUsersAsync()
    {
        var allUsersDb = await _context.Users.OrderByDescending(u => u.CreatedAt).ToListAsync();
        
        var totalUsers = allUsersDb.Count;
        var activeUsers = allUsersDb.Count(u => u.IsActive == true);
        var blockedUsers = allUsersDb.Count(u => u.IsActive == false);
        
        var todayMonth = DateTime.UtcNow.Month;
        var todayYear = DateTime.UtcNow.Year;
        var newUsers = allUsersDb.Count(u => u.CreatedAt.GetValueOrDefault().Month == todayMonth && u.CreatedAt.GetValueOrDefault().Year == todayYear);

        var bgColors = new[] { "bg-primary-container/20", "bg-secondary-container/20", "bg-tertiary-container/20", "bg-surface-container" };
        var random = new Random();

        var usersList = allUsersDb.Select(u => new AdminUserDto
        {
            Id = u.Id,
            DisplayId = $"SKY-{u.Id:D4}",
            Name = string.IsNullOrWhiteSpace(u.FullName) ? "Chưa có tên" : u.FullName,
            Email = u.Email ?? "No Email",
            Phone = u.Phone ?? "No Phone",
            JoinDate = u.CreatedAt.GetValueOrDefault().ToString("dd/MM/yyyy"),
            Status = u.IsActive == true ? "active" : "blocked",
            AvatarBg = bgColors[random.Next(bgColors.Length)]
        }).ToList();

        return new AdminUserStatsDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            NewUsers = newUsers,
            BlockedUsers = blockedUsers,
            Users = usersList
        };
    }

    private string GetInitials(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return "U";
        var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
        return (parts[0].Substring(0, 1) + parts[^1].Substring(0, 1)).ToUpper();
    }

    private string MapStatus(TripStatus? status)
    {
        return status switch
        {
            TripStatus.Paid => "paid",
            TripStatus.Cancelled => "cancelled",
            _ => "pending"
        };
    }
}
