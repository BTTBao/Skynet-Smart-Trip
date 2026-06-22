using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Catalog;
using SmartTrip.Application.Interfaces;
using SmartTrip.Application.Interfaces.Catalog;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Application.Services.Catalog;

public class CatalogService : ICatalogService
{
    private readonly IApplicationDbContext _context;

    public CatalogService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<CatalogHomeDto> GetHomeAsync()
    {
        var destinationBookingCounts = await _context.Trips
            .AsNoTracking()
            .Where(trip => trip.DestinationId.HasValue &&
                           (trip.Status == TripStatus.Paid || trip.Status == TripStatus.BookingOnly))
            .GroupBy(trip => trip.DestinationId!.Value)
            .Select(group => new { DestinationId = group.Key, BookingCount = group.Count() })
            .ToDictionaryAsync(item => item.DestinationId, item => item.BookingCount);

        var destinations = (await _context.Destinations
            .AsNoTracking()
            .ToListAsync())
            .OrderByDescending(destination => destinationBookingCounts.GetValueOrDefault(destination.Id))
            .ThenByDescending(destination => destination.IsHot)
            .ThenBy(destination => destination.Name)
            .Take(6)
            .ToList();

        var hotels = await _context.Hotels
            .AsNoTracking()
            .Include(hotel => hotel.Destination)
            .Include(hotel => hotel.Rooms)
            .Include(hotel => hotel.Amenities)
            .Where(hotel => hotel.IsAvailable != false)
            .Take(12)
            .ToListAsync();

        var hotelIds = hotels.Select(hotel => hotel.Id).ToList();
        var hotelReviews = await _context.Reviews
            .AsNoTracking()
            .Where(review => review.TargetType == ReviewTargetType.Hotel && review.TargetId.HasValue && hotelIds.Contains(review.TargetId.Value))
            .Include(review => review.User)
            .ToListAsync();
        var hotelGalleries = await GetGalleryLookupAsync(GalleryReferenceType.Hotel, hotelIds);

        var busSchedulesQuery = _context.BusSchedules
            .AsNoTracking()
            .Include(schedule => schedule.Company)
            .Include(schedule => schedule.FromDest)
            .Include(schedule => schedule.ToDest);

        var now = DateTime.UtcNow;
        var busSchedules = await busSchedulesQuery
            .Where(schedule => !schedule.DepartureTime.HasValue || schedule.DepartureTime >= now)
            .OrderBy(schedule => schedule.DepartureTime)
            .Take(8)
            .ToListAsync();
        if (busSchedules.Count == 0)
        {
            busSchedules = await busSchedulesQuery
                .OrderByDescending(schedule => schedule.DepartureTime)
                .Take(8)
                .ToListAsync();
        }

        var busCompanyIds = busSchedules.Where(schedule => schedule.CompanyId.HasValue).Select(schedule => schedule.CompanyId!.Value).Distinct().ToList();
        var busReviews = await _context.Reviews
            .AsNoTracking()
            .Where(review => review.TargetType == ReviewTargetType.BusCompany && review.TargetId.HasValue && busCompanyIds.Contains(review.TargetId.Value))
            .Include(review => review.User)
            .ToListAsync();

        var mappedHotels = hotels
            .Select(hotel => MapHotelCard(hotel, hotelReviews.Where(review => review.TargetId == hotel.Id).ToList(), hotelGalleries))
            .OrderByDescending(hotel => hotel.Rating)
            .ThenBy(hotel => hotel.PricePerNight)
            .ToList();

        return new CatalogHomeDto
        {
            PopularDestinations = destinations.Select(destination => new CatalogDestinationDto
            {
                Id = destination.Id,
                Name = destination.Name,
                Description = destination.Description ?? string.Empty,
                CoverImageUrl = destination.CoverImageUrl ?? string.Empty,
                IsHot = destination.IsHot ?? false
            }).ToList(),
            FeaturedHotels = mappedHotels.Take(6).ToList(),
            RecommendedHotels = mappedHotels.OrderBy(hotel => hotel.PricePerNight).Take(4).ToList(),
            FeaturedBuses = busSchedules
                .Select(schedule => MapBusCard(schedule, busReviews.Where(review => review.TargetId == schedule.CompanyId).ToList()))
                .OrderByDescending(bus => bus.Rating)
                .ThenByDescending(bus => bus.ReviewCount)
                .ThenBy(bus => bus.DepartureTime)
                .Take(6)
                .ToList()
        };
    }

