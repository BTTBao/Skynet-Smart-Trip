using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IChatRepository
{
    // Chat history
    Task<List<ChatHistory>> GetChatHistoryAsync(int userId, string sessionId, int limit);
    Task<string?> GetLatestSessionIdAsync(int userId);
    Task<List<ChatSessionSummaryDto>> GetChatSessionsAsync(int userId, int limit);
    Task SaveChatHistoryAsync(ChatHistory history);
    Task ClearChatHistoryAsync(int userId, string? sessionId = null);

    // Database context for AI
    Task<List<Destination>> GetDestinationsAsync(int limit = 20);
    Task<List<Hotel>> SearchDestinationsHotelsAsync(IEnumerable<int> destinationIds, int limit = 10);
    Task<List<Hotel>> GetAvailableHotelsAsync(int limit = 10);
    Task<List<BusSchedule>> GetBusSchedulesAsync(int limit = 10, IEnumerable<int>? destinationIds = null);
    Task<List<Promotion>> GetActivePromotionsAsync(int limit = 5);
    Task<int> GetBusScheduleCountAsync();
}
