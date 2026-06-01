using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

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
            return BadRequest(new { message = "Điểm đánh giá phải từ 1 đến 5 sao." });
        }

        if (!Enum.TryParse<ReviewTargetType>(dto.TargetType, true, out var targetType))
        {
            return BadRequest(new { message = "Loại dịch vụ đánh giá không hợp lệ." });
        }

        // Kiểm tra xem trip có thuộc về user không
        var ownsTrip = await _context.Trips.AnyAsync(t => t.Id == dto.TripId && t.UserId == userId.Value);
        if (!ownsTrip)
        {
            return BadRequest(new { message = "Chuyến đi không tồn tại hoặc không thuộc về bạn." });
        }

        // Kiểm tra xem đã đánh giá chưa
        var alreadyReviewed = await _context.Reviews.AnyAsync(r => 
            r.UserId == userId.Value && 
            r.TripId == dto.TripId && 
            r.TargetType == targetType && 
            r.TargetId == dto.TargetId);

        if (alreadyReviewed)
        {
            return BadRequest(new { message = "Bạn đã đánh giá dịch vụ này cho chuyến đi này rồi." });
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

        return Ok(new { message = "Đánh giá của bạn đã được gửi thành công!" });
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
    public string TargetType { get; set; } = string.Empty; // "Hotel" or "BusCompany"
    public int TargetId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