    public async Task<CatalogHotelSearchResultDto> SearchHotelsAsync(
        string? query,
        int? destinationId,
        decimal? minPrice,
        decimal? maxPrice,
        double? minRating,
        string? starRatings,
        string? sort)
    {
        var hotels = await _context.Hotels
            .AsNoTracking()
            .Include(hotel => hotel.Destination)
            .Include(hotel => hotel.Rooms)
            .Include(hotel => hotel.Amenities)
            .Where(hotel => hotel.IsAvailable != false)
            .ToListAsync();

        var hotelIds = hotels.Select(hotel => hotel.Id).ToList();
        var reviews = await _context.Reviews
            .AsNoTracking()
            .Where(review => review.TargetType == ReviewTargetType.Hotel && review.TargetId.HasValue && hotelIds.Contains(review.TargetId.Value))
            .Include(review => review.User)
            .ToListAsync();
        var galleries = await GetGalleryLookupAsync(GalleryReferenceType.Hotel, hotelIds);

        var allowedStarRatings = ParseIntList(starRatings);

        var mapped = hotels
            .Select(hotel => MapHotelCard(hotel, reviews.Where(review => review.TargetId == hotel.Id).ToList(), galleries))
            .Where(hotel =>
                string.IsNullOrWhiteSpace(query) ||
                hotel.Name.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                hotel.DestinationName.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                hotel.Address.Contains(query, StringComparison.OrdinalIgnoreCase))
            .Where(hotel => !destinationId.HasValue || hotel.DestinationId == destinationId.Value)
            .Where(hotel => !minPrice.HasValue || hotel.PricePerNight >= minPrice.Value)
            .Where(hotel => !maxPrice.HasValue || hotel.PricePerNight <= maxPrice.Value)
            .Where(hotel => !minRating.HasValue || hotel.Rating >= minRating.Value)
            .Where(hotel => allowedStarRatings.Count == 0 || allowedStarRatings.Contains(hotel.StarRating))
            .ToList();

        mapped = NormalizeHotelSort(sort) switch
        {
            "priceasc" => mapped.OrderBy(hotel => hotel.PricePerNight).ToList(),
            "pricedesc" => mapped.OrderByDescending(hotel => hotel.PricePerNight).ToList(),
            "ratingdesc" => mapped.OrderByDescending(hotel => hotel.Rating).ThenByDescending(hotel => hotel.ReviewCount).ToList(),
            _ => mapped.OrderByDescending(hotel => hotel.ReviewCount).ThenByDescending(hotel => hotel.Rating).ThenBy(hotel => hotel.PricePerNight).ToList()
        };

        return new CatalogHotelSearchResultDto
        {
            Total = mapped.Count,
            Items = mapped
        };
    }

