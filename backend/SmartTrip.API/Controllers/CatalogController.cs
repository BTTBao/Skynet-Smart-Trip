using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.Interfaces.Catalog;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CatalogController : ControllerBase
{
    private readonly ICatalogService _catalogService;

    public CatalogController(ICatalogService catalogService)
    {
        _catalogService = catalogService;
    }

    [HttpGet("popular-destinations")]
    public async Task<IActionResult> GetPopularDestinations()
    {
        return Ok(await _catalogService.GetPopularDestinationsAsync());
    }

    [HttpGet("featured-hotels")]
    public async Task<IActionResult> GetFeaturedHotels()
    {
        return Ok(await _catalogService.GetFeaturedHotelsAsync());
    }

    [HttpGet("hotels")]
    public async Task<IActionResult> SearchHotels(
        [FromQuery] int? destinationId,
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] decimal? minPrice = null,
        [FromQuery] decimal? maxPrice = null,
        [FromQuery] int? starRating = null,
        [FromQuery] string? sort = null)
    {
        return Ok(await _catalogService.SearchHotelsAsync(destinationId, query, page, pageSize, minPrice, maxPrice, starRating, sort));
    }

    [HttpGet("hotels/{hotelId:int}")]
    public async Task<IActionResult> GetHotelDetail(int hotelId)
    {
        var hotel = await _catalogService.GetHotelDetailAsync(hotelId);
        return hotel is null ? NotFound() : Ok(hotel);
    }

    [HttpGet("featured-buses")]
    public async Task<IActionResult> GetFeaturedBuses()
    {
        return Ok(await _catalogService.GetFeaturedBusesAsync());
    }

    [HttpGet("buses")]
    public async Task<IActionResult> SearchBuses(
        [FromQuery] int? fromDestinationId,
        [FromQuery] int? toDestinationId,
        [FromQuery] DateTime? departureDate,
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] decimal? minPrice = null,
        [FromQuery] decimal? maxPrice = null,
        [FromQuery] string? sort = null)
    {
        return Ok(await _catalogService.SearchBusesAsync(fromDestinationId, toDestinationId, departureDate, query, page, pageSize, minPrice, maxPrice, sort));
    }

    [HttpGet("buses/{scheduleId:int}")]
    public async Task<IActionResult> GetBusDetail(int scheduleId)
    {
        var schedule = await _catalogService.GetBusDetailAsync(scheduleId);
        return schedule is null ? NotFound() : Ok(schedule);
    }

    [HttpGet("promotions")]
    public async Task<IActionResult> GetPromotions()
    {
        return Ok(await _catalogService.GetPromotionsAsync());
    }

    [HttpGet("promotions/validate/{code}")]
    public async Task<IActionResult> ValidatePromotion(string code)
    {
        var result = await _catalogService.ValidatePromotionAsync(code);
        if (result == null)
        {
            return NotFound(new { message = "Mã khuyến mãi không hợp lệ hoặc đã hết hạn." });
        }

        return Ok(result);
    }

    [HttpGet("vehicle-rentals")]
    public async Task<IActionResult> SearchVehicleRentalShops(
        [FromQuery] string? query,
        [FromQuery] int? destinationId,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string? vehicleType,
        [FromQuery] string? sort)
    {
        return Ok(await _catalogService.SearchVehicleRentalShopsAsync(
            query,
            destinationId,
            minPrice,
            maxPrice,
            vehicleType,
            sort));
    }

    [HttpGet("vehicle-rentals/{shopId:int}")]
    public async Task<IActionResult> GetVehicleRentalShopDetail(int shopId)
    {
        var shop = await _catalogService.GetVehicleRentalShopDetailAsync(shopId);
        return shop is null ? NotFound() : Ok(shop);
    }
}
