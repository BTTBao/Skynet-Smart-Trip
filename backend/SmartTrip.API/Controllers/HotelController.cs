using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Enums;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HotelController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public HotelController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET /api/hotel?destinationId=1
    [HttpGet]
    public async Task<IActionResult> GetHotels([FromQuery] int? destinationId)
    {
        var query = _context.Hotels
            .Include(h => h.Rooms)
            .Include(h => h.Amenities)
            .Include(h => h.Destination)
            .Where(h => h.IsAvailable == true);

        if (destinationId.HasValue)
            query = query.Where(h => h.DestinationId == destinationId.Value);

        var hotels = await query
            .OrderBy(h => h.StarRating)
            .ToListAsync();

        // Lấy review aggregates
        var hotelIds = hotels.Select(h => h.Id).ToList();
        var reviewStats = await _context.Reviews
            .Where(r => r.TargetType == ReviewTargetType.Hotel && r.TargetId != null && hotelIds.Contains(r.TargetId!.Value))
            .GroupBy(r => r.TargetId)
            .Select(g => new
            {
                HotelId = g.Key,
                AvgRating = g.Average(r => (double?)r.Rating) ?? 0,
                ReviewCount = g.Count()
            })
            .ToListAsync();

        // Lấy ảnh cover đầu tiên của mỗi hotel
        var coverImages = await _context.Galleries
            .Where(g => g.ReferenceType == GalleryReferenceType.Hotel && g.ReferenceId != null && hotelIds.Contains(g.ReferenceId!.Value))
            .GroupBy(g => g.ReferenceId)
            .Select(g => new { HotelId = g.Key, CoverUrl = g.OrderBy(x => x.Id).First().ImageUrl })
            .ToListAsync();

        var result = hotels.Select(h =>
        {
            var stats = reviewStats.FirstOrDefault(r => r.HotelId == h.Id);
            var cover = coverImages.FirstOrDefault(c => c.HotelId == h.Id);
            var minPrice = h.Rooms.Any() ? h.Rooms.Min(r => r.PricePerNight) : 0;

            return new
            {
                h.Id,
                h.DestinationId,
                DestinationName = h.Destination != null ? h.Destination.Name : "",
                h.Name,
                h.Address,
                h.StarRating,
                h.Description,
                MinPricePerNight = minPrice,
                CoverImageUrl = cover?.CoverUrl ?? "",
                AvgRating = Math.Round(stats?.AvgRating ?? 0, 1),
                ReviewCount = stats?.ReviewCount ?? 0,
                Amenities = h.Amenities.Take(5).Select(a => new { a.Name, a.IconUrl })
            };
        });

        return Ok(result);
    }

    // GET /api/hotel/{id}
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetHotelDetail(int id)
    {
        var hotel = await _context.Hotels
            .Include(h => h.Rooms)
            .Include(h => h.Amenities)
            .Include(h => h.Destination)
            .FirstOrDefaultAsync(h => h.Id == id);

        if (hotel is null) return NotFound(new { message = "Không tìm thấy khách sạn." });

        var images = await _context.Galleries
            .Where(g => g.ReferenceType == GalleryReferenceType.Hotel && g.ReferenceId == id)
            .OrderBy(g => g.Id)
            .Select(g => g.ImageUrl)
            .ToListAsync();

        var roomIds = hotel.Rooms.Select(r => r.Id).ToList();
        var roomImages = await _context.Galleries
            .Where(g =>
                g.ReferenceType == GalleryReferenceType.Room &&
                g.ReferenceId.HasValue &&
                roomIds.Contains(g.ReferenceId.Value))
            .OrderBy(g => g.Id)
            .GroupBy(g => g.ReferenceId!.Value)
            .ToDictionaryAsync(
                group => group.Key,
                group => group
                    .Select(g => g.ImageUrl ?? string.Empty)
                    .Where(url => !string.IsNullOrWhiteSpace(url))
                    .ToList());

        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.TargetType == ReviewTargetType.Hotel && r.TargetId == id)
            .OrderByDescending(r => r.CreatedAt)
            .Take(10)
            .Select(r => new
            {
                r.Id,
                UserName = r.User != null ? r.User.FullName : "Khách ẩn danh",
                UserAvatar = r.User != null ? r.User.AvatarUrl : null,
                r.Rating,
                r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();

        var avgRating = reviews.Any() ? Math.Round(reviews.Average(r => (double)(r.Rating ?? 0)), 1) : 0;

        var minPrice = hotel.Rooms.Any() ? hotel.Rooms.Min(r => r.PricePerNight) : 0;

        return Ok(new
        {
            hotel.Id,
            hotel.DestinationId,
            DestinationName = hotel.Destination != null ? hotel.Destination.Name : "",
            hotel.Name,
            hotel.Address,
            hotel.StarRating,
            hotel.Description,
            MinPricePerNight = minPrice,
            AvgRating = avgRating,
            ReviewCount = reviews.Count,
            ImageUrls = images,
            Amenities = hotel.Amenities.Select(a => new { a.Name, a.IconUrl }),
            Rooms = hotel.Rooms.Select(r => new
            {
                r.Id,
                r.RoomType,
                r.Capacity,
                r.PricePerNight,
                r.AvailableQty,
                ImageUrls = roomImages.TryGetValue(r.Id, out var urls) ? urls : []
            }),
            Reviews = reviews
        });
    }

    // GET /api/hotel/{id}/calendar?year=2025&month=6
    // Trả về lịch giá động theo từng ngày trong tháng — giống Booking.com / Agoda
    [HttpGet("{id:int}/calendar")]
    public async Task<IActionResult> GetHotelCalendar(
        int id,
        [FromQuery] int year,
        [FromQuery] int month,
        [FromQuery] int? roomId)
    {
        if (year < 2020 || year > 2030 || month < 1 || month > 12)
            return BadRequest(new { message = "Tháng/năm không hợp lệ." });

        var hotel = await _context.Hotels
            .Include(h => h.Rooms)
            .FirstOrDefaultAsync(h => h.Id == id);

        if (hotel is null) return NotFound();
        if (!hotel.Rooms.Any()) return Ok(new { hotelId = id, year, month, days = Array.Empty<object>() });
        if (roomId.HasValue && hotel.Rooms.All(room => room.Id != roomId.Value))
        {
            return NotFound(new { message = "Room was not found for this hotel." });
        }

        // Lấy tất cả trip đã đặt các phòng của khách sạn này trong khoảng tháng cần xem
        var startOfMonth = new DateOnly(year, month, 1);
        var endOfMonth = startOfMonth.AddMonths(1);
        var selectedRooms = roomId.HasValue
            ? hotel.Rooms.Where(room => room.Id == roomId.Value).ToList()
            : hotel.Rooms.ToList();
        var roomIds = selectedRooms.Select(room => room.Id).ToList();

        var bookedItineraries = await _context.TripItineraries
            .Include(ti => ti.Trip)
            .Where(ti =>
                ti.ServiceType == TripServiceType.Hotel &&
                ti.ServiceId.HasValue &&
                roomIds.Contains(ti.ServiceId.Value) &&
                ti.Trip != null &&
                ti.Trip.StartDate.HasValue &&
                ti.Trip.EndDate.HasValue &&
                ti.Trip.StartDate < endOfMonth &&
                ti.Trip.EndDate > startOfMonth &&
                ti.Trip.Status != TripStatus.Cancelled &&
                ti.Trip.Status != TripStatus.Draft)
            .Select(ti => new
            {
                ti.ServiceId,
                ti.ServiceDate,
                ti.BookedPrice,
                StartDate = ti.Trip!.StartDate!.Value,
                EndDate = ti.Trip!.EndDate!.Value,
                Quantity = ti.Quantity ?? 1
            })
            .ToListAsync();

        // Tổng số phòng của khách sạn
        int totalRooms = selectedRooms.Sum(r => r.AvailableQty ?? 0);
        decimal basePrice = selectedRooms.Min(r => r.PricePerNight) ?? 0;
        var selectedRoomType = roomId.HasValue
            ? selectedRooms.FirstOrDefault()?.RoomType
            : null;
        var roomPriceLookup = selectedRooms.ToDictionary(
            room => room.Id,
            room => room.PricePerNight ?? 0);

        int daysInMonth = DateTime.DaysInMonth(year, month);
        var days = new List<object>();

        for (int day = 1; day <= daysInMonth; day++)
        {
            var date = new DateOnly(year, month, day);

            // Tính số phòng đã đặt cho ngày này
            int bookedQty = bookedItineraries
                .Where(b =>
                {
                    var bookingStart = b.ServiceDate ?? b.StartDate;
                    var bookingEnd = ResolveHotelBookingEndDate(
                        bookingStart,
                        b.EndDate,
                        b.BookedPrice,
                        b.ServiceId.HasValue && roomPriceLookup.TryGetValue(b.ServiceId.Value, out var roomPrice)
                            ? roomPrice
                            : basePrice);

                    return bookingStart <= date && bookingEnd > date;
                })
                .Sum(b => b.Quantity);

            int availableRooms = totalRooms - bookedQty;
            bool available = availableRooms > 0;

            // === THUẬT TOÁN GIÁ ĐỘNG (nghiệp vụ thực tế) ===
            decimal price = basePrice;

            // 1. Cuối tuần (Thứ 6, Thứ 7): +30%
            var dayOfWeek = date.DayOfWeek;
            if (dayOfWeek == DayOfWeek.Friday || dayOfWeek == DayOfWeek.Saturday)
                price = Math.Round(price * 1.3m / 1000m) * 1000m; // làm tròn đến ngàn

            // 2. Mùa cao điểm: Tháng 4 (lễ 30/4), Tháng 7-8 (hè), Tháng 12 (Noel/Tết dương): +20%
            if (month == 4 || month == 7 || month == 8 || month == 12)
                price = Math.Round(price * 1.2m / 1000m) * 1000m;

            // 3. Ngày lễ đặc biệt: 30/4, 1/5, 2/9, 1/1: +50%
            bool isHoliday = (month == 4 && day == 30) ||
                             (month == 5 && day == 1) ||
                             (month == 9 && day == 2) ||
                             (month == 1 && day == 1);
            if (isHoliday)
                price = Math.Round(basePrice * 1.5m / 1000m) * 1000m;

            // 4. Còn ít phòng (≤ 20% tổng): +10% (khan hiếm thực tế)
            if (available && availableRooms <= Math.Max(1, totalRooms / 5))
                price = Math.Round(price * 1.1m / 1000m) * 1000m;

            days.Add(new
            {
                Date = date.ToString("yyyy-MM-dd"),
                Price = price,
                Available = available,
                AvailableRooms = Math.Max(0, availableRooms),
                IsWeekend = dayOfWeek == DayOfWeek.Friday || dayOfWeek == DayOfWeek.Saturday || dayOfWeek == DayOfWeek.Sunday,
                IsHoliday = isHoliday
            });
        }

        return Ok(new
        {
            HotelId = id,
            RoomId = roomId,
            RoomType = selectedRoomType,
            Year = year,
            Month = month,
            BasePrice = basePrice,
            Days = days
        });
    }

    private static DateOnly ResolveHotelBookingEndDate(
        DateOnly checkInDate,
        DateOnly fallbackCheckOutDate,
        decimal? bookedPrice,
        decimal? pricePerNight)
    {
        if (bookedPrice.HasValue && pricePerNight.HasValue && pricePerNight.Value > 0)
        {
            var nightsValue = bookedPrice.Value / pricePerNight.Value;
            var roundedNights = (int)Math.Round(nightsValue, MidpointRounding.AwayFromZero);

            if (roundedNights > 0 && Math.Abs(nightsValue - roundedNights) < 0.01m)
            {
                return checkInDate.AddDays(roundedNights);
            }
        }

        return fallbackCheckOutDate;
    }
}
