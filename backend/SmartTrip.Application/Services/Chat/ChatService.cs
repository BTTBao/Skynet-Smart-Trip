using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;
using System.Globalization;
using System.Text;
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

        var intent = DetectIntent(request.Message);
        var dbContext = await BuildDatabaseContext(request.Message, intent);

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

        var response = await TryGenerateAiResponseAsync(context);
        response = NormalizeAiResponse(response);

        if (NeedsDeterministicFallback(response))
        {
            response = await BuildDeterministicResponseAsync(intent, request.Message);
        }

        response = await EnrichWithDatabaseData(response, intent, request.Message);
        response = await AlignResponseToIntentAsync(response, intent, request.Message);
        response = EnsureQuickActions(response, intent);
        response.SessionId = normalizedSessionId;

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
        foreach (var history in histories)
        {
            result.Add(new ChatHistoryItemDto
            {
                Role = "user",
                Content = history.UserMessage,
                SessionId = history.SessionId,
                Timestamp = history.CreatedAt
            });
            result.Add(new ChatHistoryItemDto
            {
                Role = "bot",
                Content = history.BotResponse,
                SessionId = history.SessionId,
                ResponseType = history.ResponseType,
                Timestamp = history.CreatedAt,
                ResponsePayload = DeserializeResponsePayload(history.ResponseDataJson)
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

    private string DetectIntent(string message)
    {
        var lower = NormalizeText(message);

        if (ContainsAny(lower, "goi du lich", "tour", "combo", "package"))
            return "package_query";

        if (ContainsAny(lower, "gia", "chi phi", "budget", "tiet kiem", "bao nhieu tien", "ngan sach"))
            return "budget_query";

        if (ContainsAny(lower, "khuyen mai", "uu dai", "voucher", "promo", "promotion", "giam gia"))
            return "promotion_query";

        if (ContainsAny(lower, "xe", "bus", "lich xe", "tuyen xe", "chuyen xe", "di chuyen"))
            return "bus_query";

        if (ContainsAny(lower, "lich trinh", "ke hoach", "plan", "itinerary", "lap ke hoach", "schedule"))
            return "itinerary_request";

        if (ContainsAny(lower, "khach san", "hotel", "phong", "cho o", "resort", "homestay", "nghi o dau"))
            return "hotel_query";

        if (ContainsAny(lower, "thoi tiet", "weather", "mua", "nang", "nhiet do", "temperature"))
            return "weather_query";

        if (ContainsAny(lower, "goi y", "recommend", "di dau", "noi nao", "diem den", "destination", "du lich o", "hot nhat"))
            return "destination_query";

        if (ContainsAny(lower, "gan toi", "nearby", "xung quanh", "quanh day", "gan day"))
            return "nearby_query";

        if (ContainsAny(lower, "dat", "book", "booking", "ve", "dat phong", "dat ve"))
            return "booking_request";

        if (ContainsAny(lower, "an gi", "quan an", "nha hang", "restaurant", "am thuc", "food", "mon an"))
            return "food_query";

        return "general";
    }

    private async Task<string> BuildDatabaseContext(string message, string intent)
    {
        var parts = new List<string>();

        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = FindMatchedDestinations(message, destinations);

        if (destinations.Any())
        {
            var destinationList = string.Join(", ", destinations.Select(d => $"{d.Name}{(d.IsHot == true ? " (HOT)" : string.Empty)}"));
            parts.Add($"Diem den trong he thong: {destinationList}");
        }

        if (intent is "hotel_query" or "destination_query" or "booking_request" or "budget_query" or "package_query")
        {
            var hotels = matchedDestinations.Any()
                ? await _chatRepo.SearchDestinationsHotelsAsync(matchedDestinations.Select(d => d.Id), 10)
                : await _chatRepo.GetAvailableHotelsAsync(10);

            if (hotels.Any())
            {
                var hotelList = string.Join("; ", hotels.Select(h =>
                    $"{h.Name} ({h.StarRating} sao, {h.Destination?.Name ?? string.Empty}, tu {FormatCurrency(GetLowestHotelPrice(h))} / dem)"));
                parts.Add($"Khach san phu hop: {hotelList}");
            }
        }

        if (intent is "itinerary_request" or "general" or "bus_query" or "budget_query" or "package_query")
        {
            var busSchedules = await _chatRepo.GetBusSchedulesAsync(
                6,
                matchedDestinations.Select(d => d.Id));

            if (busSchedules.Any())
            {
                var routeList = string.Join("; ", busSchedules.Select(schedule =>
                    $"{schedule.FromDest?.Name ?? "?"} -> {schedule.ToDest?.Name ?? "?"} ({FormatCurrency(schedule.Price)}, {FormatDateTime(schedule.DepartureTime)})"));
                parts.Add($"Tuyen xe hien co: {routeList}");
            }
        }

        if (intent is "promotion_query" or "budget_query" or "booking_request" or "package_query")
        {
            var promotions = await _chatRepo.GetActivePromotionsAsync(5);
            if (promotions.Any())
            {
                var promotionList = string.Join("; ", promotions.Select(p =>
                    $"{p.Code}: giam {p.DiscountPercent?.ToString("0") ?? "0"}% toi da {FormatCurrency(p.MaxDiscountAmount)}"));
                parts.Add($"Khuyen mai dang hoat dong: {promotionList}");
            }
        }

        return parts.Any() ? string.Join("\n", parts) : string.Empty;
    }

    private async Task<ChatResponseDto> EnrichWithDatabaseData(
        ChatResponseDto response,
        string intent,
        string userMessage)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = FindMatchedDestinations(userMessage, destinations);

        if (intent == "destination_query"
            && (response.DestinationCards == null || response.DestinationCards.Count == 0))
        {
            var destinationMatches = matchedDestinations.Any()
                ? matchedDestinations.Take(3).ToList()
                : destinations.Take(3).ToList();

            if (destinationMatches.Any())
            {
                response.DestinationCards = destinationMatches.Select(d => new DestinationCardDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    ImageUrl = d.CoverImageUrl,
                    IsHot = d.IsHot
                }).ToList();

                if (response.ResponseType == "text")
                {
                    response.ResponseType = "destination_card";
                }
            }
        }

        if (intent == "package_query"
            && (response.DestinationCards == null || response.DestinationCards.Count == 0)
            && matchedDestinations.Any())
        {
            response.DestinationCards = matchedDestinations
                .Take(3)
                .Select(d => new DestinationCardDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    ImageUrl = d.CoverImageUrl,
                    IsHot = d.IsHot
                })
                .ToList();
        }

        if (intent == "hotel_query" && (response.HotelCards == null || response.HotelCards.Count == 0))
        {
            var hotels = matchedDestinations.Any()
                ? await _chatRepo.SearchDestinationsHotelsAsync(matchedDestinations.Select(d => d.Id), 3)
                : await _chatRepo.GetAvailableHotelsAsync(3);

            if (hotels.Any())
            {
                response.HotelCards = hotels.Select(h => new HotelCardDto
                {
                    Id = h.Id,
                    Name = h.Name,
                    Address = h.Address,
                    StarRating = h.StarRating,
                    Description = h.Description,
                    PricePerNight = GetLowestHotelPrice(h),
                    DestinationName = h.Destination?.Name,
                    Amenities = h.Amenities.Select(a => a.Name ?? string.Empty).ToList(),
                    IsAvailable = h.IsAvailable
                }).ToList();

                if (response.ResponseType == "text")
                {
                    response.ResponseType = "hotel_list";
                }
            }
        }

        if (intent == "promotion_query")
        {
            response.Text = await BuildPromotionSummaryAsync();
            if (response.QuickActions == null || response.QuickActions.Count == 0)
            {
                response.QuickActions = new List<QuickActionDto>
                {
                    new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san tot dang co uu dai" },
                    new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh tiet kiem chi phi cho toi" }
                };
            }
        }

        if (intent == "bus_query")
        {
            response.Text = await BuildBusSummaryAsync(response.Text, matchedDestinations);
            if (response.QuickActions == null || response.QuickActions.Count == 0)
            {
                response.QuickActions = new List<QuickActionDto>
                {
                    new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san gan diem den nay" },
                    new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh dua tren tuyen xe hien co" }
                };
            }
        }

        if (intent == "budget_query")
        {
            response.Text = await BuildBudgetSummaryAsync(response.Text, matchedDestinations, userMessage);
            response.ResponseType = "text";
            response.WeatherInfo = null;
        }

        if (intent == "package_query")
        {
            response.Text = await BuildPackageSummaryAsync(response.Text, matchedDestinations);
            response.ResponseType = "destination_card";
            response.WeatherInfo = null;
            response.QuickActions = BuildPackageQuickActions(matchedDestinations.FirstOrDefault());
        }

        if (intent == "itinerary_request" && response.SuggestedItinerary == null)
        {
            response.SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations);
            if (response.SuggestedItinerary != null && response.ResponseType == "text")
            {
                response.ResponseType = "itinerary";
            }
        }

        return response;
    }

    private async Task SaveChatHistory(
        int userId,
        string userMessage,
        ChatResponseDto response,
        string intent,
        string? sessionId)
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

    private async Task<ChatResponseDto> TryGenerateAiResponseAsync(ChatContextDto context)
    {
        try
        {
            return await _aiService.GenerateResponseAsync(context);
        }
        catch
        {
            return new ChatResponseDto();
        }
    }

    private ChatResponseDto NormalizeAiResponse(ChatResponseDto response)
    {
        if (string.IsNullOrWhiteSpace(response.Text))
        {
            return response;
        }

        var trimmed = response.Text.Trim();
        if (!trimmed.StartsWith('{') || !trimmed.EndsWith('}'))
        {
            return response;
        }

        try
        {
            var parsed = JsonSerializer.Deserialize<ChatResponseDto>(trimmed, JsonOptions);
            if (parsed == null)
            {
                return response;
            }

            parsed.Timestamp = response.Timestamp == default ? DateTime.UtcNow : response.Timestamp;
            parsed.SessionId ??= response.SessionId;
            parsed.QuickActions ??= response.QuickActions;
            return parsed;
        }
        catch
        {
            return response;
        }
    }

    private static bool NeedsDeterministicFallback(ChatResponseDto response)
    {
        var text = response.Text?.Trim() ?? string.Empty;
        var hasRichContent = response.SuggestedItinerary != null
            || (response.DestinationCards?.Count > 0)
            || (response.HotelCards?.Count > 0)
            || response.WeatherInfo != null;

        if (string.IsNullOrWhiteSpace(text) && !hasRichContent)
        {
            return true;
        }

        return text.StartsWith("Sky dang tam thoi tra loi o che do fallback", StringComparison.OrdinalIgnoreCase)
            || text.StartsWith("{", StringComparison.Ordinal);
    }

    private async Task<ChatResponseDto> BuildDeterministicResponseAsync(string intent, string userMessage)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = FindMatchedDestinations(userMessage, destinations);

        return intent switch
        {
            "promotion_query" => new ChatResponseDto
            {
                Text = await BuildPromotionSummaryAsync(),
                ResponseType = "text"
            },
            "bus_query" => new ChatResponseDto
            {
                Text = await BuildBusSummaryAsync(string.Empty, matchedDestinations),
                ResponseType = "text"
            },
            "budget_query" => new ChatResponseDto
            {
                Text = await BuildBudgetSummaryAsync(string.Empty, matchedDestinations, userMessage),
                ResponseType = "text"
            },
            "package_query" => new ChatResponseDto
            {
                Text = await BuildPackageSummaryAsync(string.Empty, matchedDestinations),
                ResponseType = "destination_card"
            },
            "itinerary_request" => new ChatResponseDto
            {
                Text = "Minh da lap nhanh mot lich trinh tham khao de ban de hinh dung hon.",
                ResponseType = "itinerary",
                SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations)
            },
            "hotel_query" => new ChatResponseDto
            {
                Text = matchedDestinations.Any()
                    ? $"Minh da loc nhanh mot so khach san phu hop tai {matchedDestinations[0].Name} cho ban."
                    : "Minh da loc nhanh mot so khach san phu hop cho ban.",
                ResponseType = "hotel_list"
            },
            "destination_query" => new ChatResponseDto
            {
                Text = matchedDestinations.Any()
                    ? $"Minh da tong hop mot vai diem den lien quan den {matchedDestinations[0].Name} cho ban."
                    : "Minh da tong hop mot vai diem den noi bat de ban tham khao.",
                ResponseType = "destination_card"
            },
            "weather_query" => new ChatResponseDto
            {
                Text = BuildWeatherFallbackMessage(matchedDestinations),
                ResponseType = "weather"
            },
            _ => new ChatResponseDto
            {
                Text = "Minh co the giup ban goi y diem den, tim khach san, xem tuyen xe, uoc tinh chi phi va lap lich trinh du lich.",
                ResponseType = "text"
            }
        };
    }

    private ChatResponseDto EnsureQuickActions(ChatResponseDto response, string intent)
    {
        response.Timestamp = response.Timestamp == default ? DateTime.UtcNow : response.Timestamp;

        if (response.QuickActions == null || response.QuickActions.Count == 0)
        {
            response.QuickActions = BuildDefaultQuickActionsForIntent(intent);
        }

        return response;
    }

    private async Task<ChatResponseDto> AlignResponseToIntentAsync(
        ChatResponseDto response,
        string intent,
        string userMessage)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = FindMatchedDestinations(userMessage, destinations);

        switch (intent)
        {
            case "budget_query":
                response.ResponseType = "text";
                response.WeatherInfo = null;
                response.SuggestedItinerary = null;
                response.Text = await BuildBudgetSummaryAsync(response.Text, matchedDestinations, userMessage);
                break;

            case "package_query":
                response.ResponseType = "destination_card";
                response.WeatherInfo = null;
                response.SuggestedItinerary = null;
                if (!matchedDestinations.Any())
                {
                    response.DestinationCards = null;
                    response.HotelCards = null;
                }
                response.Text = await BuildPackageSummaryAsync(response.Text, matchedDestinations);
                response.QuickActions = BuildPackageQuickActions(matchedDestinations.FirstOrDefault());
                break;

            case "bus_query":
                response.ResponseType = "text";
                response.WeatherInfo = null;
                response.SuggestedItinerary = null;
                response.Text = await BuildBusSummaryAsync(response.Text, matchedDestinations);
                break;

            case "weather_query":
                response.ResponseType = "weather";
                response.HotelCards = null;
                break;

            case "itinerary_request":
                response = await EnsureValidItineraryAsync(response, matchedDestinations, userMessage);
                break;
        }

        return response;
    }

    private static bool ContainsAny(string text, params string[] keywords)
    {
        return keywords.Any(keyword => text.Contains(keyword, StringComparison.OrdinalIgnoreCase));
    }

    private static List<Destination> FindMatchedDestinations(
        string message,
        IEnumerable<Destination> destinations)
    {
        var normalizedMessage = NormalizeText(message);
        if (string.IsNullOrWhiteSpace(normalizedMessage))
        {
            return [];
        }

        return destinations
            .Where(destination =>
            {
                var normalizedName = NormalizeText(destination.Name);
                return normalizedMessage.Contains(normalizedName)
                    || normalizedName.Contains(normalizedMessage);
            })
            .DistinctBy(destination => destination.Id)
            .ToList();
    }

    private async Task<string> BuildPromotionSummaryAsync()
    {
        var promotions = await _chatRepo.GetActivePromotionsAsync(5);
        if (!promotions.Any())
        {
            return "Hien tai chua co khuyen mai noi bat. Ban co the thu lai sau de xem uu dai moi nhat.";
        }

        var lines = promotions.Select(p =>
            $"- {p.Code}: giam {p.DiscountPercent?.ToString("0") ?? "0"}% toi da {FormatCurrency(p.MaxDiscountAmount)}");

        return "Day la mot so khuyen mai dang hoat dong:\n" + string.Join("\n", lines);
    }

    private async Task<string> BuildBusSummaryAsync(string fallbackText, List<Destination> matchedDestinations)
    {
        var routes = await _chatRepo.GetBusSchedulesAsync(
            4,
            matchedDestinations.Select(destination => destination.Id));

        if (!routes.Any())
        {
            return string.IsNullOrWhiteSpace(fallbackText)
                ? "Minh chua tim thay tuyen xe phu hop trong he thong cho yeu cau nay."
                : fallbackText;
        }

        var lines = routes.Select(route =>
            $"- {route.FromDest?.Name ?? "?"} -> {route.ToDest?.Name ?? "?"}, {FormatDateTime(route.DepartureTime)}, gia tu {FormatCurrency(route.Price)}");

        return "Minh tim thay mot so tuyen xe phu hop:\n" + string.Join("\n", lines);
    }

    private async Task<string> BuildBudgetSummaryAsync(
        string fallbackText,
        List<Destination> matchedDestinations,
        string requestText)
    {
        var requestedDays = ExtractRequestedDays(requestText);
        if (requestedDays <= 0)
        {
            requestedDays = 3;
        }

        var hotels = matchedDestinations.Any()
            ? await _chatRepo.SearchDestinationsHotelsAsync(matchedDestinations.Select(d => d.Id), 3)
            : await _chatRepo.GetAvailableHotelsAsync(3);

        var buses = await _chatRepo.GetBusSchedulesAsync(
            3,
            matchedDestinations.Select(destination => destination.Id));
        var promotions = await _chatRepo.GetActivePromotionsAsync(2);

        var parts = new List<string>();

        if (hotels.Any())
        {
            var hotelText = string.Join("; ", hotels.Select(h =>
                $"{h.Name} tu {FormatCurrency(GetEstimatedStayCost(GetLowestHotelPrice(h), requestedDays))} cho {requestedDays} ngay"));
            parts.Add($"Khach san: {hotelText}");
        }

        if (buses.Any())
        {
            var busText = string.Join("; ", buses.Select(b =>
                $"{b.FromDest?.Name ?? "?"} -> {b.ToDest?.Name ?? "?"} tu {FormatCurrency(b.Price)}"));
            parts.Add($"Di chuyen: {busText}");
        }

        if (promotions.Any())
        {
            var promoText = string.Join("; ", promotions.Select(p =>
                $"{p.Code} giam {p.DiscountPercent?.ToString("0") ?? "0"}%"));
            parts.Add($"Khuyen mai: {promoText}");
        }

        if (!parts.Any())
        {
            return string.IsNullOrWhiteSpace(fallbackText)
                ? "Minh chua du du lieu de uoc tinh ngan sach cho yeu cau nay."
                : fallbackText;
        }

        return $"Minh tong hop nhanh chi phi tham khao cho chuyen di {requestedDays} ngay:\n- " + string.Join("\n- ", parts);
    }

    private static string BuildWeatherFallbackMessage(List<Destination> matchedDestinations)
    {
        var destinationName = matchedDestinations.FirstOrDefault()?.Name;
        if (!string.IsNullOrWhiteSpace(destinationName))
        {
            return $"Minh chua co du lieu thoi tiet thoi gian thuc cho {destinationName}. Neu ban muon, minh van co the goi y lich trinh, khach san va ngan sach tham khao cho diem den nay.";
        }

        return "Minh chua co du lieu thoi tiet thoi gian thuc luc nay. Neu ban muon, minh van co the goi y diem den, khach san va lich trinh tham khao.";
    }

    private static List<QuickActionDto> BuildPackageQuickActions(Destination? destination)
    {
        if (destination?.Name is string destinationName && !string.IsNullOrWhiteSpace(destinationName))
        {
            return new List<QuickActionDto>
            {
                new() { Label = $"Khach san o {destinationName}", Icon = "hotel", ActionPayload = $"Tim khach san phu hop o {destinationName}" },
                new() { Label = $"Lich trinh {destinationName}", Icon = "calendar", ActionPayload = $"Lap lich trinh du lich cho {destinationName}" }
            };
        }

        return new List<QuickActionDto>
        {
            new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san phu hop cho diem den nay" },
            new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh du lich cho diem den nay" }
        };
    }

    private async Task<string> BuildPackageSummaryAsync(string fallbackText, List<Destination> matchedDestinations)
    {
        var destinationName = matchedDestinations.FirstOrDefault()?.Name;
        var promotions = await _chatRepo.GetActivePromotionsAsync(2);
        var promoSummary = promotions.Any()
            ? $" Uu dai hien co: {string.Join("; ", promotions.Select(p => $"{p.Code} giam {p.DiscountPercent?.ToString("0") ?? "0"}%"))}."
            : string.Empty;

        if (!string.IsNullOrWhiteSpace(destinationName))
        {
            return $"Hien he thong chua co module goi du lich dong goi san cho {destinationName}, nhung minh co the goi y diem den, lich trinh, khach san va chi phi tham khao de ban tu ghep thanh mot goi phu hop.{promoSummary}";
        }

        return $"Hien he thong chua co module goi du lich dong goi san cho diem den nay, nhung minh co the giup ban ghep lich trinh, khach san va ngan sach thanh mot goi tham khao.{promoSummary}";
    }

    private async Task<ChatResponseDto> EnsureValidItineraryAsync(
        ChatResponseDto response,
        List<Destination> matchedDestinations,
        string userMessage)
    {
        var requestedDays = ExtractRequestedDays(userMessage);
        var itinerary = response.SuggestedItinerary;

        if (itinerary == null || itinerary.TotalDays <= 0 || itinerary.Days.Count == 0)
        {
            response.SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations, requestedDays);
        }
        else if (requestedDays > 0 && itinerary.TotalDays != requestedDays)
        {
            response.SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations, requestedDays);
        }

        if (response.SuggestedItinerary != null)
        {
            response.ResponseType = "itinerary";
            if (string.IsNullOrWhiteSpace(response.Text))
            {
                response.Text = $"Minh da lap lich trinh tham khao {response.SuggestedItinerary.TotalDays} ngay cho ban.";
            }
        }

        return response;
    }

    private static int ExtractRequestedDays(string text)
    {
        var normalized = NormalizeText(text);
        var dayMatch = System.Text.RegularExpressions.Regex.Match(normalized, @"(\d+)\s*ngay");
        if (dayMatch.Success && int.TryParse(dayMatch.Groups[1].Value, out var days) && days > 0)
        {
            return days;
        }

        var nightMatch = System.Text.RegularExpressions.Regex.Match(normalized, @"(\d+)\s*dem");
        if (nightMatch.Success && int.TryParse(nightMatch.Groups[1].Value, out var nights) && nights >= 0)
        {
            return nights + 1;
        }

        return 3;
    }

    private async Task<ItineraryDto?> BuildSuggestedItineraryAsync(
        List<Destination> matchedDestinations,
        int requestedDays = 3)
    {
        var destination = matchedDestinations.FirstOrDefault()
            ?? (await _chatRepo.GetDestinationsAsync(1)).FirstOrDefault();
        if (destination == null)
        {
            return null;
        }

        var hotels = await _chatRepo.SearchDestinationsHotelsAsync([destination.Id], 1);
        var buses = await _chatRepo.GetBusSchedulesAsync(2, [destination.Id]);

        return new ItineraryDto
        {
            Title = $"Lich trinh goi y tai {destination.Name}",
            Destination = destination.Name,
            TotalDays = requestedDays,
            EstimatedBudget = hotels.Any()
                ? $"Tu {FormatCurrency(GetEstimatedStayCost(GetLowestHotelPrice(hotels[0]), requestedDays))} cho {requestedDays} ngay"
                : "Lien he de nhan bao gia",
            TravelStyle = "Linh hoat",
            Days = BuildItineraryDays(destination, hotels.FirstOrDefault(), buses.FirstOrDefault(), requestedDays)
        };
    }

    private static List<ItineraryDayDto> BuildItineraryDays(
        Destination destination,
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays)
    {
        var totalDays = Math.Max(1, requestedDays);
        var days = new List<ItineraryDayDto>();

        for (var dayNumber = 1; dayNumber <= totalDays; dayNumber++)
        {
            if (dayNumber == 1)
            {
                days.Add(new ItineraryDayDto
                {
                    DayNumber = dayNumber,
                    Theme = "Di chuyen va nhan phong",
                    Activities = new List<ItineraryActivityDto>
                    {
                        new()
                        {
                            Time = "08:00",
                            Title = $"Di chuyen den {destination.Name}",
                            Description = bus != null
                                ? $"Co the tham khao tuyen {bus.FromDest?.Name ?? "diem khoi hanh"} -> {bus.ToDest?.Name ?? destination.Name} vao {FormatDateTime(bus.DepartureTime)}"
                                : $"Bat dau hanh trinh den {destination.Name}",
                            Icon = "map"
                        },
                        new()
                        {
                            Time = "14:00",
                            Title = "Nhan phong va nghi ngoi",
                            Description = !string.IsNullOrWhiteSpace(hotel?.Name)
                                ? $"Goi y luu tru tai {hotel!.Name}"
                                : "Nhan phong tai khach san phu hop",
                            Icon = "hotel"
                        }
                    }
                });
                continue;
            }

            if (dayNumber == totalDays)
            {
                days.Add(new ItineraryDayDto
                {
                    DayNumber = dayNumber,
                    Theme = "Thu gian va ket thuc hanh trinh",
                    Activities = new List<ItineraryActivityDto>
                    {
                        new()
                        {
                            Time = "09:30",
                            Title = "Mua sam va chup anh",
                            Description = "Luu lai nhung trai nghiem cuoi cung trong chuyen di",
                            Icon = "camera"
                        },
                        new()
                        {
                            Time = "13:00",
                            Title = "Tra phong va di chuyen ve",
                            Description = $"Ket thuc lich trinh goi y {totalDays} ngay",
                            Icon = "car"
                        }
                    }
                });
                continue;
            }

            days.Add(new ItineraryDayDto
            {
                DayNumber = dayNumber,
                Theme = "Kham pha diem den",
                Activities = new List<ItineraryActivityDto>
                {
                    new()
                    {
                        Time = "09:00",
                        Title = $"Tham quan cac diem noi bat o {destination.Name}",
                        Description = destination.Description ?? $"Danh mot ngay de kham pha {destination.Name}",
                        Icon = "location"
                    },
                    new()
                    {
                        Time = "19:00",
                        Title = "Thu am thuc dia phuong",
                        Description = $"Tan huong buoi toi tai {destination.Name}",
                        Icon = "restaurant"
                    }
                }
            });
        }

        return days;
    }

    private static decimal? GetLowestHotelPrice(Hotel hotel)
    {
        return hotel.Rooms
            .Where(room => room.PricePerNight.HasValue)
            .Select(room => room.PricePerNight)
            .Min();
    }

    private static decimal? GetEstimatedStayCost(decimal? nightlyPrice, int days)
    {
        if (!nightlyPrice.HasValue)
        {
            return null;
        }

        var stayDays = Math.Max(1, days);
        return nightlyPrice.Value * stayDays;
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

    private static string NormalizeText(string text)
    {
        var normalized = text.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder();

        foreach (var character in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(character);
            if (category != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(char.ToLowerInvariant(character));
            }
        }

        return builder
            .ToString()
            .Normalize(NormalizationForm.FormC)
            .Replace('đ', 'd');
    }

    private static List<QuickActionDto> BuildDefaultQuickActionsForIntent(string intent)
    {
        return intent switch
        {
            "promotion_query" => new List<QuickActionDto>
            {
                new() { Label = "Tim uu dai hotel", Icon = "hotel", ActionPayload = "Tim khach san co uu dai tot" },
                new() { Label = "Lap lich trinh tiet kiem", Icon = "calendar", ActionPayload = "Lap lich trinh du lich tiet kiem cho toi" }
            },
            "bus_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem them tuyen xe", Icon = "map", ActionPayload = "Co them tuyen xe nao khac phu hop khong" },
                new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san gan diem den nay" }
            },
            "hotel_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem muc gia re hon", Icon = "hotel", ActionPayload = "Co khach san nao gia mem hon khong" },
                new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh du lich cho diem den nay" }
            },
            "budget_query" => new List<QuickActionDto>
            {
                new() { Label = "Toi uu chi phi", Icon = "explore", ActionPayload = "Goi y cach toi uu chi phi chuyen di nay" },
                new() { Label = "Tim uu dai", Icon = "explore", ActionPayload = "Co khuyen mai nao phu hop voi chuyen di nay" }
            },
            "package_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem khach san", Icon = "hotel", ActionPayload = "Tim khach san phu hop cho diem den nay" },
                new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh du lich cho diem den nay" }
            },
            "itinerary_request" => new List<QuickActionDto>
            {
                new() { Label = "Thay doi lich trinh", Icon = "calendar", ActionPayload = "Toi muon chinh sua lich trinh nay" },
                new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san phu hop voi lich trinh nay" }
            },
            _ => new List<QuickActionDto>
            {
                new() { Label = "Goi y diem den", Icon = "explore", ActionPayload = "Goi y cho toi mot vai diem den dep o Viet Nam" },
                new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san tot cho chuyen di cua toi" }
            }
        };
    }

    private static string FormatCurrency(decimal? amount)
    {
        return amount.HasValue ? $"{amount.Value:N0} VND" : "lien he";
    }

    private static string FormatDateTime(DateTime? dateTime)
    {
        return dateTime.HasValue
            ? dateTime.Value.ToLocalTime().ToString("dd/MM HH:mm")
            : "chua cap nhat";
    }
}
