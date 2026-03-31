using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using TripEntity = SmartTrip.Domain.Entities.Trip;

namespace SmartTrip.Application.Services.Trip;

public class ItineraryService : IItineraryService
{
    private const string HotelServiceType = "HOTEL";
    private const string BusServiceType = "BUS";

    private readonly IApplicationDbContext _context;
    private readonly ITripServiceOptionService _optionService;

    public ItineraryService(IApplicationDbContext context, ITripServiceOptionService optionService)
    {
        _context = context;
        _optionService = optionService;
    }

    public async Task<TripItineraryDto> AddItineraryAsync(int tripId, CreateTripItineraryDto request)
    {
        if (tripId <= 0)
        {
            throw new ArgumentException("TripId must be greater than 0.");
        }

        ValidateCreateItineraryRequest(request);

        var trip = await _context.Trips.FirstOrDefaultAsync(item => item.Id == tripId);
        if (trip == null)
        {
            throw new KeyNotFoundException($"Trip {tripId} was not found.");
        }

        ValidateDayNumber(trip, request.DayNumber);

        var normalizedServiceType = TripServiceOptionService.NormalizeServiceType(request.ServiceType);
        var serviceOption = await _optionService.GetServiceOptionByIdAsync(normalizedServiceType, request.ServiceId);
        if (serviceOption == null)
        {
            throw new KeyNotFoundException($"Service {request.ServiceId} with type {normalizedServiceType} was not found.");
        }

        var itinerary = new TripItinerary
        {
            TripId = tripId,
            DayNumber = request.DayNumber,
            ServiceType = normalizedServiceType,
            ServiceId = request.ServiceId,
            Quantity = request.Quantity,
            BookedPrice = request.BookedPrice ?? serviceOption.DefaultPrice ?? 0,
            BookedCommissionRate = request.BookedCommissionRate ?? serviceOption.DefaultCommissionRate ?? 0
        };

        _context.TripItineraries.Add(itinerary);
        await _context.SaveChangesAsync();

        await RecalculateTripTotalsAsync(tripId);

        return await MapItineraryAsync(itinerary);
    }

    public async Task<TripItineraryDto> MapItineraryAsync(TripItinerary itinerary)
    {
        var normalizedServiceType = TripServiceOptionService.NormalizeServiceType(itinerary.ServiceType);
        var serviceName = $"Service #{itinerary.ServiceId}";
        string? serviceSubtitle = null;

        if (normalizedServiceType == HotelServiceType && itinerary.ServiceId.HasValue)
        {
            var hotel = await _context.Hotels
                .AsNoTracking()
                .FirstOrDefaultAsync(h => h.Id == itinerary.ServiceId.Value);

            if (hotel != null)
            {
                serviceName = hotel.Name;
                serviceSubtitle = string.Join(" • ", new[]
                {
                    hotel.Address,
                    hotel.StarRating.HasValue ? $"{hotel.StarRating.Value} sao" : null,
                    hotel.Description
                }.Where(value => !string.IsNullOrWhiteSpace(value)));
            }
        }
        else if (normalizedServiceType == BusServiceType && itinerary.ServiceId.HasValue)
        {
            var busSchedule = await _context.BusSchedules
                .AsNoTracking()
                .Include(s => s.Company)
                .Include(s => s.FromDest)
                .Include(s => s.ToDest)
                .FirstOrDefaultAsync(s => s.Id == itinerary.ServiceId.Value);

            if (busSchedule != null)
            {
                serviceName = $"{(busSchedule.Company != null ? busSchedule.Company.Name : "Xe khach")} - {(busSchedule.FromDest != null ? busSchedule.FromDest.Name : "N/A")} -> {(busSchedule.ToDest != null ? busSchedule.ToDest.Name : "N/A")}";
                // Manual subtitle build to avoid dependency on private methods if not shared
                var departure = busSchedule.DepartureTime?.ToString("HH:mm dd/MM");
                var arrival = busSchedule.ArrivalTime?.ToString("HH:mm dd/MM");
                serviceSubtitle = string.Join(" • ", new[]
                {
                    !string.IsNullOrWhiteSpace(departure) ? $"Di: {departure}" : null,
                    !string.IsNullOrWhiteSpace(arrival) ? $"Den: {arrival}" : null,
                    busSchedule.TotalSeats.HasValue ? $"Ghe: {busSchedule.TotalSeats.Value}" : null
                }.Where(value => !string.IsNullOrWhiteSpace(value)));
            }
        }

        return new TripItineraryDto
        {
            ItineraryId = itinerary.Id,
            DayNumber = itinerary.DayNumber ?? 1,
            ServiceType = normalizedServiceType,
            ServiceId = itinerary.ServiceId,
            ServiceName = serviceName,
            ServiceSubtitle = serviceSubtitle,
            Quantity = itinerary.Quantity ?? 1,
            BookedPrice = itinerary.BookedPrice,
            BookedCommissionRate = itinerary.BookedCommissionRate
        };
    }

