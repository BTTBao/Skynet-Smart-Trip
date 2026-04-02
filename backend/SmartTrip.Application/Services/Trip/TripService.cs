using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces;
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

    private readonly IApplicationDbContext _context;
    private readonly IItineraryService _itineraryService;

    public TripService(IApplicationDbContext context, IItineraryService itineraryService)
    {
        _context = context;
        _itineraryService = itineraryService;
    }

    public async Task<IReadOnlyList<TripSummaryDto>> GetTripsByUserAsync(int userId)
    {
        if (userId <= 0)
        {
            throw new ArgumentException("UserId must be greater than 0.");
        }

        var trips = await _context.Trips
            .AsNoTracking()
            .Where(trip => trip.UserId == userId)
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
                StartDate = trip.StartDate,
                EndDate = trip.EndDate,
                TotalAmount = trip.TotalAmount,
                TotalProfit = trip.TotalProfit,
                Status = NormalizeTripStatus(trip.Status?.ToString()),
                CreatedAt = trip.CreatedAt,
                ItineraryCount = trip.ItineraryCount
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
            .OrderBy(item => item.DayNumber ?? int.MaxValue)
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

    public async Task<TripSummaryDto> CreateTripAsync(CreateTripDto request)
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
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            Status = ParseTripStatus(request.Status),
            CreatedAt = DateTime.UtcNow,
            TotalAmount = 0,
            TotalProfit = 0
        };

        _context.Trips.Add(trip);
        await _context.SaveChangesAsync();

        return await GetTripSummaryAsync(trip.Id)
            ?? throw new InvalidOperationException("Trip was created but could not be loaded.");
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
            StartDate = trip.StartDate,
            EndDate = trip.EndDate,
            TotalAmount = trip.TotalAmount,
            TotalProfit = trip.TotalProfit,
            Status = NormalizeTripStatus(trip.Status?.ToString()),
            CreatedAt = trip.CreatedAt,
            ItineraryCount = trip.ItineraryCount
        };
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
        var trip = await _context.Trips.FirstOrDefaultAsync(t => t.Id == tripId);
        if (trip == null)
        {
            throw new KeyNotFoundException($"Trip {tripId} was not found.");
        }

        if (request.Title != null) trip.Title = request.Title.Trim();
        if (request.StartDate.HasValue) trip.StartDate = request.StartDate.Value;
        if (request.EndDate.HasValue) trip.EndDate = request.EndDate.Value;
        if (request.Status != null) trip.Status = ParseTripStatus(request.Status);

        if (request.DestinationId.HasValue || request.DestinationName != null)
        {
            var destination = await ResolveDestinationAsync(request.DestinationId, request.DestinationName);
            trip.DestinationId = destination?.Id;
        }

        await _context.SaveChangesAsync();

        return await GetTripSummaryAsync(trip.Id)
            ?? throw new InvalidOperationException("Trip was updated but could not be loaded.");
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
                _ => DraftStatus
            };
        }

        return status?.Trim().ToUpperInvariant() switch
        {
            DraftStatus => DraftStatus,
            PendingStatus => PendingStatus,
            PaidStatus => PaidStatus,
            CancelledStatus => CancelledStatus,
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
            _ => TripStatus.Draft
        };
    }
}
