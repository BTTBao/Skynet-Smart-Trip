namespace SmartTrip.Application.DTOs.Trip;

public class CreateHotelBookingDto
{
    public int UserId { get; set; }

    public int HotelId { get; set; }

    public int RoomId { get; set; }

    public int? DestinationId { get; set; }

    public string? DestinationName { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateOnly CheckInDate { get; set; }

    public DateOnly CheckOutDate { get; set; }

    public int Quantity { get; set; } = 1;

    public int AdultCount { get; set; } = 1;

    public int ChildCount { get; set; }

    public int InfantCount { get; set; }
}
