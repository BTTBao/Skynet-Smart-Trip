using SmartTrip.Application.DTOs.Catalog;

namespace SmartTrip.Application.Interfaces.Catalog;

public interface ICatalogService
{
    Task<List<CatalogDestinationDto>> GetPopularDestinationsAsync();
    Task<List<CatalogHotelCardDto>> GetFeaturedHotelsAsync();
    Task<CatalogHotelSearchResultDto> SearchHotelsAsync(
        int? destinationId,
        string? query,
        int page,
        int pageSize,
        decimal? minPrice,
        decimal? maxPrice,
        int? starRating,
        string? sort);
    Task<CatalogHotelDetailDto?> GetHotelDetailAsync(int hotelId);
    Task<List<CatalogBusCardDto>> GetFeaturedBusesAsync();
    Task<CatalogBusSearchResultDto> SearchBusesAsync(
        int? fromDestinationId,
        int? toDestinationId,
        DateTime? departureDate,
        string? query,
        int page,
        int pageSize,
        decimal? minPrice,
        decimal? maxPrice,
        string? sort);
    Task<CatalogBusDetailDto?> GetBusDetailAsync(int scheduleId);
    Task<CatalogPromotionDto?> ValidatePromotionAsync(string code);
    Task<List<CatalogPromotionDto>> GetPromotionsAsync();
    Task<CatalogVehicleRentalSearchResultDto> SearchVehicleRentalShopsAsync(
        string? query,
        int? destinationId,
        decimal? minPrice,
        decimal? maxPrice,
        string? vehicleType,
        string? sort);
    Task<CatalogVehicleRentalShopDetailDto?> GetVehicleRentalShopDetailAsync(int shopId);
}
