using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SmartTrip.Application.Interfaces.Email;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/trips")]
public class TripController : ControllerBase
{
    private readonly ITripService _tripService;
    private readonly IItineraryService _itineraryService;
    private readonly ITripServiceOptionService _optionService;
    private readonly ApplicationDbContext _context;
    private readonly IEmailService _emailService;

    public TripController(
        ITripService tripService,
        IItineraryService itineraryService,
        ITripServiceOptionService optionService,
        ApplicationDbContext context,
        IEmailService emailService)
    {
        _tripService = tripService;
        _itineraryService = itineraryService;
        _optionService = optionService;
        _context = context;
        _emailService = emailService;
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


    [HttpPost("{tripId:int}/fake-payment")]
    public async Task<IActionResult> CompleteFakePayment(int tripId, [FromBody] CreateFakePaymentDto request)
    {
        try
        {
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
            var trip = await _context.Trips
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

            // Send booking confirmation email asynchronously
            _ = Task.Run(async () =>
            {
                try
                {
                    // Create a new scope to safely access DbContext inside a background task
                    using (var scope = HttpContext.RequestServices.CreateScope())
                    {
                        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                        var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

                        var dbTrip = await dbContext.Trips.FirstOrDefaultAsync(t => t.Id == tripId);
                        if (dbTrip == null) return;

                        var user = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == dbTrip.UserId);
                        if (user != null && !string.IsNullOrWhiteSpace(user.Email))
                        {
                            var bookingCode = $"ST{dbTrip.Id}";
                            var hotelName = dbTrip.Title ?? "Khách sạn & Resort";
                            var dateRange = dbTrip.StartDate.HasValue && dbTrip.EndDate.HasValue 
                                ? $"{dbTrip.StartDate.Value:dd/MM/yyyy} - {dbTrip.EndDate.Value:dd/MM/yyyy}"
                                : "Chi tiết hành trình";
                            var roomInfo = "Chi tiết phòng và các dịch vụ xem tại ứng dụng di động SmartTrip";
                            var totalPrice = $"{dbTrip.TotalAmount:N0}đ";
                            var paymentMethodName = request.PaymentMethod == "Momo" ? "Ví điện tử MoMo" 
                                                   : request.PaymentMethod == "Zalopay" ? "Ví điện tử ZaloPay" 
                                                   : request.PaymentMethod == "Promotion" ? "Khuyến mãi (0đ)"
                                                   : "Thẻ ngân hàng";

                            await emailService.SendBookingConfirmationEmailAsync(
                                user.Email,
                                user.FullName ?? user.Email,
                                bookingCode,
                                hotelName,
                                dateRange,
                                roomInfo,
                                totalPrice,
                                paymentMethodName
                            );
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Email Error] Failed to send booking confirmation email for trip {tripId}: {ex.Message}");
                }
            });

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
}

public class ConfirmPaymentDto
{
    public string PaymentMethod { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public List<string>? SelectedSeats { get; set; }
}

