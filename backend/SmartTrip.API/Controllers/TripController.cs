using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/trips")]
public class TripController : ControllerBase
{
    private readonly ITripService _tripService;
    private readonly IItineraryService _itineraryService;
    private readonly ITripServiceOptionService _optionService;
    private readonly INotificationService _notificationService;
    private readonly IEmailService _emailService;
    private readonly ILogger<TripController> _logger;
    private readonly ApplicationDbContext _context;

    public TripController(
        ITripService tripService,
        IItineraryService itineraryService,
        ITripServiceOptionService optionService,
        INotificationService notificationService,
        IEmailService emailService,
        ILogger<TripController> logger,
        ApplicationDbContext context)
    {
        _tripService = tripService;
        _itineraryService = itineraryService;
        _optionService = optionService;
        _notificationService = notificationService;
        _emailService = emailService;
        _logger = logger;
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
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("hotel-bookings")]
    public async Task<IActionResult> CreateHotelBooking([FromBody] CreateHotelBookingDto request)
    {
        try
        {
            var strategy = _context.Database.CreateExecutionStrategy();

            return await strategy.ExecuteAsync<IActionResult>(async () =>
            {
                await using var transaction = await _context.Database.BeginTransactionAsync();

                if (request.HotelId <= 0)
                {
                    return BadRequest(new { message = "HotelId must be greater than 0." });
                }

                if (request.RoomId <= 0)
                {
                    return BadRequest(new { message = "RoomId must be greater than 0." });
                }

                var room = await _context.Rooms
                    .AsNoTracking()
                    .Include(item => item.Hotel)
                    .FirstOrDefaultAsync(item => item.Id == request.RoomId);

                if (room?.Hotel == null || room.HotelId != request.HotelId || room.Hotel.IsAvailable == false)
                {
                    return NotFound(new { message = "Room was not found for this hotel or is not available." });
                }

                var nights = Math.Max(1, request.CheckOutDate.DayNumber - request.CheckInDate.DayNumber);
                var trip = await _tripService.CreateTripAsync(new CreateTripDto
                {
                    UserId = GetCurrentUserId(),
                    DestinationId = request.DestinationId,
                    DestinationName = request.DestinationName,
                    Title = string.IsNullOrWhiteSpace(request.Title)
                        ? $"Hotel booking - {room.Hotel.Name}"
                        : request.Title,
                    StartDate = request.CheckInDate,
                    EndDate = request.CheckOutDate,
                    Status = "PENDING"
                });

                await _itineraryService.AddItineraryAsync(trip.TripId, new CreateTripItineraryDto
                {
                    DayNumber = 1,
                    ServiceType = "HOTEL",
                    ServiceId = request.RoomId,
                    Quantity = request.Quantity,
                    BookedPrice = (room.PricePerNight ?? 0) * nights,
                    BookedCommissionRate = room.CommissionRate,
                    ServiceDate = request.CheckInDate
                });

                await transaction.CommitAsync();

                var createdTrip = await _tripService.GetTripByIdAsync(trip.TripId);
                return CreatedAtAction(nameof(GetTripById), new { tripId = trip.TripId }, new TripSummaryDto
                {
                    TripId = trip.TripId,
                    UserId = trip.UserId,
                    DestinationId = trip.DestinationId,
                    DestinationName = trip.DestinationName,
                    DestinationDescription = trip.DestinationDescription,
                    DestinationCoverImageUrl = trip.DestinationCoverImageUrl,
                    Title = trip.Title,
                    StartDate = trip.StartDate,
                    EndDate = trip.EndDate,
                    TotalAmount = createdTrip?.TotalAmount ?? trip.TotalAmount,
                    TotalProfit = createdTrip?.TotalProfit ?? trip.TotalProfit,
                    Status = createdTrip?.Status ?? trip.Status,
                    CreatedAt = trip.CreatedAt,
                    ItineraryCount = createdTrip?.ItineraryCount ?? trip.ItineraryCount
                });
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("{tripId:int}/fake-payment")]
    public async Task<IActionResult> CompleteFakePayment(int tripId, [FromBody] CreateFakePaymentDto request)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            var trip = await _tripService.CompleteFakePaymentAsync(tripId, request);
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
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
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
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
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

    [HttpPost("{tripId:int}/pay")]
    public async Task<IActionResult> ConfirmPayment(int tripId, [FromBody] ConfirmPaymentDto request)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            var trip = await _context.Trips
                .Include(t => t.User)
                .Include(t => t.TripItineraries)
                .FirstOrDefaultAsync(t => t.Id == tripId);

            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            // Parse payment method
            if (!Enum.TryParse<PaymentMethod>(request.PaymentMethod, true, out var method))
            {
                method = PaymentMethod.Card;
            }

            var payment = new Payment
            {
                TripId = tripId,
                PaymentMethod = method,
                TransactionId = string.IsNullOrWhiteSpace(request.TransactionId) 
                    ? $"PAY-{tripId}-{DateTime.UtcNow:yyyyMMddHHmmss}" 
                    : request.TransactionId,
                Amount = request.Amount > 0 ? request.Amount : trip.TotalAmount,
                Status = PaymentStatus.Paid,
                PaidAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            trip.Status = TripStatus.Paid;

            // If it is a BUS booking, book the corresponding seats!
            if (request.SelectedSeats != null && request.SelectedSeats.Any())
            {
                var busItinerary = trip.TripItineraries
                    .FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
                if (busItinerary != null && busItinerary.ServiceId.HasValue)
                {
                    var scheduleId = busItinerary.ServiceId.Value;
                    var seatsToBook = await _context.Seats
                        .Where(s => s.ScheduleId == scheduleId && s.SeatNumber != null && request.SelectedSeats.Contains(s.SeatNumber))
                        .ToListAsync();
                    
                    foreach (var seat in seatsToBook)
                    {
                        seat.Status = SeatStatus.Booked;
                    }
                }
            }

            await _context.SaveChangesAsync();
            await TryNotifyConfirmedPaymentAsync(trip, payment);
            return Ok(new { message = "Thanh toán thành công.", tripId = trip.Id, status = "PAID" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private int GetCurrentUserId()
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (int.TryParse(userIdString, out var userId))
        {
            return userId;
        }
        throw new ArgumentException("User is not authenticated or invalid user ID.");
    }

    private async Task<bool> UserOwnsTripAsync(int tripId)
    {
        return await _context.Trips.AnyAsync(t => t.Id == tripId && t.UserId == GetCurrentUserId());
    }

    private async Task<bool> UserOwnsItineraryAsync(int itineraryId)
    {
        var itinerary = await _context.Trips
            .SelectMany(t => t.TripItineraries)
            .FirstOrDefaultAsync(i => i.Id == itineraryId);
            
        if (itinerary == null) return false;

        return await _context.Trips.AnyAsync(t => t.Id == itinerary.TripId && t.UserId == GetCurrentUserId());
    }

    private async Task TryNotifyConfirmedPaymentAsync(Trip trip, Payment payment)
    {
        if (!trip.UserId.HasValue || trip.UserId.Value <= 0)
        {
            return;
        }

        try
        {
            await _notificationService.CreateAsync(new CreateNotificationDto
            {
                UserId = trip.UserId.Value,
                Title = "Thanh toán thành công",
                Message = $"Thanh toán cho \"{trip.Title ?? "booking"}\" đã hoàn tất.",
                Type = "payment.succeeded",
                ReferenceType = "payment",
                ReferenceId = payment.Id,
                ActionUrl = $"/trips/{trip.Id}"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create payment notification for trip {TripId}", trip.Id);
        }

        try
        {
            var user = trip.User;
            if (user == null || !await _notificationService.AreEmailNotificationsEnabledAsync(user.Id))
            {
                return;
            }

            await _emailService.SendPaymentSuccessEmailAsync(
                user.Email,
                user.FullName ?? user.Email,
                trip.Title ?? "Booking SmartTrip",
                payment.Amount ?? 0m,
                payment.TransactionId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send payment success email for trip {TripId}", trip.Id);
        }
    }
}

public class ConfirmPaymentDto
{
    public string PaymentMethod { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public List<string>? SelectedSeats { get; set; }
}


