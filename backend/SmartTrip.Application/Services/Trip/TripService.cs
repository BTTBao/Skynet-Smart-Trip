using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces;
using SmartTrip.Application.Interfaces.Email;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using TripEntity = SmartTrip.Domain.Entities.Trip;

namespace SmartTrip.Application.Services.Trip;

public class TripService : ITripService
{
    private const string DraftStatus = "DRAFT";
    private const string PendingStatus = "PENDING";
    private const string PaidStatus = "PAID";
    private const string CancelledStatus = "CANCELLED";
    private const string BookingOnlyStatus = "BOOKING_ONLY";

    private readonly IApplicationDbContext _context;
    private readonly IItineraryService _itineraryService;
    private readonly INotificationService _notificationService;
    private readonly IEmailService _emailService;
    private readonly ILogger<TripService> _logger;

    public TripService(
        IApplicationDbContext context,
        IItineraryService itineraryService,
        INotificationService notificationService,
        IEmailService emailService,
        ILogger<TripService> logger)
    {
        _context = context;
        _itineraryService = itineraryService;
        _notificationService = notificationService;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<IReadOnlyList<TripSummaryDto>> GetTripsByUserAsync(int userId)
    {
        if (userId <= 0)
        {
            throw new ArgumentException("UserId must be greater than 0.");
        }

        var trips = await _context.Trips
            .AsNoTracking()
            .Where(trip => trip.UserId == userId && trip.Status != TripStatus.BookingOnly)
            .OrderByDescending(trip => trip.StartDate)
            .ThenByDescending(trip => trip.CreatedAt)
            .Select(trip => new
            {
                TripId = trip.Id,
                trip.UserId,
                trip.DestinationId,
                DestinationName = trip.Destination != null ? trip.Destination.Name : null,
                DestinationDescription = trip.Destination != null ? trip.Destination.Description : null,
                DestinationCoverImageUrl = trip.Destination != null ? trip.Destination.CoverImageUrl : null,
                Title = trip.Title ?? string.Empty,
                ShareCode = trip.ShareCode ?? string.Empty,
                trip.SharedFromTripId,
                trip.StartDate,
                trip.EndDate,
                trip.TotalAmount,
                trip.TotalProfit,
                trip.Status,
                trip.CreatedAt,
                ItineraryCount = trip.TripItineraries.Count
            })
            .ToListAsync();

        return trips
            .Select(trip => new TripSummaryDto
            {
                TripId = trip.TripId,
                UserId = trip.UserId,
                DestinationId = trip.DestinationId,
                DestinationName = trip.DestinationName,
                DestinationDescription = trip.DestinationDescription,
                DestinationCoverImageUrl = trip.DestinationCoverImageUrl,
                Title = trip.Title,
                ShareCode = trip.ShareCode,
                SharedFromTripId = trip.SharedFromTripId,
                StartDate = trip.StartDate,
                EndDate = trip.EndDate,
                TotalAmount = trip.TotalAmount,
                TotalProfit = trip.TotalProfit,
                Status = NormalizeTripStatus(trip.Status?.ToString()),
                CreatedAt = trip.CreatedAt,
                ItineraryCount = trip.ItineraryCount,
                CanEdit = true,
                CanSave = false
            })
            .ToList();
    }

    public async Task<TripDetailDto?> GetTripByIdAsync(int tripId)
    {
        if (tripId <= 0)
        {
            throw new ArgumentException("TripId must be greater than 0.");
        }

        var trip = await _context.Trips
            .AsNoTracking()
            .Include(item => item.Destination)
            .Include(item => item.TripItineraries)
            .FirstOrDefaultAsync(item => item.Id == tripId);

        if (trip == null)
        {
            return null;
        }

        var itineraryItems = trip.TripItineraries
            .OrderBy(item => item.ServiceDate ?? DateOnly.MaxValue)
            .ThenBy(item => item.DayNumber ?? int.MaxValue)
            .ThenBy(item => item.DepartureTime ?? TimeOnly.MaxValue)
            .ThenBy(item => item.Id)
            .ToList();

        var itineraries = new List<TripItineraryDto>();
        if (_itineraryService is ItineraryService concreteItineraryService)
        {
            foreach (var item in itineraryItems)
            {
                itineraries.Add(await concreteItineraryService.MapItineraryAsync(item));
            }
        }

        return new TripDetailDto
        {
            TripId = trip.Id,
            UserId = trip.UserId,
            DestinationId = trip.DestinationId,
            DestinationName = trip.Destination?.Name,
            DestinationDescription = trip.Destination?.Description,
            DestinationCoverImageUrl = trip.Destination?.CoverImageUrl,
            Title = trip.Title ?? string.Empty,
            ShareCode = trip.ShareCode ?? string.Empty,
            SharedFromTripId = trip.SharedFromTripId,
            StartDate = trip.StartDate,
            EndDate = trip.EndDate,
            TotalAmount = trip.TotalAmount,
            TotalProfit = trip.TotalProfit,
            Status = NormalizeTripStatus(trip.Status?.ToString()),
            CreatedAt = trip.CreatedAt,
            ItineraryCount = itineraryItems.Count,
            Itineraries = itineraries,
            CanEdit = true,
            CanSave = false
        };
    }

    public async Task<TripDetailDto?> GetTripByShareCodeAsync(string shareCode, int currentUserId)
    {
        var normalizedShareCode = NormalizeShareCode(shareCode);
        if (string.IsNullOrWhiteSpace(normalizedShareCode))
        {
            throw new ArgumentException("Share code is required.");
        }

        var trip = await FindTripByShareCodeAsync(normalizedShareCode, currentUserId);

        if (trip == null)
        {
            return null;
        }

        var detail = await MapTripDetailAsync(trip);
        var ownsTrip = trip.UserId == currentUserId;
        var savedTrip = !ownsTrip
            ? await _context.Trips
                .AsNoTracking()
                .Where(item => item.UserId == currentUserId && item.SharedFromTripId == trip.Id)
                .Select(item => new { item.Id })
                .FirstOrDefaultAsync()
            : null;
        var alreadySaved = savedTrip != null;

        detail.CanEdit = ownsTrip;
        detail.CanSave = !ownsTrip && !alreadySaved;
        detail.SavedTripId = savedTrip?.Id;
        return detail;
    }

    public async Task<TripSummaryDto> SaveSharedTripAsync(string shareCode, int currentUserId)
    {
        var normalizedShareCode = NormalizeShareCode(shareCode);
        if (string.IsNullOrWhiteSpace(normalizedShareCode))
        {
            throw new ArgumentException("Share code is required.");
        }

        var sourceTrip = await FindShareSourceTripAsync(normalizedShareCode);

        if (sourceTrip == null)
        {
            throw new KeyNotFoundException("Shared trip was not found.");
        }

        if (sourceTrip.UserId == currentUserId)
        {
            return await GetTripSummaryAsync(sourceTrip.Id)
                ?? throw new InvalidOperationException("Trip could not be loaded.");
        }

        var existingSavedTrip = await _context.Trips
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.UserId == currentUserId && item.SharedFromTripId == sourceTrip.Id);

        if (existingSavedTrip != null)
        {
            return await GetTripSummaryAsync(existingSavedTrip.Id)
                ?? throw new InvalidOperationException("Saved trip could not be loaded.");
        }

        var savedTrip = new TripEntity
        {
            UserId = currentUserId,
            DestinationId = sourceTrip.DestinationId,
            Title = sourceTrip.Title,
            ShareCode = sourceTrip.ShareCode,
            SharedFromTripId = sourceTrip.Id,
            StartDate = sourceTrip.StartDate,
            EndDate = sourceTrip.EndDate,
            Status = TripStatus.Draft,
            CreatedAt = DateTime.UtcNow,
            TotalAmount = sourceTrip.TotalAmount,
            TotalProfit = 0
        };

        foreach (var item in sourceTrip.TripItineraries)
        {
            savedTrip.TripItineraries.Add(new TripItinerary
            {
                DayNumber = item.DayNumber,
                ServiceType = item.ServiceType,
                ServiceId = item.ServiceId,
                Quantity = item.Quantity,
                AdultCount = item.AdultCount,
                ChildCount = item.ChildCount,
                InfantCount = item.InfantCount,
                BookedPrice = item.BookedPrice,
                BookedCommissionRate = item.BookedCommissionRate,
                ServiceDate = item.ServiceDate,
                HotelCheckOutDate = item.HotelCheckOutDate,
                DepartureTime = item.DepartureTime,
                ServiceAddress = item.ServiceAddress,
                SelectedSeats = item.SelectedSeats
            });
        }

        _context.Trips.Add(savedTrip);
        await _context.SaveChangesAsync();

        return await GetTripSummaryAsync(savedTrip.Id)
            ?? throw new InvalidOperationException("Shared trip was saved but could not be loaded.");
    }

