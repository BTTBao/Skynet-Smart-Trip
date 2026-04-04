using System;

namespace SmartTrip.Domain.Entities;

public class ChatHistory
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserMessage { get; set; } = null!;
    public string BotResponse { get; set; } = null!;
    public string? ResponseType { get; set; }
    public string? ResponseDataJson { get; set; }
    public string? DetectedIntent { get; set; }
    public string? SessionId { get; set; }
    public DateTime CreatedAt { get; set; }

    public virtual User? User { get; set; }
}
