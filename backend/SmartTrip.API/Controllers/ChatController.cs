using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;

    public ChatController(IChatService chatService)
    {
        _chatService = chatService;
    }

    [HttpPost("send")]
    public async Task<IActionResult> SendMessage([FromBody] ChatRequestDto request)
    {
        if (string.IsNullOrEmpty(request.Message))
            return BadRequest("Message cannot be empty");

        var response = await _chatService.GetAiResponseAsync(request);
        return Ok(response);
    }

    [HttpGet("history/{userId}")]
    public async Task<IActionResult> GetHistory(int userId, [FromQuery] int limit = 50)
    {
        var history = await _chatService.GetChatHistoryAsync(userId, limit);
        return Ok(history);
    }

    [HttpDelete("history/{userId}")]
    public async Task<IActionResult> ClearHistory(int userId)
    {
        await _chatService.ClearChatHistoryAsync(userId);
        return Ok(new { message = "Chat history cleared" });
    }

    [HttpGet("suggestions")]
    public IActionResult GetSuggestions()
    {
        var suggestions = new List<QuickActionDto>
        {
            new() { Label = "🏖 Gợi ý điểm đến", Icon = "explore", ActionPayload = "Gợi ý cho tôi 3 điểm đến đẹp ở Việt Nam" },
            new() { Label = "📋 Lập lịch trình", Icon = "calendar", ActionPayload = "Lập lịch trình du lịch Đà Lạt 3 ngày 2 đêm" },
            new() { Label = "🏨 Tìm khách sạn", Icon = "hotel", ActionPayload = "Tìm khách sạn tốt nhất ở Phú Quốc" },
            new() { Label = "☀️ Xem thời tiết", Icon = "weather", ActionPayload = "Thời tiết Đà Nẵng hôm nay thế nào?" },
            new() { Label = "🍜 Ẩm thực", Icon = "restaurant", ActionPayload = "Món ăn ngon nhất Hội An" },
            new() { Label = "💰 Du lịch tiết kiệm", Icon = "explore", ActionPayload = "Du lịch Việt Nam giá rẻ dưới 3 triệu" }
        };

        return Ok(suggestions);
    }
}
