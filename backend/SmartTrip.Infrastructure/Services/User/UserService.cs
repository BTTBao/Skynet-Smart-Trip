using SmartTrip.Application.DTOs.User;
using SmartTrip.Application.Interfaces.User;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.Notifications;

namespace SmartTrip.Infrastructure.Services.User;

public class UserService : IUserService
{
    private const string PushNotificationKey = "push_notifications";
    private const string EmailNotificationKey = "email_notifications";
    private const string EmailOfferKey = "email_offers";
    private const string DarkModeKey = "dark_mode";
    private const string LanguageKey = "language";
    private const string CurrencyKey = "currency";

    private readonly ApplicationDbContext _context;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<UserService> _logger;

    public UserService(
        ApplicationDbContext context,
        IEmailService emailService,
        INotificationService notificationService,
        ILogger<UserService> logger)
    {
        _context = context;
        _emailService = emailService;
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task<UserDto?> GetUserProfileAsync(int userId)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null) return null;

        var walletInfo = await _context.UserWallets
            .AsNoTracking()
            .Where(w => w.UserId == userId)
            .Select(w => new { LoyaltyPoints = w.LoyaltyPoints ?? 0, Balance = w.Balance ?? 0m })
            .FirstOrDefaultAsync();

        var loyaltyPoints = walletInfo?.LoyaltyPoints ?? 0;
        var walletBalance = walletInfo?.Balance ?? 0m;

        var tripsCount = await _context.Trips
            .AsNoTracking()
            .CountAsync(t => t.UserId == userId && t.Status != TripStatus.BookingOnly);

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
            WalletBalance = walletBalance,
            Vouchers = vouchersCount,
            BirthDate = user.BirthDate?.ToString("yyyy-MM-dd"),
            IdentityNumber = user.IdentityNumber,
            IdentityCardPhotoUrl = user.IdentityCardPhotoUrl
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

        var reviews = await _context.Reviews
            .AsNoTracking()
            .Where(r => r.UserId == userId)
            .ToListAsync();

        var trips = await _context.Trips
            .AsNoTracking()
            .Include(t => t.Destination)
            .Include(t => t.Invoices)
            .Include(t => t.Payments)
            .Where(t => t.UserId == userId)
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        static string ResolveHistoryTripStatus(Trip t)
        {
            var hasPaidPayment = t.Payments.Any(p => p.Status == PaymentStatus.Paid);
            var hasInvoice = t.Invoices.Any();

            if (t.Status == TripStatus.Cancelled)
            {
                return TripStatus.Cancelled.ToString();
            }

            if (hasPaidPayment || hasInvoice)
            {
                return TripStatus.Paid.ToString();
            }

            return t.Status?.ToString() ?? TripStatus.Draft.ToString();
        }

        static decimal ResolvePaidTripAmount(Trip t)
        {
            return t.Payments
                .Where(p => p.Status == PaymentStatus.Paid)
                .Sum(p => p.Amount ?? 0m);
        }

        var bookings = trips.Select(t => new BookingHistoryItemDto
        {
            TripId = t.Id,
            Title = t.Title ?? "Chuyen di",
            DestinationName = t.Destination?.Name ?? string.Empty,
            StartDate = t.StartDate?.ToString("yyyy-MM-dd"),
            EndDate = t.EndDate?.ToString("yyyy-MM-dd"),
            TotalAmount = ResolvePaidTripAmount(t) > 0 ? ResolvePaidTripAmount(t) : t.TotalAmount ?? 0,
            Status = ResolveHistoryTripStatus(t),
            CreatedAt = t.CreatedAt?.ToString("O"),
            InvoiceNumber = t.Invoices
                .OrderByDescending(i => i.IssuedAt)
                .Select(i => i.InvoiceNumber)
                .FirstOrDefault(),
            IsBookingOnly = t.Status == TripStatus.BookingOnly
        }).ToList();

        var hotelItineraries = await _context.TripItineraries
            .AsNoTracking()
            .Where(i => i.Trip != null && i.Trip.UserId == userId && i.ServiceType == TripServiceType.Hotel)
            .ToListAsync();

