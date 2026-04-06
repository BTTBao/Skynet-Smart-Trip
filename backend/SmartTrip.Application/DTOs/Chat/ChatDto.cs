namespace SmartTrip.Application.DTOs.Chat;

// === REQUEST DTOs ===

public class ChatRequestDto
{
    public string Message { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public string? SessionId { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

// === RESPONSE DTOs ===

public class ChatResponseDto
{
    public string Text { get; set; } = string.Empty;
    public string ResponseType { get; set; } = "text";
    public string? SessionId { get; set; }
    public List<DestinationCardDto>? DestinationCards { get; set; }
    public ItineraryDto? SuggestedItinerary { get; set; }
    public List<QuickActionDto>? QuickActions { get; set; }
    public WeatherInfoDto? WeatherInfo { get; set; }
    public List<HotelCardDto>? HotelCards { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

public class ChatSessionHistoryDto
{
    public string? SessionId { get; set; }
    public List<ChatHistoryItemDto> Messages { get; set; } = new();
}

public class ChatSessionSummaryDto
{
    public string SessionId { get; set; } = string.Empty;
    public string PreviewText { get; set; } = string.Empty;
    public DateTime LastUpdatedAt { get; set; }
    public int MessageCount { get; set; }
}

// === DESTINATION CARD ===

public class DestinationCardDto
{
    public int? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public double? Rating { get; set; }
    public string? BestSeason { get; set; }
    public string? EstimatedBudget { get; set; }
    public bool? IsHot { get; set; }
}

// === HOTEL CARD ===

public class HotelCardDto
{
    public int? Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public int? StarRating { get; set; }
    public string? Description { get; set; }
    public decimal? PricePerNight { get; set; }
    public string? DestinationName { get; set; }
    public List<string>? Amenities { get; set; }
    public bool? IsAvailable { get; set; }
}

// === ITINERARY ===

public class ItineraryDto
{
    public string Title { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public int TotalDays { get; set; }
    public string? EstimatedBudget { get; set; }
    public string? TravelStyle { get; set; }
    public List<ItineraryDayDto> Days { get; set; } = new();
}

public class ItineraryDayDto
{
    public int DayNumber { get; set; }
    public string? Theme { get; set; }
    public List<ItineraryActivityDto> Activities { get; set; } = new();
}

public class ItineraryActivityDto
{
    public string Time { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Icon { get; set; } = "location";
    public string? EstimatedCost { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

// === QUICK ACTION ===

public class QuickActionDto
{
    public string Label { get; set; } = string.Empty;
    public string Icon { get; set; } = "chat";
    public string ActionPayload { get; set; } = string.Empty;
}

// === WEATHER INFO ===

public class WeatherInfoDto
{
    public string Location { get; set; } = string.Empty;
    public double? Temperature { get; set; }
    public string? Condition { get; set; }
    public string? Icon { get; set; }
    public int? Humidity { get; set; }
    public double? WindSpeed { get; set; }
    public string? TravelAdvice { get; set; }
    public List<WeatherForecastDayDto>? Forecast { get; set; }
}

public class WeatherForecastDayDto
{
    public string Day { get; set; } = string.Empty;
    public double? TempHigh { get; set; }
    public double? TempLow { get; set; }
    public string? Condition { get; set; }
    public string? Icon { get; set; }
}

// === CONTEXT DTO (Internal) ===

public class ChatContextDto
{
    public string UserMessage { get; set; } = string.Empty;
    public int? UserId { get; set; }
    public string? SessionId { get; set; }
    public List<ChatHistoryItemDto> ConversationHistory { get; set; } = new();
    public string? DetectedIntent { get; set; }
    public string? DatabaseContext { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class ChatHistoryItemDto
{
    public string Role { get; set; } = string.Empty; // "user" or "bot"
    public string Content { get; set; } = string.Empty;
    public string? SessionId { get; set; }
    public string? ResponseType { get; set; }
    public DateTime Timestamp { get; set; }
    public ChatResponseDto? ResponsePayload { get; set; }
}
