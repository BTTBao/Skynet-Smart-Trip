using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace SmartTrip.Infrastructure.Services.User;

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public UserService(ApplicationDbContext context, IWebHostEnvironment environment, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _environment = environment;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<UserDto?> GetUserProfileAsync(int userId)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return null;

        var loyaltyPoints = await _context.UserWallets
            .AsNoTracking()
            .Where(w => w.UserId == userId)
            .Select(w => w.LoyaltyPoints ?? 0)
            .FirstOrDefaultAsync();

        var tripsCount = await _context.Trips
            .AsNoTracking()
            .CountAsync(t => t.UserId == userId);

        var vouchersCount = await _context.Promotions
            .AsNoTracking()
            .CountAsync(p =>
                (!p.ValidUntil.HasValue || p.ValidUntil >= DateTime.UtcNow) &&
                (!p.UsageLimit.HasValue || (p.UsedCount ?? 0) < p.UsageLimit.Value));

        return new UserDto
        {
            UserId = user.Id,
            Name = user.FullName ?? "",
            Email = user.Email,
            Phone = user.Phone,
            AvatarUrl = user.AvatarUrl,
            MemberTier = GetMemberTier(loyaltyPoints),
            TripsCount = tripsCount,
            Coins = loyaltyPoints,
            Vouchers = vouchersCount
        };
    }

    public async Task<ActivityHistoryDto?> GetActivityHistoryAsync(int userId)
    {
        var userExists = await _context.Users
            .AsNoTracking()
            .AnyAsync(u => u.Id == userId);

        if (!userExists)
        {
            return null;
        }

        var trips = await _context.Trips
            .AsNoTracking()
            .Include(t => t.Destination)
            .Include(t => t.Invoices)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        var bookings = trips.Select(t => new BookingHistoryItemDto
        {
            TripId = t.Id,
            Title = t.Title ?? "Chuyen di",
            DestinationName = t.Destination?.Name ?? string.Empty,
            StartDate = t.StartDate?.ToString("yyyy-MM-dd"),
            EndDate = t.EndDate?.ToString("yyyy-MM-dd"),
            TotalAmount = t.TotalAmount ?? 0,
            Status = t.Status?.ToString() ?? TripStatus.Draft.ToString(),
            CreatedAt = t.CreatedAt?.ToString("O"),
            InvoiceNumber = t.Invoices
                .OrderByDescending(i => i.IssuedAt)
                .Select(i => i.InvoiceNumber)
                .FirstOrDefault()
        }).ToList();

        var hotelItineraries = await _context.TripItineraries
            .AsNoTracking()
            .Where(i => i.Trip != null && i.Trip.UserId == userId && i.ServiceType == TripServiceType.Hotel)
            .ToListAsync();

        var hotelIds = hotelItineraries
            .Where(i => i.ServiceId.HasValue)
            .Select(i => i.ServiceId!.Value)
            .Distinct()
            .ToList();

        var hotelsById = await _context.Hotels
            .AsNoTracking()
            .Include(h => h.Destination)
            .Where(h => hotelIds.Contains(h.Id))
            .ToDictionaryAsync(h => h.Id);

        var tripsById = trips.ToDictionary(t => t.Id);

        var hotels = hotelItineraries
            .OrderByDescending(i => tripsById.TryGetValue(i.TripId ?? 0, out var trip) ? trip.CreatedAt : null)
            .Select(i =>
            {
                hotelsById.TryGetValue(i.ServiceId ?? 0, out var hotel);
                tripsById.TryGetValue(i.TripId ?? 0, out var trip);

                return new HotelHistoryItemDto
                {
                    TripId = i.TripId ?? 0,
                    ItineraryId = i.Id,
                    ServiceId = hotel?.Id ?? i.ServiceId ?? 0,
                    TripTitle = trip?.Title ?? "Chuyen di",
                    HotelName = hotel?.Name ?? "Khach san",
                    Address = hotel?.Address ?? string.Empty,
                    DestinationName = hotel?.Destination?.Name ?? string.Empty,
                    CheckInDate = trip?.StartDate?.ToString("yyyy-MM-dd"),
                    CheckOutDate = trip?.EndDate?.ToString("yyyy-MM-dd"),
                    Quantity = i.Quantity ?? 0,
                    BookedPrice = i.BookedPrice ?? 0,
                    Status = trip?.Status?.ToString() ?? TripStatus.Draft.ToString()
                };
            })
            .ToList();

        var busItineraries = await _context.TripItineraries
            .AsNoTracking()
            .Where(i => i.Trip != null && i.Trip.UserId == userId && i.ServiceType == TripServiceType.Bus)
            .ToListAsync();

        var busIds = busItineraries
            .Where(i => i.ServiceId.HasValue)
            .Select(i => i.ServiceId!.Value)
            .Distinct()
            .ToList();

        var busSchedulesById = await _context.BusSchedules
            .AsNoTracking()
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Where(s => busIds.Contains(s.Id))
            .ToDictionaryAsync(s => s.Id);

        var buses = busItineraries
            .OrderByDescending(i => tripsById.TryGetValue(i.TripId ?? 0, out var trip) ? trip.CreatedAt : null)
            .Select(i =>
            {
                busSchedulesById.TryGetValue(i.ServiceId ?? 0, out var schedule);
                tripsById.TryGetValue(i.TripId ?? 0, out var trip);

                return new BusHistoryItemDto
                {
                    TripId = i.TripId ?? 0,
                    ItineraryId = i.Id,
                    ServiceId = schedule?.Id ?? i.ServiceId ?? 0,
                    TripTitle = trip?.Title ?? "Chuyen di",
                    CompanyName = schedule?.Company?.Name ?? "Nha xe",
                    FromDestination = schedule?.FromDest?.Name ?? string.Empty,
                    ToDestination = schedule?.ToDest?.Name ?? string.Empty,
                    DepartureTime = schedule?.DepartureTime?.ToString("O"),
                    ArrivalTime = schedule?.ArrivalTime?.ToString("O"),
                    Quantity = i.Quantity ?? 0,
                    BookedPrice = i.BookedPrice ?? 0,
                    Status = trip?.Status?.ToString() ?? TripStatus.Draft.ToString()
                };
            })
            .ToList();

        var paymentEntities = await _context.Payments
            .AsNoTracking()
            .Include(p => p.Trip)
                .ThenInclude(t => t!.Invoices)
            .Where(p => p.Trip != null && p.Trip.UserId == userId)
            .OrderByDescending(p => p.PaidAt)
            .ToListAsync();

        var payments = paymentEntities.Select(p =>
            {
                var latestInvoice = p.Trip?.Invoices
                    .OrderByDescending(i => i.IssuedAt)
                    .FirstOrDefault();

                return new PaymentHistoryItemDto
                {
                    PaymentId = p.Id,
                    TripId = p.TripId ?? 0,
                    TripTitle = p.Trip?.Title ?? "Chuyen di",
                    Amount = p.Amount ?? 0,
                    PaymentMethod = p.PaymentMethod?.ToString() ?? string.Empty,
                    Status = p.Status?.ToString() ?? PaymentStatus.Pending.ToString(),
                    PaidAt = p.PaidAt?.ToString("O"),
                    TransactionId = p.TransactionId,
                    InvoiceNumber = latestInvoice?.InvoiceNumber,
                    InvoicePdfUrl = latestInvoice?.PdfUrl
                };
            })
            .ToList();

        return new ActivityHistoryDto
        {
            Bookings = bookings,
            Hotels = hotels,
            Buses = buses,
            Payments = payments
        };
    }

    public async Task<bool> UpdateUserProfileAsync(int userId, UserDto userDto)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        user.FullName = userDto.Name;
        user.Phone = userDto.Phone;
        user.AvatarUrl = userDto.AvatarUrl;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<string?> UploadAvatarAsync(int userId, IFormFile file)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        string wwwRootPath = _environment.WebRootPath;
        if (string.IsNullOrEmpty(wwwRootPath)) 
        {
            wwwRootPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
        }

        string fileName = $"avatar_{userId}_{DateTime.Now.Ticks}{Path.GetExtension(file.FileName)}";
        string filePath = Path.Combine(wwwRootPath, "uploads", "avatars", fileName);

        // Đảm bảo thư mục tồn tại
        Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);

        using (var fileStream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(fileStream);
        }

        // Tạo URL đầy đủ
        var request = _httpContextAccessor.HttpContext?.Request;
        string baseUrl = $"{request?.Scheme}://{request?.Host}{request?.PathBase}";
        string avatarUrl = $"{baseUrl}/uploads/avatars/{fileName}";

        // Cập nhật DB
        user.AvatarUrl = avatarUrl;
        await _context.SaveChangesAsync();

        return avatarUrl;
    }

    private static string GetMemberTier(int loyaltyPoints)
    {
        if (loyaltyPoints >= 1000) return "Platinum Member";
        if (loyaltyPoints >= 500) return "Gold Member";
        if (loyaltyPoints >= 100) return "Silver Member";
        return "Member";
    }
}
