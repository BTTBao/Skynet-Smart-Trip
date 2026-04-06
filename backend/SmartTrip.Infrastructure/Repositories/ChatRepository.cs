using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Infrastructure.Repositories;

public class ChatRepository : IChatRepository
{
    private readonly ApplicationDbContext _dbContext;

    public ChatRepository(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<ChatHistory>> GetChatHistoryAsync(int userId, string sessionId, int limit)
    {
        return await _dbContext.ChatHistories
            .Where(h => h.UserId == userId && h.SessionId == sessionId)
            .OrderByDescending(h => h.CreatedAt)
            .Take(limit)
            .OrderBy(h => h.CreatedAt)
            .ToListAsync();
    }

    public async Task<string?> GetLatestSessionIdAsync(int userId)
    {
        return await _dbContext.ChatHistories
            .Where(h => h.UserId == userId && h.SessionId != null && h.SessionId != "")
            .OrderByDescending(h => h.CreatedAt)
            .Select(h => h.SessionId)
            .FirstOrDefaultAsync();
    }

    public async Task<List<ChatSessionSummaryDto>> GetChatSessionsAsync(int userId, int limit)
    {
        var histories = await _dbContext.ChatHistories
            .Where(h => h.UserId == userId && h.SessionId != null && h.SessionId != "")
            .OrderByDescending(h => h.CreatedAt)
            .Select(h => new
            {
                h.SessionId,
                h.CreatedAt,
                h.UserMessage,
                h.BotResponse
            })
            .ToListAsync();

        return histories
            .GroupBy(h => h.SessionId!)
            .Select(group =>
            {
                var latest = group
                    .OrderByDescending(item => item.CreatedAt)
                    .First();

                return new ChatSessionSummaryDto
                {
                    SessionId = group.Key,
                    PreviewText = !string.IsNullOrWhiteSpace(latest.UserMessage)
                        ? latest.UserMessage
                        : latest.BotResponse,
                    LastUpdatedAt = latest.CreatedAt,
                    MessageCount = group.Count() * 2
                };
            })
            .OrderByDescending(item => item.LastUpdatedAt)
            .Take(limit)
            .ToList();
    }

    public async Task SaveChatHistoryAsync(ChatHistory history)
    {
        _dbContext.ChatHistories.Add(history);
        await _dbContext.SaveChangesAsync();
    }

    public async Task ClearChatHistoryAsync(int userId, string? sessionId = null)
    {
        var histories = await _dbContext.ChatHistories
            .Where(h => h.UserId == userId && (sessionId == null || h.SessionId == sessionId))
            .ToListAsync();

        _dbContext.ChatHistories.RemoveRange(histories);
        await _dbContext.SaveChangesAsync();
    }

    public async Task<List<Destination>> GetDestinationsAsync(int limit = 20)
    {
        return await _dbContext.Destinations
            .OrderByDescending(d => d.IsHot == true)
            .ThenBy(d => d.Name)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<Hotel>> SearchDestinationsHotelsAsync(IEnumerable<int> destinationIds, int limit = 10)
    {
        var destinationIdList = destinationIds
            .Distinct()
            .ToList();

        if (destinationIdList.Count == 0)
        {
            return [];
        }

        return await _dbContext.Hotels
            .Include(h => h.Destination)
            .Include(h => h.Rooms)
            .Include(h => h.Amenities)
            .Where(h => h.IsAvailable == true
                && h.DestinationId.HasValue
                && destinationIdList.Contains(h.DestinationId.Value))
            .OrderByDescending(h => h.StarRating ?? 0)
            .ThenBy(h => h.Name)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<Hotel>> GetAvailableHotelsAsync(int limit = 10)
    {
        return await _dbContext.Hotels
            .Include(h => h.Destination)
            .Include(h => h.Rooms)
            .Include(h => h.Amenities)
            .Where(h => h.IsAvailable == true)
            .OrderByDescending(h => h.StarRating ?? 0)
            .ThenBy(h => h.Name)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<BusSchedule>> GetBusSchedulesAsync(int limit = 10, IEnumerable<int>? destinationIds = null)
    {
        var query = _dbContext.BusSchedules
            .Include(b => b.Company)
            .Include(b => b.FromDest)
            .Include(b => b.ToDest)
            .AsQueryable();

        var destinationIdList = destinationIds?
            .Distinct()
            .ToList();

        if (destinationIdList is { Count: > 0 })
        {
            query = query.Where(b =>
                (b.FromDestId.HasValue && destinationIdList.Contains(b.FromDestId.Value)) ||
                (b.ToDestId.HasValue && destinationIdList.Contains(b.ToDestId.Value)));
        }

        return await query
            .OrderBy(b => b.DepartureTime ?? DateTime.MaxValue)
            .ThenBy(b => b.Price ?? decimal.MaxValue)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<List<Promotion>> GetActivePromotionsAsync(int limit = 5)
    {
        var now = DateTime.UtcNow;

        return await _dbContext.Promotions
            .Where(p =>
                (p.ValidUntil == null || p.ValidUntil >= now) &&
                (p.UsageLimit == null || (p.UsedCount ?? 0) < p.UsageLimit))
            .OrderByDescending(p => p.DiscountPercent ?? 0)
            .ThenBy(p => p.Code)
            .Take(limit)
            .ToListAsync();
    }

    public async Task<int> GetBusScheduleCountAsync()
    {
        return await _dbContext.BusSchedules.CountAsync();
    }
}
