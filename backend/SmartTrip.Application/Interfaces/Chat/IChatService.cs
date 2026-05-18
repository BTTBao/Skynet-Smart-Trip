using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IChatService
{
    Task<ChatResponseDto> GetAiResponseAsync(ChatRequestDto request);
    Task<ChatSessionHistoryDto> GetChatHistoryAsync(int userId, string? sessionId = null, int limit = 50);
    Task<List<ChatSessionSummaryDto>> GetChatSessionsAsync(int userId, int limit = 20);
    Task ClearChatHistoryAsync(int userId, string? sessionId = null);
}
