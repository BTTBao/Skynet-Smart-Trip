using Microsoft.EntityFrameworkCore;
using SmartTrip.Application.DTOs.Notifications;
using SmartTrip.Application.Interfaces.Notifications;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Services.Notifications;

public class NotificationService : INotificationService
{
    private const string PushNotificationKey = "push_notifications";
    private const string EmailNotificationKey = "email_notifications";

    private readonly IApplicationDbContext _context;

    public NotificationService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<NotificationListDto> GetNotificationsAsync(int userId, CancellationToken cancellationToken = default)
    {
        var notifications = await _context.Notifications
            .AsNoTracking()
            .Where(item => item.UserId == userId)
            .OrderByDescending(item => item.CreatedAt)
            .ThenByDescending(item => item.Id)
            .ToListAsync(cancellationToken);
        var items = notifications.Select(MapNotification).ToList();

        return new NotificationListDto
        {
            Items = items,
            UnreadCount = items.Count(item => !item.IsRead)
        };
    }

    public Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default)
    {
        return _context.Notifications
            .AsNoTracking()
            .CountAsync(item => item.UserId == userId && item.IsRead != true, cancellationToken);
    }

    public async Task<NotificationDto?> MarkAsReadAsync(int userId, int notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(item => item.Id == notificationId && item.UserId == userId, cancellationToken);

        if (notification == null)
        {
            return null;
        }

        if (notification.IsRead != true)
        {
            notification.IsRead = true;
            await _context.SaveChangesAsync(cancellationToken);
        }

        return MapNotification(notification);
    }

    public async Task MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default)
    {
        var unreadNotifications = await _context.Notifications
            .Where(item => item.UserId == userId && item.IsRead != true)
            .ToListAsync(cancellationToken);

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
        }

        if (unreadNotifications.Count > 0)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task<NotificationDto?> CreateAsync(CreateNotificationDto request, CancellationToken cancellationToken = default)
    {
        if (request.UserId <= 0 || string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.Message))
        {
            return null;
        }

        if (!await AreInAppNotificationsEnabledAsync(request.UserId, cancellationToken))
        {
            return null;
        }

        var title = request.Title.Trim();
        var message = request.Message.Trim();
        var type = string.IsNullOrWhiteSpace(request.Type) ? "general" : request.Type.Trim();
        var referenceType = string.IsNullOrWhiteSpace(request.ReferenceType) ? null : request.ReferenceType.Trim();
        var actionUrl = string.IsNullOrWhiteSpace(request.ActionUrl) ? null : request.ActionUrl.Trim();
        var now = DateTime.UtcNow;
        var duplicateSince = now.AddMinutes(-5);

        var duplicateExists = await _context.Notifications
            .AsNoTracking()
            .AnyAsync(item =>
                item.UserId == request.UserId &&
                item.Type == type &&
                item.ReferenceType == referenceType &&
                item.ReferenceId == request.ReferenceId &&
                item.Title == title &&
                item.Message == message &&
                item.CreatedAt >= duplicateSince,
                cancellationToken);

        if (duplicateExists)
        {
            return null;
        }

        var notification = new Notification
        {
            UserId = request.UserId,
            Title = title,
            Message = message,
            Type = type,
            ReferenceType = referenceType,
            ReferenceId = request.ReferenceId,
            ActionUrl = actionUrl,
            IsRead = false,
            CreatedAt = now
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(cancellationToken);

        return MapNotification(notification);
    }

    public async Task<bool> AreEmailNotificationsEnabledAsync(int userId, CancellationToken cancellationToken = default)
    {
        var value = await _context.UserPreferences
            .AsNoTracking()
            .Where(item => item.UserId == userId && item.PreferenceKey == EmailNotificationKey)
            .Select(item => item.PreferenceValue)
            .FirstOrDefaultAsync(cancellationToken);

        return !bool.TryParse(value, out var enabled) || enabled;
    }

    private async Task<bool> AreInAppNotificationsEnabledAsync(int userId, CancellationToken cancellationToken)
    {
        var value = await _context.UserPreferences
            .AsNoTracking()
            .Where(item => item.UserId == userId && item.PreferenceKey == PushNotificationKey)
            .Select(item => item.PreferenceValue)
            .FirstOrDefaultAsync(cancellationToken);

        return !bool.TryParse(value, out var enabled) || enabled;
    }

    private static NotificationDto MapNotification(Notification item)
    {
        return new NotificationDto
        {
            Id = item.Id,
            Title = item.Title ?? string.Empty,
            Message = item.Message ?? string.Empty,
            Type = item.Type ?? "general",
            ReferenceType = item.ReferenceType,
            ReferenceId = item.ReferenceId,
            ActionUrl = item.ActionUrl,
            IsRead = item.IsRead == true,
            CreatedAt = item.CreatedAt
        };
    }
}
