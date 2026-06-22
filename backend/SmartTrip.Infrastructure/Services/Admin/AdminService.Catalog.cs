using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Admin;

public partial class AdminService
{
    public async Task<List<AdminDestinationDto>> GetDestinationsAsync()
    {
        var destinations = await _context.Destinations
            .Include(destination => destination.Hotels)
            .Include(destination => destination.Trips)
            .OrderBy(destination => destination.Name)
            .ToListAsync();

        return destinations.Select(MapDestination).ToList();
    }

    public async Task<AdminDestinationDto> CreateDestinationAsync(AdminDestinationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên điểm đến không được để trống.");
        }

        var destination = new Destination
        {
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            CoverImageUrl = string.IsNullOrWhiteSpace(request.CoverImageUrl) ? null : request.CoverImageUrl.Trim(),
            IsHot = request.IsHot
        };

        _context.Destinations.Add(destination);
        await _context.SaveChangesAsync();

        var created = await _context.Destinations
            .Include(item => item.Hotels)
            .Include(item => item.Trips)
            .FirstAsync(item => item.Id == destination.Id);

        return MapDestination(created);
    }

    public async Task<AdminDestinationDto> UpdateDestinationAsync(int destinationId, AdminDestinationRequest request)
    {
        var destination = await _context.Destinations
            .Include(item => item.Hotels)
            .Include(item => item.Trips)
            .FirstOrDefaultAsync(item => item.Id == destinationId);

        if (destination is null)
        {
            throw new BadHttpRequestException("Không tìm thấy điểm đến.");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên điểm đến không được để trống.");
        }

        destination.Name = request.Name.Trim();
        destination.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        destination.CoverImageUrl = string.IsNullOrWhiteSpace(request.CoverImageUrl) ? null : request.CoverImageUrl.Trim();
        destination.IsHot = request.IsHot;

        await _context.SaveChangesAsync();

        return MapDestination(destination);
    }

    public async Task DeleteDestinationAsync(int destinationId)
    {
        var destination = await _context.Destinations
            .Include(item => item.Hotels)
            .Include(item => item.Trips)
            .Include(item => item.BusScheduleFromDests)
            .Include(item => item.BusScheduleToDests)
            .FirstOrDefaultAsync(item => item.Id == destinationId);

        if (destination is null)
        {
            throw new BadHttpRequestException("Không tìm thấy điểm đến.");
        }

        if (destination.Hotels.Any() || destination.Trips.Any() || destination.BusScheduleFromDests.Any() || destination.BusScheduleToDests.Any())
        {
            throw new BadHttpRequestException("Không thể xóa điểm đến đang được sử dụng bởi khách sạn, chuyến đi hoặc lịch xe.");
        }

        _context.Destinations.Remove(destination);
        await _context.SaveChangesAsync();
    }

    public async Task<List<AdminHotelDto>> GetHotelsAsync()
    {
        var hotels = await _context.Hotels
            .Include(hotel => hotel.Destination)
            .Include(hotel => hotel.Rooms)
            .OrderBy(hotel => hotel.Name)
            .ToListAsync();

        var hotelStatsLookup = await BuildHotelRevenueLookupAsync(hotels.Select(hotel => hotel.Id).ToList());

        return hotels
            .Select(hotel => MapHotel(hotel, hotelStatsLookup.GetValueOrDefault(hotel.Id) ?? AdminHotelBookingStats.Empty))
            .ToList();
    }

    public async Task<AdminHotelDetailDto> GetHotelDetailAsync(int hotelId)
    {
        var hotel = await _context.Hotels
            .Include(item => item.Destination)
            .Include(item => item.Rooms)
            .FirstOrDefaultAsync(item => item.Id == hotelId);

        if (hotel is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khách sạn.");
        }

        var roomIds = hotel.Rooms.Select(room => room.Id).ToList();
        var roomGalleryLookup = await BuildGalleryLookupAsync(GalleryReferenceType.Room, roomIds);
        var hotelStatsLookup = await BuildHotelRevenueLookupAsync([hotelId]);
        return MapHotelDetail(hotel, hotelStatsLookup.GetValueOrDefault(hotelId) ?? AdminHotelBookingStats.Empty, roomGalleryLookup);
    }

    public async Task<AdminHotelDto> CreateHotelAsync(AdminHotelRequest request)
    {
        ValidateHotelRequest(request);

        var destinationExists = await _context.Destinations.AnyAsync(destination => destination.Id == request.DestinationId);
        if (!destinationExists)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        var hotel = new Hotel
        {
            DestinationId = request.DestinationId,
            Name = request.Name.Trim(),
            Address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim(),
            StarRating = request.StarRating,
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            IsAvailable = request.IsAvailable
        };

        _context.Hotels.Add(hotel);
        await _context.SaveChangesAsync();

        var created = await _context.Hotels
            .Include(item => item.Destination)
            .Include(item => item.Rooms)
            .FirstAsync(item => item.Id == hotel.Id);

        return MapHotel(created, AdminHotelBookingStats.Empty);
    }

    public async Task<AdminHotelDto> UpdateHotelAsync(int hotelId, AdminHotelRequest request)
    {
        ValidateHotelRequest(request);

        var hotel = await _context.Hotels
            .Include(item => item.Destination)
            .Include(item => item.Rooms)
            .FirstOrDefaultAsync(item => item.Id == hotelId);

        if (hotel is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khách sạn.");
        }

        var destinationExists = await _context.Destinations.AnyAsync(destination => destination.Id == request.DestinationId);
        if (!destinationExists)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        hotel.DestinationId = request.DestinationId;
        hotel.Name = request.Name.Trim();
        hotel.Address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim();
        hotel.StarRating = request.StarRating;
        hotel.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        hotel.IsAvailable = request.IsAvailable;

        await _context.SaveChangesAsync();

        var hotelStatsLookup = await BuildHotelRevenueLookupAsync([hotelId]);
        return MapHotel(hotel, hotelStatsLookup.GetValueOrDefault(hotelId) ?? AdminHotelBookingStats.Empty);
    }

    public async Task<AdminRoomDto> CreateRoomAsync(int hotelId, AdminRoomRequest request)
    {
        ValidateRoomRequest(request);

        var hotel = await _context.Hotels.FirstOrDefaultAsync(item => item.Id == hotelId);
        if (hotel is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khách sạn.");
        }

        var room = new Room
        {
            HotelId = hotelId,
            RoomType = request.RoomType.Trim(),
            Capacity = request.Capacity,
            PricePerNight = request.PricePerNight,
            CommissionRate = request.CommissionRate,
            AvailableQty = request.AvailableQty
        };

        _context.Rooms.Add(room);
        await _context.SaveChangesAsync();

        var imageUrls = NormalizeGalleryUrls(request.ImageUrls);
        AddGalleryImages(GalleryReferenceType.Room, room.Id, imageUrls);
        await _context.SaveChangesAsync();

        return MapRoom(room, imageUrls);
    }

    public async Task<AdminRoomDto> UpdateRoomAsync(int roomId, AdminRoomRequest request)
    {
        ValidateRoomRequest(request);

        var room = await _context.Rooms.FirstOrDefaultAsync(item => item.Id == roomId);
        if (room is null)
        {
            throw new BadHttpRequestException("Không tìm thấy phòng.");
        }

        room.RoomType = request.RoomType.Trim();
        room.Capacity = request.Capacity;
        room.PricePerNight = request.PricePerNight;
        room.CommissionRate = request.CommissionRate;
        room.AvailableQty = request.AvailableQty;

        var imageUrls = NormalizeGalleryUrls(request.ImageUrls);
        await ReplaceGalleryImagesAsync(GalleryReferenceType.Room, room.Id, imageUrls);
        await _context.SaveChangesAsync();

        return MapRoom(room, imageUrls);
    }

    public Task DeleteRoomAsync(int roomId)
    {
        throw new BadHttpRequestException("Không hỗ trợ xóa phòng. Hãy đặt số lượng còn bán về 0 để ngừng nhận booking.");
    }

    public Task DeleteHotelAsync(int hotelId)
    {
        throw new BadHttpRequestException("Không hỗ trợ xóa khách sạn. Hãy chuyển khách sạn sang trạng thái ngừng bán để giữ an toàn dữ liệu.");
    }

    public async Task<List<AdminPromotionDto>> GetPromotionsAsync()
    {
        var promotions = await _context.Promotions
            .OrderByDescending(promotion => promotion.ValidUntil)
            .ToListAsync();

        return promotions.Select(MapPromotion).ToList();
    }

    public async Task<AdminPromotionDto> CreatePromotionAsync(AdminPromotionRequest request)
    {
        ValidatePromotionRequest(request);
        var normalizedCode = request.Code.Trim().ToUpperInvariant();
        if (await _context.Promotions.AnyAsync(item => item.Code == normalizedCode))
        {
            throw new BadHttpRequestException("Ma khuyen mai da ton tai.");
        }

        if (string.IsNullOrWhiteSpace(request.Code))
        {
            throw new BadHttpRequestException("Mã khuyến mãi không được để trống.");
        }

        var promotion = new Promotion
        {
            Code = normalizedCode,
            DiscountPercent = request.DiscountPercent,
            MaxDiscountAmount = request.MaxDiscountAmount,
            ValidUntil = request.ValidUntil,
            UsageLimit = request.UsageLimit,
            UsedCount = 0
        };

        _context.Promotions.Add(promotion);
        await _context.SaveChangesAsync();

        return MapPromotion(promotion);
    }

    public async Task<AdminPromotionDto> UpdatePromotionAsync(int promotionId, AdminPromotionRequest request)
    {
        ValidatePromotionRequest(request);
        var promotion = await _context.Promotions.FirstOrDefaultAsync(item => item.Id == promotionId);
        if (promotion is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khuyến mãi.");
        }

        var normalizedCode = request.Code.Trim().ToUpperInvariant();
        if (await _context.Promotions.AnyAsync(item => item.Id != promotionId && item.Code == normalizedCode))
        {
            throw new BadHttpRequestException("Ma khuyen mai da ton tai.");
        }
        if (request.UsageLimit < promotion.UsedCount.GetValueOrDefault())
        {
            throw new BadHttpRequestException("Gioi han luot dung khong duoc nho hon so luot da dung.");
        }

        promotion.Code = normalizedCode;
        promotion.DiscountPercent = request.DiscountPercent;
        promotion.MaxDiscountAmount = request.MaxDiscountAmount;
        promotion.ValidUntil = request.ValidUntil;
        promotion.UsageLimit = request.UsageLimit;

        await _context.SaveChangesAsync();

        return MapPromotion(promotion);
    }

    public async Task DeletePromotionAsync(int promotionId)
    {
        var promotion = await _context.Promotions.FirstOrDefaultAsync(item => item.Id == promotionId);
        if (promotion is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khuyến mãi.");
        }

        if (promotion.UsedCount.GetValueOrDefault() > 0)
        {
            throw new BadHttpRequestException("Khong the xoa khuyen mai da phat sinh luot dung.");
        }

        _context.Promotions.Remove(promotion);
        await _context.SaveChangesAsync();
    }

    public async Task<AdminReportSummaryDto> GetReportSummaryAsync()
    {
        var trips = await _context.Trips.Include(trip => trip.Destination).ToListAsync();
        var payments = await _context.Payments.ToListAsync();

        return new AdminReportSummaryDto
        {
            TotalRevenue = payments.Where(payment => payment.Status == PaymentStatus.Paid).Sum(payment => payment.Amount.GetValueOrDefault()),
            TotalProfit = trips.Where(trip => trip.Status == TripStatus.Paid).Sum(trip => trip.TotalProfit.GetValueOrDefault()),
            TotalUsers = await _context.Users.CountAsync(),
            TotalBookings = trips.Count,
            TotalSchedules = await _context.BusSchedules.CountAsync(),
            TopDestinations = trips
                .Where(trip => trip.Destination is not null)
                .GroupBy(trip => trip.Destination!.Name)
                .Select(group => new AdminReportBreakdownDto
                {
                    Label = group.Key,
                    Value = group.Sum(trip => trip.TotalAmount.GetValueOrDefault())
                })
                .OrderByDescending(item => item.Value)
                .Take(5)
                .ToList(),
            RevenueByPaymentStatus = payments
                .GroupBy(payment => payment.Status)
                .Select(group => new AdminReportBreakdownDto
                {
                    Label = MapPaymentStatus(group.Key),
                    Value = group.Sum(payment => payment.Amount.GetValueOrDefault())
                })
                .OrderByDescending(item => item.Value)
                .ToList()
        };
    }

    private async Task<Dictionary<int, AdminHotelBookingStats>> BuildHotelRevenueLookupAsync(List<int> hotelIds)
    {
        if (hotelIds.Count == 0)
        {
            return new Dictionary<int, AdminHotelBookingStats>();
        }

        var roomMappings = await _context.Rooms
            .AsNoTracking()
            .Where(room => room.HotelId.HasValue && hotelIds.Contains(room.HotelId.Value))
            .Select(room => new
            {
                RoomId = room.Id,
                HotelId = room.HotelId!.Value,
                CommissionRate = room.CommissionRate
            })
            .ToListAsync();

        if (roomMappings.Count == 0)
        {
            return new Dictionary<int, AdminHotelBookingStats>();
        }

        var roomToHotelLookup = roomMappings.ToDictionary(item => item.RoomId, item => item.HotelId);
        var roomCommissionLookup = roomMappings.ToDictionary(item => item.RoomId, item => item.CommissionRate);
        var roomIds = roomMappings.Select(item => item.RoomId).ToList();

        var hotelItineraries = await _context.TripItineraries
            .AsNoTracking()
            .Where(item =>
                item.ServiceType == TripServiceType.Hotel &&
                item.ServiceId.HasValue &&
                roomIds.Contains(item.ServiceId.Value) &&
                item.Trip != null &&
                item.Trip.Status != TripStatus.Cancelled &&
                item.Trip.Payments.Any(payment => payment.Status == PaymentStatus.Paid))
            .Select(item => new
            {
                RoomId = item.ServiceId!.Value,
                Revenue = item.BookedPrice.GetValueOrDefault(),
                Quantity = item.Quantity ?? 1,
                CommissionRate = item.BookedCommissionRate
            })
            .ToListAsync();

        return hotelItineraries
            .GroupBy(item => roomToHotelLookup[item.RoomId])
            .ToDictionary(group => group.Key, group =>
            {
                var roomStats = group
                    .GroupBy(item => item.RoomId)
                    .ToDictionary(roomGroup => roomGroup.Key, roomGroup =>
                    {
                        var revenue = roomGroup.Sum(item => item.Revenue * Math.Max(item.Quantity, 1));
                        var profit = roomGroup.Sum(item =>
                        {
                            var quantity = Math.Max(item.Quantity, 1);
                            var commission = item.CommissionRate ?? roomCommissionLookup.GetValueOrDefault(item.RoomId);
                            return item.Revenue * quantity * NormalizeCommissionRate(commission);
                        });

                        return new AdminRoomBookingStats(
                            Revenue: revenue,
                            Profit: profit,
                            BookedRoomQty: roomGroup.Sum(item => Math.Max(item.Quantity, 1)),
                            BookingCount: roomGroup.Count());
                    });

                return new AdminHotelBookingStats(roomStats);
            });
    }

    private static AdminDestinationDto MapDestination(Destination destination)
    {
        return new AdminDestinationDto
        {
            Id = destination.Id,
            Name = destination.Name,
            Description = destination.Description ?? string.Empty,
            CoverImageUrl = destination.CoverImageUrl ?? string.Empty,
            IsHot = destination.IsHot ?? false,
            HotelCount = destination.Hotels.Count,
            TripCount = destination.Trips.Count
        };
    }

    private static AdminHotelDto MapHotel(Hotel hotel, AdminHotelBookingStats bookingStats)
    {
        var availableRoomQty = hotel.Rooms.Sum(room => Math.Max(room.AvailableQty ?? 0, 0));
        var lowestPrice = hotel.Rooms
            .Where(room => room.PricePerNight.HasValue)
            .Select(room => room.PricePerNight!.Value)
            .DefaultIfEmpty(0)
            .Min();

        return new AdminHotelDto
        {
            Id = hotel.Id,
            DestinationId = hotel.DestinationId ?? 0,
            DestinationName = hotel.Destination?.Name ?? "Chưa xác định",
            Name = hotel.Name,
            Address = hotel.Address ?? string.Empty,
            StarRating = hotel.StarRating ?? 0,
            Description = hotel.Description ?? string.Empty,
            IsAvailable = hotel.IsAvailable ?? false,
            RoomCount = hotel.Rooms.Count,
            AvailableRoomQty = availableRoomQty,
            LowestPrice = lowestPrice,
            TotalRevenue = bookingStats.TotalRevenue,
            TotalProfit = bookingStats.TotalProfit,
            BookedRoomQty = bookingStats.BookedRoomQty
        };
    }

    private static AdminHotelDetailDto MapHotelDetail(
        Hotel hotel,
        AdminHotelBookingStats bookingStats,
        Dictionary<int, List<string>> roomGalleryLookup)
    {
        var summary = MapHotel(hotel, bookingStats);

        return new AdminHotelDetailDto
        {
            Id = summary.Id,
            DestinationId = summary.DestinationId,
            DestinationName = summary.DestinationName,
            Name = summary.Name,
            Address = summary.Address,
            StarRating = summary.StarRating,
            Description = summary.Description,
            IsAvailable = summary.IsAvailable,
            RoomCount = summary.RoomCount,
            AvailableRoomQty = summary.AvailableRoomQty,
            LowestPrice = summary.LowestPrice,
            TotalRevenue = summary.TotalRevenue,
            TotalProfit = summary.TotalProfit,
            BookedRoomQty = summary.BookedRoomQty,
            Rooms = hotel.Rooms
                .OrderBy(room => room.PricePerNight ?? decimal.MaxValue)
                .ThenBy(room => room.RoomType)
                .Select(room => MapRoom(
                    room,
                    roomGalleryLookup.TryGetValue(room.Id, out var images) ? images : [],
                    bookingStats.RoomStats.GetValueOrDefault(room.Id) ?? AdminRoomBookingStats.Empty))
                .ToList()
        };
    }

    private static AdminRoomDto MapRoom(Room room, List<string>? imageUrls = null, AdminRoomBookingStats? bookingStats = null)
    {
        var availableQty = Math.Max(room.AvailableQty ?? 0, 0);
        var stats = bookingStats ?? AdminRoomBookingStats.Empty;

        return new AdminRoomDto
        {
            Id = room.Id,
            HotelId = room.HotelId ?? 0,
            RoomType = room.RoomType ?? "Standard",
            Capacity = room.Capacity ?? 0,
            PricePerNight = room.PricePerNight ?? 0,
            CommissionRate = (double)(NormalizeCommissionRate(room.CommissionRate) * 100m),
            AvailableQty = availableQty,
            IsSelling = availableQty > 0,
            ImageUrls = imageUrls ?? [],
            TotalRevenue = stats.Revenue,
            TotalProfit = stats.Profit,
            BookedRoomQty = stats.BookedRoomQty,
            BookingCount = stats.BookingCount
        };
    }

    private sealed class AdminHotelBookingStats
    {
        public static readonly AdminHotelBookingStats Empty = new(new Dictionary<int, AdminRoomBookingStats>());

        public AdminHotelBookingStats(Dictionary<int, AdminRoomBookingStats> roomStats)
        {
            RoomStats = roomStats;
            TotalRevenue = roomStats.Values.Sum(item => item.Revenue);
            TotalProfit = roomStats.Values.Sum(item => item.Profit);
            BookedRoomQty = roomStats.Values.Sum(item => item.BookedRoomQty);
        }

        public Dictionary<int, AdminRoomBookingStats> RoomStats { get; }
        public decimal TotalRevenue { get; }
        public decimal TotalProfit { get; }
        public int BookedRoomQty { get; }
    }

    private sealed record AdminRoomBookingStats(
        decimal Revenue,
        decimal Profit,
        int BookedRoomQty,
        int BookingCount)
    {
        public static readonly AdminRoomBookingStats Empty = new(0m, 0m, 0, 0);
    }

    private async Task<Dictionary<int, List<string>>> BuildGalleryLookupAsync(GalleryReferenceType referenceType, List<int> referenceIds)
    {
        if (referenceIds.Count == 0)
        {
            return new Dictionary<int, List<string>>();
        }

        return await _context.Galleries
            .AsNoTracking()
            .Where(gallery =>
                gallery.ReferenceType == referenceType &&
                gallery.ReferenceId.HasValue &&
                referenceIds.Contains(gallery.ReferenceId.Value))
            .OrderBy(gallery => gallery.Id)
            .GroupBy(gallery => gallery.ReferenceId!.Value)
            .ToDictionaryAsync(
                group => group.Key,
                group => group
                    .Select(gallery => gallery.ImageUrl ?? string.Empty)
                    .Where(url => !string.IsNullOrWhiteSpace(url))
                    .ToList());
    }

    private async Task ReplaceGalleryImagesAsync(GalleryReferenceType referenceType, int referenceId, List<string> imageUrls)
    {
        var existing = await _context.Galleries
            .Where(gallery => gallery.ReferenceType == referenceType && gallery.ReferenceId == referenceId)
            .ToListAsync();

        _context.Galleries.RemoveRange(existing);
        AddGalleryImages(referenceType, referenceId, imageUrls);
    }

    private void AddGalleryImages(GalleryReferenceType referenceType, int referenceId, List<string> imageUrls)
    {
        foreach (var imageUrl in imageUrls)
        {
            _context.Galleries.Add(new Gallery
            {
                ReferenceType = referenceType,
                ReferenceId = referenceId,
                ImageUrl = imageUrl
            });
        }
    }

    private static List<string> NormalizeGalleryUrls(IEnumerable<string>? imageUrls)
    {
        if (imageUrls is null)
        {
            return [];
        }

        var normalized = imageUrls
            .Select(url => url?.Trim() ?? string.Empty)
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(12)
            .ToList();

        if (normalized.Any(url => url.Length > 255))
        {
            throw new BadHttpRequestException("URL anh khong duoc vuot qua 255 ky tu.");
        }

        return normalized;
    }

    private static void ValidatePromotionRequest(AdminPromotionRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            throw new BadHttpRequestException("Ma khuyen mai khong duoc de trong.");
        }
        if (request.DiscountPercent <= 0 || request.DiscountPercent > 100)
        {
            throw new BadHttpRequestException("Phan tram giam phai lon hon 0 va khong vuot qua 100.");
        }
        if (request.MaxDiscountAmount < 0)
        {
            throw new BadHttpRequestException("Muc giam toi da khong hop le.");
        }
        if (request.UsageLimit <= 0)
        {
            throw new BadHttpRequestException("Gioi han luot dung phai lon hon 0.");
        }
        if (request.ValidUntil <= DateTime.UtcNow)
        {
            throw new BadHttpRequestException("Han dung phai nam trong tuong lai.");
        }
    }

    private static AdminPromotionDto MapPromotion(Promotion promotion)
    {
        var validUntil = promotion.ValidUntil ?? DateTime.UtcNow;
        return new AdminPromotionDto
        {
            Id = promotion.Id,
            Code = promotion.Code ?? string.Empty,
            DiscountPercent = promotion.DiscountPercent ?? 0,
            MaxDiscountAmount = promotion.MaxDiscountAmount ?? 0,
            ValidUntil = validUntil.ToString("yyyy-MM-dd"),
            UsageLimit = promotion.UsageLimit ?? 0,
            UsedCount = promotion.UsedCount ?? 0,
            IsActive = validUntil >= DateTime.UtcNow && (promotion.UsageLimit == null || promotion.UsedCount < promotion.UsageLimit)
        };
    }

    private static void ValidateHotelRequest(AdminHotelRequest request)
    {
        if (request.DestinationId <= 0)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên khách sạn không được để trống.");
        }

        if (request.StarRating < 1 || request.StarRating > 5)
        {
            throw new BadHttpRequestException("Số sao phải nằm trong khoảng từ 1 đến 5.");
        }
    }

    private static void ValidateRoomRequest(AdminRoomRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.RoomType))
        {
            throw new BadHttpRequestException("Loại phòng không được để trống.");
        }

        if (request.Capacity <= 0)
        {
            throw new BadHttpRequestException("Sức chứa phải lớn hơn 0.");
        }

        if (request.PricePerNight <= 0)
        {
            throw new BadHttpRequestException("Giá mỗi đêm phải lớn hơn 0.");
        }

        if (request.CommissionRate < 0 || request.CommissionRate > 100)
        {
            throw new BadHttpRequestException("Hoa hồng phải nằm trong khoảng từ 0 đến 100.");
        }

        if (request.AvailableQty < 0)
        {
            throw new BadHttpRequestException("Số lượng còn bán không được âm.");
        }
    }
}
