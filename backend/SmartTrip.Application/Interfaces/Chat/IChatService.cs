using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IChatService
{
    Task<ChatResponseDto> GetAiResponseAsync(ChatRequestDto request);
    Task<List<ChatHistoryItemDto>> GetChatHistoryAsync(int userId, int limit = 50);
    Task ClearChatHistoryAsync(int userId);
}
