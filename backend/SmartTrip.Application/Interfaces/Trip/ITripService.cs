using SmartTrip.Application.DTOs.Trip;

namespace SmartTrip.Application.Interfaces.Trip;

public interface ITripService
{
    Task<IReadOnlyList<TripSummaryDto>> GetTripsByUserAsync(int userId);

    Task<TripDetailDto?> GetTripByIdAsync(int tripId);

    Task<TripDetailDto?> GetTripByShareCodeAsync(string shareCode, int currentUserId);

    Task<TripSummaryDto> SaveSharedTripAsync(string shareCode, int currentUserId);

    Task<TripSummaryDto> CreateTripAsync(CreateTripDto request);

    Task<TripSummaryDto> CreateHotelBookingAsync(CreateHotelBookingDto request);

    Task<TripSummaryDto> CompleteFakePaymentAsync(int tripId, CreateFakePaymentDto request);

    Task<TripSummaryDto> UpdateTripAsync(int tripId, UpdateTripDto request);

    Task DeleteTripAsync(int tripId, int currentUserId);
}
