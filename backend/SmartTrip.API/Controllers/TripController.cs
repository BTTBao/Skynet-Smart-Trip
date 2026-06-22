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
        ApplicationDbContext context,
        INotificationService notificationService,
        ILogger<TripController> logger,
        IEmailService emailService)
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

    [HttpGet("shared/{shareCode}")]
    public async Task<IActionResult> GetTripByShareCode(string shareCode)
    {
        try
        {
            var trip = await _tripService.GetTripByShareCodeAsync(shareCode, GetCurrentUserId());
            if (trip == null)
            {
                return NotFound(new { message = "Shared trip was not found." });
            }

            return Ok(trip);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("shared/{shareCode}/save")]
    public async Task<IActionResult> SaveSharedTrip(string shareCode)
    {
        try
        {
            var trip = await _tripService.SaveSharedTripAsync(shareCode, GetCurrentUserId());
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
            var currentUser = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(user => user.Id == GetCurrentUserId());
            if (currentUser == null)
            {
                return Unauthorized();
            }

            var missingProfileFields = GetMissingHotelBookingProfileFields(currentUser);
            if (missingProfileFields.Count > 0)
            {
                return Conflict(new
                {
                    code = "PROFILE_INCOMPLETE",
                    message = "Vui long hoan tat ho so truoc khi dat phong.",
                    missingFields = missingProfileFields
                });
            }

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

                var guestCapacityError = ValidateHotelGuestCapacity(
                    room.Capacity.GetValueOrDefault(1),
                    request.Quantity,
                    request.AdultCount,
                    request.ChildCount,
                    request.InfantCount);
                if (guestCapacityError != null)
                {
                    return BadRequest(new { message = guestCapacityError });
                }

                var nights = Math.Max(1, request.CheckOutDate.DayNumber - request.CheckInDate.DayNumber);
                var extraGuestCount = Math.Max(
                    0,
                    request.AdultCount + request.ChildCount -
                    room.Capacity.GetValueOrDefault(1) * request.Quantity);
                var roomPrice = room.PricePerNight.GetValueOrDefault();
                var totalRoomPrice =
                    roomPrice * nights * request.Quantity +
                    roomPrice * 0.2m * nights * extraGuestCount;
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
                    AdultCount = request.AdultCount,
                    ChildCount = request.ChildCount,
                    InfantCount = request.InfantCount,
                    BookedPrice = totalRoomPrice / request.Quantity,
                    BookedCommissionRate = room.Hotel?.CommissionRate ?? room.CommissionRate,
                    ServiceDate = request.CheckInDate,
                    HotelCheckOutDate = request.CheckOutDate
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

            if (string.Equals(request.ServiceType, "HOTEL", StringComparison.OrdinalIgnoreCase))
            {
                var currentUser = await _context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(user => user.Id == GetCurrentUserId());
                if (currentUser == null)
                {
                    return Unauthorized();
                }

                var missingProfileFields = GetMissingHotelBookingProfileFields(currentUser);
                if (missingProfileFields.Count > 0)
                {
                    return Conflict(new
                    {
                        code = "PROFILE_INCOMPLETE",
                        message = "Vui long hoan tat ho so truoc khi dat phong.",
                        missingFields = missingProfileFields
                    });
                }
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

    [HttpDelete("{tripId:int}")]
    public async Task<IActionResult> DeleteTrip(int tripId)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            await _tripService.DeleteTripAsync(tripId, GetCurrentUserId());
            return NoContent();
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
                .Include(t => t.Payments)
                .Include(t => t.Invoices)
                .FirstOrDefaultAsync(t => t.Id == tripId);

            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            var totalPaidAmountSoFar = trip.Payments
                .Where(p => p.Status == PaymentStatus.Paid)
                .Sum(p => p.Amount ?? 0m);

            var totalRequired = trip.TotalAmount ?? 0m;

            if (totalPaidAmountSoFar >= totalRequired && trip.Invoices.Any())
            {
                return Ok(new
                {
                    message = "Booking da duoc thanh toan va phat hanh hoa don.",
                    tripId = trip.Id,
                    status = "PAID",
                    alreadyPaid = true
                });
            }

            if (request.Amount < 0)
            {
                return BadRequest(new { message = "So tien thanh toan khong hop le." });
            }

            // Parse payment method
            if (!Enum.TryParse<PaymentMethod>(request.PaymentMethod, true, out var method))
            {
                method = PaymentMethod.Card;
            }
            if (request.Amount == 0 && method != PaymentMethod.Promotion)
            {
                return BadRequest(new { message = "Thanh toan 0 dong chi hop le khi dung khuyen mai." });
            }
            var paymentAmount = request.Amount;
            var payment = new Payment
            {
                TripId = tripId,
                PaymentMethod = method,
                TransactionId = string.IsNullOrWhiteSpace(request.TransactionId) 
                    ? $"PAY-{tripId}-{DateTime.UtcNow:yyyyMMddHHmmss}" 
                    : request.TransactionId,
                Amount = paymentAmount,
                Status = PaymentStatus.Paid,
    public async Task<IActionResult> AddItinerary(int tripId, [FromBody] CreateTripItineraryDto request)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            if (string.Equals(request.ServiceType, "HOTEL", StringComparison.OrdinalIgnoreCase))
            {
                var currentUser = await _context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(user => user.Id == GetCurrentUserId());
                if (currentUser == null)
                {
                    return Unauthorized();
                }

                var missingProfileFields = GetMissingHotelBookingProfileFields(currentUser);
                if (missingProfileFields.Count > 0)
                {
                    return Conflict(new
                    {
                        code = "PROFILE_INCOMPLETE",
                        message = "Vui long hoan tat ho so truoc khi dat phong.",
                        missingFields = missingProfileFields
                    });
                }
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
                .Include(t => t.Payments)
                .Include(t => t.Invoices)
                .FirstOrDefaultAsync(t => t.Id == tripId);

            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            var totalPaidAmountSoFar = trip.Payments
                .Where(p => p.Status == PaymentStatus.Paid)
                .Sum(p => p.Amount ?? 0m);

            var totalRequired = trip.TotalAmount ?? 0m;

            if (totalPaidAmountSoFar >= totalRequired && trip.Invoices.Any())
            {
                return Ok(new
                {
                    message = "Booking da duoc thanh toan va phat hanh hoa don.",
                    tripId = trip.Id,
                    status = "PAID",
                    alreadyPaid = true
                });
            }

            if (request.Amount < 0)
            {
                return BadRequest(new { message = "So tien thanh toan khong hop le." });
            }

            // Parse payment method
            if (!Enum.TryParse<PaymentMethod>(request.PaymentMethod, true, out var method))
            {
                method = PaymentMethod.Card;
            }
            if (request.Amount == 0 && method != PaymentMethod.Promotion)
            {
                return BadRequest(new { message = "Thanh toan 0 dong chi hop le khi dung khuyen mai." });
            }
            var paymentAmount = request.Amount;
            var payment = new Payment
            {
                TripId = tripId,
                PaymentMethod = method,
                TransactionId = string.IsNullOrWhiteSpace(request.TransactionId) 
                    ? $"PAY-{tripId}-{DateTime.UtcNow:yyyyMMddHHmmss}" 
                    : request.TransactionId,
                Amount = paymentAmount,
                Status = PaymentStatus.Paid,
                PaidAt = DateTime.UtcNow,
                MetadataJson = request.UsedCoins.HasValue && request.UsedCoins.Value > 0
                    ? $"{{\"usedCoins\": {request.UsedCoins.Value}}}"
                    : null
            };

            _context.Payments.Add(payment);

            var newTotalPaid = totalPaidAmountSoFar + paymentAmount;
            var isFullyPaid = newTotalPaid >= totalRequired;

            // Deduct used coins
            if (request.UsedCoins.HasValue && request.UsedCoins.Value > 0 && trip.UserId.HasValue)
            {
                var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == trip.UserId.Value);
                if (wallet != null)
                {
                    wallet.LoyaltyPoints = Math.Max(0, (wallet.LoyaltyPoints ?? 0) - request.UsedCoins.Value);
                }
            }

            // Reward loyalty points (1% of actual paid cash amount)
            if (paymentAmount > 0 && trip.UserId.HasValue)
            {
                var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == trip.UserId.Value);
                if (wallet == null)
                {
                    wallet = new UserWallet
                    {
                        UserId = trip.UserId.Value,
                        Balance = 0m,
                        LoyaltyPoints = 0
                    };
                    _context.UserWallets.Add(wallet);
                }
                int earnedCoins = (int)(paymentAmount / 100000m);
                if (earnedCoins > 0)
                {
                    wallet.LoyaltyPoints = (wallet.LoyaltyPoints ?? 0) + earnedCoins;
                }
            }

            if (trip.Status != TripStatus.BookingOnly)
            {
                trip.Status = TripStatus.Paid;
            }
            trip.TotalProfit = CalculateTripProfitFromPaidAmount(trip, newTotalPaid);

            if (isFullyPaid)
            {
                var invoice = new Invoice
                {
                    TripId = tripId,
                    InvoiceNumber = $"INV-{DateTime.UtcNow:yyyyMMdd}-{tripId:D6}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}",
                    TaxAmount = 0,
                    IssuedAt = DateTime.UtcNow
                };
                _context.Invoices.Add(invoice);
            }

            // If it is a BUS booking, book the corresponding seats!
            var busItinerary = trip.TripItineraries
                .FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
            if (busItinerary != null && busItinerary.ServiceId.HasValue)
            {
                var scheduleId = request.ScheduleId ?? busItinerary.ServiceId.Value;
                if (request.ScheduleId.HasValue && !trip.TripItineraries.Any(i =>
                             i.ServiceType == TripServiceType.Bus &&
                             i.ServiceId == scheduleId))
                {
                    return BadRequest(new { message = "Schedule does not belong to this trip." });
                }

                var lockedSeats = await _context.Seats
                    .Where(s => s.ScheduleId == scheduleId && s.LockedByTripId == tripId)
                    .ToListAsync();

                if (!lockedSeats.Any())
                {
                    var seatNumbersStr = busItinerary.SelectedSeats ?? (request.SelectedSeats != null ? string.Join(",", request.SelectedSeats) : "");
                    if (!string.IsNullOrEmpty(seatNumbersStr))
                    {
                        var seatNumbers = seatNumbersStr.Split(',', StringSplitOptions.RemoveEmptyEntries)
                            .Select(s => s.Trim())
                            .ToList();

                        lockedSeats = await _context.Seats
                            .Where(s => s.ScheduleId == scheduleId && s.SeatNumber != null && seatNumbers.Contains(s.SeatNumber))
                            .ToListAsync();
                    }
                }

                foreach (var seat in lockedSeats)
                {
                    seat.Status = SeatStatus.Booked;
                    seat.LockedUntil = null;
                    seat.LockedByTripId = null;
                }
            }

            await _context.SaveChangesAsync();

            try
            {
                var isBusBooking = busItinerary != null;
                await _notificationService.CreateAsync(new CreateNotificationDto
                {
                    UserId = trip.UserId ?? 0,
                    Title = isBusBooking ? "Đặt vé xe thành công" : "Đặt phòng thành công",
                    Message = isBusBooking
                        ? $"Vé xe \"{trip.Title ?? "booking"}\" đã được thanh toán và lưu vào lịch sử hoạt động."
                        : $"Đặt phòng \"{trip.Title ?? "booking"}\" đã được thanh toán và lưu vào lịch sử hoạt động.",
                    Type = isBusBooking ? "booking.bus_paid" : "booking.hotel_paid",
                    ReferenceType = "booking",
                    ReferenceId = trip.Id,
                    ActionUrl = isFullyPaid ? $"/activity/invoices/{trip.Id}" : $"/trips/{trip.Id}"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create booking notification for trip {TripId}", trip.Id);
            }

             // Send booking confirmation email asynchronously
             if (isFullyPaid)
             {
                 _ = Task.Run(async () =>
                 {
                     try
                     {
                         // Create a new scope to safely access DbContext inside a background task
                         using (var scope = HttpContext.RequestServices.CreateScope())
                         {
                             var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                             var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
 
                             var dbTrip = await dbContext.Trips
                                 .Include(t => t.Destination)
                                 .Include(t => t.TripItineraries)
                                 .FirstOrDefaultAsync(t => t.Id == tripId);
                             if (dbTrip == null) return;
 
                             var user = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == dbTrip.UserId);
                             if (user != null && !string.IsNullOrWhiteSpace(user.Email))
                             {
                                 var bookingCode = $"SKN-{dbTrip.Id:D6}";
                                 
                                 var busItinerary = dbTrip.TripItineraries
                                     .FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
                                     
                                 if (busItinerary != null && busItinerary.ServiceId.HasValue)
                                 {
                                     var schedule = await dbContext.BusSchedules
                                         .Include(s => s.Company)
                                         .Include(s => s.FromDest)
                                         .Include(s => s.ToDest)
                                         .FirstOrDefaultAsync(s => s.Id == busItinerary.ServiceId.Value);
                                         
                                     var companyName = schedule?.Company?.Name ?? dbTrip.Title?.Replace("Vé xe: ", "") ?? "Nhà xe SmartTrip";
                                     var fromDest = schedule?.FromDest?.Name ?? "N/A";
                                     var toDest = schedule?.ToDest?.Name ?? dbTrip.Destination?.Name ?? "N/A";
                                     var departure = schedule?.DepartureTime?.ToString("dd/MM/yyyy HH:mm") ?? "N/A";
                                     var arrival = schedule?.ArrivalTime?.ToString("dd/MM/yyyy HH:mm") ?? "N/A";
                                     var seats = busItinerary.SelectedSeats ?? "N/A";
                                     var totalPrice = $"{dbTrip.TotalAmount:N0}đ";
                                     
                                     await emailService.SendBusBookingConfirmationEmailAsync(
                                         user.Email,
                                         user.FullName ?? user.Email,
                                         bookingCode,
                                         companyName,
                                         fromDest,
                                         toDest,
                                         departure,
                                         arrival,
                                         seats,
                                         totalPrice
                                     );
                                 }
                                 else
                                 {
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
                     }
                     catch (Exception ex)
                     {
                         Console.WriteLine($"[Email Error] Failed to send booking confirmation email for trip {tripId}: {ex.Message}");
                     }
                 });
             }

            return Ok(new { message = "Thanh toán thành công.", tripId = trip.Id, status = "PAID" });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{tripId:int}/cancel-booking")]
    public async Task<IActionResult> CancelBooking(int tripId)
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
                .Include(t => t.Payments)
                .FirstOrDefaultAsync(t => t.Id == tripId);

            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            if (trip.Status == TripStatus.Cancelled)
            {
                return BadRequest(new { message = "Đơn đặt chỗ này đã bị hủy trước đó." });
            }

            if (trip.Status != TripStatus.BookingOnly)
            {
                return BadRequest(new { message = "Chỉ hỗ trợ hủy đơn đặt phòng khách sạn." });
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow.AddHours(7));
            var checkInDate = trip.StartDate ?? today;

            if (today >= checkInDate)
            {
                return BadRequest(new { message = "Không thể hủy đặt phòng khi đã đến ngày nhận phòng hoặc phòng đã sử dụng." });
            }
            
            // Calculate refund eligibility: check-in date must be at least 2 days in the future (more than 24 hours from check-in day)
            var canRefund = checkInDate >= today.AddDays(2);

            var totalPaid = trip.Payments
                .Where(p => p.Status == PaymentStatus.Paid)
                .Sum(p => p.Amount ?? 0m);

            decimal refundAmount = 0m;
            int totalUsedCoinsRefund = 0;
            int totalEarnedCoinsDeduct = 0;

            if (canRefund && totalPaid > 0)
            {
                refundAmount = totalPaid;

                foreach (var p in trip.Payments.Where(pm => pm.Status == PaymentStatus.Paid))
                {
                    // Calculate earned coins that need to be deducted (1% of actual paid cash amount)
                    int earned = (int)((p.Amount ?? 0m) / 100000m);
                    totalEarnedCoinsDeduct += earned;

                    // Calculate used coins that need to be refunded
                    if (!string.IsNullOrEmpty(p.MetadataJson))
                    {
                        try
                        {
                            using var doc = System.Text.Json.JsonDocument.Parse(p.MetadataJson);
                            if (doc.RootElement.TryGetProperty("usedCoins", out var usedElement))
                            {
                                totalUsedCoinsRefund += usedElement.GetInt32();
                            }
                        }
                        catch
                        {
                            // Ignore parsing issues
                        }
                    }
                }
            }

            // Perform wallet refund if there's a refund amount
            if (refundAmount > 0)
            {
                var wallet = await _context.UserWallets.FirstOrDefaultAsync(w => w.UserId == trip.UserId);
                if (wallet == null)
                {
                    wallet = new UserWallet
                    {
                        UserId = trip.UserId,
                        Balance = 0m,
                        LoyaltyPoints = 0
                    };
                    _context.UserWallets.Add(wallet);
                }

                wallet.Balance = (wallet.Balance ?? 0m) + refundAmount;
                
                // Refund used coins and deduct earned coins
                wallet.LoyaltyPoints = (wallet.LoyaltyPoints ?? 0) + totalUsedCoinsRefund;
                wallet.LoyaltyPoints = Math.Max(0, (wallet.LoyaltyPoints ?? 0) - totalEarnedCoinsDeduct);

                // Log the refund transaction
                var refundPayment = new Payment
                {
                    TripId = tripId,
                    Amount = -refundAmount,
                    PaymentMethod = PaymentMethod.Card,
                    Status = PaymentStatus.Refunded,
                    TransactionId = $"REFUND-{tripId}-{DateTime.UtcNow:yyyyMMddHHmmss}",
                    Description = $"Hoàn tiền hủy đặt phòng #{tripId}",
                    PaidAt = DateTime.UtcNow
                };
                _context.Payments.Add(refundPayment);
            }

            // Release bus seats if any
            var busItinerary = trip.TripItineraries.FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
            if (busItinerary != null && busItinerary.ServiceId.HasValue && !string.IsNullOrEmpty(busItinerary.SelectedSeats))
            {
                var seatNumbers = busItinerary.SelectedSeats.Split(',', StringSplitOptions.RemoveEmptyEntries)
                    .Select(s => s.Trim())
                    .ToList();
                var seats = await _context.Seats
                    .Where(s => s.ScheduleId == busItinerary.ServiceId.Value && s.SeatNumber != null && seatNumbers.Contains(s.SeatNumber))
                    .ToListAsync();
                foreach (var seat in seats)
                {
                    seat.Status = SeatStatus.Available;
                    seat.LockedUntil = null;
                    seat.LockedByTripId = null;
                }
            }

            trip.Status = TripStatus.Cancelled;
            await _context.SaveChangesAsync();

            // Create notification
            try
            {
                await _notificationService.CreateAsync(new CreateNotificationDto
                {
                    UserId = trip.UserId ?? 0,
                    Title = "Hủy đặt phòng thành công",
                    Message = refundAmount > 0
                        ? $"Đặt phòng \"{trip.Title}\" đã được hủy. Đã hoàn {refundAmount:N0}đ vào ví của bạn."
                        : $"Đặt phòng \"{trip.Title}\" đã được hủy. Bạn không được hoàn tiền do hủy sát giờ.",
                    Type = "booking.cancelled",
                    ReferenceType = "booking",
                    ReferenceId = trip.Id,
                    ActionUrl = $"/trips/{trip.Id}"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send cancellation notification for trip {TripId}", trip.Id);
            }

            // Send cancellation email
            try
            {
                var user = trip.User ?? await _context.Users.FirstOrDefaultAsync(u => u.Id == trip.UserId);
                if (user != null && !string.IsNullOrWhiteSpace(user.Email))
                {
                    await _emailService.SendBookingStatusChangedEmailAsync(
                        user.Email,
                        user.FullName ?? user.Email,
                        trip.Title ?? $"Booking #{trip.Id}",
                        refundAmount > 0 ? $"Đã hủy & Hoàn tiền {refundAmount:N0}đ vào ví" : "Đã hủy (Không hoàn cọc)",
                        trip.TotalAmount
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send cancellation email for trip {TripId}", trip.Id);
            }

            return Ok(new 
            { 
                message = "Hủy phòng thành công.", 
                refunded = refundAmount > 0, 
                refundAmount = refundAmount, 
                status = "CANCELLED" 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{tripId:int}/re-lock-seats")]
    public async Task<IActionResult> ReLockSeats(int tripId)
    {
        try
        {
            if (!await UserOwnsTripAsync(tripId))
            {
                return Forbid();
            }

            var trip = await _context.Trips
                .Include(t => t.TripItineraries)
                .FirstOrDefaultAsync(t => t.Id == tripId);

            if (trip == null)
            {
                return NotFound(new { message = $"Trip {tripId} was not found." });
            }

            var busItinerary = trip.TripItineraries
                .FirstOrDefault(i => i.ServiceType == TripServiceType.Bus);
            if (busItinerary == null || !busItinerary.ServiceId.HasValue || string.IsNullOrEmpty(busItinerary.SelectedSeats))
            {
                return BadRequest(new { message = "Chuyến đi không chứa thông tin đặt ghế xe khách." });
            }

            var scheduleId = busItinerary.ServiceId.Value;
            var seatNumbers = busItinerary.SelectedSeats.Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim())
                .ToList();

            if (!seatNumbers.Any())
            {
                return BadRequest(new { message = "Không tìm thấy danh sách số ghế." });
            }

            var seats = await _context.Seats
                .Where(s => s.ScheduleId == scheduleId && s.SeatNumber != null && seatNumbers.Contains(s.SeatNumber))
                .ToListAsync();

            foreach (var seatNum in seatNumbers)
            {
                var seat = seats.FirstOrDefault(s => s.SeatNumber == seatNum);
                if (seat == null)
                {
                    return NotFound(new { message = $"Ghế {seatNum} không tồn tại trên tuyến xe này." });
                }

                if (seat.Status == SeatStatus.Booked)
                {
                    return BadRequest(new { message = $"Ghế {seatNum} đã được đặt trước bởi hành khách khác." });
                }

                if (seat.Status == SeatStatus.Locked && seat.LockedUntil.HasValue && seat.LockedUntil.Value > DateTime.UtcNow && seat.LockedByTripId != tripId)
                {
                    return BadRequest(new { message = $"Ghế {seatNum} đang được giữ bởi người khác. Vui lòng đặt vé mới." });
                }
            }

            foreach (var seat in seats)
            {
                seat.Status = SeatStatus.Locked;
                seat.LockedUntil = DateTime.UtcNow.AddMinutes(10);
                seat.LockedByTripId = tripId;
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Giữ ghế thành công.", lockedUntil = DateTime.UtcNow.AddMinutes(10) });
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

    private static List<string> GetMissingHotelBookingProfileFields(User user)
    {
        var missingFields = new List<string>();

        if (string.IsNullOrWhiteSpace(user.FullName))
        {
            missingFields.Add("name");
        }

        var phone = user.Phone?.Trim();
        if (string.IsNullOrWhiteSpace(phone) ||
            phone.Length < 10 ||
            phone.Length > 11 ||
            !phone.All(char.IsDigit))
        {
            missingFields.Add("phone");
        }

        if (!user.BirthDate.HasValue || user.BirthDate.Value.Date >= DateTime.UtcNow.Date)
        {
            missingFields.Add("birthDate");
        }

        var identityNumber = user.IdentityNumber?.Trim();
        if (string.IsNullOrWhiteSpace(identityNumber) ||
            (identityNumber.Length != 9 && identityNumber.Length != 12) ||
            !identityNumber.All(char.IsDigit))
        {
            missingFields.Add("identityNumber");
        }

        if (string.IsNullOrWhiteSpace(user.IdentityCardPhotoUrl))
        {
            missingFields.Add("identityCardPhoto");
        }

        return missingFields;
    }

    private static string? ValidateHotelGuestCapacity(
        int roomCapacity,
        int roomQuantity,
        int adultCount,
        int childCount,
        int infantCount)
    {
        if (roomQuantity <= 0 || childCount < 0 || infantCount < 0)
        {
            return "So luong phong hoac khach khong hop le.";
        }
        if (adultCount < roomQuantity)
        {
            return "Moi phong phai co it nhat mot nguoi lon.";
        }

        var capacity = Math.Max(roomCapacity, 1);
        var maximumCapacity = (capacity + 1) * roomQuantity;
        if (adultCount + childCount > maximumCapacity)
        {
            return $"Toi da {maximumCapacity} khach cho {roomQuantity} phong, bao gom toi da 1 khach phu thu moi phong.";
        }
        if (infantCount > roomQuantity)
        {
            return "Moi phong chi duoc khai bao toi da mot em be duoi 2 tuoi.";
        }

        return null;
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

    private static decimal CalculateTripProfitFromPaidAmount(Trip trip, decimal paidAmount)
    {
        if (paidAmount <= 0 || trip.TripItineraries.Count == 0)
        {
            return 0m;
        }

        var grossAmount = trip.TripItineraries.Sum(item =>
            item.BookedPrice.GetValueOrDefault() * item.Quantity.GetValueOrDefault(1));

        if (grossAmount <= 0)
        {
            return 0m;
        }

        return trip.TripItineraries.Sum(item =>
        {
            var lineGross = item.BookedPrice.GetValueOrDefault() * item.Quantity.GetValueOrDefault(1);
            var paidLineAmount = paidAmount * lineGross / grossAmount;
            return paidLineAmount * NormalizeCommissionRate(item.BookedCommissionRate);
        });
    }

    private static decimal NormalizeCommissionRate(double? rate)
    {
        var value = (decimal)(rate ?? 0d);
        return value > 1m ? value / 100m : value;
    }
}

public class ConfirmPaymentDto
{
    public string PaymentMethod { get; set; } = string.Empty;
    public string TransactionId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int? ScheduleId { get; set; }
    public List<string>? SelectedSeats { get; set; }
    public bool IsDeposit { get; set; }
    public int? UsedCoins { get; set; }
}