    public async Task<TripSummaryDto> CreateTripAsync(CreateTripDto request)
    {
        return await CreateTripInternalAsync(request, sendCreatedNotification: true);
    }

    private async Task<TripSummaryDto> CreateTripInternalAsync(CreateTripDto request, bool sendCreatedNotification)
    {
        ValidateCreateTripRequest(request);

        var userExists = await _context.Users.AnyAsync(user => user.Id == request.UserId);
        if (!userExists)
        {
            throw new KeyNotFoundException($"User {request.UserId} was not found.");
        }

        var destination = await ResolveDestinationAsync(request.DestinationId, request.DestinationName);

        var trip = new TripEntity
        {
            UserId = request.UserId,
            DestinationId = destination?.Id,
            Title = request.Title.Trim(),
            ShareCode = await GenerateUniqueShareCodeAsync(),
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            Status = ParseTripStatus(request.Status),
            CreatedAt = DateTime.UtcNow,
            TotalAmount = 0,
            TotalProfit = 0
        };

        _context.Trips.Add(trip);
        await _context.SaveChangesAsync();

        var createdTrip = await GetTripSummaryAsync(trip.Id)
            ?? throw new InvalidOperationException("Trip was created but could not be loaded.");

        if (sendCreatedNotification && createdTrip.Status != BookingOnlyStatus)
        {
            await NotifyTripCreatedAsync(createdTrip);
        }

        return createdTrip;
    }