    public async Task<CatalogHotelDetailDto?> GetHotelDetailAsync(int hotelId)
    {
        var hotel = await _context.Hotels
            .AsNoTracking()
            .Include(item => item.Destination)
            .Include(item => item.Rooms)
            .Include(item => item.Amenities)
            .FirstOrDefaultAsync(item => item.Id == hotelId && item.IsAvailable != false);

        if (hotel is null)
        {
            return null;
        }

        var reviews = await _context.Reviews
            .AsNoTracking()
            .Where(review => review.TargetType == ReviewTargetType.Hotel && review.TargetId == hotelId)
            .Include(review => review.User)
            .OrderByDescending(review => review.CreatedAt)
            .ToListAsync();
        var galleries = await GetGalleryLookupAsync(GalleryReferenceType.Hotel, [hotelId]);
        var roomIds = hotel.Rooms.Select(room => room.Id).ToList();
        var roomGalleries = await GetGalleryLookupAsync(GalleryReferenceType.Room, roomIds);
        var card = MapHotelCard(hotel, reviews, galleries);

        return new CatalogHotelDetailDto
        {
            Id = hotel.Id,
            DestinationId = hotel.DestinationId ?? 0,
            Name = hotel.Name,
            DestinationName = hotel.Destination?.Name ?? string.Empty,
            Address = hotel.Address ?? string.Empty,
            Description = hotel.Description ?? string.Empty,
            StarRating = hotel.StarRating ?? 0,
            PricePerNight = card.PricePerNight,
            Rating = card.Rating,
            ReviewCount = card.ReviewCount,
            IsAvailable = hotel.IsAvailable ?? false,
            Latitude = BuildLatitude(hotel.Id),
            Longitude = BuildLongitude(hotel.Id),
            ImageUrls = galleries.TryGetValue(hotelId, out var images) && images.Count > 0
                ? images
                : [card.ImageUrl],
            Amenities = hotel.Amenities.Select(amenity => amenity.Name ?? string.Empty).Where(name => !string.IsNullOrWhiteSpace(name)).ToList(),
            Rooms = hotel.Rooms
                .OrderBy(room => room.PricePerNight)
                .Select(room => new CatalogRoomOptionDto
                {
                    Id = room.Id,
                    RoomType = room.RoomType ?? "Standard",
                    Capacity = room.Capacity ?? 2,
                    PricePerNight = room.PricePerNight ?? 0,
                    AvailableQty = room.AvailableQty ?? 0,
                    ImageUrls = roomGalleries.TryGetValue(room.Id, out var roomImages) ? roomImages : []
                })
                .ToList(),
            Reviews = reviews.Select(MapReview).ToList()
        };
    }

    public async Task<CatalogRoomAvailabilityDto> GetRoomAvailabilityAsync(
        int roomId,
        DateOnly checkInDate,
        DateOnly checkOutDate,
        int quantity)
    {
        if (roomId <= 0)
        {
            throw new ArgumentException("RoomId phai lon hon 0.");
        }

        if (checkOutDate <= checkInDate)
        {
            checkOutDate = checkInDate.AddDays(1);
        }

        if (quantity <= 0)
        {
            throw new ArgumentException("So luong phong phai lon hon 0.");
        }

        var room = await _context.Rooms
            .AsNoTracking()
            .Include(item => item.Hotel)
            .FirstOrDefaultAsync(item => item.Id == roomId);

        if (room?.Hotel == null || room.Hotel.IsAvailable == false)
        {
            return new CatalogRoomAvailabilityDto
            {
                RoomId = roomId,
                TotalQty = 0,
                RemainingQty = 0,
                IsAvailable = false,
                Message = "Phong nay hien khong con kha dung."
            };
        }

        var totalQty = Math.Max(room.AvailableQty ?? 0, 0);
        if (totalQty == 0)
        {
            return new CatalogRoomAvailabilityDto
            {
                RoomId = roomId,
                TotalQty = 0,
                RemainingQty = 0,
                IsAvailable = false,
                Message = "Loai phong nay hien da het phong."
            };
        }

        var bookings = await _context.TripItineraries
            .AsNoTracking()
            .Include(item => item.Trip)
            .Where(item =>
                item.ServiceType == TripServiceType.Hotel &&
                item.ServiceId == roomId &&
                item.Trip != null &&
                item.Trip.Status != TripStatus.Cancelled &&
                item.Trip.StartDate.HasValue &&
                item.Trip.EndDate.HasValue)
            .ToListAsync();

        var bookedQty = GetPeakBookedQtyForDateRange(
            checkInDate,
            checkOutDate,
            bookings.Select(item => (
                StartDate: item.ServiceDate ?? item.Trip!.StartDate!.Value,
                EndDate: ResolveHotelBookingEndDate(
                    item.ServiceDate ?? item.Trip!.StartDate!.Value,
                    item.HotelCheckOutDate ?? item.Trip!.EndDate!.Value),
                Quantity: item.Quantity ?? 1)));

        var remainingQty = Math.Max(totalQty - bookedQty, 0);

        return new CatalogRoomAvailabilityDto
        {
            RoomId = roomId,
            TotalQty = totalQty,
            RemainingQty = remainingQty,
            IsAvailable = quantity <= remainingQty,
            Message = remainingQty switch
            {
                <= 0 => "Da het phong trong khoang ngay nay.",
                _ when quantity > remainingQty => $"Chi con {remainingQty} phong trong khoang ngay ban chon.",
                _ => $"Con {remainingQty} phong co the dat."
            }
        };
    }

