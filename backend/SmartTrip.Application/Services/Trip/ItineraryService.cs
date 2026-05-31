using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces;
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

        var existingHotelItinerary = normalizedServiceType == HotelServiceType
            ? await _context.TripItineraries.FirstOrDefaultAsync(item =>
                item.TripId == tripId &&
                item.ServiceType == TripServiceType.Hotel &&
                item.ServiceId == request.ServiceId &&
                item.ServiceDate == request.ServiceDate)
            : null;

        if (normalizedServiceType == HotelServiceType)
        {
            await ValidateHotelBookingAsync(trip, request, existingHotelItinerary?.Quantity ?? 0);
        }

        if (existingHotelItinerary != null)
        {
            existingHotelItinerary.Quantity = (existingHotelItinerary.Quantity ?? 1) + request.Quantity;
            existingHotelItinerary.BookedPrice = request.BookedPrice ?? existingHotelItinerary.BookedPrice;
            existingHotelItinerary.BookedCommissionRate = request.BookedCommissionRate ?? existingHotelItinerary.BookedCommissionRate;
            existingHotelItinerary.ServiceDate = request.ServiceDate ?? existingHotelItinerary.ServiceDate;
            existingHotelItinerary.DepartureTime = request.DepartureTime ?? existingHotelItinerary.DepartureTime;
            existingHotelItinerary.ServiceAddress = request.ServiceAddress ?? existingHotelItinerary.ServiceAddress;

            await _context.SaveChangesAsync();
            await RecalculateTripTotalsAsync(tripId);

            return await MapItineraryAsync(existingHotelItinerary);
        }

        var itinerary = new TripItinerary
        {
            TripId = tripId,
            DayNumber = request.DayNumber,
            ServiceType = TripServiceOptionService.ParseServiceTypeEnum(request.ServiceType),
            ServiceId = request.ServiceId,
            Quantity = request.Quantity,
            BookedPrice = request.BookedPrice ?? await ResolveDefaultBookedPriceAsync(normalizedServiceType, request.ServiceId, trip) ?? serviceOption.DefaultPrice ?? 0,
            BookedCommissionRate = request.BookedCommissionRate ?? serviceOption.DefaultCommissionRate ?? 0,
            ServiceDate = request.ServiceDate,
            DepartureTime = request.DepartureTime,
            ServiceAddress = request.ServiceAddress
        };

        _context.TripItineraries.Add(itinerary);
        await _context.SaveChangesAsync();

        await RecalculateTripTotalsAsync(tripId);

        return await MapItineraryAsync(itinerary);
    }

    public async Task<TripItineraryDto> MapItineraryAsync(TripItinerary itinerary)
    {
        var normalizedServiceType = TripServiceOptionService.NormalizeServiceType(itinerary.ServiceType?.ToString());
        var serviceName = $"Service #{itinerary.ServiceId}";
        string? serviceSubtitle = null;

        if (normalizedServiceType == HotelServiceType && itinerary.ServiceId.HasValue)
        {
            var room = await _context.Rooms
                .AsNoTracking()
                .Include(item => item.Hotel)
                .ThenInclude(item => item!.Destination)
                .FirstOrDefaultAsync(item => item.Id == itinerary.ServiceId.Value);

            if (room?.Hotel != null)
            {
                serviceName = room.Hotel.Name;
                serviceSubtitle = string.Join(" • ", new[]
                {
                    room.RoomType,
                    room.Hotel.Address,
                    room.Capacity.HasValue ? $"Suc chua {room.Capacity.Value} nguoi" : null,
                    room.Hotel.StarRating.HasValue ? $"{room.Hotel.StarRating.Value} sao" : null
                }.Where(value => !string.IsNullOrWhiteSpace(value)));
            }
            else
            {
                var hotel = await _context.Hotels
                    .AsNoTracking()
                    .FirstOrDefaultAsync(item => item.Id == itinerary.ServiceId.Value);

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
        }
        else if (normalizedServiceType == BusServiceType && itinerary.ServiceId.HasValue)
        {
            var busSchedule = await _context.BusSchedules
                .AsNoTracking()
                .Include(item => item.Company)
                .Include(item => item.FromDest)
                .Include(item => item.ToDest)
                .FirstOrDefaultAsync(item => item.Id == itinerary.ServiceId.Value);

            if (busSchedule != null)
            {
                serviceName = $"{(busSchedule.Company != null ? busSchedule.Company.Name : "Xe khach")} - {(busSchedule.FromDest != null ? busSchedule.FromDest.Name : "N/A")} -> {(busSchedule.ToDest != null ? busSchedule.ToDest.Name : "N/A")}";
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
            BookedCommissionRate = itinerary.BookedCommissionRate,
            ServiceDate = itinerary.ServiceDate,
            DepartureTime = itinerary.DepartureTime,
            ServiceAddress = itinerary.ServiceAddress
        };
    }

    public async Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(item => item.Id == itineraryId);
        if (itinerary == null)
        {
            throw new KeyNotFoundException($"Itinerary {itineraryId} was not found.");
        }

        if (request.DayNumber.HasValue)
        {
            var trip = await _context.Trips.FirstAsync(item => item.Id == itinerary.TripId);
            ValidateDayNumber(trip, request.DayNumber.Value);
            itinerary.DayNumber = request.DayNumber.Value;
        }

        if (request.Quantity.HasValue)
        {
            itinerary.Quantity = request.Quantity.Value;
        }

        if (request.BookedPrice.HasValue)
        {
            itinerary.BookedPrice = request.BookedPrice.Value;
        }

        if (request.BookedCommissionRate.HasValue)
        {
            itinerary.BookedCommissionRate = request.BookedCommissionRate.Value;
        }

        if (request.ServiceDate.HasValue)
        {
            itinerary.ServiceDate = request.ServiceDate.Value;
        }

        if (request.DepartureTime.HasValue)
        {
            itinerary.DepartureTime = request.DepartureTime.Value;
        }

        if (request.ServiceAddress != null)
        {
            itinerary.ServiceAddress = request.ServiceAddress;
        }

        await _context.SaveChangesAsync();
        if (itinerary.TripId.HasValue)
        {
            await RecalculateTripTotalsAsync(itinerary.TripId.Value);
        }

        return await MapItineraryAsync(itinerary);
    }

    public async Task<bool> DeleteItineraryAsync(int itineraryId)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(item => item.Id == itineraryId);
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

    private async Task ValidateHotelBookingAsync(TripEntity trip, CreateTripItineraryDto request, int existingQuantityInTrip)
    {
        if (trip.StartDate == null || trip.EndDate == null)
        {
            throw new ArgumentException("Hotel bookings require check-in and check-out dates.");
        }

        var tripStart = trip.StartDate.Value;
        var tripEnd = trip.EndDate.Value;
        var checkIn = request.ServiceDate ?? tripStart;

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        if (checkIn < today)
        {
            throw new ArgumentException("Check-in date cannot be in the past.");
        }

        var room = await _context.Rooms
            .AsNoTracking()
            .Include(item => item.Hotel)
            .FirstOrDefaultAsync(item => item.Id == request.ServiceId);

        if (room?.Hotel == null || room.Hotel.IsAvailable == false)
        {
            throw new KeyNotFoundException($"Room {request.ServiceId} was not found or is not available.");
        }

        var checkOut = ResolveHotelCheckOutDate(request, room, checkIn, tripEnd);
        if (checkOut <= checkIn)
        {
            throw new ArgumentException("Check-out date must be after check-in date.");
        }

        if (checkIn < tripStart || checkOut > tripEnd)
        {
            throw new ArgumentException("Hotel booking dates must be within the selected trip dates.");
        }

        var totalRooms = room.AvailableQty ?? 0;
        if (totalRooms <= 0)
        {
            throw new InvalidOperationException("This room type is currently sold out.");
        }

        var requestedTotalInTrip = existingQuantityInTrip + request.Quantity;
        if (requestedTotalInTrip > totalRooms)
        {
            throw new InvalidOperationException($"Only {totalRooms} room(s) are available for the selected room type.");
        }

        var overlappingBookings = await _context.TripItineraries
            .AsNoTracking()
            .Include(item => item.Trip)
            .Where(item =>
                item.ServiceType == TripServiceType.Hotel &&
                item.ServiceId == request.ServiceId &&
                item.TripId != trip.Id &&
                item.Trip != null &&
                item.Trip.Status != TripStatus.Cancelled &&
                item.Trip.StartDate.HasValue &&
                item.Trip.EndDate.HasValue)
            .ToListAsync();

        var bookedRooms = overlappingBookings
            .Where(item =>
            {
                var bookedCheckIn = item.ServiceDate ?? item.Trip!.StartDate!.Value;
                var bookedCheckOut = ResolveHotelCheckOutDate(
                    item.BookedPrice,
                    room.PricePerNight,
                    bookedCheckIn,
                    item.Trip!.EndDate!.Value);

                return DateRangesOverlap(checkIn, checkOut, bookedCheckIn, bookedCheckOut);
            })
            .Sum(item => item.Quantity ?? 1);

        var remainingRooms = totalRooms - bookedRooms;
        if (requestedTotalInTrip > remainingRooms)
        {
            throw new InvalidOperationException($"Only {Math.Max(remainingRooms, 0)} room(s) are still available for these dates.");
        }
    }

    private async Task<decimal?> ResolveDefaultBookedPriceAsync(string normalizedServiceType, int serviceId, TripEntity trip)
    {
        if (normalizedServiceType != HotelServiceType || trip.StartDate == null || trip.EndDate == null)
        {
            return null;
        }

        var nights = Math.Max(1, trip.EndDate.Value.DayNumber - trip.StartDate.Value.DayNumber);
        var pricePerNight = await _context.Rooms
            .AsNoTracking()
            .Where(item => item.Id == serviceId && (item.AvailableQty ?? 0) > 0)
            .Select(item => item.PricePerNight)
            .FirstOrDefaultAsync();

        return (pricePerNight ?? 0) * nights;
    }

    private static bool DateRangesOverlap(DateOnly start, DateOnly end, DateOnly otherStart, DateOnly otherEnd)
    {
        return start < otherEnd && end > otherStart;
    }

    private static DateOnly ResolveHotelCheckOutDate(
        CreateTripItineraryDto request,
        Room room,
        DateOnly checkIn,
        DateOnly fallbackCheckOut)
    {
        return ResolveHotelCheckOutDate(request.BookedPrice, room.PricePerNight, checkIn, fallbackCheckOut);
    }

    private static DateOnly ResolveHotelCheckOutDate(
        decimal? bookedPrice,
        decimal? pricePerNight,
        DateOnly checkIn,
        DateOnly fallbackCheckOut)
    {
        var nightlyPrice = pricePerNight ?? 0;
        if (bookedPrice.HasValue && nightlyPrice > 0)
        {
            var nightsValue = bookedPrice.Value / nightlyPrice;
            var roundedNights = (int)Math.Round(nightsValue, MidpointRounding.AwayFromZero);

            if (roundedNights > 0 && Math.Abs(nightsValue - roundedNights) < 0.01m)
            {
                return checkIn.AddDays(roundedNights);
            }
        }

        return fallbackCheckOut;
    }

    private async Task RecalculateTripTotalsAsync(int tripId)
    {
        var trip = await _context.Trips
            .Include(item => item.TripItineraries)
            .FirstAsync(item => item.Id == tripId);

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
