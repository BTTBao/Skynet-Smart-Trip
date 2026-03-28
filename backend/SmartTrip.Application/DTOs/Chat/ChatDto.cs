namespace SmartTrip.Application.DTOs.Chat;

public class ChatRequestDto
{
    public string Message { get; set; } = string.Empty;
}

public class ChatResponseDto
{
    public string Response { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
