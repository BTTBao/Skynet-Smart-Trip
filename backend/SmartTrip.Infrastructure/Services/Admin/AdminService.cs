using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Application.Interfaces.Admin;
using SmartTrip.Application.Interfaces;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Admin;

public partial class AdminService : IAdminService
{
    private readonly IApplicationDbContext _context;
    private readonly IEmailService _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AdminService> _logger;

    public AdminService(
        IApplicationDbContext context,
        IEmailService emailService,
        IConfiguration configuration,
        ILogger<AdminService> logger)
    {
        _context = context;
        _emailService = emailService;
        _configuration = configuration;
        _logger = logger;
    }

public async Task<AdminDashboardDto> GetDashboardStatsAsync(DateOnly? startDate = null, DateOnly? endDate = null)
    {
        var now = DateTime.UtcNow;
        var resolvedEnd = endDate?.ToDateTime(TimeOnly.MaxValue) ?? now;
        var resolvedStart = startDate?.ToDateTime(TimeOnly.MinValue) ?? new DateTime(resolvedEnd.Year, resolvedEnd.Month, 1).AddMonths(-5);

        if (resolvedStart > resolvedEnd)
        {
            throw new BadHttpRequestException("Khoảng thời gian không hợp lệ.");
        }

        var totalUsers = await _context.Users.CountAsync();
        var today = now.Date;
        var newUsersToday = await _context.Users.CountAsync(u => u.CreatedAt >= today);
        var activeTrips = await _context.Trips.CountAsync(t => t.Status == TripStatus.Pending || t.Status == TripStatus.Paid);

        var usersInRange = await _context.Users
            .Where(u => u.CreatedAt.HasValue && u.CreatedAt.Value >= resolvedStart && u.CreatedAt.Value <= resolvedEnd)
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();

        var tripsInRange = await _context.Trips
            .Include(t => t.User)
            .Include(t => t.Destination)
            .Include(t => t.Payments)
            .Where(t => t.CreatedAt.HasValue && t.CreatedAt.Value >= resolvedStart && t.CreatedAt.Value <= resolvedEnd)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        var paymentsInRange = await _context.Payments
            .Include(p => p.Trip)
            .ThenInclude(t => t!.Destination)
            .Where(p => p.PaidAt.HasValue && p.PaidAt.Value >= resolvedStart && p.PaidAt.Value <= resolvedEnd)
            .OrderByDescending(p => p.PaidAt)
            .ToListAsync();

        var paidPayments = paymentsInRange.Where(p => p.Status == PaymentStatus.Paid).ToList();
        var totalRevenue = paidPayments.Sum(p => p.Amount.GetValueOrDefault());
        var totalProfit = tripsInRange
            .Where(t => t.Status == TripStatus.Paid)
            .Sum(t => t.TotalProfit.GetValueOrDefault());

        var useMonthlyBucket = (resolvedEnd - resolvedStart).TotalDays > 62;
        var chartSeries = new List<AdminDashboardChartPointDto>();
        var cursor = useMonthlyBucket
            ? new DateTime(resolvedStart.Year, resolvedStart.Month, 1)
            : resolvedStart.Date;

        while (cursor <= resolvedEnd)
        {
            var bucketStart = cursor;
            var bucketEnd = useMonthlyBucket
                ? cursor.AddMonths(1).AddTicks(-1)
                : cursor.Date.AddDays(1).AddTicks(-1);

            chartSeries.Add(new AdminDashboardChartPointDto
            {
                Label = useMonthlyBucket ? cursor.ToString("MMM").ToUpperInvariant() : cursor.ToString("dd/MM"),
                Revenue = paidPayments
                    .Where(p => p.PaidAt.HasValue && p.PaidAt.Value >= bucketStart && p.PaidAt.Value <= bucketEnd)
                    .Sum(p => p.Amount.GetValueOrDefault()),
                Profit = tripsInRange
                    .Where(t => t.Status == TripStatus.Paid && t.CreatedAt.HasValue && t.CreatedAt.Value >= bucketStart && t.CreatedAt.Value <= bucketEnd)
                    .Sum(t => t.TotalProfit.GetValueOrDefault()),
                Bookings = tripsInRange.Count(t => t.CreatedAt.HasValue && t.CreatedAt.Value >= bucketStart && t.CreatedAt.Value <= bucketEnd)
            });

            cursor = useMonthlyBucket ? cursor.AddMonths(1) : cursor.AddDays(1);
        }

        var recentTrips = tripsInRange.Take(6).ToList();
        if (recentTrips.Count == 0)
        {
            recentTrips = await _context.Trips
                .Include(t => t.User)
                .Include(t => t.Destination)
                .OrderByDescending(t => t.CreatedAt)
                .Take(6)
                .ToListAsync();
        }

        var recentBookings = recentTrips.Select(t => new AdminRecentBookingDto
        {
            Id = $"#SK-{t.Id:D5}",
            Initials = GetInitials(t.User?.FullName ?? "Unknown"),
            Name = t.User?.FullName ?? "Khách vãng lai",
            Destination = t.Destination?.Name ?? "Chưa xác định",
            Amount = $"{t.TotalAmount.GetValueOrDefault(0m):N0}₫",
            Status = MapStatus(t.Status)
        }).ToList();

        var activityFeed = usersInRange
            .Select(user => new
            {
                OccurredAt = user.CreatedAt ?? DateTime.MinValue,
                Item = new AdminActivityFeedItemDto
                {
                    Id = $"user-{user.Id}",
                    Type = "user",
                    Title = $"{(string.IsNullOrWhiteSpace(user.FullName) ? user.Email : user.FullName)} vừa tham gia hệ thống",
                    Description = $"Tài khoản {MapUserRole(user.Role)} được tạo với email {user.Email}.",
                    OccurredAt = user.CreatedAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
                }
            })
            .Concat(tripsInRange.Select(trip => new
            {
                OccurredAt = trip.CreatedAt ?? DateTime.MinValue,
                Item = new AdminActivityFeedItemDto
                {
                    Id = $"trip-{trip.Id}",
                    Type = "booking",
                    Title = $"{trip.User?.FullName ?? "Khách hàng"} vừa tạo booking {trip.Destination?.Name ?? "mới"}",
                    Description = $"{trip.Title ?? "Hành trình mới"} • {trip.TotalAmount.GetValueOrDefault():N0}₫",
                    OccurredAt = trip.CreatedAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
                }
            }))
            .Concat(paymentsInRange.Select(payment => new
            {
                OccurredAt = payment.PaidAt ?? DateTime.MinValue,
                Item = new AdminActivityFeedItemDto
                {
                    Id = $"payment-{payment.Id}",
                    Type = "payment",
                    Title = $"Thanh toán {MapPaymentStatus(payment.Status)} cho booking #{payment.TripId:D4}",
                    Description = $"{payment.Trip?.Destination?.Name ?? "Chưa xác định"} • {payment.Amount.GetValueOrDefault():N0}₫",
                    OccurredAt = payment.PaidAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "--"
                }
            }))
            .OrderByDescending(item => item.OccurredAt)
            .Select(item => item.Item)
            .Take(10)
            .ToList();

        return new AdminDashboardDto
        {
            TotalRevenue = totalRevenue,
            TotalProfit = totalProfit,
            TotalUsers = totalUsers,
            NewUsersToday = newUsersToday,
            ActiveTrips = activeTrips,
            StartDate = resolvedStart.ToString("yyyy-MM-dd"),
            EndDate = resolvedEnd.ToString("yyyy-MM-dd"),
            ChartSeries = chartSeries,
            ActivityFeed = activityFeed,
            RecentBookings = recentBookings
        };
    }

public async Task<AdminUserStatsDto> GetUsersAsync(string? search = null)
    {
        var allUsersDb = await _context.Users.OrderByDescending(u => u.CreatedAt).ToListAsync();

        var totalUsers = allUsersDb.Count;
        var activeUsers = allUsersDb.Count(u => u.IsActive == true);
        var blockedUsers = allUsersDb.Count(u => u.IsActive == false);

        var todayMonth = DateTime.UtcNow.Month;
        var todayYear = DateTime.UtcNow.Year;
        var newUsers = allUsersDb.Count(u => u.CreatedAt.GetValueOrDefault().Month == todayMonth && u.CreatedAt.GetValueOrDefault().Year == todayYear);

        var filteredUsers = allUsersDb
            .Where(u =>
                string.IsNullOrWhiteSpace(search) ||
                (u.FullName?.Contains(search, StringComparison.OrdinalIgnoreCase) ?? false) ||
                u.Email.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                (u.Phone?.Contains(search, StringComparison.OrdinalIgnoreCase) ?? false) ||
                $"SKY-{u.Id:D4}".Contains(search, StringComparison.OrdinalIgnoreCase))
            .ToList();

        var usersList = filteredUsers.Select(MapAdminUser).ToList();

        return new AdminUserStatsDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            NewUsers = newUsers,
            BlockedUsers = blockedUsers,
            Users = usersList
        };
    }

    public async Task<AdminUserDto> CreateUserAsync(AdminCreateUserRequest request)
    {
        ValidateAdminUserRequest(request.Name, request.Email);

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var existedUser = await _context.Users.AnyAsync(user => user.Email.ToLower() == normalizedEmail);
        if (existedUser)
        {
            throw new BadHttpRequestException("Email đã tồn tại trong hệ thống.");
        }

        var user = new SmartTrip.Domain.Entities.User
        {
            FullName = request.Name.Trim(),
            Email = normalizedEmail,
            Phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim(),
            Role = ParseUserRole(request.Role),
            IsActive = request.IsActive,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
            IsEmailVerified = true,
            AuthProvider = AuthProvider.Local,
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return MapAdminUser(user);
    }

    public async Task<AdminUserDto> UpdateUserAsync(int userId, AdminUpdateUserRequest request)
    {
        ValidateAdminUserRequest(request.Name, request.Email);

        var user = await _context.Users.FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            throw new BadHttpRequestException("Không tìm thấy người dùng.");
        }

        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var emailExisted = await _context.Users.AnyAsync(item => item.Id != userId && item.Email.ToLower() == normalizedEmail);
        if (emailExisted)
        {
            throw new BadHttpRequestException("Email đã tồn tại trong hệ thống.");
        }

        user.FullName = request.Name.Trim();
        user.Email = normalizedEmail;
        user.Phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();
        user.Role = ParseUserRole(request.Role);
        user.IsActive = request.IsActive;

        await _context.SaveChangesAsync();

        return MapAdminUser(user);
    }

    public async Task<AdminUserDto> UpdateUserStatusAsync(int userId, bool isActive)
    {
        var user = await _context.Users.FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            throw new BadHttpRequestException("Không tìm thấy người dùng.");
        }

        user.IsActive = isActive;
        await _context.SaveChangesAsync();

        return MapAdminUser(user);
    }

    public async Task<AdminUserPasswordResetDto> ResetUserPasswordAsync(int userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            throw new BadHttpRequestException("Không tìm thấy người dùng.");
        }

        var resetToken = Guid.NewGuid().ToString("N");
        var frontendUrl = _configuration["FrontendUrl"] ?? "http://localhost:5173";

        user.PasswordResetToken = resetToken;
        user.PasswordResetTokenExpiry = DateTime.UtcNow.AddMinutes(15);
        await _context.SaveChangesAsync();

        var resetLink = $"{frontendUrl}/reset-password?token={resetToken}";
        var emailSent = false;

        try
        {
            await _emailService.SendPasswordResetEmailAsync(
                user.Email,
                user.FullName ?? user.Email,
                resetLink);
            emailSent = true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send admin reset password email for user {UserId}", userId);
        }

        return new AdminUserPasswordResetDto
        {
            ResetLink = resetLink,
            EmailSent = emailSent
        };
    }

    public async Task DeleteUserAsync(int userId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            throw new BadHttpRequestException("Không tìm thấy người dùng.");
        }

        user.IsActive = false;
        user.RefreshToken = null;
        user.RefreshTokenExpiry = null;

        await _context.SaveChangesAsync();
    }

