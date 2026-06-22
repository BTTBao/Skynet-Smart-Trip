namespace SmartTrip.Application.DTOs.Catalog;

public class CatalogHomeDto
{
    public List<CatalogDestinationDto> PopularDestinations { get; set; } = new();
    public List<CatalogHotelCardDto> FeaturedHotels { get; set; } = new();
    public List<CatalogHotelCardDto> RecommendedHotels { get; set; } = new();
    public List<CatalogBusCardDto> FeaturedBuses { get; set; } = new();
    public List<CatalogVehicleRentalShopCardDto> FeaturedVehicleRentalShops { get; set; } = new();
}

public class CatalogDestinationDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string CoverImageUrl { get; set; } = string.Empty;
    public bool IsHot { get; set; }
}

public class CatalogHotelSearchResultDto
{
    public int Total { get; set; }
    public List<CatalogHotelCardDto> Items { get; set; } = new();
}

public class CatalogBusSearchResultDto
{
    public int Total { get; set; }
    public List<CatalogBusCardDto> Items { get; set; } = new();
}

public class CatalogHotelCardDto
{
    public int Id { get; set; }
    public int DestinationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string DestinationName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int StarRating { get; set; }
    public decimal PricePerNight { get; set; }
    public double Rating { get; set; }
    public int ReviewCount { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public bool IsAvailable { get; set; }
    public string? Tag { get; set; }
}

public class CatalogHotelDetailDto
{
    public int Id { get; set; }
    public int DestinationId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string DestinationName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int StarRating { get; set; }
    public decimal PricePerNight { get; set; }
    public double Rating { get; set; }
    public int ReviewCount { get; set; }
    public bool IsAvailable { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public List<string> ImageUrls { get; set; } = new();
    public List<string> Amenities { get; set; } = new();
    public List<CatalogRoomOptionDto> Rooms { get; set; } = new();
    public List<CatalogReviewDto> Reviews { get; set; } = new();
}

public class CatalogRoomOptionDto
{
    public int Id { get; set; }
    public string RoomType { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public decimal PricePerNight { get; set; }
    public int AvailableQty { get; set; }
    public List<string> ImageUrls { get; set; } = new();
}

public class CatalogRoomAvailabilityDto
{
    public int RoomId { get; set; }
    public int TotalQty { get; set; }
    public int RemainingQty { get; set; }
    public bool IsAvailable { get; set; }
    public string Message { get; set; } = string.Empty;
}

public class CatalogBusCardDto
{
    public int Id { get; set; }
    public int? CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string FromDestination { get; set; } = string.Empty;
    public string ToDestination { get; set; } = string.Empty;
    public DateTime? DepartureTime { get; set; }
    public DateTime? ArrivalTime { get; set; }
    public decimal Price { get; set; }
    public int TotalSeats { get; set; }
    public double Rating { get; set; }
    public int ReviewCount { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
}

public class CatalogBusDetailDto
{
    public int Id { get; set; }
    public int? CompanyId { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string Hotline { get; set; } = string.Empty;
    public string FromDestination { get; set; } = string.Empty;
    public string ToDestination { get; set; } = string.Empty;
    public DateTime? DepartureTime { get; set; }
    public DateTime? ArrivalTime { get; set; }
    public decimal Price { get; set; }
    public int TotalSeats { get; set; }
    public double Rating { get; set; }
    public int ReviewCount { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public List<CatalogReviewDto> Reviews { get; set; } = new();
}

public class CatalogReviewDto
{
    public string UserName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime? CreatedAt { get; set; }
}

public class CatalogPromotionDto
{
    public string Code { get; set; } = string.Empty;
    public double DiscountPercent { get; set; }
    public decimal MaxDiscountAmount { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class CatalogVehicleRentalSearchResultDto
{
    public int Total { get; set; }
    public List<CatalogVehicleRentalShopCardDto> Items { get; set; } = new();
}

public class CatalogVehicleRentalShopCardDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int DestinationId { get; set; }
    public string DestinationName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public decimal MinPricePerDay { get; set; }
    public List<string> VehicleTypeLabels { get; set; } = new();
}

public class CatalogVehicleRentalShopDetailDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int DestinationId { get; set; }
    public string DestinationName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public List<CatalogVehicleRentalOptionDto> VehicleOptions { get; set; } = new();
}

public class CatalogVehicleRentalOptionDto
{
    public int Id { get; set; }
    public string VehicleType { get; set; } = string.Empty;
    public string VehicleTypeLabel { get; set; } = string.Empty;
    public int? MaxSeats { get; set; }
    public decimal PricePerDay { get; set; }
    public bool IsAvailable { get; set; }
}
