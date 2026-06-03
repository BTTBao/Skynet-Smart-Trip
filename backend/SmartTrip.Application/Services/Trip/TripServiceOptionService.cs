using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Trip;
using SmartTrip.Application.Interfaces;
using SmartTrip.Application.Interfaces.Trip;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Application.Services.Trip;

public class TripServiceOptionService : ITripServiceOptionService
{
    private const string HotelServiceType = "HOTEL";
    private const string BusServiceType = "BUS";
    private const string NoteServiceType = "NOTE";

    private readonly IApplicationDbContext _context;

    public TripServiceOptionService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<TripServiceOptionDto>> GetServiceOptionsAsync(string serviceType, int? destinationId)
    {
        var normalizedServiceType = NormalizeServiceType(serviceType);

        if (normalizedServiceType == NoteServiceType)
        {
            return new List<TripServiceOptionDto>
            {
                new()
                {
                    ServiceId = 1,
                    ServiceType = NoteServiceType,
                    Title = "Ghi chú",
                    Subtitle = "Ghi lại nơi bạn muốn đi và thời gian dự kiến.",
                    DefaultPrice = 0,
                    DefaultCommissionRate = 0
                }
            };
        }

        if (normalizedServiceType == HotelServiceType)
        {
            var query = _context.Hotels
                .AsNoTracking()
                .Include(hotel => hotel.Destination)
                .Include(hotel => hotel.Rooms)
                .Where(hotel => hotel.IsAvailable != false);

            if (destinationId.HasValue)
            {
                query = query.Where(hotel => hotel.DestinationId == destinationId);
            }

            var hotels = await query
                .OrderBy(hotel => hotel.Name)
                .Take(20)
                .ToListAsync();

            return hotels
                .Select(hotel => new TripServiceOptionDto
                {
                    ServiceId = hotel.Id,
                    ServiceType = HotelServiceType,
                    Title = hotel.Name,
                    Subtitle = string.Join(" • ", new[]
                    {
                        hotel.Destination != null ? hotel.Destination.Name : null,
                        hotel.Address,
                        hotel.StarRating.HasValue ? $"{hotel.StarRating.Value} sao" : null
                    }.Where(value => !string.IsNullOrWhiteSpace(value))),
                    DefaultPrice = hotel.Rooms
                        .OrderBy(room => room.PricePerNight)
                        .Select(room => room.PricePerNight)
                        .FirstOrDefault(),
                    DefaultCommissionRate = null
                })
                .ToList();
        }

        var busQuery = _context.BusSchedules
            .AsNoTracking()
            .Include(schedule => schedule.Company)
            .Include(schedule => schedule.FromDest)
            .Include(schedule => schedule.ToDest)
            .AsQueryable();

        if (destinationId.HasValue)
        {
            busQuery = busQuery.Where(schedule =>
                schedule.FromDestId == destinationId || schedule.ToDestId == destinationId);
        }

        var busSchedules = await busQuery
            .OrderBy(schedule => schedule.DepartureTime)
            .Take(20)
            .ToListAsync();

        return busSchedules
            .Select(schedule => new TripServiceOptionDto
            {
                ServiceId = schedule.Id,
                ServiceType = BusServiceType,
                Title = $"{(schedule.Company != null ? schedule.Company.Name : "Xe khach")} - {(schedule.FromDest != null ? schedule.FromDest.Name : "N/A")} -> {(schedule.ToDest != null ? schedule.ToDest.Name : "N/A")}",
                Subtitle = BuildBusSubtitle(schedule),
                DefaultPrice = schedule.Price,
                DefaultCommissionRate = schedule.CommissionRate
            })
            .ToList();
    }

