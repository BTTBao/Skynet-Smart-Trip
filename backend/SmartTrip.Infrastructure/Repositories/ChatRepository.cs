using Microsoft.EntityFrameworkCore;
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

    public async Task<List<ChatHistory>> GetChatHistoryAsync(int userId, int limit)
    {
        return await _dbContext.ChatHistories
            .Where(h => h.UserId == userId)
            .OrderByDescending(h => h.CreatedAt)
            .Take(limit)
            .OrderBy(h => h.CreatedAt)
            .ToListAsync();
    }

    public async Task SaveChatHistoryAsync(ChatHistory history)
    {
        _dbContext.ChatHistories.Add(history);
        await _dbContext.SaveChangesAsync();
    }

    public async Task ClearChatHistoryAsync(int userId)
    {
        var histories = await _dbContext.ChatHistories
            .Where(h => h.UserId == userId)
            .ToListAsync();

        _dbContext.ChatHistories.RemoveRange(histories);
        await _dbContext.SaveChangesAsync();
    }

    public async Task<List<Destination>> GetDestinationsAsync(int limit = 20)
    {
        return await _dbContext.Destinations
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
            .Take(limit)
            .ToListAsync();
    }

    public async Task<int> GetBusScheduleCountAsync()
    {
        return await _dbContext.BusSchedules.CountAsync();
    }
}
