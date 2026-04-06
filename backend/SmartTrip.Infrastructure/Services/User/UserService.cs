using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System.Globalization;

namespace SmartTrip.Infrastructure.Services.User;

public class UserService : IUserService
{
    private const string PushNotificationKey = "push_notifications";
    private const string EmailOfferKey = "email_offers";
    private const string DarkModeKey = "dark_mode";
    private const string LanguageKey = "language";
    private const string CurrencyKey = "currency";

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
            IsEmailVerified = user.IsEmailVerified,
            MemberTier = GetMemberTier(loyaltyPoints),
            TripsCount = tripsCount,
            Coins = loyaltyPoints,
            Vouchers = vouchersCount,
            BirthDate = user.BirthDate?.ToString("yyyy-MM-dd")
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

    public async Task<bool> UpdateUserProfileAsync(int userId, UpdateUserProfileRequestDto request)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return false;

        user.FullName = request.Name.Trim();
        user.Phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();
        user.BirthDate = ParseBirthDate(request.BirthDate);

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

        string fileName = $"avatar_{userId}_{DateTime.UtcNow.Ticks}{Path.GetExtension(file.FileName)}";
        string filePath = Path.Combine(wwwRootPath, "uploads", "avatars", fileName);

        // Đảm bảo thư mục tồn tại
        Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);
        DeletePreviousAvatarIfOwnedByApp(user.AvatarUrl, wwwRootPath);

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

    public async Task<List<UserFavoriteDto>> GetFavoritesAsync(int userId)
    {
        var favorites = await _context.Wishlists
            .AsNoTracking()
            .Where(w => w.UserId == userId)
            .OrderByDescending(w => w.CreatedAt)
            .ToListAsync();

        return await MapFavoritesAsync(favorites);
    }

    public async Task<UserFavoriteDto?> AddFavoriteAsync(int userId, CreateFavoriteRequestDto request)
    {
        if (!TryParseWishlistType(request.ItemType, out var itemType))
        {
            return null;
        }

        if (!await FavoriteItemExistsAsync(itemType, request.ItemId))
        {
            return null;
        }

        var existing = await _context.Wishlists
            .AsNoTracking()
            .FirstOrDefaultAsync(w =>
                w.UserId == userId &&
                w.ItemType == itemType &&
                w.ItemId == request.ItemId);

        if (existing != null)
        {
            return (await MapFavoritesAsync(new List<Wishlist> { existing })).FirstOrDefault();
        }

        var favorite = new Wishlist
        {
            UserId = userId,
            ItemType = itemType,
            ItemId = request.ItemId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Wishlists.Add(favorite);
        await _context.SaveChangesAsync();

        return (await MapFavoritesAsync(new List<Wishlist> { favorite })).FirstOrDefault();
    }

    public async Task<bool> RemoveFavoriteAsync(int userId, int wishId)
    {
        var favorite = await _context.Wishlists
            .FirstOrDefaultAsync(w => w.UserId == userId && w.WishId == wishId);

        if (favorite == null)
        {
            return false;
        }

        _context.Wishlists.Remove(favorite);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<UserSettingsDto?> GetUserSettingsAsync(int userId)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            return null;
        }

        var preferences = await _context.UserPreferences
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .ToDictionaryAsync(p => p.PreferenceKey, p => p.PreferenceValue);

        return BuildSettingsDto(user, preferences);
    }

    public async Task<UserSettingsDto?> UpdateUserSettingsAsync(int userId, UpdateUserSettingsDto request)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
        {
            return null;
        }

        await UpsertPreferenceAsync(userId, PushNotificationKey, request.PushNotificationEnabled.ToString().ToLowerInvariant());
        await UpsertPreferenceAsync(userId, EmailOfferKey, request.EmailOfferEnabled.ToString().ToLowerInvariant());
        await UpsertPreferenceAsync(userId, DarkModeKey, request.DarkModeEnabled.ToString().ToLowerInvariant());
        await UpsertPreferenceAsync(userId, LanguageKey, request.Language.Trim().ToLowerInvariant());
        await UpsertPreferenceAsync(userId, CurrencyKey, request.Currency.Trim().ToUpperInvariant());

        await _context.SaveChangesAsync();

        var preferences = await _context.UserPreferences
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .ToDictionaryAsync(p => p.PreferenceKey, p => p.PreferenceValue);

        return BuildSettingsDto(user, preferences);
    }

    public async Task<UserActionResultDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
        {
            return new UserActionResultDto { Success = false, Message = "Nguoi dung khong ton tai" };
        }

        if (string.IsNullOrWhiteSpace(request.CurrentPassword) ||
            string.IsNullOrWhiteSpace(request.NewPassword) ||
            string.IsNullOrWhiteSpace(request.ConfirmNewPassword))
        {
            return new UserActionResultDto { Success = false, Message = "Vui long nhap day du thong tin" };
        }

        if (user.AuthProvider != AuthProvider.Local || string.IsNullOrWhiteSpace(user.PasswordHash))
        {
            return new UserActionResultDto { Success = false, Message = "Tai khoan nay khong ho tro doi mat khau tai day" };
        }

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
        {
            return new UserActionResultDto { Success = false, Message = "Mat khau hien tai khong chinh xac" };
        }

        if (request.NewPassword.Length < 8)
        {
            return new UserActionResultDto { Success = false, Message = "Mat khau moi phai co it nhat 8 ky tu" };
        }

        if (request.NewPassword != request.ConfirmNewPassword)
        {
            return new UserActionResultDto { Success = false, Message = "Xac nhan mat khau moi khong khop" };
        }

        if (request.CurrentPassword == request.NewPassword)
        {
            return new UserActionResultDto { Success = false, Message = "Mat khau moi phai khac mat khau hien tai" };
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        user.RefreshToken = null;
        user.RefreshTokenExpiry = null;

        await _context.SaveChangesAsync();

        return new UserActionResultDto
        {
            Success = true,
            Message = "Doi mat khau thanh cong. Vui long dang nhap lai."
        };
    }

    private static DateTime? ParseBirthDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        if (DateTime.TryParseExact(
                value.Trim(),
                "yyyy-MM-dd",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var parsed))
        {
            return parsed;
        }

        if (DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
        {
            return parsed.Date;
        }

        throw new InvalidOperationException("Ngay sinh khong hop le");
    }

    private void DeletePreviousAvatarIfOwnedByApp(string? avatarUrl, string wwwRootPath)
    {
        if (string.IsNullOrWhiteSpace(avatarUrl))
        {
            return;
        }

        if (!Uri.TryCreate(avatarUrl, UriKind.Absolute, out var uri))
        {
            return;
        }

        var relativePath = uri.AbsolutePath
            .Replace('/', Path.DirectorySeparatorChar)
            .TrimStart(Path.DirectorySeparatorChar);

        if (!relativePath.StartsWith($"uploads{Path.DirectorySeparatorChar}avatars", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var fullPath = Path.Combine(wwwRootPath, relativePath);
        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }
    }

    private async Task<List<UserFavoriteDto>> MapFavoritesAsync(List<Wishlist> favorites)
    {
        var hotelIds = favorites
            .Where(w => w.ItemType == WishlistItemType.Hotel && w.ItemId.HasValue)
            .Select(w => w.ItemId!.Value)
            .Distinct()
            .ToList();

        var busIds = favorites
            .Where(w => w.ItemType == WishlistItemType.Bus && w.ItemId.HasValue)
            .Select(w => w.ItemId!.Value)
            .Distinct()
            .ToList();

        var hotelsById = await _context.Hotels
            .AsNoTracking()
            .Include(h => h.Destination)
            .Include(h => h.Rooms)
            .Where(h => hotelIds.Contains(h.Id))
            .ToDictionaryAsync(h => h.Id);

        var busesById = await _context.BusSchedules
            .AsNoTracking()
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Where(s => busIds.Contains(s.Id))
            .ToDictionaryAsync(s => s.Id);

        return favorites.Select(favorite =>
        {
            if (favorite.ItemType == WishlistItemType.Hotel &&
                favorite.ItemId.HasValue &&
                hotelsById.TryGetValue(favorite.ItemId.Value, out var hotel))
            {
                var lowestPrice = hotel.Rooms
                    .Where(r => r.PricePerNight.HasValue)
                    .OrderBy(r => r.PricePerNight)
                    .Select(r => r.PricePerNight)
                    .FirstOrDefault();

                return new UserFavoriteDto
                {
                    WishId = favorite.WishId,
                    ItemType = WishlistItemType.Hotel.ToString(),
                    ItemId = hotel.Id,
                    Title = hotel.Name ?? "Khach san",
                    Subtitle = hotel.Destination?.Name ?? "Chua cap nhat diem den",
                    Description = hotel.Address,
                    PriceLabel = lowestPrice.HasValue ? $"{lowestPrice.Value:N0} d/dem" : null,
                    StatusLabel = hotel.IsAvailable == true ? "Con phong" : "Tam het phong",
                    CreatedAt = favorite.CreatedAt?.ToString("O")
                };
            }

            if (favorite.ItemType == WishlistItemType.Bus &&
                favorite.ItemId.HasValue &&
                busesById.TryGetValue(favorite.ItemId.Value, out var bus))
            {
                return new UserFavoriteDto
                {
                    WishId = favorite.WishId,
                    ItemType = WishlistItemType.Bus.ToString(),
                    ItemId = bus.Id,
                    Title = bus.Company?.Name ?? "Nha xe",
                    Subtitle = $"{bus.FromDest?.Name ?? "Diem di"} -> {bus.ToDest?.Name ?? "Diem den"}",
                    Description = bus.DepartureTime?.ToString("dd/MM/yyyy HH:mm"),
                    PriceLabel = bus.Price.HasValue ? $"{bus.Price.Value:N0} d/ve" : null,
                    StatusLabel = "Lich trinh yeu thich",
                    CreatedAt = favorite.CreatedAt?.ToString("O")
                };
            }

            return new UserFavoriteDto
            {
                WishId = favorite.WishId,
                ItemType = favorite.ItemType?.ToString() ?? string.Empty,
                ItemId = favorite.ItemId ?? 0,
                Title = "Muc yeu thich",
                Subtitle = "Khong con kha dung",
                CreatedAt = favorite.CreatedAt?.ToString("O")
            };
        }).ToList();
    }

    private async Task<bool> FavoriteItemExistsAsync(WishlistItemType itemType, int itemId)
    {
        return itemType switch
        {
            WishlistItemType.Hotel => await _context.Hotels.AsNoTracking().AnyAsync(h => h.Id == itemId),
            WishlistItemType.Bus => await _context.BusSchedules.AsNoTracking().AnyAsync(s => s.Id == itemId),
            _ => false
        };
    }

    private static bool TryParseWishlistType(string itemType, out WishlistItemType parsed)
    {
        return Enum.TryParse(itemType, true, out parsed);
    }

    private static UserSettingsDto BuildSettingsDto(SmartTrip.Domain.Entities.User user, Dictionary<string, string> preferences)
    {
        return new UserSettingsDto
        {
            Email = user.Email,
            IsEmailVerified = user.IsEmailVerified,
            PushNotificationEnabled = GetBoolPreference(preferences, PushNotificationKey, true),
            EmailOfferEnabled = GetBoolPreference(preferences, EmailOfferKey, false),
            DarkModeEnabled = GetBoolPreference(preferences, DarkModeKey, false),
            Language = GetStringPreference(preferences, LanguageKey, "vi"),
            Currency = GetStringPreference(preferences, CurrencyKey, "VND")
        };
    }

    private static bool GetBoolPreference(Dictionary<string, string> preferences, string key, bool defaultValue)
    {
        return preferences.TryGetValue(key, out var value) && bool.TryParse(value, out var parsed)
            ? parsed
            : defaultValue;
    }

    private static string GetStringPreference(Dictionary<string, string> preferences, string key, string defaultValue)
    {
        return preferences.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value)
            ? value
            : defaultValue;
    }

    private async Task UpsertPreferenceAsync(int userId, string key, string value)
    {
        var existing = await _context.UserPreferences
            .FirstOrDefaultAsync(p => p.UserId == userId && p.PreferenceKey == key);

        if (existing == null)
        {
            _context.UserPreferences.Add(new UserPreference
            {
                UserId = userId,
                PreferenceKey = key,
                PreferenceValue = value,
                UpdatedAt = DateTime.UtcNow
            });
            return;
        }

        existing.PreferenceValue = value;
        existing.UpdatedAt = DateTime.UtcNow;
    }

    private static string GetMemberTier(int loyaltyPoints)
    {
        if (loyaltyPoints >= 1000) return "Platinum Member";
        if (loyaltyPoints >= 500) return "Gold Member";
        if (loyaltyPoints >= 100) return "Silver Member";
        return "Member";
    }
}