    public async Task<CatalogBusSearchResultDto> SearchBusesAsync(
        string? query,
        int? fromDestinationId,
        int? toDestinationId,
        decimal? minPrice,
        decimal? maxPrice,
        string? sort)
    {
        var schedules = await _context.BusSchedules
            .AsNoTracking()
            .Include(schedule => schedule.Company)
            .Include(schedule => schedule.FromDest)
            .Include(schedule => schedule.ToDest)
            .ToListAsync();

        var companyIds = schedules.Where(schedule => schedule.CompanyId.HasValue).Select(schedule => schedule.CompanyId!.Value).Distinct().ToList();
        var reviews = await _context.Reviews
            .AsNoTracking()
            .Where(review => review.TargetType == ReviewTargetType.BusCompany && review.TargetId.HasValue && companyIds.Contains(review.TargetId.Value))
            .Include(review => review.User)
            .ToListAsync();

        var filteredSchedules = schedules
            .Where(schedule =>
                string.IsNullOrWhiteSpace(query) ||
                (schedule.Company?.Name?.Contains(query, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (schedule.FromDest?.Name?.Contains(query, StringComparison.OrdinalIgnoreCase) ?? false) ||
                (schedule.ToDest?.Name?.Contains(query, StringComparison.OrdinalIgnoreCase) ?? false))
            .Where(schedule => !fromDestinationId.HasValue || schedule.FromDestId == fromDestinationId.Value)
            .Where(schedule => !toDestinationId.HasValue || schedule.ToDestId == toDestinationId.Value)
            .Where(schedule => !minPrice.HasValue || (schedule.Price ?? 0) >= minPrice.Value)
            .Where(schedule => !maxPrice.HasValue || (schedule.Price ?? 0) <= maxPrice.Value)
            .ToList();

        var mapped = filteredSchedules
            .Select(schedule => MapBusCard(schedule, reviews.Where(review => review.TargetId == schedule.CompanyId).ToList()))
            .ToList();

        mapped = NormalizeBusSort(sort) switch
        {
            "priceasc" => mapped.OrderBy(item => item.Price).ToList(),
            "pricedesc" => mapped.OrderByDescending(item => item.Price).ToList(),
            _ => mapped.OrderBy(item => item.DepartureTime).ToList()
        };

        return new CatalogBusSearchResultDto
        {
            Total = mapped.Count,
            Items = mapped
        };
    }

    public async Task<CatalogBusDetailDto?> GetBusDetailAsync(int scheduleId)
    {
        var schedule = await _context.BusSchedules
            .AsNoTracking()
            .Include(item => item.Company)
            .Include(item => item.FromDest)
            .Include(item => item.ToDest)
            .FirstOrDefaultAsync(item => item.Id == scheduleId);

        if (schedule is null)
        {
            return null;
        }

        var reviews = schedule.CompanyId.HasValue
            ? await _context.Reviews
                .AsNoTracking()
                .Where(review => review.TargetType == ReviewTargetType.BusCompany && review.TargetId == schedule.CompanyId.Value)
                .Include(review => review.User)
                .OrderByDescending(review => review.CreatedAt)
                .ToListAsync()
            : new List<Review>();

        var card = MapBusCard(schedule, reviews);
        return new CatalogBusDetailDto
        {
            Id = schedule.Id,
            CompanyId = schedule.CompanyId,
            CompanyName = schedule.Company?.Name ?? "Xe khach",
            Hotline = schedule.Company?.Hotline ?? string.Empty,
            FromDestination = schedule.FromDest?.Name ?? string.Empty,
            ToDestination = schedule.ToDest?.Name ?? string.Empty,
            DepartureTime = schedule.DepartureTime,
            ArrivalTime = schedule.ArrivalTime,
            Price = schedule.Price ?? 0,
            TotalSeats = schedule.TotalSeats ?? 0,
            Rating = card.Rating,
            ReviewCount = card.ReviewCount,
            ImageUrl = card.ImageUrl,
            Reviews = reviews.Select(MapReview).ToList()
        };
    }

    private async Task<Dictionary<int, List<string>>> GetGalleryLookupAsync(GalleryReferenceType referenceType, List<int> referenceIds)
    {
        if (referenceIds.Count == 0)
        {
            return new Dictionary<int, List<string>>();
        }

        return await _context.Galleries
            .AsNoTracking()
            .Where(gallery => gallery.ReferenceType == referenceType && gallery.ReferenceId.HasValue && referenceIds.Contains(gallery.ReferenceId.Value))
            .GroupBy(gallery => gallery.ReferenceId!.Value)
            .ToDictionaryAsync(
                group => group.Key,
                group => group.Select(gallery => gallery.ImageUrl ?? string.Empty).Where(url => !string.IsNullOrWhiteSpace(url)).ToList());
    }

    private static CatalogHotelCardDto MapHotelCard(
        Hotel hotel,
        List<Review> reviews,
        Dictionary<int, List<string>> galleries)
    {
        var price = hotel.Rooms
            .Where(room => room.PricePerNight.HasValue)
            .OrderBy(room => room.PricePerNight)
            .Select(room => room.PricePerNight!.Value)
            .FirstOrDefault();

        var ratingValues = reviews.Where(review => review.Rating.HasValue).Select(review => review.Rating!.Value).ToList();
        var rating = ratingValues.Count == 0 ? 4.6 : Math.Round(ratingValues.Average(), 1);
        var reviewCount = ratingValues.Count == 0 ? 12 : ratingValues.Count;
        var firstImage = galleries.TryGetValue(hotel.Id, out var imageUrls) && imageUrls.Count > 0
            ? imageUrls[0]
            : hotel.Destination?.CoverImageUrl ?? string.Empty;

        return new CatalogHotelCardDto
        {
            Id = hotel.Id,
            DestinationId = hotel.DestinationId ?? 0,
            Name = hotel.Name,
            DestinationName = hotel.Destination?.Name ?? string.Empty,
            Address = hotel.Address ?? string.Empty,
            Description = hotel.Description ?? string.Empty,
            StarRating = hotel.StarRating ?? 0,
            PricePerNight = price,
            Rating = rating,
            ReviewCount = reviewCount,
            ImageUrl = firstImage,
            IsAvailable = hotel.IsAvailable ?? false,
            Tag = (hotel.StarRating ?? 0) >= 5 ? "Cao cap" : price < 1000000 ? "Gia tot" : null
        };
    }

    private static CatalogBusCardDto MapBusCard(BusSchedule schedule, List<Review> reviews)
    {
        var ratingValues = reviews.Where(review => review.Rating.HasValue).Select(review => review.Rating!.Value).ToList();
        var rating = ratingValues.Count == 0 ? 4.5 : Math.Round(ratingValues.Average(), 1);
        var reviewCount = ratingValues.Count == 0 ? 8 : ratingValues.Count;

        return new CatalogBusCardDto
        {
            Id = schedule.Id,
            CompanyId = schedule.CompanyId,
            CompanyName = schedule.Company?.Name ?? "Xe khach",
            FromDestination = schedule.FromDest?.Name ?? string.Empty,
            ToDestination = schedule.ToDest?.Name ?? string.Empty,
            DepartureTime = schedule.DepartureTime,
            ArrivalTime = schedule.ArrivalTime,
            Price = schedule.Price ?? 0,
            TotalSeats = schedule.TotalSeats ?? 0,
            Rating = rating,
            ReviewCount = reviewCount,
            ImageUrl = schedule.Company?.LogoUrl ?? string.Empty
        };
    }

    private static CatalogReviewDto MapReview(Review review)
    {
        return new CatalogReviewDto
        {
            UserName = review.User?.FullName ?? "Khach hang",
            Rating = review.Rating ?? 5,
            Comment = review.Comment ?? string.Empty,
            CreatedAt = review.CreatedAt
        };
    }

    private static List<int> ParseIntList(string? source)
    {
        if (string.IsNullOrWhiteSpace(source))
        {
            return [];
        }

        return source
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(value => int.TryParse(value, out var parsed) ? parsed : 0)
            .Where(value => value > 0)
            .Distinct()
            .ToList();
    }

    private static string NormalizeHotelSort(string? sort)
    {
        return sort?.Trim().ToLowerInvariant() ?? "popular";
    }

    private static string NormalizeBusSort(string? sort)
    {
        return sort?.Trim().ToLowerInvariant() ?? "earliest";
    }

    private static int GetPeakBookedQtyForDateRange(
        DateOnly checkInDate,
        DateOnly checkOutDate,
        IEnumerable<(DateOnly StartDate, DateOnly EndDate, int Quantity)> bookings)
    {
        var peakBookedQty = 0;

        for (var date = checkInDate; date < checkOutDate; date = date.AddDays(1))
        {
            var bookedQtyForDate = bookings
                .Where(item => item.StartDate <= date && item.EndDate > date)
                .Sum(item => item.Quantity <= 0 ? 0 : item.Quantity);

            if (bookedQtyForDate > peakBookedQty)
            {
                peakBookedQty = bookedQtyForDate;
            }
        }

        return peakBookedQty;
    }

    private static DateOnly ResolveHotelBookingEndDate(
        DateOnly checkInDate,
        DateOnly fallbackCheckOutDate)
    {
        return fallbackCheckOutDate > checkInDate ? fallbackCheckOutDate : checkInDate.AddDays(1);
    }

    private static double BuildLatitude(int id) => 11.9404 + (id * 0.0035);

    private static double BuildLongitude(int id) => 108.4583 + (id * 0.0041);

    public async Task<CatalogPromotionDto?> ValidatePromotionAsync(string code)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return null;
        }

        var normalizedCode = code.Trim().ToUpperInvariant();
        var promotion = await _context.Promotions
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Code == normalizedCode);

