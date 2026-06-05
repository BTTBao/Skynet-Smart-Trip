using System.Collections.Generic;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminDestinationDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public bool IsHot { get; set; }
    public int HotelCount { get; set; }
    public int TripCount { get; set; }
}

public class AdminDestinationRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public bool IsHot { get; set; }
}

public class AdminHotelDto
{
    public int Id { get; set; }
    public int DestinationId { get; set; }
    public string DestinationName { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int StarRating { get; set; }
    public string Description { get; set; } = string.Empty;
    public bool IsAvailable { get; set; }
    public int RoomCount { get; set; }
    public int AvailableRoomQty { get; set; }
    public decimal LowestPrice { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class AdminHotelRequest
{
    public int DestinationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int StarRating { get; set; }
    public string Description { get; set; } = string.Empty;
    public bool IsAvailable { get; set; }
}

public class AdminHotelDetailDto : AdminHotelDto
{
    public List<AdminRoomDto> Rooms { get; set; } = new();
}

public class AdminRoomDto
{
    public int Id { get; set; }
    public int HotelId { get; set; }
    public string RoomType { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal PricePerNight { get; set; }
    public double CommissionRate { get; set; }
    public int AvailableQty { get; set; }
    public bool IsSelling { get; set; }
    public List<string> ImageUrls { get; set; } = new();
}

public class AdminRoomRequest
{
    public string RoomType { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal PricePerNight { get; set; }
    public double CommissionRate { get; set; }
    public int AvailableQty { get; set; }
    public List<string> ImageUrls { get; set; } = new();
}

public class AdminPromotionDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public double DiscountPercent { get; set; }
    public decimal MaxDiscountAmount { get; set; }
    public string ValidUntil { get; set; } = string.Empty;
    public int UsageLimit { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; }
}

public class AdminPromotionRequest
{
    public string Code { get; set; } = string.Empty;
    public double DiscountPercent { get; set; }
    public decimal MaxDiscountAmount { get; set; }
    public DateTime ValidUntil { get; set; }
    public int UsageLimit { get; set; }
}

public class AdminReportSummaryDto
{
    public decimal TotalRevenue { get; set; }
    public decimal TotalProfit { get; set; }
    public int TotalUsers { get; set; }
    public int TotalBookings { get; set; }
    public int TotalSchedules { get; set; }
    public List<AdminReportBreakdownDto> TopDestinations { get; set; } = new();
    public List<AdminReportBreakdownDto> RevenueByPaymentStatus { get; set; } = new();
}

public class AdminReportBreakdownDto
{
    public string Label { get; set; } = string.Empty;
    public decimal Value { get; set; }
}
