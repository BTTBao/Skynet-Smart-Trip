using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Admin;
using SmartTrip.Domain.Entities;
using SmartTrip.Domain.Enums;

namespace SmartTrip.Infrastructure.Services.Admin;

public partial class AdminService
{
    public async Task<List<AdminPaymentHistoryDto>> GetPaymentHistoryAsync()
    {
        var payments = await _context.Payments
            .AsNoTracking()
            .Include(p => p.Trip)
                .ThenInclude(t => t!.User)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();

        var result = new List<AdminPaymentHistoryDto>();
        foreach (var p in payments)
        {
            SmartTrip.Domain.Entities.User? user = p.Trip?.User;
            if (user == null && p.TripId.HasValue)
            {
                var trip = await _context.Trips.Include(t => t.User).FirstOrDefaultAsync(t => t.Id == p.TripId.Value);
                user = trip?.User;
            }

            if (user == null && !string.IsNullOrEmpty(p.MetadataJson))
            {
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(p.MetadataJson!);
                    if (doc.RootElement.TryGetProperty("userId", out var prop) && prop.ValueKind == System.Text.Json.JsonValueKind.Number)
                    {
                        var userId = prop.GetInt32();
                        user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                    }
                }
                catch { }
            }

            result.Add(new AdminPaymentHistoryDto
            {
                PaymentId = p.Id,
                UserId = user?.Id,
                UserName = user?.FullName ?? user?.UserName ?? "Hệ thống / Guest",
                UserEmail = user?.Email ?? string.Empty,
                Amount = p.Amount ?? 0m,
                PaymentMethod = p.PaymentMethod?.ToString() ?? "Không rõ",
                Status = p.Status?.ToString() ?? "Pending",
                PaidAt = p.PaidAt.HasValue ? p.PaidAt.Value.ToLocalTime().ToString("dd/MM/yyyy HH:mm") : string.Empty,
                TransactionId = p.TransactionId,
                Description = p.Description ?? string.Empty,
                CreatedAt = p.CreatedAt.HasValue ? p.CreatedAt.Value.ToLocalTime().ToString("dd/MM/yyyy HH:mm") : string.Empty
            });
        }

        return result;
    }

    public async Task<List<AdminReviewDto>> GetReviewsAsync()
    {
        var reviews = await _context.Reviews
            .AsNoTracking()
            .Include(r => r.User)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        var result = new List<AdminReviewDto>();
        foreach (var r in reviews)
        {
            var targetName = "N/A";
            if (r.TargetType == ReviewTargetType.Hotel && r.TargetId.HasValue)
            {
                var hotel = await _context.Hotels.AsNoTracking().FirstOrDefaultAsync(h => h.Id == r.TargetId.Value);
                targetName = hotel?.Name ?? $"Hotel #{r.TargetId.Value}";
            }
            else if (r.TargetType == ReviewTargetType.BusCompany && r.TargetId.HasValue)
            {
                var company = await _context.BusCompanies.AsNoTracking().FirstOrDefaultAsync(c => c.Id == r.TargetId.Value);
                targetName = company?.Name ?? $"BusCompany #{r.TargetId.Value}";
            }

            result.Add(new AdminReviewDto
            {
                ReviewId = r.Id,
                UserId = r.UserId,
                UserName = r.User?.FullName ?? r.User?.UserName ?? r.User?.Email ?? "Anonymous",
                UserEmail = r.User?.Email ?? string.Empty,
                TargetType = r.TargetType?.ToString() ?? string.Empty,
                TargetId = r.TargetId ?? 0,
                TargetName = targetName,
                Rating = r.Rating ?? 0,
                Comment = r.Comment ?? string.Empty,
                CreatedAt = r.CreatedAt.HasValue ? r.CreatedAt.Value.ToLocalTime().ToString("dd/MM/yyyy HH:mm") : string.Empty
            });
        }

        return result;
    }

    public async Task DeleteReviewAsync(int reviewId)
    {
        var review = await _context.Reviews.FirstOrDefaultAsync(r => r.Id == reviewId);
        if (review != null)
        {
            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();
        }
    }
}
