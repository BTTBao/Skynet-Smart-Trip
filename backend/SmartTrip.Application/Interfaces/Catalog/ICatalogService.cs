using SmartTrip.Application.DTOs.Catalog;

namespace SmartTrip.Application.Interfaces.Catalog;

public interface ICatalogService
{
    Task<CatalogHomeDto> GetHomeAsync();
    Task<CatalogHotelSearchResultDto> SearchHotelsAsync(
        string? query,
        int? destinationId,
        decimal? minPrice,
        decimal? maxPrice,
        double? minRating,
        string? starRatings,
        string? sort);
    Task<CatalogHotelDetailDto?> GetHotelDetailAsync(int hotelId);
    Task<CatalogRoomAvailabilityDto> GetRoomAvailabilityAsync(int roomId, DateOnly checkInDate, DateOnly checkOutDate, int quantity);
    Task<CatalogBusSearchResultDto> SearchBusesAsync(
        string? query,
        int? fromDestinationId,
        int? toDestinationId,
        decimal? minPrice,
        decimal? maxPrice,
        string? sort);
    Task<CatalogBusDetailDto?> GetBusDetailAsync(int scheduleId);
}
