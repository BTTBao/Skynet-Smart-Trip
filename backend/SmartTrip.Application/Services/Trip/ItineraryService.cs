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
    private const string NoteServiceType = "NOTE";

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
        var requestedHotelCheckOutDate = normalizedServiceType == HotelServiceType
            ? request.HotelCheckOutDate ?? trip.EndDate
            : null;
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
                item.ServiceDate == request.ServiceDate &&
                item.HotelCheckOutDate == requestedHotelCheckOutDate)
            : null;

        if (normalizedServiceType == HotelServiceType)
        {
            await ValidateHotelBookingAsync(trip, request, existingHotelItinerary);
        }

        if (normalizedServiceType == BusServiceType && !string.IsNullOrEmpty(request.SelectedSeats))
        {
            await LockSeatsAsync(tripId, request.ServiceId, request.SelectedSeats);
        }

        if (existingHotelItinerary != null)
        {
            existingHotelItinerary.Quantity = (existingHotelItinerary.Quantity ?? 1) + request.Quantity;
            existingHotelItinerary.AdultCount += request.AdultCount;
            existingHotelItinerary.ChildCount += request.ChildCount;
            existingHotelItinerary.InfantCount += request.InfantCount;
            existingHotelItinerary.BookedPrice = request.BookedPrice ?? existingHotelItinerary.BookedPrice;
            existingHotelItinerary.BookedCommissionRate = request.BookedCommissionRate ?? existingHotelItinerary.BookedCommissionRate;
            existingHotelItinerary.ServiceDate = request.ServiceDate ?? existingHotelItinerary.ServiceDate;
            existingHotelItinerary.HotelCheckOutDate = requestedHotelCheckOutDate ?? existingHotelItinerary.HotelCheckOutDate;
            existingHotelItinerary.DepartureTime = request.DepartureTime ?? existingHotelItinerary.DepartureTime;
            existingHotelItinerary.ServiceAddress = request.ServiceAddress ?? existingHotelItinerary.ServiceAddress;

            await _context.SaveChangesAsync();
            await RecalculateTripTotalsWithPaymentsAsync(tripId);

            return await MapItineraryAsync(existingHotelItinerary);
        }

        var itinerary = new TripItinerary
        {
            TripId = tripId,
            DayNumber = request.DayNumber,
            ServiceType = TripServiceOptionService.ParseServiceTypeEnum(request.ServiceType),
            ServiceId = request.ServiceId,
            Quantity = request.Quantity,
            AdultCount = request.AdultCount,
            ChildCount = request.ChildCount,
            InfantCount = request.InfantCount,
            BookedPrice = request.BookedPrice ?? await ResolveDefaultBookedPriceAsync(normalizedServiceType, request.ServiceId, trip) ?? serviceOption.DefaultPrice ?? 0,
            BookedCommissionRate = request.BookedCommissionRate ?? serviceOption.DefaultCommissionRate ?? 0,
            ServiceDate = request.ServiceDate,
            HotelCheckOutDate = requestedHotelCheckOutDate,
            DepartureTime = request.DepartureTime,
            ServiceAddress = request.ServiceAddress,
            SelectedSeats = request.SelectedSeats
        };

        _context.TripItineraries.Add(itinerary);
        await _context.SaveChangesAsync();

        await RecalculateTripTotalsWithPaymentsAsync(tripId);

        return await MapItineraryAsync(itinerary);
    }

    public async Task<TripItineraryDto> MapItineraryAsync(TripItinerary itinerary)
    {
        var normalizedServiceType = TripServiceOptionService.NormalizeServiceType(itinerary.ServiceType?.ToString());
        var serviceName = $"Service #{itinerary.ServiceId}";
        string? serviceSubtitle = null;
        DateOnly? hotelCheckOutDate = null;

        if (normalizedServiceType == HotelServiceType && itinerary.ServiceId.HasValue)
        {
            var room = await _context.Rooms
                .AsNoTracking()
                .Include(item => item.Hotel)
                .ThenInclude(item => item!.Destination)
                .FirstOrDefaultAsync(item => item.Id == itinerary.ServiceId.Value);

            if (room?.Hotel != null)
            {
                var tripDates = itinerary.TripId.HasValue
                    ? await _context.Trips
                        .AsNoTracking()
                        .Where(item => item.Id == itinerary.TripId.Value)
                        .Select(item => new { item.StartDate, item.EndDate })
                        .FirstOrDefaultAsync()
                    : null;
                var checkInDate = itinerary.ServiceDate ?? tripDates?.StartDate;
                hotelCheckOutDate = ResolveHotelCheckOutDate(itinerary, checkInDate, tripDates?.EndDate);

                serviceName = room.Hotel.Name;
                serviceSubtitle = string.Join(" • ", new[]
                {
                    room.RoomType,
                    checkInDate.HasValue
                        ? FormatHotelBookingDateRange(checkInDate.Value, hotelCheckOutDate)
                        : null,
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
        else if (normalizedServiceType == NoteServiceType)
        {
            serviceName = "Ghi chú";
            serviceSubtitle = itinerary.ServiceAddress;
        }
        if (normalizedServiceType == NoteServiceType)
        {
            var noteLines = (itinerary.ServiceAddress ?? string.Empty)
                .Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(line => line.Trim())
                .Where(line => !string.IsNullOrWhiteSpace(line))
                .ToList();

            if (noteLines.Count > 0)
            {
                serviceName = noteLines[0];
                serviceSubtitle = noteLines.Count > 1
                    ? string.Join(" - ", noteLines.Skip(1))
                    : null;
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
            AdultCount = itinerary.AdultCount,
            ChildCount = itinerary.ChildCount,
            InfantCount = itinerary.InfantCount,
            BookedPrice = itinerary.BookedPrice,
            BookedCommissionRate = itinerary.BookedCommissionRate,
            ServiceDate = itinerary.ServiceDate,
            HotelCheckOutDate = hotelCheckOutDate,
            DepartureTime = itinerary.DepartureTime,
            ServiceAddress = itinerary.ServiceAddress,
            SelectedSeats = itinerary.SelectedSeats
        };
    }

    public async Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request)
    {
        var itinerary = await _context.TripItineraries.FirstOrDefaultAsync(item => item.Id == itineraryId);
        if (itinerary == null)
        {
            throw new KeyNotFoundException($"Itinerary {itineraryId} was not found.");
        }

        if (request.TripId.HasValue && request.TripId.Value != itinerary.TripId)
        {
            var newTrip = await _context.Trips.FirstOrDefaultAsync(t => t.Id == request.TripId.Value);
            if (newTrip == null)
            {
                throw new KeyNotFoundException($"Target Trip {request.TripId.Value} was not found.");
            }

            var oldTripId = itinerary.TripId;
            itinerary.TripId = request.TripId.Value;

            if (request.DayNumber.HasValue)
            {
                itinerary.DayNumber = request.DayNumber.Value;
            }
            else
            {
                itinerary.DayNumber = 1;
            }

            // Move payments and invoices associated with old trip to new trip
            if (oldTripId.HasValue)
            {
                var payments = await _context.Payments
                    .Where(p => p.TripId == oldTripId.Value)
                    .ToListAsync();
                foreach (var payment in payments)
                {
                    payment.TripId = request.TripId.Value;
                }

                var invoices = await _context.Invoices
                    .Where(i => i.TripId == oldTripId.Value)
                    .ToListAsync();
                foreach (var invoice in invoices)
                {
                    invoice.TripId = request.TripId.Value;
                }
            }

            await _context.SaveChangesAsync();

            // Recalculate totals and profit for both trips
            if (oldTripId.HasValue)
            {
                await RecalculateTripTotalsWithPaymentsAsync(oldTripId.Value);

                // If old trip was BOOKING_ONLY and now has no itineraries, delete it
                var oldTrip = await _context.Trips
                    .Include(t => t.TripItineraries)
                    .FirstOrDefaultAsync(t => t.Id == oldTripId.Value);
                if (oldTrip != null && oldTrip.Status == TripStatus.BookingOnly && !oldTrip.TripItineraries.Any())
                {
                    _context.Trips.Remove(oldTrip);
                    await _context.SaveChangesAsync();
                }
            }

            await RecalculateTripTotalsWithPaymentsAsync(request.TripId.Value);
        }
        else
        {
            if (request.DayNumber.HasValue)
            {
                var trip = await _context.Trips.FirstAsync(item => item.Id == itinerary.TripId);
                ValidateDayNumber(trip, request.DayNumber.Value);
                itinerary.DayNumber = request.DayNumber.Value;
            }
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

        if (request.HotelCheckOutDate.HasValue)
        {
            itinerary.HotelCheckOutDate = request.HotelCheckOutDate.Value;
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

        if (itinerary.TripId.HasValue && (!request.TripId.HasValue || request.TripId.Value == itinerary.TripId))
        {
            await RecalculateTripTotalsWithPaymentsAsync(itinerary.TripId.Value);
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
            await RecalculateTripTotalsWithPaymentsAsync(tripId.Value);
        }

        return true;
    }

    private async Task ValidateHotelBookingAsync(TripEntity trip, CreateTripItineraryDto request, TripItinerary? existingHotelItinerary)
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

        ValidateHotelGuestCapacity(
            room.Capacity.GetValueOrDefault(1),
            request.Quantity,
            request.AdultCount,
            request.ChildCount,
            request.InfantCount);

        var checkOut = ResolveHotelCheckOutDate(request, checkIn, tripEnd);
        if (checkOut <= checkIn)
        {
            throw new ArgumentException("Check-out date must be after check-in date.");
        }

        var extraGuestCount = Math.Max(
            0,
            request.AdultCount + request.ChildCount -
            room.Capacity.GetValueOrDefault(1) * request.Quantity);
        var nights = Math.Max(1, checkOut.DayNumber - checkIn.DayNumber);
        var roomPrice = room.PricePerNight.GetValueOrDefault();
        var minimumBookingTotal =
            roomPrice * nights * request.Quantity +
            roomPrice * 0.2m * nights * extraGuestCount;
        var submittedBookingTotal =
            request.BookedPrice.GetValueOrDefault() * request.Quantity;
        if (request.BookedPrice.HasValue && submittedBookingTotal < minimumBookingTotal)
        {
            throw new ArgumentException("Tong tien dat phong chua bao gom phu thu khach vuot suc chua.");
        }

        var lastUsedDate = checkOut.AddDays(-1);
        if (checkIn < tripStart || lastUsedDate > tripEnd)
        {
            throw new ArgumentException("Hotel booking dates must be within the selected trip dates.");
        }

        var totalRooms = room.AvailableQty ?? 0;
        if (totalRooms <= 0)
        {
            throw new InvalidOperationException("This room type is currently sold out.");
        }

        var requestedTotalInTrip = (existingHotelItinerary?.Quantity ?? 0) + request.Quantity;
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
                (existingHotelItinerary == null || item.Id != existingHotelItinerary.Id) &&
                item.Trip != null &&
                item.Trip.Status != TripStatus.Cancelled &&
                item.Trip.StartDate.HasValue &&
                item.Trip.EndDate.HasValue)
            .ToListAsync();

        var bookedRooms = GetPeakBookedQtyForDateRange(
            checkIn,
            checkOut,
            overlappingBookings.Select(item =>
            {
                var bookedCheckIn = item.ServiceDate ?? item.Trip!.StartDate!.Value;
                var bookedCheckOut = ResolveHotelCheckOutDate(item, bookedCheckIn, item.Trip!.EndDate!.Value);

                return (StartDate: bookedCheckIn, EndDate: bookedCheckOut, Quantity: item.Quantity ?? 1);
            }));

        var remainingRooms = totalRooms - bookedRooms;
        if (requestedTotalInTrip > remainingRooms)
        {
            throw new InvalidOperationException($"Only {Math.Max(remainingRooms, 0)} room(s) are still available for these dates.");
        }
    }

    private static void ValidateHotelGuestCapacity(
        int roomCapacity,
        int roomQuantity,
        int adultCount,
        int childCount,
        int infantCount)
    {
        if (roomQuantity <= 0)
        {
            throw new ArgumentException("So luong phong khong hop le.");
        }
        if (adultCount < roomQuantity)
        {
            throw new ArgumentException("Moi phong phai co it nhat mot nguoi lon.");
        }
        if (childCount < 0 || infantCount < 0)
        {
            throw new ArgumentException("So luong khach khong hop le.");
        }

        var standardCapacity = Math.Max(roomCapacity, 1) * roomQuantity;
        var maximumCapacityWithExtraGuest = (Math.Max(roomCapacity, 1) + 1) * roomQuantity;
        var countedGuests = adultCount + childCount;
        if (countedGuests > maximumCapacityWithExtraGuest)
        {
            throw new ArgumentException(
                $"Toi da {maximumCapacityWithExtraGuest} khach cho {roomQuantity} phong, bao gom toi da 1 khach phu thu moi phong.");
        }
        if (infantCount > roomQuantity)
        {
            throw new ArgumentException("Moi phong chi duoc khai bao toi da mot em be duoi 2 tuoi.");
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

    private static DateOnly ResolveHotelCheckOutDate(
        CreateTripItineraryDto request,
        DateOnly checkIn,
        DateOnly fallbackCheckOut)
    {
        return NormalizeHotelCheckOutDate(checkIn, request.HotelCheckOutDate ?? fallbackCheckOut);
    }

    private static DateOnly ResolveHotelCheckOutDate(
        TripItinerary itinerary,
        DateOnly? checkIn,
        DateOnly? fallbackCheckOut)
    {
        var resolvedCheckIn = checkIn ?? itinerary.ServiceDate;
        if (!resolvedCheckIn.HasValue)
        {
            return fallbackCheckOut ?? DateOnly.FromDateTime(DateTime.UtcNow).AddDays(1);
        }

        return NormalizeHotelCheckOutDate(
            resolvedCheckIn.Value,
            itinerary.HotelCheckOutDate ?? fallbackCheckOut ?? resolvedCheckIn.Value.AddDays(1));
    }

    private static DateOnly NormalizeHotelCheckOutDate(
        DateOnly checkIn,
        DateOnly fallbackCheckOut)
    {
        return fallbackCheckOut > checkIn ? fallbackCheckOut : checkIn.AddDays(1);
    }

    private static int GetPeakBookedQtyForDateRange(
        DateOnly checkInDate,
        DateOnly checkOutDate,
        IEnumerable<(DateOnly StartDate, DateOnly EndDate, int Quantity)> bookings)
    {
        var peakBookedQty = 0;

        for (var date = checkInDate; date < checkOutDate; date = date.AddDays(1))
        {
            var bookedQtyForDate = bookings
                .Where(item => item.StartDate <= date && item.EndDate > date)
                .Sum(item => item.Quantity <= 0 ? 0 : item.Quantity);

            if (bookedQtyForDate > peakBookedQty)
            {
                peakBookedQty = bookedQtyForDate;
            }
        }

        return peakBookedQty;
    }

    private static string FormatHotelBookingDateRange(DateOnly checkIn, DateOnly? checkOut)
    {
        if (!checkOut.HasValue)
        {
            return $"Nhan phong {checkIn:dd/MM/yyyy}";
        }

        return $"Nhan phong {checkIn:dd/MM/yyyy} - Tra phong {checkOut.Value:dd/MM/yyyy}";
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


    private async Task RecalculateTripTotalsWithPaymentsAsync(int tripId)
    {
        var trip = await _context.Trips
            .Include(item => item.TripItineraries)
            .Include(item => item.Payments)
            .FirstOrDefaultAsync(item => item.Id == tripId);

        if (trip == null) return;

        trip.TotalAmount = trip.TripItineraries.Sum(item =>
            (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

        var totalPaidAmount = trip.Payments
            .Where(p => p.Status == PaymentStatus.Paid)
            .Sum(p => p.Amount ?? 0m);

        if (totalPaidAmount <= 0)
        {
            trip.TotalProfit = 0m;
        }
        else
        {
            var grossAmount = trip.TripItineraries.Sum(item =>
                (item.BookedPrice ?? 0) * (item.Quantity ?? 1));

            if (grossAmount <= 0)
            {
                trip.TotalProfit = 0m;
            }
            else
            {
                var originalCommission = trip.TripItineraries.Sum(item =>
                {
                    var lineGross = (item.BookedPrice ?? 0) * (item.Quantity ?? 1);
                    return lineGross * (decimal)((item.BookedCommissionRate ?? 0) / 100d);
                });
                var discount = Math.Max(0m, grossAmount - totalPaidAmount);
                trip.TotalProfit = originalCommission - discount;
            }
        }

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

    private async Task LockSeatsAsync(int tripId, int scheduleId, string selectedSeatsString)
    {
        var seatNumbers = selectedSeatsString.Split(',', StringSplitOptions.RemoveEmptyEntries)
            .Select(s => s.Trim())
            .ToList();

        if (!seatNumbers.Any()) return;

        var seats = await _context.Seats
            .Where(s => s.ScheduleId == scheduleId && s.SeatNumber != null && seatNumbers.Contains(s.SeatNumber))
            .ToListAsync();

        foreach (var seatNum in seatNumbers)
        {
            var seat = seats.FirstOrDefault(s => s.SeatNumber == seatNum);
            if (seat == null)
            {
                throw new KeyNotFoundException($"Ghế {seatNum} không tồn tại trên tuyến xe này.");
            }

            if (seat.Status == SeatStatus.Booked)
            {
                throw new InvalidOperationException($"Ghế {seatNum} đã được đặt trước bởi hành khách khác.");
            }

            if (seat.Status == SeatStatus.Locked && seat.LockedUntil.HasValue && seat.LockedUntil.Value > DateTime.UtcNow && seat.LockedByTripId != tripId)
            {
                throw new InvalidOperationException($"Ghế {seatNum} đang được giữ bởi người khác. Vui lòng chọn ghế khác.");
            }
        }

        foreach (var seat in seats)
        {
            seat.Status = SeatStatus.Locked;
            seat.LockedUntil = DateTime.UtcNow.AddMinutes(10);
            seat.LockedByTripId = tripId;
        }
    }
}