        if (promotion == null)
        {
            return null;
        }

        var now = DateTime.UtcNow;
        if (promotion.ValidUntil.HasValue && promotion.ValidUntil.Value < now)
        {
            return null;
        }

        if (promotion.UsageLimit.HasValue && promotion.UsedCount.HasValue && promotion.UsedCount.Value >= promotion.UsageLimit.Value)
        {
            return null;
        }

        return new CatalogPromotionDto
        {
            Code = promotion.Code ?? string.Empty,
            DiscountPercent = promotion.DiscountPercent ?? 0,
            MaxDiscountAmount = promotion.MaxDiscountAmount ?? 0,
            Title = GetPromotionTitle(promotion),
            Description = GetPromotionDescription(promotion)
        };
    }

    public async Task<List<CatalogPromotionDto>> GetPromotionsAsync()
    {
        var now = DateTime.UtcNow;
        var promotions = await _context.Promotions
            .AsNoTracking()
            .Where(p => (!p.ValidUntil.HasValue || p.ValidUntil.Value >= now) &&
                        (!p.UsageLimit.HasValue || !p.UsedCount.HasValue || p.UsedCount.Value < p.UsageLimit.Value))
            .ToListAsync();

        return promotions.Select(p => new CatalogPromotionDto
        {
            Code = p.Code ?? string.Empty,
            DiscountPercent = p.DiscountPercent ?? 0,
            MaxDiscountAmount = p.MaxDiscountAmount ?? 0,
            Title = GetPromotionTitle(p),
            Description = GetPromotionDescription(p)
        }).ToList();
    }

    private static string GetPromotionTitle(Promotion p)
    {
        if (p.Code == "WELCOME10") return "Mừng Bạn Mới";
        if (p.Code == "SUMMER20") return "Chào Hè Rực Rỡ";
        if (p.Code == "HOTEL5") return "Ưu Đãi Đặt Phòng";
        
        return p.DiscountPercent.HasValue && p.DiscountPercent > 0 
            ? $"Giảm Giá {p.DiscountPercent.Value}%" 
            : "Khuyến Mãi Đặc Biệt";
    }

    private static string GetPromotionDescription(Promotion p)
    {
        if (p.Code == "WELCOME10") return "Giảm ngay 10% cho khách hàng mới đăng ký trải nghiệm.";
        if (p.Code == "SUMMER20") return "Giảm 20% đặt khách sạn và vé xe, tối đa 250k.";
        if (p.Code == "HOTEL5") return "Giảm 5% cho tất cả phòng khách sạn trong tháng này.";
        
        var maxDesc = p.MaxDiscountAmount.HasValue && p.MaxDiscountAmount.Value > 0 
            ? $" tối đa {p.MaxDiscountAmount.Value:N0}đ" 
            : "";
        return $"Áp dụng giảm {p.DiscountPercent ?? 0}%{maxDesc} cho đơn hàng.";
    }
}
