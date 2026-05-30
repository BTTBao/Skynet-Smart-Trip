using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IGrokAiService
{
    Task<ChatResponseDto> GenerateResponseAsync(ChatContextDto context);
}