public async Task<AdminTransportStatsDto> GetTransportStatsAsync()
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1);
        var nextMonthStart = monthStart.AddMonths(1);
        var previousMonthStart = monthStart.AddMonths(-1);

        var schedules = await _context.BusSchedules
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Include(s => s.Seats)
            .ToListAsync();

        var schedulesThisMonth = schedules
            .Where(s => s.DepartureTime.HasValue &&
                        s.DepartureTime.Value >= monthStart &&
                        s.DepartureTime.Value < nextMonthStart)
            .ToList();

        var previousMonthSchedules = schedules
            .Where(s => s.DepartureTime.HasValue &&
                        s.DepartureTime.Value >= previousMonthStart &&
                        s.DepartureTime.Value < monthStart)
            .ToList();

        var displayedSchedules = schedules
            .OrderBy(s => GetTransportStatusOrder(GetTransportStatus(s, now)))
            .ThenBy(s => s.DepartureTime ?? DateTime.MaxValue)
            .Select(s => MapTransportSchedule(s, now))
            .ToList();

        var totalSeatsThisMonth = schedulesThisMonth.Sum(GetTotalSeatCount);
        var occupiedSeatsThisMonth = schedulesThisMonth.Sum(GetOccupiedSeatCount);
        var averageOccupancyRate = totalSeatsThisMonth == 0
            ? 0
            : Math.Round((double)occupiedSeatsThisMonth / totalSeatsThisMonth * 100, 1);

        var currentAffiliateRevenue = schedulesThisMonth.Sum(CalculateAffiliateProfit);
        var previousAffiliateRevenue = previousMonthSchedules.Sum(CalculateAffiliateProfit);
        var affiliateGrowthRate = previousAffiliateRevenue == 0
            ? (currentAffiliateRevenue > 0 ? 100 : 0)
            : Math.Round((double)((currentAffiliateRevenue - previousAffiliateRevenue) / previousAffiliateRevenue * 100), 1);

        return new AdminTransportStatsDto
        {
            TotalSchedules = schedules.Count,
            TotalSchedulesThisMonth = schedulesThisMonth.Count,
            ExpectedRevenueThisMonth = schedulesThisMonth.Sum(s => s.Price.GetValueOrDefault() * GetTotalSeatCount(s)),
            AffiliateRevenueThisMonth = currentAffiliateRevenue,
            AverageOccupancyRate = averageOccupancyRate,
            AffiliateGrowthRate = affiliateGrowthRate,
            ActiveSchedules = schedules.Count(s => GetTransportStatus(s, now) == "running"),
            UpcomingSchedules = schedules.Count(s => GetTransportStatus(s, now) == "upcoming"),
            CompletedSchedules = schedules.Count(s => GetTransportStatus(s, now) == "completed"),
            TotalCompanies = schedules
                .Where(s => !string.IsNullOrWhiteSpace(s.Company?.Name))
                .Select(s => s.CompanyId)
                .Distinct()
                .Count(),
            Schedules = displayedSchedules
        };
    }

    public async Task<AdminBookingStatsDto> GetBookingStatsAsync()
    {
        var today = DateTime.UtcNow;
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var trips = await _context.Trips
            .Include(t => t.User)
            .Include(t => t.Destination)
            .Include(t => t.Payments)
            .Include(t => t.TripItineraries)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        var paidBookings = trips.Count(t => GetBookingPaymentStatus(t) == "paid");
        var pendingBookings = trips.Count(t => GetBookingPaymentStatus(t) == "pending");
        var cancelledBookings = trips.Count(t => GetBookingPaymentStatus(t) == "cancelled");

        var newCustomers = trips
            .Where(t => t.UserId.HasValue)
            .GroupBy(t => t.UserId!.Value)
            .Count(group =>
            {
                var firstBookingAt = group
                    .Where(t => t.CreatedAt.HasValue)
                    .Select(t => t.CreatedAt!.Value)
                    .DefaultIfEmpty(DateTime.MinValue)
                    .Min();

                return firstBookingAt >= monthStart;
            });

        var bookingRows = trips.Select(MapBooking).ToList();

        return new AdminBookingStatsDto
        {
            TotalRevenue = trips
                .Where(t => GetBookingPaymentStatus(t) == "paid")
                .Sum(t => t.TotalAmount.GetValueOrDefault()),
            TotalBookings = trips.Count,
            NewCustomers = newCustomers,
            PaidBookings = paidBookings,
            PendingBookings = pendingBookings,
            CancelledBookings = cancelledBookings,
            Bookings = bookingRows
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

    private static int GetTotalSeatCount(BusSchedule schedule)
    {
        return schedule.TotalSeats ?? schedule.Seats.Count;
    }

    private static int GetOccupiedSeatCount(BusSchedule schedule)
    {
        return schedule.Seats.Count(seat => seat.Status == SeatStatus.Booked || seat.Status == SeatStatus.Locked);
    }

    private static decimal CalculateAffiliateProfit(BusSchedule schedule)
    {
        var ticketPrice = schedule.Price.GetValueOrDefault();
        var totalSeats = GetTotalSeatCount(schedule);
        var commissionRate = (decimal)(schedule.CommissionRate ?? 0d);

        return ticketPrice * totalSeats * commissionRate / 100m;
    }

    private static string GetTransportStatus(BusSchedule schedule, DateTime now)
    {
        if (schedule.DepartureTime.HasValue && schedule.DepartureTime.Value <= now)
        {
            if (!schedule.ArrivalTime.HasValue || schedule.ArrivalTime.Value > now)
            {
                return "running";
            }
        }

        if (schedule.ArrivalTime.HasValue && schedule.ArrivalTime.Value <= now)
        {
            return "completed";
        }

        return "upcoming";
    }

    private static int GetTransportStatusOrder(string status)
    {
        return status switch
        {
            "running" => 0,
            "upcoming" => 1,
            _ => 2
        };
    }

    private static string GetBookingPaymentStatus(Trip trip)
    {
        var latestPayment = trip.Payments
            .OrderByDescending(p => p.PaidAt ?? DateTime.MinValue)
            .FirstOrDefault();

        if (latestPayment?.Status is PaymentStatus.Paid)
        {
            return "paid";
        }

        if (latestPayment?.Status is PaymentStatus.Cancelled or PaymentStatus.Failed or PaymentStatus.Refunded)
        {
            return "cancelled";
        }

        if (trip.Status == TripStatus.Paid)
        {
            return "paid";
        }

        if (trip.Status == TripStatus.Cancelled)
        {
            return "cancelled";
        }

        return "pending";
    }

    private static string BuildTripSummary(Trip trip)
    {
        var itineraryCount = trip.TripItineraries.Count;

        if (trip.StartDate.HasValue && trip.EndDate.HasValue)
        {
            var days = Math.Max(1, trip.EndDate.Value.DayNumber - trip.StartDate.Value.DayNumber + 1);
            return itineraryCount > 0
                ? $"{itineraryCount} hoạt động / {days} ngày"
                : $"{days} ngày hành trình";
        }

        if (itineraryCount > 0)
        {
            return $"{itineraryCount} hoạt động đã lên kế hoạch";
        }

        return "Đang chờ hoàn thiện lịch trình";
    }

    private static string MapPaymentStatus(PaymentStatus? status)
    {
        return status switch
        {
            PaymentStatus.Paid => "đã thanh toán",
            PaymentStatus.Cancelled => "đã hủy",
            PaymentStatus.Failed => "thất bại",
            PaymentStatus.Refunded => "đã hoàn tiền",
            _ => "đang chờ xử lý"
        };
    }

    private static string MapTripStatus(TripStatus? status)
    {
        return status switch
        {
            TripStatus.Paid => "paid",
            TripStatus.Cancelled => "cancelled",
            _ => "pending"
        };
    }

    private static AdminUserDto MapAdminUser(SmartTrip.Domain.Entities.User user)
    {
        var bgColors = new[] { "bg-primary-container/20", "bg-secondary-container/20", "bg-tertiary-container/20", "bg-surface-container" };
        var avatarBg = bgColors[user.Id % bgColors.Length];

        return new AdminUserDto
        {
            Id = user.Id,
            DisplayId = $"SKY-{user.Id:D4}",
            Name = string.IsNullOrWhiteSpace(user.FullName) ? "Chưa có tên" : user.FullName,
            Email = user.Email ?? "No Email",
            Phone = user.Phone ?? "No Phone",
            JoinDate = user.CreatedAt.GetValueOrDefault().ToString("dd/MM/yyyy"),
            LastLoginAt = user.LastLoginAt?.ToLocalTime().ToString("dd/MM/yyyy HH:mm") ?? "Chưa đăng nhập",
            Role = MapUserRole(user.Role),
            Status = user.IsActive == true ? "active" : "blocked",
            AvatarBg = avatarBg
        };
    }
}