    public async Task<TripSummaryDto> CreateHotelBookingAsync(CreateHotelBookingDto request)
    {
        ValidateCreateHotelBookingRequest(request);

        if (_context is not DbContext dbContext)
        {
            throw new InvalidOperationException("Booking transaction is not supported by the current data context.");
        }

        var executionStrategy = dbContext.Database.CreateExecutionStrategy();
        return await executionStrategy.ExecuteAsync(async () =>
        {
            await using IDbContextTransaction transaction = await dbContext.Database.BeginTransactionAsync();
            try
            {
                var trip = await CreateTripInternalAsync(new CreateTripDto
                {
                    UserId = request.UserId,
                    DestinationId = request.DestinationId,
                    DestinationName = request.DestinationName,
                    Title = request.Title,
                    StartDate = request.CheckInDate,
                    EndDate = request.CheckOutDate,
                    Status = PendingStatus
                }, sendCreatedNotification: false);

                await _itineraryService.AddItineraryAsync(trip.TripId, new CreateTripItineraryDto
                {
                    DayNumber = 1,
                    ServiceType = "HOTEL",
                    ServiceId = request.RoomId,
                    Quantity = request.Quantity,
                    AdultCount = request.AdultCount,
                    ChildCount = request.ChildCount,
                    InfantCount = request.InfantCount,
                    ServiceDate = request.CheckInDate,
                    HotelCheckOutDate = request.CheckOutDate
                });

                await transaction.CommitAsync();

                var createdBooking = await GetTripSummaryAsync(trip.TripId)
                    ?? throw new InvalidOperationException("Hotel booking was created but could not be loaded.");

                await NotifyHotelBookingCreatedAsync(createdBooking);
                await SendHotelBookingEmailAsync(createdBooking);

                return createdBooking;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });
    }

    public async Task<TripSummaryDto> CompleteFakePaymentAsync(int tripId, CreateFakePaymentDto request)
    {
        if (tripId <= 0)
        {
            throw new ArgumentException("TripId must be greater than 0.");
        }

        var trip = await _context.Trips
            .Include(item => item.User)
            .Include(item => item.Destination)
            .Include(item => item.Payments)
            .Include(item => item.TripItineraries)
            .FirstOrDefaultAsync(item => item.Id == tripId);

        if (trip == null)
        {
            throw new KeyNotFoundException($"Trip {tripId} was not found.");
        }

        if (!trip.TripItineraries.Any())
        {
            throw new InvalidOperationException("Booking has no services to pay for.");
        }

        if (trip.Status == TripStatus.Cancelled)
        {
            throw new InvalidOperationException("Cancelled bookings cannot be paid.");
        }

        var amount = request.Amount ?? trip.TotalAmount ?? trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

        if (amount <= 0)
        {
            throw new InvalidOperationException("Booking total amount is invalid.");
        }

        var payment = new Payment
        {
            TripId = trip.Id,
            TransactionId = $"FAKE-{trip.Id:D6}-{DateTime.UtcNow:yyyyMMddHHmmss}",
        };

        _context.Payments.Add(payment);
        trip.Payments.Add(payment);

        payment.PaymentMethod = ParsePaymentMethod(request.PaymentMethod);
        payment.Amount = amount;
        payment.Status = PaymentStatus.Paid;
        payment.PaidAt = DateTime.UtcNow;
        trip.TotalProfit = CalculateTripProfitFromPaidAmount(trip, amount);
        if (trip.Status != TripStatus.BookingOnly)
        {
            trip.Status = TripStatus.Pending;
        }

        await _context.SaveChangesAsync();

        await NotifyPaymentSucceededAsync(trip, payment);
        await SendPaymentSucceededEmailAsync(trip, payment);

        return await GetTripSummaryAsync(trip.Id)
            ?? throw new InvalidOperationException("Payment was saved but booking could not be reloaded.");
    }

    private async Task<TripSummaryDto?> GetTripSummaryAsync(int tripId)
    {
        var trip = await _context.Trips
            .AsNoTracking()
            .Where(item => item.Id == tripId)
            .Select(item => new
            {
                TripId = item.Id,
                item.UserId,
                item.DestinationId,
                DestinationName = item.Destination != null ? item.Destination.Name : null,
                DestinationDescription = item.Destination != null ? item.Destination.Description : null,
                DestinationCoverImageUrl = item.Destination != null ? item.Destination.CoverImageUrl : null,
                Title = item.Title ?? string.Empty,
                ShareCode = item.ShareCode ?? string.Empty,
                item.SharedFromTripId,
                item.StartDate,
                item.EndDate,
                item.TotalAmount,
                item.TotalProfit,
                item.Status,
                item.CreatedAt,
                ItineraryCount = item.TripItineraries.Count
            })
            .FirstOrDefaultAsync();

        if (trip == null)
        {
            return null;
        }

        return new TripSummaryDto
        {
            TripId = trip.TripId,
            UserId = trip.UserId,
            DestinationId = trip.DestinationId,
            DestinationName = trip.DestinationName,
            DestinationDescription = trip.DestinationDescription,
            DestinationCoverImageUrl = trip.DestinationCoverImageUrl,
            Title = trip.Title,
            ShareCode = trip.ShareCode,
            SharedFromTripId = trip.SharedFromTripId,
            StartDate = trip.StartDate,
            EndDate = trip.EndDate,
            TotalAmount = trip.TotalAmount,
            TotalProfit = trip.TotalProfit,
            Status = NormalizeTripStatus(trip.Status?.ToString()),
            CreatedAt = trip.CreatedAt,
            ItineraryCount = trip.ItineraryCount
        };
    }

    private async Task<TripDetailDto> MapTripDetailAsync(TripEntity trip)
    {
        var itineraryItems = trip.TripItineraries
            .OrderBy(item => item.ServiceDate ?? DateOnly.MaxValue)
            .ThenBy(item => item.DayNumber ?? int.MaxValue)
            .ThenBy(item => item.DepartureTime ?? TimeOnly.MaxValue)
            .ThenBy(item => item.Id)
            .ToList();

        var itineraries = new List<TripItineraryDto>();
        if (_itineraryService is ItineraryService concreteItineraryService)
        {
            foreach (var item in itineraryItems)
            {
                itineraries.Add(await concreteItineraryService.MapItineraryAsync(item));
            }
        }

        return new TripDetailDto
        {
            TripId = trip.Id,
            UserId = trip.UserId,
            DestinationId = trip.DestinationId,
            DestinationName = trip.Destination?.Name,
            DestinationDescription = trip.Destination?.Description,
            DestinationCoverImageUrl = trip.Destination?.CoverImageUrl,
            Title = trip.Title ?? string.Empty,
            ShareCode = trip.ShareCode ?? string.Empty,
            SharedFromTripId = trip.SharedFromTripId,
            StartDate = trip.StartDate,
            EndDate = trip.EndDate,
            TotalAmount = trip.TotalAmount,
            TotalProfit = trip.TotalProfit,
            Status = NormalizeTripStatus(trip.Status?.ToString()),
            CreatedAt = trip.CreatedAt,
            ItineraryCount = itineraryItems.Count,
            Itineraries = itineraries
        };
    }

    private static decimal CalculateTripProfitFromPaidAmount(TripEntity trip, decimal paidAmount)
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

    private async Task<Destination?> ResolveDestinationAsync(int? destinationId, string? destinationName)
    {
        if (destinationId.HasValue)
        {
            var destination = await _context.Destinations.FindAsync(destinationId.Value);
            if (destination == null)
            {
                throw new KeyNotFoundException($"Destination {destinationId.Value} was not found.");
            }

            return destination;
        }

        if (string.IsNullOrWhiteSpace(destinationName))
        {
            return null;
        }

        var normalizedName = destinationName.Trim();
        var existingDestination = await _context.Destinations
            .FirstOrDefaultAsync(destination => destination.Name.ToLower() == normalizedName.ToLower());

        if (existingDestination != null)
        {
            return existingDestination;
        }

        var newDestination = new Destination
        {
            Name = normalizedName
        };

        _context.Destinations.Add(newDestination);
        await _context.SaveChangesAsync();
        return newDestination;
    }

    public async Task<TripSummaryDto> UpdateTripAsync(int tripId, UpdateTripDto request)
    {
        var trip = await _context.Trips
            .Include(t => t.TripItineraries)
            .FirstOrDefaultAsync(t => t.Id == tripId);
        if (trip == null)
        {
            throw new KeyNotFoundException($"Trip {tripId} was not found.");
        }

        var previousDestinationId = trip.DestinationId;
        var itinerariesCleared = false;

        if (request.Title != null) trip.Title = request.Title.Trim();
        if (request.StartDate.HasValue) trip.StartDate = request.StartDate.Value;
        if (request.EndDate.HasValue) trip.EndDate = request.EndDate.Value;
        if (request.Status != null) trip.Status = ParseTripStatus(request.Status);

        if (trip.StartDate.HasValue && trip.EndDate.HasValue && trip.EndDate < trip.StartDate)
        {
            throw new ArgumentException("EndDate must be greater than or equal to StartDate.");
        }

        if (request.DestinationId.HasValue || request.DestinationName != null)
        {
            var destination = await ResolveDestinationAsync(request.DestinationId, request.DestinationName);
            var newDestinationId = destination?.Id;

            if (newDestinationId != previousDestinationId && trip.TripItineraries.Count > 0)
            {
                _context.TripItineraries.RemoveRange(trip.TripItineraries);
                trip.TotalAmount = 0;
                trip.TotalProfit = 0;
                itinerariesCleared = true;
            }

            trip.DestinationId = newDestinationId;
        }

        await _context.SaveChangesAsync();

        var summary = await GetTripSummaryAsync(trip.Id)
            ?? throw new InvalidOperationException("Trip was updated but could not be loaded.");
        summary.ItinerariesCleared = itinerariesCleared;
        return summary;
    }

    public async Task DeleteTripAsync(int tripId, int currentUserId)
    {
        var trip = await _context.Trips
            .Include(t => t.TripItineraries)
            .Include(t => t.Payments)
            .Include(t => t.Reviews)
            .Include(t => t.Invoices)
            .FirstOrDefaultAsync(t => t.Id == tripId);

        if (trip == null)
        {
            throw new KeyNotFoundException($"Trip {tripId} was not found.");
        }

        if (trip.UserId != currentUserId)
        {
            throw new UnauthorizedAccessException("You do not have permission to delete this trip.");
        }

        if (trip.SharedFromTripId == null)
        {
            var hasSharedCopies = await _context.Trips
                .AsNoTracking()
                .AnyAsync(item => item.SharedFromTripId == tripId);

            if (hasSharedCopies)
            {
                throw new InvalidOperationException(
                    "Không thể xóa chuyến đi vì đã có người khác lưu lịch trình này.");
            }
        }

        _context.TripItineraries.RemoveRange(trip.TripItineraries);
        _context.Payments.RemoveRange(trip.Payments);
        _context.Reviews.RemoveRange(trip.Reviews);
        _context.Invoices.RemoveRange(trip.Invoices);
        _context.Trips.Remove(trip);
        await _context.SaveChangesAsync();
    }

    private async Task<TripEntity?> FindTripByShareCodeAsync(string normalizedShareCode, int currentUserId)
    {
        var ownedTrip = await _context.Trips
            .AsNoTracking()
            .Include(item => item.Destination)
            .Include(item => item.TripItineraries)
            .FirstOrDefaultAsync(item => item.ShareCode == normalizedShareCode && item.UserId == currentUserId);

        if (ownedTrip != null)
        {
            return ownedTrip;
        }

        return await _context.Trips
            .AsNoTracking()
            .Include(item => item.Destination)
            .Include(item => item.TripItineraries)
            .Where(item => item.ShareCode == normalizedShareCode)
            .OrderBy(item => item.SharedFromTripId == null ? 0 : 1)
            .ThenBy(item => item.Id)
            .FirstOrDefaultAsync();
    }

    private async Task<TripEntity?> FindShareSourceTripAsync(string normalizedShareCode)
    {
        return await _context.Trips
            .AsNoTracking()
            .Include(item => item.TripItineraries)
            .Where(item => item.ShareCode == normalizedShareCode)
            .OrderBy(item => item.SharedFromTripId == null ? 0 : 1)
            .ThenBy(item => item.Id)
            .FirstOrDefaultAsync();
    }

    private async Task<string> GenerateUniqueShareCodeAsync()
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = $"TRIP-{Guid.NewGuid().ToString("N")[..8].ToUpperInvariant()}";
            var exists = await _context.Trips.AnyAsync(item => item.ShareCode == code);
            if (!exists)
            {
                return code;
            }
        }

