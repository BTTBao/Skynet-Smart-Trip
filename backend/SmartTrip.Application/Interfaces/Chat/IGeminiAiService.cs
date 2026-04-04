using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IGeminiAiService
{
    Task<ChatResponseDto> GenerateResponseAsync(ChatContextDto context);
}
