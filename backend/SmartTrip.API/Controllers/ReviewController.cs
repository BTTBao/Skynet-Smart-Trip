using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using System.Security.Claims;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/reviews")]
public class ReviewController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ReviewController(ApplicationDbContext context)
    {
        _context = context;
    }

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateReview([FromBody] CreateReviewRequest dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null) return Unauthorized();

        if (dto.Rating < 1 || dto.Rating > 5)
        {
            return BadRequest(new { message = "Diem danh gia phai tu 1 den 5 sao." });
        }

        if (!Enum.TryParse<ReviewTargetType>(dto.TargetType, true, out var targetType))
        {
            return BadRequest(new { message = "Loai dich vu danh gia khong hop le." });
        }

        var trip = await _context.Trips
            .AsNoTracking()
            .Include(t => t.TripItineraries)
            .Include(t => t.Payments)
            .FirstOrDefaultAsync(t => t.Id == dto.TripId && t.UserId == userId.Value);
        if (trip == null)
        {
            return BadRequest(new { message = "Chuyen di khong ton tai hoac khong thuoc ve ban." });
        }

        var hasPaidPayment = trip.Status == TripStatus.Paid ||
            trip.Payments.Any(payment => payment.Status == PaymentStatus.Paid);
        if (!hasPaidPayment)
        {
            return BadRequest(new { message = "Ban chi co the danh gia sau khi thanh toan thanh cong." });
        }

        var completionValidationError = await ValidateReviewCompletionAsync(trip, targetType, dto.TargetId);
        if (completionValidationError != null)
        {
            return BadRequest(new { message = completionValidationError });
        }

        var alreadyReviewed = await _context.Reviews.AnyAsync(r =>
            r.UserId == userId.Value &&
            r.TripId == dto.TripId &&
            r.TargetType == targetType &&
            r.TargetId == dto.TargetId);

        if (alreadyReviewed)
        {
            return BadRequest(new { message = "Ban da danh gia dich vu nay cho chuyen di nay roi." });
        }

        var review = new Review
        {
            UserId = userId.Value,
            TripId = dto.TripId,
            TargetType = targetType,
            TargetId = dto.TargetId,
            Rating = dto.Rating,
            Comment = dto.Comment,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Danh gia cua ban da duoc gui thanh cong!" });
    }

    private async Task<string?> ValidateReviewCompletionAsync(Trip trip, ReviewTargetType targetType, int targetId)
    {
        switch (targetType)
        {
            case ReviewTargetType.Hotel:
            {
                var hotelItineraries = trip.TripItineraries
                    .Where(item => item.ServiceType == TripServiceType.Hotel && item.ServiceId.HasValue)
                    .ToList();
                if (hotelItineraries.Count == 0)
                {
                    return "Chuyen di nay khong chua dich vu khach san de danh gia.";
                }

                var roomIds = hotelItineraries
                    .Select(item => item.ServiceId!.Value)
                    .Distinct()
                    .ToList();
                var roomHotelLookup = await _context.Rooms
                    .AsNoTracking()
                    .Where(room => roomIds.Contains(room.Id) && room.HotelId.HasValue)
                    .Select(room => new { room.Id, HotelId = room.HotelId!.Value })
                    .ToDictionaryAsync(item => item.Id, item => item.HotelId);

                var matchedItineraries = hotelItineraries
                    .Where(item =>
                        item.ServiceId.HasValue &&
                        roomHotelLookup.TryGetValue(item.ServiceId.Value, out var hotelId) &&
                        hotelId == targetId)
                    .ToList();
                if (matchedItineraries.Count == 0)
                {
                    return "Khach san nay khong thuoc chuyen di de danh gia.";
                }

                var completedDate = matchedItineraries
                    .Select(item => item.HotelCheckOutDate ?? trip.EndDate)
                    .Where(item => item.HasValue)
                    .Select(item => item!.Value)
                    .OrderByDescending(item => item)
                    .FirstOrDefault();
                if (completedDate == default)
                {
                    return "Chua du du lieu de xac nhan ngay tra phong.";
                }

                return DateOnly.FromDateTime(DateTime.Now) > completedDate
                    ? null
                    : "Ban chi co the danh gia sau ngay tra phong.";
            }

            case ReviewTargetType.BusCompany:
            {
                var busItineraries = trip.TripItineraries
                    .Where(item => item.ServiceType == TripServiceType.Bus && item.ServiceId.HasValue)
                    .ToList();
                if (busItineraries.Count == 0)
                {
                    return "Chuyen di nay khong chua dich vu xe khach de danh gia.";
                }

                var scheduleIds = busItineraries
                    .Select(item => item.ServiceId!.Value)
                    .Distinct()
                    .ToList();
                var scheduleLookup = await _context.BusSchedules
                    .AsNoTracking()
                    .Where(schedule => scheduleIds.Contains(schedule.Id) && schedule.CompanyId.HasValue)
                    .Select(schedule => new
                    {
                        schedule.Id,
                        CompanyId = schedule.CompanyId!.Value,
                        schedule.ArrivalTime
                    })
                    .ToDictionaryAsync(item => item.Id);

                var completedAt = busItineraries
                    .Where(item =>
                        item.ServiceId.HasValue &&
                        scheduleLookup.TryGetValue(item.ServiceId.Value, out var schedule) &&
                        schedule.CompanyId == targetId)
                    .Select(item => scheduleLookup[item.ServiceId!.Value].ArrivalTime)
                    .Where(item => item.HasValue)
                    .Select(item => item!.Value)
                    .OrderByDescending(item => item)
                    .FirstOrDefault();
                if (completedAt == default)
                {
                    return "Nha xe nay khong thuoc chuyen di de danh gia.";
                }

                return DateTime.Now >= completedAt
                    ? null
                    : "Ban chi co the danh gia sau khi chuyen xe ket thuc.";
            }

            default:
                return "Loai dich vu danh gia khong hop le.";
        }
    }

    private int? GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        return int.TryParse(rawUserId, out var userId) ? userId : null;
    }
}

public class CreateReviewRequest
{
    public int TripId { get; set; }
    public string TargetType { get; set; } = string.Empty;
    public int TargetId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
