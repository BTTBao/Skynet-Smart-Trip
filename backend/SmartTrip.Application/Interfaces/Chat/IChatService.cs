using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IChatService
{
    Task<ChatResponseDto> GetAiResponseAsync(string userMessage);
}
