using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IGrokAiService
{
    Task<ChatResponseDto> GenerateResponseAsync(ChatContextDto context);
    Task<ChatResponseDto> GenerateResponseWithJsonModeAsync(ChatContextDto context);
    Task<ChatIntentResultDto> ClassifyIntentAsync(string message, List<ChatHistoryItemDto> history);
}
