using SmartTrip.Application.DTOs.Trip;

namespace SmartTrip.Application.Interfaces.Trip;

public interface ITripServiceOptionService
{
    Task<IReadOnlyList<TripServiceOptionDto>> GetServiceOptionsAsync(string serviceType, int? destinationId);

    Task<TripServiceOptionDto?> GetServiceOptionByIdAsync(string serviceType, int serviceId);
}
