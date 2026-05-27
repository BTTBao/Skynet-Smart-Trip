using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartTrip.Application.Interfaces.Notifications;

namespace SmartTrip.API.Controllers;

[ApiController]
[Authorize]
[Route("api/notifications")]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetNotifications(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        return Ok(await _notificationService.GetNotificationsAsync(userId, cancellationToken));
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var count = await _notificationService.GetUnreadCountAsync(userId, cancellationToken);
        return Ok(new { unreadCount = count });
    }

    [HttpPost("{notificationId:int}/read")]
    public async Task<IActionResult> MarkAsRead(int notificationId, CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        var notification = await _notificationService.MarkAsReadAsync(userId, notificationId, cancellationToken);
        return notification == null ? NotFound(new { message = "Notification was not found." }) : Ok(notification);
    }

    [HttpPost("mark-all-read")]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        await _notificationService.MarkAllAsReadAsync(userId, cancellationToken);
        return NoContent();
    }

    private int GetCurrentUserId()
    {
        var rawUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(ClaimTypes.Name)
            ?? User.FindFirstValue(ClaimTypes.Sid)
            ?? User.FindFirstValue("sub");

        if (!int.TryParse(rawUserId, out var userId) || userId <= 0)
        {
            throw new UnauthorizedAccessException("Invalid user token.");
        }

        return userId;
    }
}
