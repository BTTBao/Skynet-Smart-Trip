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

        var response = await _chatService.GetAiResponseAsync(request.Message);
        return Ok(response);
    }
}
