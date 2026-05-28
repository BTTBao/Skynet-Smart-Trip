using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/bus")]
public class BusController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public BusController(ApplicationDbContext context)
    {
        _context = context;
    }

    // GET /api/bus/schedules?fromDestId=3&toDestId=1&date=2026-05-28
    [HttpGet("schedules")]
    public async Task<IActionResult> GetSchedules(
        [FromQuery] int? fromDestId,
        [FromQuery] int? toDestId,
        [FromQuery] string? date)
    {
        var query = _context.BusSchedules
            .Include(s => s.Company)
            .Include(s => s.FromDest)
            .Include(s => s.ToDest)
            .Include(s => s.Seats)
            .AsQueryable();

        if (fromDestId.HasValue)
        {
            query = query.Where(s => s.FromDestId == fromDestId.Value);
        }

        if (toDestId.HasValue)
        {
            query = query.Where(s => s.ToDestId == toDestId.Value);
        }

        var allRouteSchedules = await query.ToListAsync();

        // Parse search date or default to 2 days from now
        var baseDate = DateTime.UtcNow.AddDays(2).Date;
        if (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out var parsedDate))
        {
            baseDate = parsedDate.Date;
        }

        // Check if there are any schedules for this route on this specific date
        var targetDateSchedules = allRouteSchedules.Where(s => 
            s.DepartureTime.HasValue && s.DepartureTime.Value.Date == baseDate
        ).ToList();


        // Apply date filtering if provided
        var filteredSchedules = allRouteSchedules;
        if (!string.IsNullOrEmpty(date) && DateTime.TryParse(date, out _))
        {
            filteredSchedules = allRouteSchedules.Where(s => 
                s.DepartureTime.HasValue && s.DepartureTime.Value.Date == baseDate
            ).ToList();
        }

        var result = filteredSchedules.Select(s =>
        {
            var duration = "";
            if (s.DepartureTime.HasValue && s.ArrivalTime.HasValue)
            {
                var diff = s.ArrivalTime.Value - s.DepartureTime.Value;
                duration = $"{(int)diff.TotalHours}h {diff.Minutes}p";
            }

            var availableSeatsCount = s.Seats.Any() 
                ? s.Seats.Count(seat => seat.Status == SeatStatus.Available)
                : (s.TotalSeats ?? 30);

            // Fetch average rating (e.g. 4.8) from reviews or default
            var avgRating = 4.8;
            var reviewCount = 12;

            return new
            {
                s.Id,
                CompanyId = s.CompanyId,
                CompanyName = s.Company?.Name ?? "Nhà xe SmartTrip",
                CompanyLogoUrl = s.Company?.LogoUrl ?? "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957",
                CompanyHotline = s.Company?.Hotline ?? "19001001",
                FromDestId = s.FromDestId,
                FromDestName = s.FromDest?.Name ?? "Điểm đi",
                ToDestId = s.ToDestId,
                ToDestName = s.ToDest?.Name ?? "Điểm đến",
                DepartureTime = s.DepartureTime?.ToString("yyyy-MM-ddTHH:mm:ss"),
                ArrivalTime = s.ArrivalTime?.ToString("yyyy-MM-ddTHH:mm:ss"),
                Duration = duration,
                Price = s.Price ?? 0m,
                SpotsLeft = availableSeatsCount,
                TotalSeats = s.TotalSeats ?? 30,
                Rating = avgRating,
                ReviewCount = reviewCount
            };
        }).ToList();

        return Ok(result);
    }

    // GET /api/bus/schedules/1/seats
    [HttpGet("schedules/{scheduleId:int}/seats")]
    public async Task<IActionResult> GetSeats(int scheduleId)
    {
        var schedule = await _context.BusSchedules
            .Include(s => s.Seats)
            .FirstOrDefaultAsync(s => s.Id == scheduleId);

        if (schedule == null)
        {
            return NotFound(new { message = "Không tìm thấy lịch trình chuyến xe." });
        }


        var result = schedule.Seats
            .OrderBy(s => s.SeatNumber)
            .Select(s => new
            {
                s.Id,
                SeatNumber = s.SeatNumber ?? $"S{s.Id}",
                Status = (s.Status ?? SeatStatus.Available).ToString().ToLowerInvariant()
            }).ToList();

        return Ok(result);
    }
}
