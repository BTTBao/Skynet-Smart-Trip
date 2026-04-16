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

        return hotels.Select(MapHotel).ToList();
    }

    public async Task<AdminHotelDto> CreateHotelAsync(AdminHotelRequest request)
    {
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

        return MapHotel(created);
    }

    public async Task<AdminHotelDto> UpdateHotelAsync(int hotelId, AdminHotelRequest request)
    {
        var hotel = await _context.Hotels
            .Include(item => item.Destination)
            .Include(item => item.Rooms)
            .FirstOrDefaultAsync(item => item.Id == hotelId);

        if (hotel is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khách sạn.");
        }

        hotel.DestinationId = request.DestinationId;
        hotel.Name = request.Name.Trim();
        hotel.Address = string.IsNullOrWhiteSpace(request.Address) ? null : request.Address.Trim();
        hotel.StarRating = request.StarRating;
        hotel.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        hotel.IsAvailable = request.IsAvailable;

        await _context.SaveChangesAsync();

        return MapHotel(hotel);
    }

    public async Task DeleteHotelAsync(int hotelId)
    {
        var hotel = await _context.Hotels
            .Include(item => item.Rooms)
            .FirstOrDefaultAsync(item => item.Id == hotelId);

        if (hotel is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khách sạn.");
        }

        if (hotel.Rooms.Any())
        {
            throw new BadHttpRequestException("Không thể xóa khách sạn còn phòng đang quản lý.");
        }

        _context.Hotels.Remove(hotel);
        await _context.SaveChangesAsync();
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
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            throw new BadHttpRequestException("Mã khuyến mãi không được để trống.");
        }

        var promotion = new Promotion
        {
            Code = request.Code.Trim().ToUpperInvariant(),
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
        var promotion = await _context.Promotions.FirstOrDefaultAsync(item => item.Id == promotionId);
        if (promotion is null)
        {
            throw new BadHttpRequestException("Không tìm thấy khuyến mãi.");
        }

        promotion.Code = request.Code.Trim().ToUpperInvariant();
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

    private static AdminHotelDto MapHotel(Hotel hotel)
    {
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
            RoomCount = hotel.Rooms.Count
        };
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
            IsActive = validUntil >= DateTime.UtcNow
        };
    }
}
