using SmartTrip.Application.DTOs.Trip;

namespace SmartTrip.Application.Interfaces.Trip;

public interface IItineraryService
{
    Task<TripItineraryDto> AddItineraryAsync(int tripId, CreateTripItineraryDto request);

    Task<TripItineraryDto> UpdateItineraryAsync(int itineraryId, UpdateTripItineraryDto request);

    Task<bool> DeleteItineraryAsync(int itineraryId);
}
