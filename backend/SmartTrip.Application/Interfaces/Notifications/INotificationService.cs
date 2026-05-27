using SmartTrip.Application.DTOs.Notifications;

namespace SmartTrip.Application.Interfaces.Notifications;

public interface INotificationService
{
    Task<NotificationListDto> GetNotificationsAsync(int userId, CancellationToken cancellationToken = default);
    Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<NotificationDto?> MarkAsReadAsync(int userId, int notificationId, CancellationToken cancellationToken = default);
    Task MarkAllAsReadAsync(int userId, CancellationToken cancellationToken = default);
    Task<NotificationDto?> CreateAsync(CreateNotificationDto request, CancellationToken cancellationToken = default);
    Task<bool> AreEmailNotificationsEnabledAsync(int userId, CancellationToken cancellationToken = default);
}
