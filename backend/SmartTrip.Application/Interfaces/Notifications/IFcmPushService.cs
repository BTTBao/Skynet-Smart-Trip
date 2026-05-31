using SmartTrip.Application.DTOs.Notifications;

namespace SmartTrip.Application.Interfaces.Notifications;

public interface IFcmPushService
{
    Task SendToUserAsync(int userId, NotificationDto notification, CancellationToken cancellationToken = default);
}
