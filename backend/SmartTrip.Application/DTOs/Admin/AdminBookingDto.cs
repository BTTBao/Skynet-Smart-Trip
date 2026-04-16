using System.Collections.Generic;

namespace SmartTrip.Application.DTOs.Admin;

public class AdminBookingStatsDto
{
    public decimal TotalRevenue { get; set; }
    public int TotalBookings { get; set; }
    public int NewCustomers { get; set; }
    public int PaidBookings { get; set; }
    public int PendingBookings { get; set; }
    public int CancelledBookings { get; set; }
    public List<AdminBookingDto> Bookings { get; set; } = new();
}

public class AdminBookingDto
{
    public int Id { get; set; }
    public string DisplayId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string UserCode { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string TotalAmount { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public string TripStatus { get; set; } = string.Empty;
    public string CreatedAt { get; set; } = string.Empty;
}

public class AdminBookingDetailDto : AdminBookingDto
{
    public string TripTitle { get; set; } = string.Empty;
    public string TravelWindow { get; set; } = string.Empty;
    public List<AdminBookingItineraryItemDto> Itinerary { get; set; } = new();
    public List<AdminBookingPaymentHistoryDto> PaymentHistory { get; set; } = new();
}

public class AdminBookingItineraryItemDto
{
    public int DayNumber { get; set; }
    public string ServiceType { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Amount { get; set; }
}

public class AdminBookingPaymentHistoryDto
{
    public string TransactionId { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string PaidAt { get; set; } = string.Empty;
}

public class AdminUpdateBookingStatusRequest
{
    public string PaymentStatus { get; set; } = string.Empty;
    public string TripStatus { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
}
