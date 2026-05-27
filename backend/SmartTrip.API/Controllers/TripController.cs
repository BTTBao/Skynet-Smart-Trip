using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces.Trip;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/trips")]
public class TripController : ControllerBase
{
    private readonly ITripService _tripService;
    private readonly IItineraryService _itineraryService;
    private readonly ITripServiceOptionService _optionService;
    private readonly IApplicationDbContext _context;

    public TripController(
        ITripService tripService,
        IItineraryService itineraryService,
        ITripServiceOptionService optionService,
        IApplicationDbContext context)
    {
        _tripService = tripService;
        _itineraryService = itineraryService;
        _optionService = optionService;
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetTrips()
    {
        try
        {
            var userId = GetCurrentUserId();
            var trips = await _tripService.GetTripsByUserAsync(userId);
            return Ok(trips);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{tripId:int}")]
    public async Task<IActionResult> GetTripById(int tripId)
    {
        try
        {
            var trip = await _tripService.GetTripByIdAsync(tripId);
            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            if (trip.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            return Ok(trip);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateTrip([FromBody] CreateTripDto request)
    {
        try
        {
            request.UserId = GetCurrentUserId();
            var trip = await _tripService.CreateTripAsync(request);
            return CreatedAtAction(nameof(GetTripById), new { tripId = trip.TripId }, trip);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost("{tripId:int}/itineraries")]
    public async Task<IActionResult> AddItinerary(int tripId, [FromBody] CreateTripItineraryDto request)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            var itinerary = await _itineraryService.AddItineraryAsync(tripId, request);
            return CreatedAtAction(nameof(GetTripById), new { tripId }, itinerary);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPut("{tripId:int}")]
    public async Task<IActionResult> UpdateTrip(int tripId, [FromBody] UpdateTripDto request)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            var trip = await _tripService.UpdateTripAsync(tripId, request);
            return Ok(trip);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPut("itineraries/{itineraryId:int}")]
    public async Task<IActionResult> UpdateItinerary(int itineraryId, [FromBody] UpdateTripItineraryDto request)
    {
        try
        {
            if (!await UserOwnsItineraryAsync(itineraryId))
            {
                return Forbid();
            }

            var itinerary = await _itineraryService.UpdateItineraryAsync(itineraryId, request);
            return Ok(itinerary);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpDelete("itineraries/{itineraryId:int}")]
    public async Task<IActionResult> DeleteItinerary(int itineraryId)
    {
        try
        {
            if (!await UserOwnsItineraryAsync(itineraryId))
            {
                return Forbid();
            }

            var result = await _itineraryService.DeleteItineraryAsync(itineraryId);
            if (!result)
            {
                return NotFound(new { message = $"Itinerary {itineraryId} was not found." });
            }

            return NoContent();
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("service-options")]
    public async Task<IActionResult> GetServiceOptions([FromQuery] string serviceType, [FromQuery] int? destinationId)
    {
        try
        {
            var options = await _optionService.GetServiceOptionsAsync(serviceType, destinationId);
            return Ok(options);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private int GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            User.FindFirstValue("sub");

        if (!int.TryParse(rawUserId, out var userId) || userId <= 0)
        {
            throw new UnauthorizedAccessException("Invalid user token.");
        }

        return userId;
    }

    private Task<bool> UserOwnsTripAsync(int tripId)
    {
        var userId = GetCurrentUserId();
        return _context.Trips.AnyAsync(trip => trip.Id == tripId && trip.UserId == userId);
    }

    private Task<bool> UserOwnsItineraryAsync(int itineraryId)
    {
        var userId = GetCurrentUserId();
        return _context.TripItineraries
            .AnyAsync(itinerary => itinerary.Id == itineraryId &&
                itinerary.Trip != null &&
                itinerary.Trip.UserId == userId);
    }
}
