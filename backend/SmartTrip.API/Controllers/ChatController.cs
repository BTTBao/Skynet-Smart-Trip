using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using System.Security.Claims;

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

    [Authorize]
    [HttpPost("send")]
    public async Task<IActionResult> SendMessage([FromBody] ChatRequestDto request)
    {
        if (string.IsNullOrEmpty(request.Message))
            return BadRequest("Message cannot be empty");

        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        request.UserId = userId.Value;
        var response = await _chatService.GetAiResponseAsync(request);
        return Ok(response);
    }

    [Authorize]
    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] string? sessionId = null, [FromQuery] int limit = 50)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var history = await _chatService.GetChatHistoryAsync(userId.Value, sessionId, limit);
        return Ok(history);
    }

    [Authorize]
    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions([FromQuery] int limit = 20)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var sessions = await _chatService.GetChatSessionsAsync(userId.Value, limit);
        return Ok(sessions);
    }

    [Authorize]
    [HttpDelete("history")]
    public async Task<IActionResult> ClearHistory([FromQuery] string? sessionId = null)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        await _chatService.ClearChatHistoryAsync(userId.Value, sessionId);
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

    private int? GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        if (int.TryParse(rawUserId, out var userId))
        {
            return userId;
        }

        return null;
    }
}
