using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Layer 1 - Intent classification with strict priority rules.
/// Keyword is only a signal; entity confirmation decides the final intent.
/// </summary>
public class IntentRouter
{
    private readonly IGrokAiService _aiService;
    private readonly EntityExtractor _entityExtractor;

    public IntentRouter(IGrokAiService aiService, EntityExtractor entityExtractor)
    {
        _aiService = aiService;
        _entityExtractor = entityExtractor;
    }

    public async Task<IntentClassificationResult> ClassifyIntent(
        string message,
        List<ChatHistoryItemDto> history)
    {
        var entities = _entityExtractor.ExtractAll(message);
        var ruleBasedIntent = DetectIntentRuleBased(message, entities);

        // If bot's last message was an itinerary follow-up question,
        // treat the user's reply as itinerary_request regardless of content
        if (IsItineraryFollowUpContext(history) && ruleBasedIntent is "bus_query" or "general")
        {
            ruleBasedIntent = "itinerary_request";
        }

        ChatIntentResultDto? llmResult = null;
        if (ruleBasedIntent == "general" || IsShortAmbiguousMessage(message))
        {
            try
            {
                llmResult = await _aiService.ClassifyIntentAsync(message, history);
            }
            catch
            {
            }
        }

        var finalIntent = ResolveConflict(ruleBasedIntent, llmResult?.Intent, entities);

        return new IntentClassificationResult
        {
            Intent = finalIntent,
            LlmEntities = llmResult?.Entities,
            ClassifierDetails = BuildClassifierDetails(ruleBasedIntent, llmResult?.Intent, finalIntent)
        };
    }

    /// <summary>
    /// Returns true if the bot's most recent message was asking for itinerary info
    /// (i.e. asking about departure date, number of travelers, or budget).
    /// </summary>
    private static bool IsItineraryFollowUpContext(List<ChatHistoryItemDto> history)
    {
        var lastBotMessage = history
            .Where(h => h.Role == "bot")
            .LastOrDefault();

        if (lastBotMessage == null) return false;

        var text = (lastBotMessage.Content ?? "").ToLowerInvariant();
        return text.Contains("ngày bắt đầu") ||
               text.Contains("bao nhiêu người") ||
               text.Contains("ngân sách") ||
               text.Contains("bao lâu") ||
               text.Contains("bạn giúp mình bổ sung") ||
               text.Contains("bạn muốn đi trong");
    }

