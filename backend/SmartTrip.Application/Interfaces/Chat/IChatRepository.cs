using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IChatRepository
{
    // Chat history
    Task<List<ChatHistory>> GetChatHistoryAsync(int userId, int limit);
    Task SaveChatHistoryAsync(ChatHistory history);
    Task ClearChatHistoryAsync(int userId);

    // Database context for AI
    Task<List<Destination>> GetDestinationsAsync(int limit = 20);
    Task<List<Hotel>> GetAvailableHotelsAsync(int limit = 10);
    Task<int> GetBusScheduleCountAsync();
}