    public async Task<TripServiceOptionDto?> GetServiceOptionByIdAsync(string serviceType, int serviceId)
    {
        var normalizedServiceType = NormalizeServiceType(serviceType);

        if (normalizedServiceType == NoteServiceType)
        {
            return new TripServiceOptionDto
            {
                ServiceId = serviceId <= 0 ? 1 : serviceId,
                ServiceType = NoteServiceType,
                Title = "Ghi chú",
                Subtitle = "Ghi lại nơi bạn muốn đi và thời gian dự kiến.",
                DefaultPrice = 0,
                DefaultCommissionRate = 0
            };
        }

        if (normalizedServiceType == HotelServiceType)
        {
            var room = await _context.Rooms
                .AsNoTracking()
                .Include(item => item.Hotel)
                .ThenInclude(item => item!.Destination)
                .FirstOrDefaultAsync(item =>
                    item.Id == serviceId &&
                    item.Hotel != null &&
                    item.Hotel.IsAvailable != false);

            if (room?.Hotel == null)
            {
                return null;
            }

            return new TripServiceOptionDto
            {
                ServiceId = room.Id,
                ServiceType = HotelServiceType,
                Title = room.Hotel.Name,
                Subtitle = string.Join(" • ", new[]
                {
                    room.RoomType,
                    room.Hotel.Destination != null ? room.Hotel.Destination.Name : null,
                    room.Hotel.Address
                }.Where(value => !string.IsNullOrWhiteSpace(value))),
                DefaultPrice = room.PricePerNight,
                DefaultCommissionRate = room.CommissionRate
            };
        }

        var busSchedule = await _context.BusSchedules
            .AsNoTracking()
            .Include(item => item.Company)
            .Include(item => item.FromDest)
            .Include(item => item.ToDest)
            .FirstOrDefaultAsync(item => item.Id == serviceId);

        if (busSchedule == null)
        {
            return null;
        }

        return new TripServiceOptionDto
        {
            ServiceId = busSchedule.Id,
            ServiceType = BusServiceType,
            Title = $"{(busSchedule.Company != null ? busSchedule.Company.Name : "Xe khach")} - {(busSchedule.FromDest != null ? busSchedule.FromDest.Name : "N/A")} -> {(busSchedule.ToDest != null ? busSchedule.ToDest.Name : "N/A")}",
            Subtitle = BuildBusSubtitle(busSchedule),
            DefaultPrice = busSchedule.Price,
            DefaultCommissionRate = busSchedule.CommissionRate
        };
    }

    public static string NormalizeServiceType(string? serviceType)
    {
        if (Enum.TryParse<TripServiceType>(serviceType, true, out var parsedServiceType))
        {
            return parsedServiceType switch
            {
                TripServiceType.Hotel => HotelServiceType,
                TripServiceType.Bus => BusServiceType,
                TripServiceType.Note => NoteServiceType,
                _ => throw new ArgumentException("Unsupported service type.")
            };
        }

        return serviceType?.Trim().ToUpperInvariant() switch
        {
            HotelServiceType => HotelServiceType,
            BusServiceType => BusServiceType,
            NoteServiceType => NoteServiceType,
            _ => throw new ArgumentException("ServiceType must be HOTEL, BUS, or NOTE.")
        };
    }

    public static TripServiceType ParseServiceTypeEnum(string? serviceType)
    {
        if (Enum.TryParse<TripServiceType>(serviceType, true, out var parsedServiceType))
        {
            return parsedServiceType;
        }

        return serviceType?.Trim().ToUpperInvariant() switch
        {
            HotelServiceType => TripServiceType.Hotel,
            BusServiceType => TripServiceType.Bus,
            NoteServiceType => TripServiceType.Note,
            _ => throw new ArgumentException("ServiceType must be HOTEL, BUS, or NOTE.")
        };
    }

    private static string BuildBusSubtitle(BusSchedule schedule)
    {
        var departure = schedule.DepartureTime?.ToString("HH:mm dd/MM");
        var arrival = schedule.ArrivalTime?.ToString("HH:mm dd/MM");

        return string.Join(" • ", new[]
        {
            !string.IsNullOrWhiteSpace(departure) ? $"Di: {departure}" : null,
            !string.IsNullOrWhiteSpace(arrival) ? $"Den: {arrival}" : null,
            schedule.TotalSeats.HasValue ? $"Ghe: {schedule.TotalSeats.Value}" : null
        }.Where(value => !string.IsNullOrWhiteSpace(value)));
    }
}
