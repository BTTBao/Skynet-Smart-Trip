using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;
using System.Diagnostics;
using System.Text.Json;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Orchestrator — coordinates the 3-layer chatbot pipeline:
///   Layer 1 (Assistant): IntentRouter + EntityExtractor
///   Layer 2 (Knowledge): KnowledgeService (DB-first)
///   Layer 3 (Planning):  PlanningService (conditional)
/// 
/// This replaces the original monolithic ChatService (2603 LOC → ~200 LOC).
/// </summary>
public class ChatService : IChatService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly IntentRouter _intentRouter;
    private readonly EntityExtractor _entityExtractor;
    private readonly KnowledgeService _knowledgeService;
    private readonly PlanningService _planningService;
    private readonly ResponseBuilder _responseBuilder;
    private readonly IGrokAiService _aiService;
    private readonly IChatRepository _chatRepo;
    private readonly IWeatherLookupService _weatherLookupService;

    public ChatService(
        IntentRouter intentRouter,
        EntityExtractor entityExtractor,
        KnowledgeService knowledgeService,
        PlanningService planningService,
        ResponseBuilder responseBuilder,
        IGrokAiService aiService,
        IChatRepository chatRepo,
        IWeatherLookupService weatherLookupService)
    {
        _intentRouter = intentRouter;
        _entityExtractor = entityExtractor;
        _knowledgeService = knowledgeService;
        _planningService = planningService;
        _responseBuilder = responseBuilder;
        _aiService = aiService;
        _chatRepo = chatRepo;
        _weatherLookupService = weatherLookupService;
    }

    // ══════════════════════════════════════════════
    // MAIN PIPELINE
    // ══════════════════════════════════════════════

    public async Task<ChatResponseDto> GetAiResponseAsync(ChatRequestDto request)
    {
        var stopwatch = Stopwatch.StartNew();
        var sessionId = NormalizeSessionId(request.SessionId) ?? GenerateSessionId();
        var userProfile = request.UserId.HasValue
            ? await _chatRepo.GetUserPersonalizationAsync(request.UserId.Value)
            : null;
        var history = await LoadHistory(request.UserId, sessionId);

        // ═══ LAYER 1: ASSISTANT ═══

        // 1a. Classify intent
        var classification = await _intentRouter.ClassifyIntent(request.Message, history);
        var intent = classification.Intent;

        // 1b. Extract entities from current message
        var entities = _entityExtractor.ExtractAll(request.Message);

        // 1c. Merge LLM-extracted entities (if LLM was called)
        if (classification.LlmEntities != null)
        {
            MergeLlmEntities(entities, classification.LlmEntities);
        }

        // 1d. Selective merge from history (only fills missing fields)
        entities = _entityExtractor.MergeEntitiesFromHistory(entities, history, intent);

        // ═══ LAYER 2: KNOWLEDGE ═══

        // 2a. Resolve location with guardrail
        var location = await _knowledgeService.ResolveLocation(
            entities.Destination, entities);

        // 2b. Query DB by intent
        var knowledge = await _knowledgeService.QueryByIntent(intent, location, entities);

        // 2c. If no data and intent requires DB → return honest no-data response
        // Note: itinerary_request can still build a plan even without bus/hotel data
        if (!knowledge.HasData && RequiresDbData(intent) && intent != "itinerary_request")
        {
            var noDataResponse = _responseBuilder.BuildNoDataResponse(
                intent, location.RequestedLocation, knowledge.Alternatives);
            noDataResponse.SessionId = sessionId;
            noDataResponse = _responseBuilder.EnsureQuickActions(noDataResponse, intent, userProfile);

            stopwatch.Stop();
            await SaveHistory(request, noDataResponse, intent, sessionId,
                (int)stopwatch.ElapsedMilliseconds, true, false, null,
                classification.ClassifierDetails);
            return noDataResponse;
        }

        // ═══ LAYER 3: PLANNING / RESPONSE ═══

        ChatResponseDto response;

        var dbFirstIntent = intent is "hotel_query" or "bus_query" or "destination_query" or "budget_query" or "package_query" or "booking_request";

        if (intent == "itinerary_request")
        {
            // Plan generation with condition gate
            var readiness = _planningService.CheckPlanReadiness(
                entities, location, request.Message, history);

            if (!readiness.IsReady)
            {
                response = _responseBuilder.BuildFollowUpResponse(
                    readiness.FollowUpQuestion!, readiness.MissingFields);

                // Enrich with destination cards so user still sees something while missing info
                response = _responseBuilder.EnrichResponse(
                    response, "destination_query", knowledge, userProfile);
            }
            else
            {
                // All data ready → build plan from DB data
                response = await _planningService.BuildPlan(readiness, knowledge, userProfile);
            }
        }
        else if (intent == "weather_query")
        {
            // Weather uses external API, not DB
            response = await HandleWeatherQuery(request.Message, location, userProfile);
        }
        else if (dbFirstIntent)
        {
            // DB-first intents should not depend on AI wording
            response = new ChatResponseDto
            {
                ResponseType = "text",
                Timestamp = DateTime.UtcNow
            };
            response = _responseBuilder.EnrichResponse(response, intent, knowledge, userProfile);
        }
        else
        {
            // General / assistant-style conversation can still use AI text
            response = await GenerateAiTextResponse(
                request.Message, intent, knowledge, history, userProfile);
            response = _responseBuilder.EnrichResponse(response, intent, knowledge, userProfile);
        }

        // ═══ FINALIZE ═══

        response.SessionId = sessionId;
        response = _responseBuilder.EnsureQuickActions(response, intent, userProfile);

        stopwatch.Stop();
        await SaveHistory(request, response, intent, sessionId,
            (int)stopwatch.ElapsedMilliseconds, true, false, null,
            classification.ClassifierDetails);

        return response;
    }

    // ══════════════════════════════════════════════
    // HISTORY MANAGEMENT (preserved from original)
    // ══════════════════════════════════════════════

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

    // ══════════════════════════════════════════════
    // AI TEXT GENERATION
    // ══════════════════════════════════════════════

    private async Task<ChatResponseDto> GenerateAiTextResponse(
        string userMessage,
        string intent,
        KnowledgeResult knowledge,
        List<ChatHistoryItemDto> history,
        ChatUserProfileDto? userProfile)
    {
        var dbContext = _knowledgeService.BuildDatabaseContextString(knowledge, userProfile);

        var context = new ChatContextDto
        {
            UserMessage = userMessage,
            DetectedIntent = intent,
            DatabaseContext = dbContext,
            PreferredLanguage = userProfile?.PreferredLanguage ?? "vi",
            PreferredCurrency = userProfile?.PreferredCurrency ?? "VND",
            PersonalizationSummary = ResponseBuilder.BuildPersonalizationSummary(userProfile),
            ConversationHistory = history
        };

        try
        {
            var response = await _aiService.GenerateResponseWithJsonModeAsync(context);

            if (!string.IsNullOrWhiteSpace(response.Text))
            {
                // Try to normalize JSON-in-text responses
                var normalized = TryNormalizeJsonResponse(response);
                return normalized ?? response;
            }

            return response;
        }
        catch
        {
            // AI failure → return a friendly fallback
            return new ChatResponseDto
            {
                Text = ResponseBuilder.Localize(
                    userProfile,
                    "Mình có thể giúp bạn gợi ý điểm đến, tìm khách sạn, xem tuyến xe, ước tính chi phí và lập lịch trình du lịch.",
                    "I can help with destinations, hotels, bus routes, travel budgets, and itineraries."),
                ResponseType = "text",
                Timestamp = DateTime.UtcNow
            };
        }
    }

    // ══════════════════════════════════════════════
    // WEATHER HANDLER (external API)
    // ══════════════════════════════════════════════

    private async Task<ChatResponseDto> HandleWeatherQuery(
        string userMessage,
        LocationMatchResult location,
        ChatUserProfileDto? userProfile)
    {
        var explicitLocation = _entityExtractor.ExtractWeatherLocation(userMessage);
        var locationQuery = explicitLocation ?? location.ExactMatches.FirstOrDefault()?.Name;

        if (string.IsNullOrWhiteSpace(locationQuery))
        {
            return new ChatResponseDto
            {
                Text = "Bạn muốn xem thời tiết ở đâu? Cho mình biết tên thành phố nhé.",
                ResponseType = "text",
                Timestamp = DateTime.UtcNow
            };
        }

        var weather = await _weatherLookupService.GetWeatherAsync(
            locationQuery, userProfile?.PreferredLanguage);

        if (weather == null)
        {
            return new ChatResponseDto
            {
                Text = $"Mình chưa lấy được thời tiết mới nhất cho {locationQuery} ngay lúc này.",
                ResponseType = "weather",
                Timestamp = DateTime.UtcNow
            };
        }

        var temp = weather.Temperature.HasValue
            ? $"{weather.Temperature.Value:0}°C"
            : "chưa rõ nhiệt độ";
        var condition = string.IsNullOrWhiteSpace(weather.Condition)
            ? "thời tiết hiện tại"
            : weather.Condition!;

        return new ChatResponseDto
        {
            Text = $"Thời tiết hiện tại tại {weather.Location}: {condition}, {temp}. Mình đã thêm dự báo ngắn ngày để bạn dễ lên lịch trình.",
            ResponseType = "weather",
            WeatherInfo = weather,
            Timestamp = DateTime.UtcNow
        };
    }

    // ══════════════════════════════════════════════
    // PRIVATE HELPERS
    // ══════════════════════════════════════════════

    private async Task<List<ChatHistoryItemDto>> LoadHistory(int? userId, string sessionId)
    {
        if (!userId.HasValue)
        {
            return [];
        }

        var historyResult = await GetChatHistoryAsync(userId.Value, sessionId, 10);
        return historyResult.Messages;
    }

    private async Task SaveHistory(
        ChatRequestDto request,
        ChatResponseDto response,
        string intent,
        string sessionId,
        int latencyMs,
        bool isJsonValid,
        bool isFallbackUsed,
        string? errorLog,
        string? classifierDetails)
    {
        if (!request.UserId.HasValue)
        {
            return;
        }

        var history = new ChatHistory
        {
            UserId = request.UserId.Value,
            UserMessage = request.Message,
            BotResponse = response.Text,
            ResponseType = response.ResponseType,
            ResponseDataJson = JsonSerializer.Serialize(response, JsonOptions),
            DetectedIntent = intent,
            SessionId = sessionId,
            CreatedAt = DateTime.UtcNow,
            LatencyMs = latencyMs,
            IsJsonValid = isJsonValid,
            IsFallbackUsed = isFallbackUsed,
            ErrorLog = errorLog,
            ClassifierDetails = classifierDetails
        };

        await _chatRepo.SaveChatHistoryAsync(history);
    }

    private static bool RequiresDbData(string intent)
    {
        return intent is "hotel_query" or "bus_query" or "booking_request";
    }

    private static void MergeLlmEntities(ChatEntitiesDto target, ChatEntitiesDto source)
    {
        if (string.IsNullOrWhiteSpace(target.Destination) && !string.IsNullOrWhiteSpace(source.Destination))
            target.Destination = source.Destination;
        if (string.IsNullOrWhiteSpace(target.Origin) && !string.IsNullOrWhiteSpace(source.Origin))
            target.Origin = source.Origin;
        if (!target.Days.HasValue && source.Days.HasValue)
            target.Days = source.Days;
        if (!target.Budget.HasValue && source.Budget.HasValue)
            target.Budget = source.Budget;
        if (!target.PassengerCount.HasValue && source.PassengerCount.HasValue)
            target.PassengerCount = source.PassengerCount;
        if (string.IsNullOrWhiteSpace(target.HotelName) && !string.IsNullOrWhiteSpace(source.HotelName))
            target.HotelName = source.HotelName;
        if (string.IsNullOrWhiteSpace(target.DepartureDate) && !string.IsNullOrWhiteSpace(source.DepartureDate))
            target.DepartureDate = source.DepartureDate;
    }

    private static ChatResponseDto? TryNormalizeJsonResponse(ChatResponseDto response)
    {
        var trimmed = response.Text?.Trim();
        if (string.IsNullOrWhiteSpace(trimmed) || !trimmed.StartsWith('{') || !trimmed.EndsWith('}'))
        {
            return null;
        }

        try
        {
            var parsed = JsonSerializer.Deserialize<ChatResponseDto>(trimmed, JsonOptions);
            if (parsed == null)
            {
                return null;
            }

            parsed.Timestamp = response.Timestamp == default ? DateTime.UtcNow : response.Timestamp;
            parsed.SessionId ??= response.SessionId;
            parsed.QuickActions ??= response.QuickActions;
            return parsed;
        }
        catch
        {
            return null;
        }
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
