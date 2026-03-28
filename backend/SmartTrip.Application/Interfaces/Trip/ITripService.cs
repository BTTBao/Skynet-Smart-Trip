using SmartTrip.Application.DTOs.Trip;

namespace SmartTrip.Application.Interfaces.Trip;

public interface ITripService
{
    Task<IReadOnlyList<TripSummaryDto>> GetTripsByUserAsync(int userId);

    Task<TripDetailDto?> GetTripByIdAsync(int tripId);

    Task<TripSummaryDto> CreateTripAsync(CreateTripDto request);

    Task<TripSummaryDto> UpdateTripAsync(int tripId, UpdateTripDto request);
}
