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

    [HttpGet("home")]
    public async Task<IActionResult> GetHome()
    {
        return Ok(await _catalogService.GetHomeAsync());
    }

    [HttpGet("hotels")]
    public async Task<IActionResult> SearchHotels(
        [FromQuery] string? query,
        [FromQuery] int? destinationId,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] double? minRating,
        [FromQuery] string? starRatings,
        [FromQuery] string? sort)
    {
        return Ok(await _catalogService.SearchHotelsAsync(
            query,
            destinationId,
            minPrice,
            maxPrice,
            minRating,
            starRatings,
            sort));
    }

    [HttpGet("hotels/{hotelId:int}")]
    public async Task<IActionResult> GetHotelDetail(int hotelId)
    {
        var hotel = await _catalogService.GetHotelDetailAsync(hotelId);
        return hotel is null ? NotFound() : Ok(hotel);
    }

    [HttpGet("rooms/{roomId:int}/availability")]
    public async Task<IActionResult> GetRoomAvailability(
        int roomId,
        [FromQuery] DateOnly checkInDate,
        [FromQuery] DateOnly checkOutDate,
        [FromQuery] int quantity = 1)
    {
        return Ok(await _catalogService.GetRoomAvailabilityAsync(roomId, checkInDate, checkOutDate, quantity));
    }

    [HttpGet("buses")]
    public async Task<IActionResult> SearchBuses(
        [FromQuery] string? query,
        [FromQuery] int? fromDestinationId,
        [FromQuery] int? toDestinationId,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string? sort)
    {
        return Ok(await _catalogService.SearchBusesAsync(
            query,
            fromDestinationId,
            toDestinationId,
            minPrice,
            maxPrice,
            sort));
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
}