    public async Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(i => i.ItineraryId == itineraryId);
        if (itinerary == null)
        {
            throw new KeyNotFoundException($"Itinerary {itineraryId} was not found.");
        }

        if (request.DayNumber.HasValue)
        {
            var trip = await _context.Trips.FirstAsync(t => t.Id == itinerary.TripId);
            ValidateDayNumber(trip, request.DayNumber.Value);
            itinerary.DayNumber = request.DayNumber.Value;
        }

        if (request.Quantity.HasValue) itinerary.Quantity = request.Quantity.Value;
        if (request.BookedPrice.HasValue) itinerary.BookedPrice = request.BookedPrice.Value;
        if (request.BookedCommissionRate.HasValue) itinerary.BookedCommissionRate = request.BookedCommissionRate.Value;

        await _context.SaveChangesAsync();
        if (itinerary.TripId.HasValue)
        {
            await RecalculateTripTotalsAsync(itinerary.TripId.Value);
        }

        return await MapItineraryAsync(itinerary);
    }

    public async Task<bool> DeleteItineraryAsync(int itineraryId)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(i => i.ItineraryId == itineraryId);
        if (itinerary == null)
        {
            return false;
        }

        var tripId = itinerary.TripId;
        _context.TripItineraries.Remove(itinerary);
        await _context.SaveChangesAsync();

        if (tripId.HasValue)
        {
            await RecalculateTripTotalsAsync(tripId.Value);
        }
        return true;
    }

    private async Task RecalculateTripTotalsAsync(int tripId)
    {
        var trip = await _context.Trips
            .Include(item => item.TripItineraries)
            .FirstAsync(item => item.TripId == tripId);

        trip.TotalAmount = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

        trip.TotalProfit = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) *
            (decimal)((item.BookedCommissionRate ?? 0) / 100d) *
            (item.Quantity ?? 1));

        await _context.SaveChangesAsync();
    }

    private static void ValidateCreateItineraryRequest(CreateTripItineraryDto request)
    {
        if (request.DayNumber <= 0)
        {
            throw new ArgumentException("DayNumber must be greater than 0.");
        }

        if (request.ServiceId <= 0)
        {
            throw new ArgumentException("ServiceId must be greater than 0.");
        }

        if (request.Quantity <= 0)
        {
            throw new ArgumentException("Quantity must be greater than 0.");
        }

        _ = TripServiceOptionService.NormalizeServiceType(request.ServiceType);
    }

    private static void ValidateDayNumber(TripEntity trip, int dayNumber)
    {
        if (trip.StartDate == null || trip.EndDate == null)
        {
            return;
        }

        var maxDay = (trip.EndDate.Value.DayNumber - trip.StartDate.Value.DayNumber) + 1;
        if (dayNumber > maxDay)
        {
            throw new ArgumentException($"DayNumber cannot be greater than {maxDay} for this trip.");
        }
    }
}
