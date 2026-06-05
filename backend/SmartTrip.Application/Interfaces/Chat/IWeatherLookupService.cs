using SmartTrip.Application.DTOs.Chat;

namespace SmartTrip.Application.Interfaces.Chat;

public interface IWeatherLookupService
{
    Task<WeatherInfoDto?> GetWeatherAsync(
        string locationQuery,
        string? language = "vi",
        CancellationToken cancellationToken = default);
}