        var itineraryCountsByTrip = await _context.TripItineraries
            .AsNoTracking()
            .Where(i => i.Trip != null && i.Trip.UserId == userId)
            .GroupBy(i => i.TripId)
            .Select(group => new { TripId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(item => item.TripId ?? 0, item => item.Count);

        decimal ResolveItineraryHistoryAmount(TripItinerary itinerary, Trip? trip)
        {
            var rawAmount = (itinerary.BookedPrice ?? 0m) * (itinerary.Quantity ?? 1);
            if (trip == null || itineraryCountsByTrip.GetValueOrDefault(trip.Id) != 1)
            {
                return rawAmount;
            }

            var paidAmount = ResolvePaidTripAmount(trip);
            return paidAmount > 0 ? paidAmount : rawAmount;
        }

        var roomIds = hotelItineraries
            .Where(i => i.ServiceId.HasValue)
            .Select(i => i.ServiceId!.Value)
            .Distinct()
            .ToList();

        var roomsById = await _context.Rooms
            .AsNoTracking()
            .Include(r => r.Hotel)
                .ThenInclude(h => h!.Destination)
            .Where(r => roomIds.Contains(r.Id))
            .ToDictionaryAsync(r => r.Id);

        var tripsById = trips.ToDictionary(t => t.Id);

        var hotels = hotelItineraries
            .OrderByDescending(i => tripsById.TryGetValue(i.TripId ?? 0, out var trip) ? trip.CreatedAt : null)
            .Select(i =>
            {
                roomsById.TryGetValue(i.ServiceId ?? 0, out var room);
                tripsById.TryGetValue(i.TripId ?? 0, out var trip);
                var targetHotelId = room?.HotelId ?? 0;
                var isReviewed = reviews.Any(r => 
                    r.TripId == i.TripId && 
                    r.TargetType == ReviewTargetType.Hotel && 
                    r.TargetId == targetHotelId);

                return new HotelHistoryItemDto
                {
                    TripId = i.TripId ?? 0,
                    ItineraryId = i.Id,
                    ServiceId = targetHotelId,
                    TripTitle = trip?.Title ?? "Chuyen di",
                    HotelName = room?.Hotel?.Name ?? "Khach san",
                    RoomType = room?.RoomType ?? string.Empty,
                    Address = room?.Hotel?.Address ?? string.Empty,
                    DestinationName = room?.Hotel?.Destination?.Name ?? string.Empty,
                    CheckInDate = (i.ServiceDate ?? trip?.StartDate)?.ToString("yyyy-MM-dd"),
                    CheckOutDate = (i.HotelCheckOutDate ?? trip?.EndDate)?.ToString("yyyy-MM-dd"),
                    Quantity = i.Quantity ?? 0,
                    BookedPrice = ResolveItineraryHistoryAmount(i, trip),
                    Status = trip != null ? ResolveHistoryTripStatus(trip) : TripStatus.Draft.ToString(),
                    IsReviewed = isReviewed,
                    IsBookingOnly = trip?.Status == TripStatus.BookingOnly,
                    InvoiceNumber = trip?.Invoices
                        .OrderByDescending(invoice => invoice.IssuedAt)
                        .Select(invoice => invoice.InvoiceNumber)
                        .FirstOrDefault()
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
                var targetCompanyId = schedule?.CompanyId ?? 0;
                var isReviewed = reviews.Any(r => 
                    r.TripId == i.TripId && 
                    r.TargetType == ReviewTargetType.BusCompany && 
                    r.TargetId == targetCompanyId);

                return new BusHistoryItemDto
                {
                    TripId = i.TripId ?? 0,
                    ItineraryId = i.Id,
                    ServiceId = schedule?.Id ?? i.ServiceId ?? 0,
                    CompanyId = targetCompanyId,
                    TripTitle = trip?.Title ?? "Chuyen di",
                    CompanyName = schedule?.Company?.Name ?? "Nha xe",
                    FromDestination = schedule?.FromDest?.Name ?? string.Empty,
                    ToDestination = schedule?.ToDest?.Name ?? string.Empty,
                    DepartureTime = schedule?.DepartureTime?.ToString("O"),
                    ArrivalTime = schedule?.ArrivalTime?.ToString("O"),
                    Quantity = i.Quantity ?? 0,
                    BookedPrice = ResolveItineraryHistoryAmount(i, trip),
                    Status = trip != null ? ResolveHistoryTripStatus(trip) : TripStatus.Draft.ToString(),
                    IsReviewed = isReviewed,
                    SelectedSeats = i.SelectedSeats,
                    IsBookingOnly = trip?.Status == TripStatus.BookingOnly,
                    InvoiceNumber = trip?.Invoices
                        .OrderByDescending(invoice => invoice.IssuedAt)
                        .Select(invoice => invoice.InvoiceNumber)
                        .FirstOrDefault()
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
                    InvoicePdfUrl = latestInvoice?.PdfUrl,
                    IsBookingOnly = p.Trip?.Status == TripStatus.BookingOnly
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

        var identityNumber = string.IsNullOrWhiteSpace(request.IdentityNumber)
            ? null
            : request.IdentityNumber.Trim();
        if (!string.IsNullOrWhiteSpace(identityNumber))
        {
            var identityExists = await _context.Users
                .AsNoTracking()
                .AnyAsync(item => item.Id != userId && item.IdentityNumber == identityNumber);
            if (identityExists)
            {
                throw new ArgumentException("So CCCD/CMND nay da duoc su dung boi tai khoan khac.");
            }
        }

        user.FullName = request.Name.Trim();
        user.Phone = string.IsNullOrWhiteSpace(request.Phone) ? null : request.Phone.Trim();
        user.BirthDate = ParseBirthDate(request.BirthDate);
        user.IdentityNumber = identityNumber;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<string?> UpdateAvatarUrlAsync(int userId, string imageUrl)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        var avatarUrl = NormalizeImageUrl(imageUrl);
        user.AvatarUrl = avatarUrl;
        await _context.SaveChangesAsync();

        return avatarUrl;
    }

    public async Task<string?> UpdateIdentityCardPhotoUrlAsync(int userId, string imageUrl)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return null;

        var identityCardPhotoUrl = NormalizeImageUrl(imageUrl);
        user.IdentityCardPhotoUrl = identityCardPhotoUrl;
        await _context.SaveChangesAsync();

        return identityCardPhotoUrl;
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
        await UpsertPreferenceAsync(userId, EmailNotificationKey, request.EmailNotificationEnabled.ToString().ToLowerInvariant());
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

        await _notificationService.CreateAsync(new CreateNotificationDto
        {
            UserId = userId,
            Title = "Mật khẩu đã được thay đổi",
            Message = "Mật khẩu tài khoản SmartTrip của bạn đã được cập nhật thành công.",
            Type = "account.password_changed",
            ReferenceType = "account",
            ReferenceId = userId,
            ActionUrl = "/profile/security"
        });

        await SendPasswordChangedEmailAsync(user);

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

    private static string NormalizeImageUrl(string imageUrl)
    {
        var normalized = imageUrl.Trim();
        if (!Uri.TryCreate(normalized, UriKind.Absolute, out var uri) ||
            (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps))
        {
            throw new ArgumentException("Duong dan anh khong hop le.");
        }

        return normalized;
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
            EmailNotificationEnabled = GetBoolPreference(preferences, EmailNotificationKey, true),
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

    private async Task SendPasswordChangedEmailAsync(SmartTrip.Domain.Entities.User user)
    {
        try
        {
            if (!await _notificationService.AreEmailNotificationsEnabledAsync(user.Id))
            {
                return;
            }

            await _emailService.SendPasswordChangedEmailAsync(
                user.Email,
                user.FullName ?? user.Email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send password changed email for user {UserId}", user.Id);
        }
    }

    private static string GetMemberTier(int loyaltyPoints)
    {
        if (loyaltyPoints >= 1000) return "Platinum Member";
        if (loyaltyPoints >= 500) return "Gold Member";
        if (loyaltyPoints >= 100) return "Silver Member";
        return "Member";
    }
}