    private static string DetectIntentRuleBased(string message, ChatEntitiesDto entities)
    {
        var lower = EntityExtractor.NormalizeText(message);

        var hasDestination = !string.IsNullOrWhiteSpace(entities.Destination);
        var hasOrigin = !string.IsNullOrWhiteSpace(entities.Origin);
        var hasDays = entities.Days.HasValue;
        var hasBudget = entities.Budget.HasValue;
        var hasDate = !string.IsNullOrWhiteSpace(entities.DepartureDate);
        var hasHotel = !string.IsNullOrWhiteSpace(entities.HotelName);
        var hasPassengerCount = entities.PassengerCount.HasValue;

        var packageKeywords = EntityExtractor.ContainsAny(lower,
            "goi du lich", "tour", "combo", "package",
            "tour tron goi", "combo du lich", "deal du lich");

        var promotionKeywords = EntityExtractor.ContainsAny(lower,
            "khuyen mai", "uu dai", "voucher",
            "promo", "promotion", "giam gia",
            "coupon", "ma giam gia");

        var weatherKeywords = EntityExtractor.ContainsAny(lower,
            "thoi tiet", "weather", "nhiet do",
            "temperature", "du bao",
            "nang nong", "troi mua", "troi nang",
            "co mua khong", "mua nhieu khong");

        var foodKeywords = EntityExtractor.ContainsAny(lower,
            "an gi", "quan an", "nha hang",
            "restaurant", "am thuc", "food",
            "mon an", "dac san", "hai san",
            "quan ngon", "do an");

        var nearbyKeywords = EntityExtractor.ContainsAny(lower,
            "gan toi", "nearby", "xung quanh",
            "quanh day", "gan day", "gan nhat",
            "o day", "khu vuc nay");

        var itineraryKeywords = EntityExtractor.ContainsAny(lower,
            "lich trinh", "ke hoach",
            "plan", "itinerary",
            "lap ke hoach", "schedule",
            "lap plan", "sap xep lich",
            "di trong", "choi trong");

        var transportKeywords = EntityExtractor.ContainsAny(lower,
            "xe", "bus", "lich xe",
            "tuyen xe", "chuyen xe",
            "di chuyen", "phuong tien",
            "may bay", "tau hoa",
            "taxi", "grab");

        var budgetKeywords = EntityExtractor.ContainsAny(lower,
            "gia", "chi phi", "budget",
            "tiet kiem", "bao nhieu tien",
            "ngan sach", "re nhat",
            "het bao nhieu", "ton bao nhieu");

        var hotelKeywords = EntityExtractor.ContainsAny(lower,
            "khach san", "hotel", "phong",
            "cho o", "resort", "homestay",
            "nghi o dau", "luu tru",
            "villa", "can ho");

        var destinationKeywords = EntityExtractor.ContainsAny(lower,
            "goi y", "recommend",
            "di dau", "noi nao",
            "diem den", "destination",
            "du lich o", "hot nhat",
            "choi gi", "tham quan",
            "check in", "dia diem");

        var bookingKeywords = EntityExtractor.ContainsAny(lower,
            "dat", "book", "booking",
            "dat phong", "dat ve", "giu cho",
            "reserve", "xac nhan dat");

        var itineraryScore = 0;
        if (itineraryKeywords) itineraryScore += 4;
        if (hasDestination) itineraryScore += 2;
        if (hasOrigin) itineraryScore += 1;
        if (hasPassengerCount) itineraryScore += 1;
        if (hasBudget) itineraryScore += 1;
        if (hasDays) itineraryScore += 1;
        if (hasDate) itineraryScore += 1;

        var hotelScore = 0;
        if (hotelKeywords) hotelScore += 3;
        if (hasDestination) hotelScore += 2;
        if (hasHotel) hotelScore += 2;

        var transportScore = 0;
        if (transportKeywords) transportScore += 3;
        if (hasOrigin) transportScore += 1;
        if (hasDestination) transportScore += 1;
        if (hasDate) transportScore += 1;

        var weatherScore = 0;
        if (weatherKeywords) weatherScore += 3;
        if (hasDestination) weatherScore += 1;

        var destinationScore = 0;
        if (destinationKeywords) destinationScore += 3;
        if (hasDestination) destinationScore += 2;

        var bookingScore = 0;
        if (bookingKeywords) bookingScore += 3;
        if (hasHotel || hasDestination) bookingScore += 1;
        if (hasDate) bookingScore += 1;

        if (packageKeywords) return "package_query";
        if (promotionKeywords) return "promotion_query";
        if (weatherScore >= 3) return "weather_query";
        if (foodKeywords) return "food_query";
        if (nearbyKeywords) return "nearby_query";
        if (itineraryScore >= 4) return "itinerary_request";
        if (transportScore >= 3) return "bus_query";
        if (budgetKeywords) return "budget_query";
        if (hotelScore >= 3) return "hotel_query";
        if (bookingScore >= 3) return "booking_request";
        if (destinationScore >= 3) return "destination_query";

        return "general";
    }

    private static string ResolveConflict(string ruleIntent, string? llmIntent, ChatEntitiesDto entities)
    {
        if (ruleIntent != "general")
        {
            return ruleIntent;
        }

        if (!string.IsNullOrWhiteSpace(llmIntent) && !string.Equals(llmIntent, "general", StringComparison.OrdinalIgnoreCase))
        {
            return llmIntent;
        }

        return InferIntentFromEntities(entities);
    }

    private static string InferIntentFromEntities(ChatEntitiesDto entities)
    {
        if (!string.IsNullOrWhiteSpace(entities.HotelName))
        {
            return "hotel_query";
        }

        // Only infer bus_query when BOTH origin AND destination are present
        // (a date alone is not enough — it could be an itinerary follow-up answer)
        if (!string.IsNullOrWhiteSpace(entities.Origin) && !string.IsNullOrWhiteSpace(entities.Destination))
        {
            return "bus_query";
        }

        if (entities.Days.HasValue || entities.Budget.HasValue || entities.PassengerCount.HasValue)
        {
            return "itinerary_request";
        }

        if (!string.IsNullOrWhiteSpace(entities.Destination))
        {
            return "destination_query";
        }

        return "general";
    }

    private static bool IsCompatibleIntent(string ruleIntent, string entityBasedIntent)
    {
        if (ruleIntent == entityBasedIntent)
        {
            return true;
        }

        return (ruleIntent, entityBasedIntent) switch
        {
            ("booking_request", "hotel_query") => true,
            ("booking_request", "bus_query") => true,
            ("destination_query", "hotel_query") => true,
            ("destination_query", "itinerary_request") => true,
            ("hotel_query", "booking_request") => true,
            ("bus_query", "booking_request") => true,
            ("itinerary_request", "destination_query") => true,
            _ => false
        };
    }

    private static bool IsShortAmbiguousMessage(string message)
    {
        var wordCount = message.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries).Length;
        return wordCount <= 5;
    }

    private static string BuildClassifierDetails(string ruleIntent, string? llmIntent, string finalIntent)
    {
        return $"rule={ruleIntent}|llm={llmIntent ?? "not_called"}|final={finalIntent}";
    }
}

public class IntentClassificationResult
{
    public string Intent { get; set; } = "general";
    public ChatEntitiesDto? LlmEntities { get; set; }
    public string? ClassifierDetails { get; set; }
}
