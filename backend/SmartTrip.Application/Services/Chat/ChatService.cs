using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;
using System.Text.Json;

namespace SmartTrip.Application.Services.Chat;

public class ChatService : IChatService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly IGrokAiService _aiService;
    private readonly IChatRepository _chatRepo;

    public ChatService(IGrokAiService aiService, IChatRepository chatRepo)
    {
        _aiService = aiService;
        _chatRepo = chatRepo;
    }

    public async Task<ChatResponseDto> GetAiResponseAsync(ChatRequestDto request)
    {
        var normalizedSessionId = NormalizeSessionId(request.SessionId);

        // 1. Detect intent
        var intent = DetectIntent(request.Message);

        // 2. Build database context
        var dbContext = await BuildDatabaseContext(request.Message, intent);

        // 3. Get conversation history
        var history = new List<ChatHistoryItemDto>();
        if (request.UserId.HasValue)
        {
            if (string.IsNullOrWhiteSpace(normalizedSessionId))
            {
                normalizedSessionId = GenerateSessionId();
            }

            var historyResult = await GetChatHistoryAsync(
                request.UserId.Value,
                normalizedSessionId,
                10);
            history = historyResult.Messages;
        }

        // 4. Build full context
        var context = new ChatContextDto
        {
            UserMessage = request.Message,
            UserId = request.UserId,
            SessionId = normalizedSessionId,
            ConversationHistory = history,
            DetectedIntent = intent,
            DatabaseContext = dbContext,
            Latitude = request.Latitude,
            Longitude = request.Longitude
        };

        // 5. Get AI response
        var response = await _aiService.GenerateResponseAsync(context);

        // 6. Enrich with database data if needed
        response = await EnrichWithDatabaseData(response, intent);
        response.SessionId = normalizedSessionId;

        // 7. Save to history
        if (request.UserId.HasValue)
        {
            await SaveChatHistory(
                request.UserId.Value,
                request.Message,
                response,
                intent,
                normalizedSessionId);
        }

        return response;
    }

    public async Task<ChatSessionHistoryDto> GetChatHistoryAsync(
        int userId,
        string? sessionId = null,
        int limit = 50)
    {
        var effectiveSessionId = NormalizeSessionId(sessionId)
            ?? await _chatRepo.GetLatestSessionIdAsync(userId);

        if (string.IsNullOrWhiteSpace(effectiveSessionId))
        {
            return new ChatSessionHistoryDto();
        }

        var histories = await _chatRepo.GetChatHistoryAsync(userId, effectiveSessionId, limit);

        var result = new List<ChatHistoryItemDto>();
        foreach (var h in histories)
        {
            result.Add(new ChatHistoryItemDto
            {
                Role = "user",
                Content = h.UserMessage,
                SessionId = h.SessionId,
                Timestamp = h.CreatedAt
            });
            result.Add(new ChatHistoryItemDto
            {
                Role = "bot",
                Content = h.BotResponse,
                SessionId = h.SessionId,
                ResponseType = h.ResponseType,
                Timestamp = h.CreatedAt,
                ResponsePayload = DeserializeResponsePayload(h.ResponseDataJson)
            });
        }

        return new ChatSessionHistoryDto
        {
            SessionId = effectiveSessionId,
            Messages = result
        };
    }

    public async Task ClearChatHistoryAsync(int userId, string? sessionId = null)
    {
        await _chatRepo.ClearChatHistoryAsync(userId, NormalizeSessionId(sessionId));
    }

    public async Task<List<ChatSessionSummaryDto>> GetChatSessionsAsync(int userId, int limit = 20)
    {
        return await _chatRepo.GetChatSessionsAsync(userId, limit);
    }

    // ==========================================
    // INTENT DETECTION
    // ==========================================

    private string DetectIntent(string message)
    {
        var lower = message.ToLower();

        if (ContainsAny(lower, "lịch trình", "kế hoạch", "plan", "itinerary", "lập kế hoạch", "schedule"))
            return "itinerary_request";

        if (ContainsAny(lower, "khách sạn", "hotel", "phòng", "chỗ ở", "resort", "homestay", "nghỉ ở đâu"))
            return "hotel_query";

        if (ContainsAny(lower, "thời tiết", "weather", "mưa", "nắng", "nhiệt độ", "temperature"))
            return "weather_query";

        if (ContainsAny(lower, "gợi ý", "recommend", "đi đâu", "nơi nào", "điểm đến", "destination", "du lịch ở", "hot nhất"))
            return "destination_query";

        if (ContainsAny(lower, "gần tôi", "nearby", "xung quanh", "quanh đây", "gần đây"))
            return "nearby_query";

        if (ContainsAny(lower, "đặt", "book", "booking", "vé", "đặt phòng", "đặt vé"))
            return "booking_request";

        if (ContainsAny(lower, "ăn gì", "quán ăn", "nhà hàng", "restaurant", "ẩm thực", "food", "món ăn"))
            return "food_query";

        if (ContainsAny(lower, "giá", "chi phí", "budget", "tiết kiệm", "bao nhiêu tiền"))
            return "budget_query";

        return "general";
    }

    // ==========================================
    // DATABASE CONTEXT BUILDER
    // ==========================================

    private async Task<string> BuildDatabaseContext(string message, string intent)
    {
        var parts = new List<string>();

        var destinations = await _chatRepo.GetDestinationsAsync(20);
        if (destinations.Any())
        {
            var destList = string.Join(", ", destinations.Select(d => $"{d.Name}" + (d.IsHot == true ? " (HOT)" : "")));
            parts.Add($"Điểm đến trong hệ thống: {destList}");
        }

        if (intent == "hotel_query" || intent == "destination_query")
        {
            var hotels = await _chatRepo.GetAvailableHotelsAsync(10);
            if (hotels.Any())
            {
                var hotelList = string.Join("; ", hotels.Select(h =>
                    $"{h.Name} ({h.StarRating}⭐, {h.Destination?.Name ?? ""}, từ {h.Rooms.Where(r => r.PricePerNight.HasValue).Min(r => r.PricePerNight)?.ToString("N0") ?? "N/A"}đ/đêm)"));
                parts.Add($"Khách sạn: {hotelList}");
            }
        }

        if (intent == "itinerary_request" || intent == "general")
        {
            var busCount = await _chatRepo.GetBusScheduleCountAsync();
            if (busCount > 0)
            {
                parts.Add($"Hệ thống có {busCount} tuyến xe buýt liên tỉnh.");
            }
        }

        return parts.Any() ? string.Join("\n", parts) : "";
    }

    // ==========================================
    // ENRICH RESPONSE WITH DB DATA
    // ==========================================

    private async Task<ChatResponseDto> EnrichWithDatabaseData(ChatResponseDto response, string intent)
    {
        if (intent == "destination_query" && (response.DestinationCards == null || response.DestinationCards.Count == 0))
        {
            var destinations = await _chatRepo.GetDestinationsAsync(3);
            if (destinations.Any())
            {
                response.DestinationCards = destinations.Select(d => new DestinationCardDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    ImageUrl = d.CoverImageUrl,
                    IsHot = d.IsHot
                }).ToList();

                if (response.ResponseType == "text") response.ResponseType = "destination_card";
            }
        }

        if (intent == "hotel_query" && (response.HotelCards == null || response.HotelCards.Count == 0))
        {
            var hotels = await _chatRepo.GetAvailableHotelsAsync(3);
            if (hotels.Any())
            {
                response.HotelCards = hotels.Select(h => new HotelCardDto
                {
                    Id = h.Id,
                    Name = h.Name,
                    Address = h.Address,
                    StarRating = h.StarRating,
                    Description = h.Description,
                    PricePerNight = h.Rooms.Where(r => r.PricePerNight.HasValue).MinBy(r => r.PricePerNight)?.PricePerNight,
                    DestinationName = h.Destination?.Name,
                    Amenities = h.Amenities.Select(a => a.Name ?? "").ToList(),
                    IsAvailable = h.IsAvailable
                }).ToList();

                if (response.ResponseType == "text") response.ResponseType = "hotel_list";
            }
        }

        return response;
    }

    // ==========================================
    // SAVE HISTORY
    // ==========================================

    private async Task SaveChatHistory(int userId, string userMessage, ChatResponseDto response, string intent, string? sessionId)
    {
        var history = new ChatHistory
        {
            UserId = userId,
            UserMessage = userMessage,
            BotResponse = response.Text,
            ResponseType = response.ResponseType,
            ResponseDataJson = JsonSerializer.Serialize(response, JsonOptions),
            DetectedIntent = intent,
            SessionId = sessionId,
            CreatedAt = DateTime.UtcNow
        };

        await _chatRepo.SaveChatHistoryAsync(history);
    }

    private static bool ContainsAny(string text, params string[] keywords)
    {
        return keywords.Any(k => text.Contains(k, StringComparison.OrdinalIgnoreCase));
    }

    private static string GenerateSessionId()
    {
        return $"chat_{Guid.NewGuid():N}";
    }

    private static string? NormalizeSessionId(string? sessionId)
    {
        return string.IsNullOrWhiteSpace(sessionId) ? null : sessionId.Trim();
    }

    private static ChatResponseDto? DeserializeResponsePayload(string? payload)
    {
        if (string.IsNullOrWhiteSpace(payload))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<ChatResponseDto>(payload, JsonOptions);
        }
        catch
        {
            return null;
        }
    }
}
