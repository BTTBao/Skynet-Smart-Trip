using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.Infrastructure.Services.AI;

public class OpenMeteoWeatherService : IWeatherLookupService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<OpenMeteoWeatherService> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public OpenMeteoWeatherService(
        HttpClient httpClient,
        ILogger<OpenMeteoWeatherService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<WeatherInfoDto?> GetWeatherAsync(
        string locationQuery,
        string? language = "vi",
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(locationQuery))
        {
            return null;
        }

        try
        {
            GeoResult? geo = null;
            foreach (var candidate in BuildSearchCandidates(locationQuery))
            {
                geo = await SearchLocationAsync(candidate, cancellationToken);
                if (geo != null)
                {
                    break;
                }
            }

            if (geo == null)
            {
                return null;
            }

            var weather = await GetForecastAsync(geo.Latitude, geo.Longitude, cancellationToken);
            if (weather == null)
            {
                return null;
            }

            return MapWeatherInfo(geo, weather, language);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "OpenMeteo lookup failed for {LocationQuery}", locationQuery);
            return null;
        }
    }

    private async Task<GeoResult?> SearchLocationAsync(
        string query,
        CancellationToken cancellationToken)
    {
        var url =
            $"https://geocoding-api.open-meteo.com/v1/search?name={Uri.EscapeDataString(query)}&count=5&language=en&format=json";

        using var response = await _httpClient.GetAsync(url, cancellationToken);
        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        var payload = await JsonSerializer.DeserializeAsync<GeoSearchResponse>(stream, JsonOptions, cancellationToken);
        var result = payload?.Results?
            .OrderByDescending(item => string.Equals(item.CountryCode, "VN", StringComparison.OrdinalIgnoreCase))
            .ThenBy(item => item.Admin1)
            .FirstOrDefault();
        if (result == null)
        {
            return null;
        }

        return new GeoResult(
            result.Name ?? query,
            result.Admin1,
            result.Country,
            result.Latitude,
            result.Longitude);
    }

    private static IEnumerable<string> BuildSearchCandidates(string locationQuery)
    {
        var cleaned = NormalizeLocationQuery(locationQuery);
        if (string.IsNullOrWhiteSpace(cleaned))
        {
            yield break;
        }

        yield return cleaned;

        foreach (var alias in ExpandVietnamAliases(cleaned))
        {
            if (!string.Equals(alias, cleaned, StringComparison.OrdinalIgnoreCase))
            {
                yield return alias;
            }
        }
    }

    private static string NormalizeLocationQuery(string raw)
    {
        var cleaned = raw.Trim();
        cleaned = cleaned
            .Replace("thoi tiet", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("weather", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("hom nay", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("ngay mai", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("ngay kia", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("tuan toi", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("cuoi tuan nay", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("mua nay", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Replace("the nao", string.Empty, StringComparison.OrdinalIgnoreCase)
            .Trim(',', '.', '-', ' ');

        return cleaned;
    }

    private static IEnumerable<string> ExpandVietnamAliases(string location)
    {
        var normalized = location.ToLowerInvariant();

        if (normalized.Contains("da lat"))
        {
            yield return "Dalat, Lam Dong, Vietnam";
            yield return "Da Lat, Lam Dong, Vietnam";
        }

        if (normalized.Contains("phu quy"))
        {
            yield return "Phu Quy, Binh Thuan, Vietnam";
            yield return "Dao Phu Quy, Binh Thuan, Vietnam";
        }

        if (normalized.Contains("sai gon") || normalized.Contains("ho chi minh"))
        {
            yield return "Ho Chi Minh City, Vietnam";
            yield return "Sai Gon, Vietnam";
        }

        if (normalized.Contains("ha noi"))
        {
            yield return "Ha Noi, Vietnam";
            yield return "Hanoi, Vietnam";
        }
    }

    private async Task<ForecastResponse?> GetForecastAsync(
        double latitude,
        double longitude,
        CancellationToken cancellationToken)
    {
        var url =
            "https://api.open-meteo.com/v1/forecast"
            + $"?latitude={latitude.ToString(CultureInfo.InvariantCulture)}"
            + $"&longitude={longitude.ToString(CultureInfo.InvariantCulture)}"
            + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=4";

        using var response = await _httpClient.GetAsync(url, cancellationToken);
        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        return await JsonSerializer.DeserializeAsync<ForecastResponse>(stream, JsonOptions, cancellationToken);
    }

    private static WeatherInfoDto? MapWeatherInfo(
        GeoResult geo,
        ForecastResponse forecast,
        string? language)
    {
        if (forecast.Current == null)
        {
            return null;
        }

        var isEnglish = string.Equals(language, "en", StringComparison.OrdinalIgnoreCase);
        var description = GetWeatherDescription(forecast.Current.WeatherCode, isEnglish);

        return new WeatherInfoDto
        {
            Location = BuildLocationLabel(geo),
            Temperature = forecast.Current.Temperature2m,
            Condition = description.Label,
            Icon = description.Icon,
            Humidity = forecast.Current.RelativeHumidity2m,
            WindSpeed = forecast.Current.WindSpeed10m,
            TravelAdvice = BuildTravelAdvice(description.Icon, isEnglish),
            Forecast = BuildForecast(forecast.Daily, isEnglish)
        };
    }

    private static List<WeatherForecastDayDto>? BuildForecast(
        ForecastDaily? daily,
        bool isEnglish)
    {
        if (daily?.Time == null || daily.WeatherCode == null)
        {
            return null;
        }

        var count = new[]
        {
            daily.Time.Count,
            daily.WeatherCode.Count,
            daily.Temperature2mMax?.Count ?? 0,
            daily.Temperature2mMin?.Count ?? 0
        }.Where(item => item > 0).Min();

        if (count <= 0)
        {
            return null;
        }

        var items = new List<WeatherForecastDayDto>();
        for (var i = 0; i < count; i++)
        {
            if (!DateTime.TryParse(daily.Time[i], out var date))
            {
                continue;
            }

            var description = GetWeatherDescription(daily.WeatherCode[i], isEnglish);
            items.Add(new WeatherForecastDayDto
            {
                Day = date.ToString("dd/MM"),
                TempHigh = daily.Temperature2mMax?[i],
                TempLow = daily.Temperature2mMin?[i],
                Condition = description.Label,
                Icon = description.Icon
            });
        }

        return items;
    }

    private static string BuildLocationLabel(GeoResult geo)
    {
        return string.Join(
            ", ",
            new[] { geo.Name, geo.Admin1, geo.Country }
                .Where(item => !string.IsNullOrWhiteSpace(item)));
    }

    private static string BuildTravelAdvice(string icon, bool isEnglish)
    {
        return icon switch
        {
            "sunny" => isEnglish
                ? "Weather is quite favorable for outdoor sightseeing. Remember sunscreen and water."
                : "Thoi tiet kha dep de di tham quan ngoai troi. Nho mang kem chong nang va nuoc uong.",
            "rainy" => isEnglish
                ? "You should bring an umbrella or raincoat and keep the schedule flexible."
                : "Ban nen mang theo o hoac ao mua va de lich trinh linh hoat hon.",
            "cloudy" => isEnglish
                ? "The weather is mild and easy to travel. Suitable for sightseeing and walking."
                : "Thoi tiet diu, de di chuyen. Phu hop de tham quan va di bo.",
            _ => isEnglish
                ? "Check the latest conditions before departure to optimize your schedule."
                : "Ban nen kiem tra cap nhat gan gio khoi hanh de toi uu lich trinh."
        };
    }

    private static (string Label, string Icon) GetWeatherDescription(int? code, bool isEnglish)
    {
        return code switch
        {
            0 => (isEnglish ? "Clear sky" : "Troi quang", "sunny"),
            1 or 2 => (isEnglish ? "Partly cloudy" : "It may", "cloudy"),
            3 => (isEnglish ? "Overcast" : "Nhieu may", "cloudy"),
            45 or 48 => (isEnglish ? "Fog" : "Suong mu", "cloudy"),
            51 or 53 or 55 or 61 or 63 or 65 or 80 or 81 or 82 => (isEnglish ? "Rain" : "Co mua", "rainy"),
            71 or 73 or 75 or 77 or 85 or 86 => (isEnglish ? "Snow" : "Tuyet", "cloudy"),
            95 or 96 or 99 => (isEnglish ? "Thunderstorm" : "Mua dong", "rainy"),
            _ => (isEnglish ? "Variable weather" : "Thoi tiet thay doi", "cloudy")
        };
    }

    private sealed record GeoResult(
        string Name,
        string? Admin1,
        string? Country,
        double Latitude,
        double Longitude);

    private sealed class GeoSearchResponse
    {
        public List<GeoSearchItem>? Results { get; set; }
    }

    private sealed class GeoSearchItem
    {
        public string? Name { get; set; }
        public string? Admin1 { get; set; }
        public string? Country { get; set; }
        public string? CountryCode { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }

    private sealed class ForecastResponse
    {
        public ForecastCurrent? Current { get; set; }
        public ForecastDaily? Daily { get; set; }
    }

    private sealed class ForecastCurrent
    {
        [JsonPropertyName("temperature_2m")]
        public double? Temperature2m { get; set; }

        [JsonPropertyName("relative_humidity_2m")]
        public int? RelativeHumidity2m { get; set; }

        [JsonPropertyName("weather_code")]
        public int? WeatherCode { get; set; }

        [JsonPropertyName("wind_speed_10m")]
        public double? WindSpeed10m { get; set; }
    }

    private sealed class ForecastDaily
    {
        public List<string>? Time { get; set; }

        [JsonPropertyName("weather_code")]
        public List<int>? WeatherCode { get; set; }

        [JsonPropertyName("temperature_2m_max")]
        public List<double>? Temperature2mMax { get; set; }

        [JsonPropertyName("temperature_2m_min")]
        public List<double>? Temperature2mMin { get; set; }
    }
}