        throw new InvalidOperationException("Could not generate a unique trip share code.");
    }

    private static string NormalizeShareCode(string? shareCode)
    {
        return (shareCode ?? string.Empty).Trim().ToUpperInvariant();
    }

    private static void ValidateCreateTripRequest(CreateTripDto request)
    {
        if (request.UserId <= 0)
        {
            throw new ArgumentException("UserId must be greater than 0.");
        }

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new ArgumentException("Trip title is required.");
        }

        if (request.EndDate < request.StartDate)
        {
            throw new ArgumentException("EndDate must be greater than or equal to StartDate.");
        }
    }

    private static void ValidateCreateHotelBookingRequest(CreateHotelBookingDto request)
    {
        if (request.UserId <= 0)
        {
            throw new ArgumentException("UserId must be greater than 0.");
        }

        if (request.HotelId <= 0)
        {
            throw new ArgumentException("HotelId must be greater than 0.");
        }

        if (request.RoomId <= 0)
        {
            throw new ArgumentException("RoomId must be greater than 0.");
        }

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new ArgumentException("Booking title is required.");
        }

        if (request.Quantity <= 0)
        {
            throw new ArgumentException("Quantity must be greater than 0.");
        }

        if (request.CheckOutDate <= request.CheckInDate)
        {
            throw new ArgumentException("CheckOutDate must be after CheckInDate.");
        }
    }

    private static PaymentMethod ParsePaymentMethod(string? paymentMethod)
    {
        if (Enum.TryParse<PaymentMethod>(paymentMethod, true, out var parsedMethod))
        {
            return parsedMethod;
        }

        return paymentMethod?.Trim().ToLowerInvariant() switch
        {
            "momo" => PaymentMethod.Momo,
            "vnpay" => PaymentMethod.Vnpay,
            "card" => PaymentMethod.Card,
            _ => throw new ArgumentException("PaymentMethod must be Momo, Vnpay, or Card.")
        };
    }

    private static string NormalizeTripStatus(string? status)
    {
        if (Enum.TryParse<TripStatus>(status, true, out var parsedStatus))
        {
            return parsedStatus switch
            {
                TripStatus.Draft => DraftStatus,
                TripStatus.Pending => PendingStatus,
                TripStatus.Paid => PaidStatus,
                TripStatus.Cancelled => CancelledStatus,
                TripStatus.BookingOnly => BookingOnlyStatus,
                _ => DraftStatus
            };
        }

        return status?.Trim().ToUpperInvariant() switch
        {
            DraftStatus => DraftStatus,
            PendingStatus => PendingStatus,
            PaidStatus => PaidStatus,
            CancelledStatus => CancelledStatus,
            BookingOnlyStatus => BookingOnlyStatus,
            _ => DraftStatus
        };
    }

    private static TripStatus ParseTripStatus(string? status)
    {
        if (Enum.TryParse<TripStatus>(status, true, out var parsedStatus))
        {
            return parsedStatus;
        }

        return status?.Trim().ToUpperInvariant() switch
        {
            DraftStatus => TripStatus.Draft,
            PendingStatus => TripStatus.Pending,
            PaidStatus => TripStatus.Paid,
            CancelledStatus => TripStatus.Cancelled,
            BookingOnlyStatus => TripStatus.BookingOnly,
            _ => TripStatus.Draft
        };
    }

    private async Task NotifyTripCreatedAsync(TripSummaryDto trip)
    {
        await TryCreateNotificationAsync(new CreateNotificationDto
        {
            UserId = trip.UserId ?? 0,
            Title = "Chuyến đi đã được tạo",
            Message = $"Chuyến đi \"{trip.Title}\" đã sẵn sàng để bạn tiếp tục lên lịch trình.",
            Type = "trip.created",
            ReferenceType = "trip",
            ReferenceId = trip.TripId,
            ActionUrl = $"/trips/{trip.TripId}"
        });
    }

    private async Task NotifyHotelBookingCreatedAsync(TripSummaryDto trip)
    {
        await TryCreateNotificationAsync(new CreateNotificationDto
        {
            UserId = trip.UserId ?? 0,
            Title = "Đặt phòng đã được ghi nhận",
            Message = $"Booking \"{trip.Title}\" đã được SmartTrip ghi nhận và đang chờ xử lý.",
            Type = "booking.hotel_created",
            ReferenceType = "booking",
            ReferenceId = trip.TripId,
            ActionUrl = $"/trips/{trip.TripId}"
        });
    }

    private async Task NotifyPaymentSucceededAsync(TripEntity trip, Payment payment)
    {
        await TryCreateNotificationAsync(new CreateNotificationDto
        {
            UserId = trip.UserId ?? 0,
            Title = "Thanh toán thành công",
            Message = $"Thanh toán cho \"{trip.Title ?? "booking"}\" đã hoàn tất.",
            Type = "payment.succeeded",
            ReferenceType = "payment",
            ReferenceId = payment.Id,
            ActionUrl = $"/trips/{trip.Id}"
        });
    }

    private async Task TryCreateNotificationAsync(CreateNotificationDto request)
    {
        try
        {
            await _notificationService.CreateAsync(request);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create notification {Type} for user {UserId}", request.Type, request.UserId);
        }
    }

    private async Task SendHotelBookingEmailAsync(TripSummaryDto trip)
    {
        try
        {
            if (!trip.UserId.HasValue || !await _notificationService.AreEmailNotificationsEnabledAsync(trip.UserId.Value))
            {
                return;
            }

            var user = await _context.Users
                .AsNoTracking()
                .Where(item => item.Id == trip.UserId.Value)
                .Select(item => new { item.Email, item.FullName })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                return;
            }

            await _emailService.SendHotelBookingCreatedEmailAsync(
                user.Email,
                user.FullName ?? user.Email,
                trip.Title,
                FormatDateRange(trip.StartDate, trip.EndDate));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send hotel booking email for trip {TripId}", trip.TripId);
        }
    }

    private async Task SendPaymentSucceededEmailAsync(TripEntity trip, Payment payment)
    {
        try
        {
            if (!trip.UserId.HasValue || !await _notificationService.AreEmailNotificationsEnabledAsync(trip.UserId.Value))
            {
                return;
            }

            var user = trip.User;
            if (user == null)
            {
                user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(item => item.Id == trip.UserId.Value);
            }

            if (user == null)
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

    private static string FormatDateRange(DateOnly? startDate, DateOnly? endDate)
    {
        if (!startDate.HasValue || !endDate.HasValue)
        {
            return "Đang cập nhật";
        }

        return $"{startDate.Value:dd/MM/yyyy} - {endDate.Value:dd/MM/yyyy}";
    }
}
