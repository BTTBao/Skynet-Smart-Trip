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
    public async Task<List<AdminVehicleRentalShopDto>> GetVehicleRentalShopsAsync()
    {
        var shops = await _context.VehicleRentalShops
            .Include(shop => shop.Destination)
            .Include(shop => shop.VehicleOptions)
            .OrderByDescending(shop => shop.CreatedAt)
            .ThenBy(shop => shop.Name)
            .ToListAsync();

        return shops.Select(MapVehicleRentalShop).ToList();
    }

    public async Task<AdminVehicleRentalShopDto> GetVehicleRentalShopDetailAsync(int shopId)
    {
        var shop = await _context.VehicleRentalShops
            .Include(item => item.Destination)
            .Include(item => item.VehicleOptions)
            .FirstOrDefaultAsync(item => item.Id == shopId);

        if (shop is null)
        {
            throw new BadHttpRequestException("Không tìm thấy cửa hàng thuê xe.");
        }

        return MapVehicleRentalShop(shop);
    }

    public async Task<AdminVehicleRentalShopDto> CreateVehicleRentalShopAsync(AdminVehicleRentalShopRequest request)
    {
        ValidateVehicleRentalShopRequest(request);

        var destinationExists = await _context.Destinations.AnyAsync(destination => destination.Id == request.DestinationId);
        if (!destinationExists)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        var shop = new VehicleRentalShop
        {
            Name = request.Name.Trim(),
            PhoneNumber = request.PhoneNumber.Trim(),
            Address = request.Address.Trim(),
            DestinationId = request.DestinationId,
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            ImageUrl = string.IsNullOrWhiteSpace(request.ImageUrl) ? null : request.ImageUrl.Trim(),
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            VehicleOptions = BuildVehicleRentalOptions(request.VehicleOptions)
        };

        _context.VehicleRentalShops.Add(shop);
        await _context.SaveChangesAsync();

        var created = await _context.VehicleRentalShops
            .Include(item => item.Destination)
            .Include(item => item.VehicleOptions)
            .FirstAsync(item => item.Id == shop.Id);

        return MapVehicleRentalShop(created);
    }

    public async Task<AdminVehicleRentalShopDto> UpdateVehicleRentalShopAsync(int shopId, AdminVehicleRentalShopRequest request)
    {
        ValidateVehicleRentalShopRequest(request);

        var shop = await _context.VehicleRentalShops
            .Include(item => item.Destination)
            .Include(item => item.VehicleOptions)
            .FirstOrDefaultAsync(item => item.Id == shopId);

        if (shop is null)
        {
            throw new BadHttpRequestException("Không tìm thấy cửa hàng thuê xe.");
        }

        var destinationExists = await _context.Destinations.AnyAsync(destination => destination.Id == request.DestinationId);
        if (!destinationExists)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        shop.Name = request.Name.Trim();
        shop.PhoneNumber = request.PhoneNumber.Trim();
        shop.Address = request.Address.Trim();
        shop.DestinationId = request.DestinationId;
        shop.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        shop.ImageUrl = string.IsNullOrWhiteSpace(request.ImageUrl) ? null : request.ImageUrl.Trim();
        shop.IsActive = request.IsActive;

        _context.VehicleRentalOptions.RemoveRange(shop.VehicleOptions);
        shop.VehicleOptions = BuildVehicleRentalOptions(request.VehicleOptions);

        await _context.SaveChangesAsync();

        return MapVehicleRentalShop(shop);
    }

    public async Task DeleteVehicleRentalShopAsync(int shopId)
    {
        var shop = await _context.VehicleRentalShops
            .Include(item => item.VehicleOptions)
            .FirstOrDefaultAsync(item => item.Id == shopId);

        if (shop is null)
        {
            throw new BadHttpRequestException("Không tìm thấy cửa hàng thuê xe.");
        }

        _context.VehicleRentalOptions.RemoveRange(shop.VehicleOptions);
        _context.VehicleRentalShops.Remove(shop);
        await _context.SaveChangesAsync();
    }

    private static List<VehicleRentalOption> BuildVehicleRentalOptions(IEnumerable<AdminVehicleRentalOptionRequest> options)
    {
        return options
            .Select(option => new VehicleRentalOption
            {
                VehicleType = ParseVehicleRentalType(option.VehicleType),
                MaxSeats = option.MaxSeats,
                PricePerDay = option.PricePerDay,
                IsAvailable = option.IsAvailable
            })
            .ToList();
    }

    private static VehicleRentalType ParseVehicleRentalType(string vehicleType)
    {
        if (!Enum.TryParse<VehicleRentalType>(vehicleType, true, out var parsed))
        {
            throw new BadHttpRequestException("Loại xe không hợp lệ.");
        }

        return parsed;
    }

    private static AdminVehicleRentalShopDto MapVehicleRentalShop(VehicleRentalShop shop)
    {
        var options = shop.VehicleOptions
            .OrderBy(option => option.PricePerDay)
            .ThenBy(option => option.VehicleType)
            .Select(MapVehicleRentalOption)
            .ToList();

        return new AdminVehicleRentalShopDto
        {
            Id = shop.Id,
            Name = shop.Name,
            PhoneNumber = shop.PhoneNumber,
            Address = shop.Address,
            DestinationId = shop.DestinationId,
            DestinationName = shop.Destination?.Name ?? "Chưa xác định",
            Description = shop.Description ?? string.Empty,
            ImageUrl = shop.ImageUrl ?? string.Empty,
            IsActive = shop.IsActive,
            CreatedAt = shop.CreatedAt.ToString("yyyy-MM-dd"),
            OptionCount = options.Count,
            MinPricePerDay = options.Count == 0 ? 0 : options.Min(option => option.PricePerDay),
            VehicleTypeLabels = options.Select(option => option.VehicleTypeLabel).Distinct().ToList(),
            VehicleOptions = options
        };
    }

    private static AdminVehicleRentalOptionDto MapVehicleRentalOption(VehicleRentalOption option)
    {
        return new AdminVehicleRentalOptionDto
        {
            Id = option.Id,
            VehicleType = option.VehicleType.ToString(),
            VehicleTypeLabel = GetVehicleRentalTypeLabel(option.VehicleType),
            MaxSeats = option.MaxSeats,
            PricePerDay = option.PricePerDay,
            IsAvailable = option.IsAvailable
        };
    }

    private static string GetVehicleRentalTypeLabel(VehicleRentalType vehicleType)
    {
        return vehicleType switch
        {
            VehicleRentalType.ManualMotorbike => "Xe số",
            VehicleRentalType.Scooter => "Xe tay ga",
            VehicleRentalType.Car => "Xe ô tô",
            VehicleRentalType.MultiSeatCar => "Xe nhiều chỗ",
            _ => vehicleType.ToString()
        };
    }

    private static void ValidateVehicleRentalShopRequest(AdminVehicleRentalShopRequest request)
    {
        if (request.DestinationId <= 0)
        {
            throw new BadHttpRequestException("Điểm đến không hợp lệ.");
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new BadHttpRequestException("Tên cửa hàng không được để trống.");
        }

        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            throw new BadHttpRequestException("Số điện thoại không được để trống.");
        }

        if (string.IsNullOrWhiteSpace(request.Address))
        {
            throw new BadHttpRequestException("Địa chỉ không được để trống.");
        }

        if (request.VehicleOptions is null || request.VehicleOptions.Count == 0)
        {
            throw new BadHttpRequestException("Cần ít nhất một loại xe cho thuê.");
        }

        foreach (var option in request.VehicleOptions)
        {
            if (option.PricePerDay <= 0)
            {
                throw new BadHttpRequestException("Giá thuê theo ngày phải lớn hơn 0.");
            }

            if (option.MaxSeats is < 1)
            {
                throw new BadHttpRequestException("Số chỗ ngồi phải lớn hơn 0 nếu được nhập.");
            }

            ParseVehicleRentalType(option.VehicleType);
        }
    }
}
