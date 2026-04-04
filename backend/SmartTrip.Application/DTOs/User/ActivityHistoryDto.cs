namespace SmartTrip.Application.DTOs.User;

public class ActivityHistoryDto
{
    public List<BookingHistoryItemDto> Bookings { get; set; } = new();
    public List<HotelHistoryItemDto> Hotels { get; set; } = new();
    public List<BusHistoryItemDto> Buses { get; set; } = new();
    public List<PaymentHistoryItemDto> Payments { get; set; } = new();
}

public class BookingHistoryItemDto
{
    public int TripId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string DestinationName { get; set; } = string.Empty;
    public string? StartDate { get; set; }
    public string? EndDate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? CreatedAt { get; set; }
    public string? InvoiceNumber { get; set; }
}

public class HotelHistoryItemDto
{
    public int TripId { get; set; }
    public int ItineraryId { get; set; }
    public int ServiceId { get; set; }
    public string TripTitle { get; set; } = string.Empty;
    public string HotelName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string DestinationName { get; set; } = string.Empty;
    public string? CheckInDate { get; set; }
    public string? CheckOutDate { get; set; }
    public int Quantity { get; set; }
    public decimal BookedPrice { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class BusHistoryItemDto
{
    public int TripId { get; set; }
    public int ItineraryId { get; set; }
    public int ServiceId { get; set; }
    public string TripTitle { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string FromDestination { get; set; } = string.Empty;
    public string ToDestination { get; set; } = string.Empty;
    public string? DepartureTime { get; set; }
    public string? ArrivalTime { get; set; }
    public int Quantity { get; set; }
    public decimal BookedPrice { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class PaymentHistoryItemDto
{
    public int PaymentId { get; set; }
    public int TripId { get; set; }
    public string TripTitle { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? PaidAt { get; set; }
    public string? TransactionId { get; set; }
    public string? InvoiceNumber { get; set; }
    public string? InvoicePdfUrl { get; set; }
}
