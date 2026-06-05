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
    private readonly IWeatherLookupService _weatherLookupService;

    public ChatService(
        IGrokAiService aiService,
        IChatRepository chatRepo,
        IWeatherLookupService weatherLookupService)
    {
        _aiService = aiService;
        _chatRepo = chatRepo;
        _weatherLookupService = weatherLookupService;
    }

    public async Task<ChatResponseDto> GetAiResponseAsync(ChatRequestDto request)
    {
        var normalizedSessionId = NormalizeSessionId(request.SessionId);
        var userProfile = request.UserId.HasValue
            ? await _chatRepo.GetUserPersonalizationAsync(request.UserId.Value)
            : null;

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

        var intent = DetectIntentWithHistory(request.Message, history);
        var contextMessage = intent == "itinerary_request"
            ? BuildMergedUserContext(request.Message, history)
            : request.Message;
        var dbContext = await BuildDatabaseContext(contextMessage, intent, userProfile);

        var context = new ChatContextDto
        {
            UserMessage = request.Message,
            UserId = request.UserId,
            SessionId = normalizedSessionId,
            ConversationHistory = history,
            DetectedIntent = intent,
            DatabaseContext = dbContext,
            PreferredLanguage = userProfile?.PreferredLanguage ?? "vi",
            PreferredCurrency = userProfile?.PreferredCurrency ?? "VND",
            PersonalizationSummary = BuildPersonalizationSummary(userProfile),
            Latitude = request.Latitude,
            Longitude = request.Longitude
        };

        var response = await TryGenerateAiResponseAsync(context);
        response = NormalizeAiResponse(response);

        if (NeedsDeterministicFallback(response))
        {
            response = await BuildDeterministicResponseAsync(intent, request.Message, userProfile);
        }

        response = await EnrichWithDatabaseData(response, intent, request.Message, userProfile);
        response = await AlignResponseToIntentAsync(response, intent, request.Message, userProfile, history);
        response = EnsureQuickActions(response, intent, userProfile);
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

    private string DetectIntentWithHistory(string message, List<ChatHistoryItemDto> history)
    {
        var directIntent = DetectIntent(message);
        if (directIntent == "itinerary_request")
        {
            return directIntent;
        }

        if (TryExtractSelectedHotelName(message, history) != null
            && history.TakeLast(6).Any(item =>
                item.Role == "bot"
                && (item.ResponseType == "itinerary"
                    || item.ResponsePayload?.SuggestedItinerary != null)))
        {
            return "itinerary_request";
        }

        var normalized = NormalizeText(message);
        var looksLikePlanFollowUp =
            ContainsAny(normalized, "di tu", "xuat phat", "tu ", "nguoi", "khach", "ngan sach", "trieu", "budget");

        if (!looksLikePlanFollowUp)
        {
            return directIntent;
        }

        var recentMessages = history.TakeLast(4).ToList();
        var lastBotText = recentMessages
            .LastOrDefault(item => item.Role == "bot")
            ?.Content;

        if (!string.IsNullOrWhiteSpace(lastBotText)
            && NormalizeText(lastBotText).Contains("de minh len plan sat thuc te"))
        {
            return "itinerary_request";
        }

        return directIntent;
    }

    private async Task<string> BuildDatabaseContext(
        string message,
        string intent,
        ChatUserProfileDto? userProfile)
    {
        var parts = new List<string>();

        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = ResolveRelevantDestinations(message, destinations, userProfile);

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
                    $"{h.Name} ({h.StarRating} sao, {h.Destination?.Name ?? string.Empty}, tu {FormatCurrency(GetLowestHotelPrice(h), userProfile?.PreferredCurrency)} / dem)"));
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
                    $"{schedule.FromDest?.Name ?? "?"} -> {schedule.ToDest?.Name ?? "?"} ({FormatCurrency(schedule.Price, userProfile?.PreferredCurrency)}, {FormatDateTime(schedule.DepartureTime)})"));
                parts.Add($"Tuyen xe hien co: {routeList}");
            }
        }

        if (intent is "promotion_query" or "budget_query" or "booking_request" or "package_query")
        {
            var promotions = await _chatRepo.GetActivePromotionsAsync(5);
            if (promotions.Any())
            {
                var promotionList = string.Join("; ", promotions.Select(p =>
                    $"{p.Code}: giam {p.DiscountPercent?.ToString("0") ?? "0"}% toi da {FormatCurrency(p.MaxDiscountAmount, userProfile?.PreferredCurrency)}"));
                parts.Add($"Khuyen mai dang hoat dong: {promotionList}");
            }
        }

        return parts.Any() ? string.Join("\n", parts) : string.Empty;
    }

    private async Task<ChatResponseDto> EnrichWithDatabaseData(
        ChatResponseDto response,
        string intent,
        string userMessage,
        ChatUserProfileDto? userProfile)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = ResolveRelevantDestinations(
            userMessage,
            destinations,
            userProfile,
            allowPreferenceFallback: ShouldAllowPreferenceFallback(intent));

        if (intent == "destination_query"
            && (response.DestinationCards == null || response.DestinationCards.Count == 0))
        {
            var destinationCards = BuildDestinationSuggestionCards(userMessage, matchedDestinations, destinations, 5);

            if (destinationCards.Any())
            {
                response.DestinationCards = destinationCards;

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

        if (intent == "hotel_query"
            && (response.HotelCards == null || response.HotelCards.Count == 0))
        {
            var hotels = matchedDestinations.Any()
                ? await _chatRepo.SearchDestinationsHotelsAsync(matchedDestinations.Select(d => d.Id), 3)
                : await _chatRepo.GetAvailableHotelsAsync(3);
            var destinationSummaryVi = string.Join(" va ", matchedDestinations.Take(2).Select(d => d.Name));
            var destinationSummaryEn = string.Join(" and ", matchedDestinations.Take(2).Select(d => d.Name));

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
                    DestinationId = h.DestinationId,
                    Amenities = h.Amenities.Select(a => a.Name ?? string.Empty).ToList(),
                    IsAvailable = h.IsAvailable,
                    Rooms = h.Rooms
                        .Where(r => (r.AvailableQty ?? 0) > 0)
                        .Select(r => new HotelRoomCardDto
                        {
                            Id = r.Id,
                            RoomType = r.RoomType ?? "Standard",
                            PricePerNight = r.PricePerNight ?? 0,
                            Capacity = r.Capacity ?? 2,
                            AvailableQty = r.AvailableQty ?? 0
                        }).ToList()
                }).ToList();

                if (response.ResponseType == "text")
                {
                    response.ResponseType = "hotel_list";
                }
            }

            if (intent == "hotel_query")
            {
                response.Text = matchedDestinations.Any()
                    ? Localize(
                        userProfile,
                        $"Duoi day la mot so khach san phu hop voi chuyen di cua ban tai {destinationSummaryVi}.",
                        $"Here are some recommended hotels for your trip in {destinationSummaryEn}.")
                    : Localize(
                        userProfile,
                        "Duoi day la mot so khach san phu hop voi chuyen di cua ban.",
                        "Here are some recommended hotels for your trip.");
            }
        }

        if (intent == "bus_query"
            && (response.TransportCards == null || response.TransportCards.Count == 0))
        {
            var routes = await _chatRepo.GetBusSchedulesAsync(
                4,
                matchedDestinations.Select(destination => destination.Id));

            if (routes.Any())
            {
                response.TransportCards = routes.Select(route => new TransportCardDto
                {
                    ScheduleId = route.Id,
                    FromDestinationId = route.FromDestId,
                    FromDestinationName = route.FromDest?.Name,
                    ToDestinationId = route.ToDestId,
                    ToDestinationName = route.ToDest?.Name,
                    CompanyName = route.Company?.Name ?? "Xe khach",
                    Price = route.Price,
                    DepartureTime = route.DepartureTime,
                    ArrivalTime = route.ArrivalTime,
                    TotalSeats = route.TotalSeats
                }).ToList();
            }
        }

        if (intent == "promotion_query")
        {
            response.Text = await BuildPromotionSummaryAsync(userProfile);
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
            response.Text = await BuildBusSummaryAsync(response.Text, matchedDestinations, userProfile);
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
            response.Text = await BuildBudgetSummaryAsync(response.Text, matchedDestinations, userMessage, userProfile);
            response.ResponseType = "text";
            response.WeatherInfo = null;
        }

        if (intent == "package_query")
        {
            response.Text = await BuildPackageSummaryAsync(response.Text, matchedDestinations, userProfile);
            response.ResponseType = "destination_card";
            response.WeatherInfo = null;
            response.QuickActions = BuildPackageQuickActions(matchedDestinations.FirstOrDefault());
        }

        if (intent == "itinerary_request" && response.SuggestedItinerary == null)
        {
            response.SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations, 3, userProfile);
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

    private async Task<ChatResponseDto> BuildDeterministicResponseAsync(
        string intent,
        string userMessage,
        ChatUserProfileDto? userProfile)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = ResolveRelevantDestinations(
            userMessage,
            destinations,
            userProfile,
            allowPreferenceFallback: ShouldAllowPreferenceFallback(intent));

        return intent switch
        {
            "promotion_query" => new ChatResponseDto
            {
                Text = await BuildPromotionSummaryAsync(userProfile),
                ResponseType = "text"
            },
            "bus_query" => new ChatResponseDto
            {
                Text = await BuildBusSummaryAsync(string.Empty, matchedDestinations, userProfile),
                ResponseType = "text"
            },
            "budget_query" => new ChatResponseDto
            {
                Text = await BuildBudgetSummaryAsync(string.Empty, matchedDestinations, userMessage, userProfile),
                ResponseType = "text"
            },
            "package_query" => new ChatResponseDto
            {
                Text = await BuildPackageSummaryAsync(string.Empty, matchedDestinations, userProfile),
                ResponseType = "destination_card"
            },
            "itinerary_request" => new ChatResponseDto
            {
                Text = "Minh da lap nhanh mot lich trinh tham khao de ban de hinh dung hon.",
                ResponseType = "itinerary",
                SuggestedItinerary = await BuildSuggestedItineraryAsync(matchedDestinations, 3, userProfile)
            },
            "hotel_query" => new ChatResponseDto
            {
                Text = matchedDestinations.Any()
                    ? Localize(
                        userProfile,
                        $"Minh da loc nhanh mot so khach san phu hop tai {matchedDestinations[0].Name} cho ban.",
                        $"Here are some recommended hotels for your {matchedDestinations[0].Name} trip.")
                    : Localize(
                        userProfile,
                        "Minh da loc nhanh mot so khach san phu hop cho ban.",
                        "Here are some recommended hotels for your trip."),
                ResponseType = "hotel_list"
            },
            "destination_query" => new ChatResponseDto
            {
                Text = BuildDestinationSuggestionText(userMessage, matchedDestinations),
                ResponseType = "destination_card",
                DestinationCards = BuildDestinationSuggestionCards(userMessage, matchedDestinations, destinations, 5)
            },
            "weather_query" => new ChatResponseDto
            {
                Text = BuildWeatherFallbackMessage(matchedDestinations),
                ResponseType = "weather"
            },
            _ => new ChatResponseDto
            {
                Text = Localize(
                    userProfile,
                    "Minh co the giup ban goi y diem den, tim khach san, xem tuyen xe, uoc tinh chi phi va lap lich trinh du lich.",
                    "I can help with destinations, hotels, bus routes, travel budgets, and itineraries."),
                ResponseType = "text"
            }
        };
    }

    private ChatResponseDto EnsureQuickActions(
        ChatResponseDto response,
        string intent,
        ChatUserProfileDto? userProfile)
    {
        response.Timestamp = response.Timestamp == default ? DateTime.UtcNow : response.Timestamp;

        if (response.QuickActions == null || response.QuickActions.Count == 0)
        {
            response.QuickActions = intent == "package_query"
                ? BuildPackageQuickActions(ResolvePreferredDestination(userProfile))
                : BuildDefaultQuickActionsForIntent(intent);
        }

        return response;
    }

    private async Task<ChatResponseDto> AlignResponseToIntentAsync(
        ChatResponseDto response,
        string intent,
        string userMessage,
        ChatUserProfileDto? userProfile,
        List<ChatHistoryItemDto> history)
    {
        var destinations = await _chatRepo.GetDestinationsAsync(20);
        var matchedDestinations = ResolveRelevantDestinations(
            userMessage,
            destinations,
            userProfile,
            allowPreferenceFallback: ShouldAllowPreferenceFallback(intent));

        switch (intent)
        {
            case "budget_query":
                response.ResponseType = "text";
                response.WeatherInfo = null;
                response.SuggestedItinerary = null;
                response.Text = await BuildBudgetSummaryAsync(response.Text, matchedDestinations, userMessage, userProfile);
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
                response.Text = await BuildPackageSummaryAsync(response.Text, matchedDestinations, userProfile);
                response.QuickActions = BuildPackageQuickActions(matchedDestinations.FirstOrDefault() ?? ResolvePreferredDestination(userProfile));
                break;

            case "bus_query":
                response.ResponseType = "text";
                response.WeatherInfo = null;
                response.SuggestedItinerary = null;
                response.Text = await BuildBusSummaryAsync(response.Text, matchedDestinations, userProfile);
                break;

            case "weather_query":
                response.ResponseType = "weather";
                response.HotelCards = null;
                response.TransportCards = null;
                response.SuggestedItinerary = null;
                response = await EnsureWeatherInfoAsync(response, matchedDestinations, userMessage, userProfile);
                break;

            case "itinerary_request":
                response = await EnsureValidItineraryAsync(
                    response,
                    matchedDestinations,
                    userMessage,
                    userProfile,
                    history);
                break;
        }

        return response;
    }

    private static bool ContainsAny(string text, params string[] keywords)
    {
        return keywords.Any(keyword => text.Contains(keyword, StringComparison.OrdinalIgnoreCase));
    }

    private static string? BuildPersonalizationSummary(ChatUserProfileDto? userProfile)
    {
        if (userProfile == null)
        {
            return null;
        }

        var parts = new List<string>();

        if (!string.IsNullOrWhiteSpace(userProfile.DisplayName))
        {
            parts.Add($"Ten nguoi dung: {userProfile.DisplayName}");
        }

        parts.Add($"Ngon ngu ua thich: {userProfile.PreferredLanguage}");
        parts.Add($"Tien te ua thich: {userProfile.PreferredCurrency}");

        if (userProfile.TripsCount > 0)
        {
            parts.Add($"So chuyen di da co: {userProfile.TripsCount}");
        }

        if (userProfile.LoyaltyPoints > 0)
        {
            parts.Add($"Diem tich luy: {userProfile.LoyaltyPoints}");
        }

        if (userProfile.RecentDestinationNames.Count > 0)
        {
            parts.Add($"Diem den gan day: {string.Join(", ", userProfile.RecentDestinationNames)}");
        }

        if (userProfile.FavoriteHotelNames.Count > 0)
        {
            parts.Add($"Khach san yeu thich: {string.Join(", ", userProfile.FavoriteHotelNames)}");
        }

        return string.Join(" | ", parts);
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

    private static List<Destination> ResolveRelevantDestinations(
        string message,
        IEnumerable<Destination> destinations,
        ChatUserProfileDto? userProfile,
        bool allowPreferenceFallback = true)
    {
        var destinationList = destinations.ToList();
        var matchedDestinations = FindMatchedDestinations(message, destinationList);
        if (matchedDestinations.Count > 0)
        {
            return matchedDestinations;
        }

        if (!allowPreferenceFallback
            || userProfile == null
            || userProfile.PreferredDestinationNames.Count == 0)
        {
            return [];
        }

        var preferredNames = userProfile.PreferredDestinationNames
            .Select(NormalizeText)
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .ToHashSet();

        return destinationList
            .Where(destination => preferredNames.Contains(NormalizeText(destination.Name)))
            .DistinctBy(destination => destination.Id)
            .Take(3)
            .ToList();
    }

    private static Destination? ResolvePreferredDestination(ChatUserProfileDto? userProfile)
    {
        var destinationName = userProfile?.PreferredDestinationNames.FirstOrDefault();
        if (string.IsNullOrWhiteSpace(destinationName))
        {
            return null;
        }

        return new Destination
        {
            Name = destinationName
        };
    }

    private static string BuildDestinationSuggestionText(string userMessage, List<Destination> matchedDestinations)
    {
        if (matchedDestinations.Count > 0)
        {
            return $"Minh chon nhanh mot vai diem den phu hop voi {matchedDestinations[0].Name} de ban de tham khao.";
        }

        var normalized = NormalizeText(userMessage);
        if (normalized.Contains("mien tay", StringComparison.Ordinal))
        {
            return "Neu ban thich khong khi song nuoc mien Tay, minh goi y truoc mot vai diem de di de chon.";
        }

        return "Minh goi y truoc mot vai diem den de ban de chon, neu thich minh se loc tiep theo gu cua ban.";
    }

    private static List<DestinationCardDto> BuildDestinationSuggestionCards(
        string userMessage,
        List<Destination> matchedDestinations,
        List<Destination> allDestinations,
        int defaultCount = 5)
    {
        var requestedCount = ExtractRequestedDestinationCount(userMessage) ?? defaultCount;
        requestedCount = Math.Clamp(requestedCount, 3, 6);

        var cards = new List<DestinationCardDto>();
        var usedNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        void AddCard(DestinationCardDto card)
        {
            if (string.IsNullOrWhiteSpace(card.Name) || !usedNames.Add(card.Name))
            {
                return;
            }

            cards.Add(card);
        }

        foreach (var destination in matchedDestinations)
        {
            AddCard(new DestinationCardDto
            {
                Id = destination.Id,
                Name = destination.Name,
                Description = destination.Description,
                ImageUrl = destination.CoverImageUrl,
                IsHot = destination.IsHot,
                Rating = 4.6,
                BestSeason = "Quanh nam",
                EstimatedBudget = "Tu 2-4 trieu"
            });
        }

        foreach (var card in BuildCuratedDestinationCards(userMessage))
        {
            AddCard(card);
        }

        foreach (var destination in allDestinations)
        {
            AddCard(new DestinationCardDto
            {
                Id = destination.Id,
                Name = destination.Name,
                Description = destination.Description,
                ImageUrl = destination.CoverImageUrl,
                IsHot = destination.IsHot,
                Rating = destination.IsHot == true ? 4.7 : 4.4,
                BestSeason = "Quanh nam",
                EstimatedBudget = "Tu 2-5 trieu"
            });
        }

        return cards.Take(requestedCount).ToList();
    }

    private static int? ExtractRequestedDestinationCount(string userMessage)
    {
        var normalized = NormalizeText(userMessage);
        var match = System.Text.RegularExpressions.Regex.Match(normalized, @"(\d+)\s*(cai|noi|diem|diem den)");
        if (match.Success && int.TryParse(match.Groups[1].Value, out var count))
        {
            return count;
        }

        return null;
    }

    private static List<DestinationCardDto> BuildCuratedDestinationCards(string userMessage)
    {
        var normalized = NormalizeText(userMessage);

        if (normalized.Contains("mien tay", StringComparison.Ordinal)
            || normalized.Contains("ca mau", StringComparison.Ordinal)
            || normalized.Contains("can tho", StringComparison.Ordinal)
            || normalized.Contains("an giang", StringComparison.Ordinal))
        {
            return
            [
                new DestinationCardDto
                {
                    Name = "Cần Thơ",
                    Description = "Hop cho chuyen di song nuoc nhe nhang, co cho noi Cai Rang, ben Ninh Kieu va nhieu quan an de thu.",
                    IsHot = true,
                    Rating = 4.6,
                    BestSeason = "Thang 12 - thang 4",
                    EstimatedBudget = "Tu 2-3.5 trieu"
                },
                new DestinationCardDto
                {
                    Name = "An Giang",
                    Description = "Noi bat voi rung tram Tra Su, nui Sam, Chau Doc va khong khi hanh huong - kham pha rat rieng.",
                    IsHot = true,
                    Rating = 4.5,
                    BestSeason = "Mua nuoc noi hoac dip dau nam",
                    EstimatedBudget = "Tu 2-4 trieu"
                },
                new DestinationCardDto
                {
                    Name = "Cà Mau",
                    Description = "Phu hop neu ban muon xuong cuc Nam, di Dat Mui, ngam rung ngap man va thu hai san dia phuong.",
                    IsHot = false,
                    Rating = 4.4,
                    BestSeason = "Thang 12 - thang 4",
                    EstimatedBudget = "Tu 2.5-4.5 trieu"
                },
                new DestinationCardDto
                {
                    Name = "Sóc Trăng",
                    Description = "Noi bat voi chua dep, am thuc da dang va de ghep cung Can Tho hoac Bac Lieu.",
                    IsHot = false,
                    Rating = 4.3,
                    BestSeason = "Cuoi nam - dau nam",
                    EstimatedBudget = "Tu 2-3 trieu"
                },
                new DestinationCardDto
                {
                    Name = "Bến Tre",
                    Description = "De di tu Sai Gon, hop cho nghi cuoi tuan voi xu dua, homestay va trai nghiem kenh rach.",
                    IsHot = true,
                    Rating = 4.5,
                    BestSeason = "Quanh nam",
                    EstimatedBudget = "Tu 1.5-3 trieu"
                }
            ];
        }

        return
        [
            new DestinationCardDto
            {
                Name = "Đà Lạt",
                Description = "Hop cho nghi duong, san may, cafe va chuyen di 3 ngay 2 dem de di de chiu.",
                IsHot = true,
                Rating = 4.7,
                BestSeason = "Thang 11 - thang 3",
                EstimatedBudget = "Tu 2.5-4.5 trieu"
            },
            new DestinationCardDto
            {
                Name = "Đà Nẵng",
                Description = "Can bang giua bien, do an, thanh pho de di va co the ghep Hoi An rat gon.",
                IsHot = true,
                Rating = 4.7,
                BestSeason = "Thang 3 - thang 8",
                EstimatedBudget = "Tu 3-5 trieu"
            },
            new DestinationCardDto
            {
                Name = "Phú Quốc",
                Description = "Hop neu ban muon bien dep, resort va chuyen di nghi duong co nhieu lua chon cao cap.",
                IsHot = true,
                Rating = 4.6,
                BestSeason = "Thang 11 - thang 4",
                EstimatedBudget = "Tu 4-7 trieu"
            },
            new DestinationCardDto
            {
                Name = "Hà Giang",
                Description = "Rat hop neu ban thich cung duong dep, nui non va trai nghiem di chuyen dang nho.",
                IsHot = true,
                Rating = 4.8,
                BestSeason = "Thang 9 - thang 11",
                EstimatedBudget = "Tu 3-5 trieu"
            },
            new DestinationCardDto
            {
                Name = "Quy Nhơn",
                Description = "Bien dep, do an on, chi phi vua phai va nhip di chuyen de chiu hon nhieu diem qua dong.",
                IsHot = false,
                Rating = 4.5,
                BestSeason = "Thang 3 - thang 8",
                EstimatedBudget = "Tu 2.5-4 trieu"
            }
        ];
    }

    private static bool ShouldAllowPreferenceFallback(string intent)
    {
        return intent is not "itinerary_request" and not "weather_query" and not "destination_query";
    }

    private async Task<string> BuildPromotionSummaryAsync(ChatUserProfileDto? userProfile)
    {
        var promotions = await _chatRepo.GetActivePromotionsAsync(5);
        if (!promotions.Any())
        {
            return "Hien tai chua co khuyen mai noi bat. Ban co the thu lai sau de xem uu dai moi nhat.";
        }

        var lines = promotions.Select(p =>
            $"- {p.Code}: giam {p.DiscountPercent?.ToString("0") ?? "0"}% toi da {FormatCurrency(p.MaxDiscountAmount, userProfile?.PreferredCurrency)}");

        return "Day la mot so khuyen mai dang hoat dong:\n" + string.Join("\n", lines);
    }

    private async Task<string> BuildBusSummaryAsync(
        string fallbackText,
        List<Destination> matchedDestinations,
        ChatUserProfileDto? userProfile)
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
            $"- {route.FromDest?.Name ?? "?"} -> {route.ToDest?.Name ?? "?"}, {FormatDateTime(route.DepartureTime)}, gia tu {FormatCurrency(route.Price, userProfile?.PreferredCurrency)}");

        return "Minh tim thay mot so tuyen xe phu hop:\n" + string.Join("\n", lines);
    }

    private async Task<string> BuildBudgetSummaryAsync(
        string fallbackText,
        List<Destination> matchedDestinations,
        string requestText,
        ChatUserProfileDto? userProfile)
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
                $"{h.Name} tu {FormatCurrency(GetEstimatedStayCost(GetLowestHotelPrice(h), requestedDays), userProfile?.PreferredCurrency)} cho {requestedDays} ngay"));
            parts.Add($"Khach san: {hotelText}");
        }

        if (buses.Any())
        {
            var busText = string.Join("; ", buses.Select(b =>
                $"{b.FromDest?.Name ?? "?"} -> {b.ToDest?.Name ?? "?"} tu {FormatCurrency(b.Price, userProfile?.PreferredCurrency)}"));
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

    private async Task<ChatResponseDto> EnsureWeatherInfoAsync(
        ChatResponseDto response,
        List<Destination> matchedDestinations,
        string userMessage,
        ChatUserProfileDto? userProfile)
    {
        var explicitLocation = ExtractWeatherLocation(userMessage);
        var locationQuery = explicitLocation ?? matchedDestinations.FirstOrDefault()?.Name;
        if (string.IsNullOrWhiteSpace(locationQuery))
        {
            response.WeatherInfo = null;
            response.Text = BuildWeatherFallbackMessage(matchedDestinations, explicitLocation);
            return response;
        }

        var weather = await _weatherLookupService.GetWeatherAsync(
            locationQuery,
            userProfile?.PreferredLanguage);

        response.WeatherInfo = weather;
        response.Text = weather == null
            ? BuildWeatherFallbackMessage(matchedDestinations, locationQuery)
            : BuildWeatherSummaryText(weather);

        return response;
    }

    private static string BuildWeatherFallbackMessage(
        List<Destination> matchedDestinations,
        string? requestedLocation = null)
    {
        var destinationName = !string.IsNullOrWhiteSpace(requestedLocation)
            ? requestedLocation
            : matchedDestinations.FirstOrDefault()?.Name;
        if (!string.IsNullOrWhiteSpace(destinationName))
        {
            return $"Minh chua lay duoc thoi tiet moi nhat cho {destinationName} ngay luc nay. Neu ban muon, minh van co the goi y lich trinh, khach san va chi phi tham khao cho diem den nay.";
        }

        return "Luc nay minh chua lay duoc du lieu thoi tiet moi nhat. Neu ban muon, minh van co the goi y diem den, khach san va lich trinh tham khao cho ban.";
    }

    private static string BuildWeatherSummaryText(WeatherInfoDto weather)
    {
        var temp = weather.Temperature.HasValue
            ? $"{weather.Temperature.Value:0}°C"
            : "chua ro nhiet do";
        var condition = string.IsNullOrWhiteSpace(weather.Condition)
            ? "thoi tiet hien tai"
            : weather.Condition!;

        return $"Thoi tiet hien tai tai {weather.Location}: {condition}, {temp}. Minh da them du bao ngan ngay de ban de len lich trinh.";
    }

    private static string? ExtractWeatherLocation(string userMessage)
    {
        var normalized = NormalizeText(userMessage);
        var match = System.Text.RegularExpressions.Regex.Match(
            normalized,
            @"(?:thoi tiet|weather|du bao|nhiet do)(?:\s+o|\s+tai|\s+cho)?\s+([a-z0-9\s]+)$");

        if (!match.Success)
        {
            return null;
        }

        var candidate = match.Groups[1].Value.Trim();
        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        candidate = System.Text.RegularExpressions.Regex.Replace(
            candidate,
            @"\b(hom nay|ngay mai|ngay kia|toi nay|sang mai|chieu nay|cuoi tuan nay|tuan nay)\b",
            string.Empty)
            .Trim();

        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        return ToDisplayText(candidate);
    }

    private static string Localize(ChatUserProfileDto? userProfile, string vi, string en)
    {
        return string.Equals(userProfile?.PreferredLanguage, "en", StringComparison.OrdinalIgnoreCase)
            ? en
            : vi;
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

    private async Task<string> BuildPackageSummaryAsync(
        string fallbackText,
        List<Destination> matchedDestinations,
        ChatUserProfileDto? userProfile)
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
        string userMessage,
        ChatUserProfileDto? userProfile,
        List<ChatHistoryItemDto> history)
    {
        var mergedUserContext = BuildMergedUserContext(userMessage, history);
        var requestedDays = ExtractRequestedDays(mergedUserContext);
        var destinations = matchedDestinations;
        var availableDestinations = await _chatRepo.GetDestinationsAsync(20);
        var explicitDestination = ExtractExplicitTripDestination(mergedUserContext);

        if (destinations.Count == 0)
        {
            destinations = ResolveRelevantDestinations(
                mergedUserContext,
                availableDestinations,
                userProfile,
                allowPreferenceFallback: false);
        }

        if (destinations.Count == 0 && !string.IsNullOrWhiteSpace(explicitDestination))
        {
            response.ResponseType = "itinerary";
            response.HotelCards = null;
            response.TransportCards = null;
            response.SuggestedItinerary = BuildGenericSuggestedItinerary(
                explicitDestination!,
                requestedDays,
                userProfile,
                ExtractDeparturePoint(mergedUserContext, []),
                ExtractTravelerCount(mergedUserContext) ?? 2,
                ExtractBudgetAmount(mergedUserContext));
            response.Text = response.SuggestedItinerary != null
                ? BuildItinerarySummaryText(response.SuggestedItinerary)
                : BuildUnsupportedDestinationMessage(
                    explicitDestination!,
                    availableDestinations);
            return response;
        }

        var origin = ExtractDeparturePoint(mergedUserContext, destinations);
        var travelerCount = ExtractTravelerCount(mergedUserContext);
        var budget = ExtractBudgetAmount(mergedUserContext);
        var preferredHotelName = TryExtractSelectedHotelName(userMessage, history);
        var missingFields = BuildMissingItineraryFields(destinations, origin, travelerCount, budget);

        if (missingFields.Count > 0)
        {
            response.ResponseType = "text";
            response.SuggestedItinerary = null;
            response.HotelCards = null;
            response.TransportCards = null;
            response.Text = BuildItineraryFollowUpQuestion(destinations, requestedDays, missingFields);
            return response;
        }

        response.SuggestedItinerary = await BuildSuggestedItineraryAsync(
            destinations,
            requestedDays,
            userProfile,
            origin,
            travelerCount ?? 2,
            budget,
            preferredHotelName);

        if (response.SuggestedItinerary != null)
        {
            response.ResponseType = "itinerary";
            response.HotelCards = null;
            response.TransportCards = null;
            response.Text = BuildItinerarySummaryText(response.SuggestedItinerary);
        }

        return response;
    }

    private static string BuildItinerarySummaryText(ItineraryDto itinerary)
    {
        return
            $"Minh da len plan {itinerary.TotalDays} ngay tai {itinerary.Destination} voi lich trinh cu the theo tung ngay. " +
            "Ban co the xem tong chi phi du kien o cuoi plan va bam luu thanh chuyen di neu thay phu hop.";
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

    private static string BuildMergedUserContext(string userMessage, List<ChatHistoryItemDto> history)
    {
        var parts = history
            .Where(item => item.Role == "user" && !string.IsNullOrWhiteSpace(item.Content))
            .Select(item => item.Content.Trim())
            .ToList();
        parts.Add(userMessage.Trim());
        return string.Join("\n", parts);
    }

    private static List<string> BuildMissingItineraryFields(
        List<Destination> matchedDestinations,
        string? origin,
        int? travelerCount,
        decimal? budget)
    {
        var missing = new List<string>();

        if (matchedDestinations.Count == 0)
        {
            missing.Add("ban muon di dau");
        }

        if (string.IsNullOrWhiteSpace(origin))
        {
            missing.Add("ban di tu dau");
        }

        if (!travelerCount.HasValue)
        {
            missing.Add("co bao nhieu nguoi");
        }

        if (!budget.HasValue)
        {
            missing.Add("ngan sach du kien la bao nhieu");
        }

        return missing;
    }

    private static string BuildItineraryFollowUpQuestion(
        List<Destination> matchedDestinations,
        int requestedDays,
        List<string> missingFields)
    {
        var destinationLabel = matchedDestinations.FirstOrDefault()?.Name;
        var tripLabel = !string.IsNullOrWhiteSpace(destinationLabel)
            ? $" cho chuyen {requestedDays} ngay tai {destinationLabel}"
            : string.Empty;

        return
            $"De minh len plan sat thuc te{tripLabel}, ban giup minh bo sung {string.Join(", ", missingFields)} nhe. " +
            "Khi co du thong tin, minh se len lich trinh cu the gom di chuyen, khach san, an uong, diem vui choi va tong chi phi du kien.";
    }

    private static string BuildUnsupportedDestinationMessage(
        string destinationName,
        IEnumerable<Destination> availableDestinations)
    {
        var availableNames = availableDestinations
            .Select(item => item.Name)
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Take(5)
            .ToList();

        var availableLabel = availableNames.Count > 0
            ? $"Hien tai he thong moi co du lieu lap plan cho: {string.Join(", ", availableNames)}."
            : "Hien tai he thong chua co du lieu diem den phu hop de lap plan.";

        return $"Minh nhan ra ban dang muon len ke hoach cho {destinationName}. Hien tai he thong chua co du lieu dat dich vu chi tiet cho diem den nay, nhung minh van co the len lich trinh tham khao de ban de canh. {availableLabel}";
    }

    private static ItineraryDto BuildGenericSuggestedItinerary(
        string destinationName,
        int requestedDays,
        ChatUserProfileDto? userProfile,
        string? origin,
        int travelerCount,
        decimal? budget)
    {
        var destination = new Destination
        {
            Name = destinationName
        };

        return new ItineraryDto
        {
            Title = $"Lich trinh goi y tai {destinationName}",
            Destination = destinationName,
            DestinationId = null,
            TotalDays = Math.Max(1, requestedDays),
            EstimatedBudget = BuildGenericBudgetSummaryLabel(
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency,
                budget),
            TravelStyle = "Linh hoat",
            HotelSuggestion = null,
            TransportSuggestion = null,
            CostBreakdown = BuildGenericCostBreakdown(
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency),
            Days = BuildGenericItineraryDays(
                destination,
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency,
                origin)
        };
    }

    private static ItineraryCostBreakdownDto BuildGenericCostBreakdown(
        int requestedDays,
        int travelerCount,
        string? currency)
    {
        var headCount = Math.Max(1, travelerCount);
        var totalDays = Math.Max(1, requestedDays);
        var nights = Math.Max(1, totalDays - 1);
        var hotelCost = 450000m * nights * Math.Max(1, (int)Math.Ceiling(headCount / 2m));
        var transportCost = 350000m * headCount;
        var foodCost = 180000m * headCount * totalDays;
        var activityCost = 160000m * headCount * totalDays;

        return new ItineraryCostBreakdownDto
        {
            HotelCost = hotelCost,
            TransportCost = transportCost,
            FoodCost = foodCost,
            ActivityCost = activityCost,
            TotalCost = hotelCost + transportCost + foodCost + activityCost,
            Currency = string.IsNullOrWhiteSpace(currency) ? "VND" : currency!
        };
    }

    private static string BuildGenericBudgetSummaryLabel(
        int requestedDays,
        int travelerCount,
        string? currency,
        decimal? budget)
    {
        var cost = BuildGenericCostBreakdown(requestedDays, travelerCount, currency);
        var totalText = FormatCurrency(cost.TotalCost, currency);

        if (budget.HasValue)
        {
            var status = cost.TotalCost.HasValue && cost.TotalCost.Value <= budget.Value
                ? "sat ngan sach"
                : "can nhac them ngan sach";
            return $"Tong du kien {totalText} cho {travelerCount} nguoi, {status}";
        }

        return $"Tong du kien {totalText} cho {travelerCount} nguoi";
    }

    private static List<ItineraryDayDto> BuildGenericItineraryDays(
        Destination destination,
        int requestedDays,
        int travelerCount,
        string? currency,
        string? origin)
    {
        var totalDays = Math.Max(1, requestedDays);
        var headCount = Math.Max(1, travelerCount);
        var breakfastCost = 50000m * headCount;
        var lunchCost = 90000m * headCount;
        var dinnerCost = 120000m * headCount;
        var cafeCost = 60000m * headCount;
        var exploreCost = 140000m * headCount;
        var days = new List<ItineraryDayDto>();

        for (var dayNumber = 1; dayNumber <= totalDays; dayNumber++)
        {
            if (dayNumber == 1)
            {
                days.Add(new ItineraryDayDto
                {
                    DayNumber = dayNumber,
                    Theme = $"Lam quen va kham pha trung tam {destination.Name}",
                    Activities = new List<ItineraryActivityDto>
                    {
                        new()
                        {
                            Time = "07:30",
                            Title = $"Di chuyen den {destination.Name}",
                            Description = $"Khoi hanh tu {origin ?? "diem xuat phat"}, uu tien chon phuong an di chuyen phu hop voi ngan sach va gio den du kien.",
                            Icon = "transport",
                            EstimatedCost = FormatCurrency(350000m * headCount, currency)
                        },
                        new()
                        {
                            Time = "10:30",
                            Title = "Nhan phong va gui hanh ly",
                            Description = $"Chon khach san/homestay gan trung tam {destination.Name} de thuan tien di lai va an uong.",
                            Icon = "hotel",
                            EstimatedCost = FormatCurrency(450000m, currency)
                        },
                        new()
                        {
                            Time = "12:00",
                            Title = "An trua dac san dia phuong",
                            Description = "Uu tien mon dac san pho bien, quan binh dan sach se va de di chuyen.",
                            Icon = "restaurant",
                            EstimatedCost = FormatCurrency(lunchCost, currency)
                        },
                        new()
                        {
                            Time = "14:30",
                            Title = $"Tham quan cac diem noi bat o {destination.Name}",
                            Description = $"Danh buoi chieu de di cac diem check-in, khu trung tam va dia danh de len hinh dep.",
                            Icon = "attraction",
                            EstimatedCost = FormatCurrency(exploreCost, currency)
                        },
                        new()
                        {
                            Time = "19:00",
                            Title = "An toi va dao choi buoi toi",
                            Description = $"Thu mon dac san buoi toi, ghe cho dem hoac khu di bo de cam nhan khong khi o {destination.Name}.",
                            Icon = "restaurant",
                            EstimatedCost = FormatCurrency(dinnerCost, currency)
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
                    Theme = "Mua sam nhe va ket thuc chuyen di",
                    Activities = new List<ItineraryActivityDto>
                    {
                        new()
                        {
                            Time = "08:00",
                            Title = "An sang va tham quan nhe",
                            Description = $"Chon mot quan an sang ngon, sau do tham quan them mot diem nhe o {destination.Name}.",
                            Icon = "restaurant",
                            EstimatedCost = FormatCurrency(breakfastCost, currency)
                        },
                        new()
                        {
                            Time = "10:30",
                            Title = "Mua dac san va chup anh",
                            Description = "Danh thoi gian mua qua mang ve, dac san dia phuong va chup anh o cac diem con lai.",
                            Icon = "shopping",
                            EstimatedCost = FormatCurrency(exploreCost, currency)
                        },
                        new()
                        {
                            Time = "13:00",
                            Title = "Tra phong va an trua",
                            Description = "Thu xep hanh ly, tra phong dung gio va an trua gon nhe truoc khi quay ve.",
                            Icon = "hotel",
                            EstimatedCost = FormatCurrency(lunchCost, currency)
                        },
                        new()
                        {
                            Time = "15:30",
                            Title = $"Di chuyen ve lai {origin ?? "diem xuat phat"}",
                            Description = "Ket thuc hanh trinh, uu tien dat ve/chuyen di som neu can tranh tre gio.",
                            Icon = "transport",
                            EstimatedCost = FormatCurrency(350000m * headCount, currency)
                        }
                    }
                });
                continue;
            }

            days.Add(new ItineraryDayDto
            {
                DayNumber = dayNumber,
                Theme = $"Kham pha them {destination.Name}",
                Activities = new List<ItineraryActivityDto>
                {
                    new()
                    {
                        Time = "05:30",
                        Title = "Don binh minh hoac san may neu phu hop",
                        Description = "Neu dia diem phu hop, co the day som de ngam canh dep, san may hoac chay bo nhe.",
                        Icon = "attraction",
                        EstimatedCost = FormatCurrency(cafeCost, currency)
                    },
                    new()
                    {
                        Time = "08:00",
                        Title = "An sang va di chuyen den diem tham quan",
                        Description = "Chon quan an sang gan khu vuc sap tham quan de tiet kiem thoi gian di lai.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(breakfastCost, currency)
                    },
                    new()
                    {
                        Time = "10:00",
                        Title = $"Kham pha thien nhien va diem noi bat o {destination.Name}",
                        Description = "Uu tien mot cum diem gan nhau de di duoc nhieu noi hon ma van de nghi.",
                        Icon = "attraction",
                        EstimatedCost = FormatCurrency(exploreCost, currency)
                    },
                    new()
                    {
                        Time = "12:30",
                        Title = "An trua va nghi ngoi",
                        Description = "Chon bua trua vua tam, sau do nghi ngoi de giu suc cho buoi chieu.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(lunchCost, currency)
                    },
                    new()
                    {
                        Time = "15:30",
                        Title = "Ca phe, check-in va tham quan tiep",
                        Description = "Danh khoang nhe cho viec nghi chan, ngam view va chup anh o dia diem dep.",
                        Icon = "entertainment",
                        EstimatedCost = FormatCurrency(cafeCost, currency)
                    },
                    new()
                    {
                        Time = "18:30",
                        Title = "An toi va vui choi buoi toi",
                        Description = "Co the thu BBQ, lau, mon nuong hoac khu an uong pho bien tuy vao khau vi.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(dinnerCost, currency)
                    }
                }
            });
        }

        return days;
    }

    private static string? ExtractExplicitTripDestination(string text)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(?:lap ke hoach|lap lich trinh|tao plan|plan|du lich)(?:\s+cho|\s+di|\s+den|\s+toi|\s+tai)?\s+([a-z0-9\s]+?)(?=(?:\s+(?:tu|voi|gom|co|ngan sach|budget|trong|vao|tu ngay|ngay|dem)\b)|[,\.\n]|$)",
            @"(?:muon di|di du lich|di)\s+([a-z0-9\s]+?)(?=(?:\s+(?:tu|voi|gom|co|ngan sach|budget|trong|vao|tu ngay|ngay|dem)\b)|[,\.\n]|$)"
        };

        foreach (var pattern in patterns)
        {
            var match = System.Text.RegularExpressions.Regex.Match(normalized, pattern);
            if (!match.Success)
            {
                continue;
            }

            var candidate = match.Groups[1].Value.Trim();
            if (string.IsNullOrWhiteSpace(candidate))
            {
                continue;
            }

            if (candidate.Length <= 2)
            {
                continue;
            }

            return ToDisplayText(candidate);
        }

        return null;
    }

    private static string? ExtractDeparturePoint(string text, List<Destination> matchedDestinations)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(?:di tu|xuat phat tu|khoi hanh tu|bay tu)\s+([a-z0-9\s]+?)(?=(?:\s+(?:voi|gom|ngan sach|budget|den|toi|trong|vao|tu ngay|ngay|dem)\b)|[,\.\n]|$)",
            @"(?:^|[,\.\n])\s*tu\s+([a-z0-9\s]+?)(?=(?:\s+(?:voi|gom|ngan sach|budget|den|toi|trong|vao|tu ngay|ngay|dem)\b)|[,\.\n]|$)"
        };

        foreach (var pattern in patterns)
        {
            var match = System.Text.RegularExpressions.Regex.Match(normalized, pattern);
            if (!match.Success)
            {
                continue;
            }

            var candidate = match.Groups[1].Value.Trim();
            if (string.IsNullOrWhiteSpace(candidate))
            {
                continue;
            }

            if (matchedDestinations.Any(destination =>
                NormalizeText(destination.Name).Contains(candidate)
                || candidate.Contains(NormalizeText(destination.Name))))
            {
                continue;
            }

            return ToDisplayText(candidate);
        }

        return null;
    }

    private static int? ExtractTravelerCount(string text)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(\d+)\s*(nguoi|khach|thanh vien|nguoi lon|ban)",
            @"nhom\s*(\d+)",
            @"gia dinh\s*(\d+)"
        };

        foreach (var pattern in patterns)
        {
            var match = System.Text.RegularExpressions.Regex.Match(normalized, pattern);
            if (match.Success && int.TryParse(match.Groups[1].Value, out var count) && count > 0)
            {
                return count;
            }
        }

        return null;
    }

    private static decimal? ExtractBudgetAmount(string text)
    {
        var normalized = NormalizeText(text);
        var match = System.Text.RegularExpressions.Regex.Match(
            normalized,
            @"(\d+(?:[\.,]\d+)?)\s*(trieu|cu|k|nghin|vnd|d)");

        if (!match.Success)
        {
            return null;
        }

        if (!decimal.TryParse(
            match.Groups[1].Value.Replace(",", ".", StringComparison.Ordinal),
            NumberStyles.AllowDecimalPoint,
            CultureInfo.InvariantCulture,
            out var amount))
        {
            return null;
        }

        return match.Groups[2].Value switch
        {
            "trieu" => amount * 1_000_000m,
            "cu" => amount * 1_000_000m,
            "k" => amount * 1_000m,
            "nghin" => amount * 1_000m,
            _ => amount
        };
    }

    private static string ToDisplayText(string normalizedText)
    {
        var canonical = TryCanonicalizeLocationName(normalizedText);
        if (!string.IsNullOrWhiteSpace(canonical))
        {
            return canonical;
        }

        return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(normalizedText.Trim());
    }

    private static string? TryCanonicalizeLocationName(string? rawText)
    {
        var normalized = NormalizeText(rawText ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return null;
        }

        return normalized switch
        {
            "sai gon" or "sai gon city" or "sai gin" or "sai ginh" or "sai gion" or "sai gonn"
                => "Sài Gòn",
            "tphcm" or "tp hcm" or "tp ho chi minh" or "ho chi minh" or "ho chi minh city"
                => "TP. Hồ Chí Minh",
            "ha noi" or "ha loi" or "ha noii"
                => "Hà Nội",
            "da nang" or "đa nang" or "dnang"
                => "Đà Nẵng",
            "da lat" or "đa lat" or "dalat"
                => "Đà Lạt",
            "phu quoc" or "phu quoc island"
                => "Phú Quốc",
            "phu quy"
                => "Phú Quý",
            "ca mau" or "ca mauu"
                => "Cà Mau",
            "can tho" or "can thoo"
                => "Cần Thơ",
            _ => null
        };
    }

    private static string? TryExtractSelectedHotelName(string message, List<ChatHistoryItemDto> history)
    {
        var normalizedMessage = NormalizeText(message);
        var candidate = ExtractChoiceCandidate(normalizedMessage);
        var hotelNames = history
            .Where(item => item.Role == "bot" && item.ResponsePayload?.HotelCards != null)
            .SelectMany(item => item.ResponsePayload!.HotelCards!)
            .Select(card => card.Name)
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (!string.IsNullOrWhiteSpace(candidate))
        {
            var matchedFromCandidate = hotelNames.FirstOrDefault(name =>
            {
                var normalizedName = NormalizeText(name);
                return normalizedName.Contains(candidate, StringComparison.Ordinal)
                    || candidate.Contains(normalizedName, StringComparison.Ordinal);
            });

            if (!string.IsNullOrWhiteSpace(matchedFromCandidate))
            {
                return matchedFromCandidate;
            }
        }

        return hotelNames.FirstOrDefault(name =>
        {
            var normalizedName = NormalizeText(name);
            return normalizedMessage.Contains(normalizedName, StringComparison.Ordinal)
                || normalizedName.Contains(normalizedMessage, StringComparison.Ordinal);
        });
    }

    private static string? ExtractChoiceCandidate(string normalizedMessage)
    {
        var match = System.Text.RegularExpressions.Regex.Match(
            normalizedMessage,
            @"(?:chon|doi sang|lay|muon o|book|dat)\s+([a-z0-9\s]+)$");

        return match.Success ? match.Groups[1].Value.Trim() : null;
    }

    private static Hotel? SelectPreferredHotel(List<Hotel> hotels, string? preferredHotelName)
    {
        if (hotels.Count == 0)
        {
            return null;
        }

        if (string.IsNullOrWhiteSpace(preferredHotelName))
        {
            return hotels.FirstOrDefault();
        }

        var normalizedPreferred = NormalizeText(preferredHotelName);
        return hotels.FirstOrDefault(hotel =>
                   NormalizeText(hotel.Name).Contains(normalizedPreferred, StringComparison.Ordinal)
                   || normalizedPreferred.Contains(NormalizeText(hotel.Name), StringComparison.Ordinal))
               ?? hotels.FirstOrDefault();
    }

    private async Task<ItineraryDto?> BuildSuggestedItineraryAsync(
        List<Destination> matchedDestinations,
        int requestedDays = 3,
        ChatUserProfileDto? userProfile = null,
        string? origin = null,
        int travelerCount = 2,
        decimal? budget = null,
        string? preferredHotelName = null)
    {
        var destination = matchedDestinations.FirstOrDefault()
            ?? (await _chatRepo.GetDestinationsAsync(1)).FirstOrDefault();
        if (destination == null)
        {
            return null;
        }

        var hotels = await _chatRepo.SearchDestinationsHotelsAsync([destination.Id], 6);
        var buses = await _chatRepo.GetBusSchedulesAsync(2, [destination.Id]);
        var selectedHotel = SelectPreferredHotel(hotels, preferredHotelName);
        var selectedBus = SelectPreferredBusSchedule(buses, origin, destination);

        return new ItineraryDto
        {
            Title = $"Lich trinh goi y tai {destination.Name}",
            Destination = destination.Name,
            DestinationId = destination.Id,
            TotalDays = requestedDays,
            EstimatedBudget = BuildBudgetSummaryLabel(
                selectedHotel,
                selectedBus,
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency,
                budget),
            TravelStyle = "Linh hoat",
            HotelSuggestion = BuildHotelSuggestion(selectedHotel),
            TransportSuggestion = BuildTransportSuggestion(selectedBus),
            CostBreakdown = BuildCostBreakdown(
                selectedHotel,
                selectedBus,
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency),
            Days = BuildItineraryDays(
                destination,
                selectedHotel,
                selectedBus,
                requestedDays,
                travelerCount,
                userProfile?.PreferredCurrency,
                origin)
        };
    }

    private static HotelPlanSuggestionDto? BuildHotelSuggestion(Hotel? hotel)
    {
        if (hotel == null)
        {
            return null;
        }

        var room = hotel.Rooms
            .Where(item => item.PricePerNight.HasValue)
            .OrderBy(item => item.PricePerNight)
            .FirstOrDefault();

        return new HotelPlanSuggestionDto
        {
            HotelId = hotel.Id,
            RoomId = room?.Id,
            Name = hotel.Name,
            RoomType = room?.RoomType,
            Address = hotel.Address,
            DestinationName = hotel.Destination?.Name,
            PricePerNight = room?.PricePerNight,
            Capacity = room?.Capacity,
            AvailableQty = room?.AvailableQty
        };
    }

    private static BusSchedule? SelectPreferredBusSchedule(
        List<BusSchedule> buses,
        string? origin,
        Destination destination)
    {
        if (buses.Count == 0)
        {
            return null;
        }

        var normalizedDestination = NormalizeText(destination.Name);
        var normalizedOrigin = string.IsNullOrWhiteSpace(origin)
            ? null
            : NormalizeText(origin);

        if (!string.IsNullOrWhiteSpace(normalizedOrigin))
        {
            var exactRoute = buses.FirstOrDefault(bus =>
                !string.IsNullOrWhiteSpace(bus.FromDest?.Name) &&
                !string.IsNullOrWhiteSpace(bus.ToDest?.Name) &&
                IsLocationMatch(bus.FromDest!.Name!, normalizedOrigin!) &&
                IsLocationMatch(bus.ToDest!.Name!, normalizedDestination));

            return exactRoute;
        }

        return buses.FirstOrDefault(bus =>
            !string.IsNullOrWhiteSpace(bus.ToDest?.Name) &&
            IsLocationMatch(bus.ToDest!.Name!, normalizedDestination));
    }

    private static bool IsLocationMatch(string locationName, string normalizedCandidate)
    {
        var normalizedLocation = NormalizeText(locationName);
        return normalizedLocation.Contains(normalizedCandidate, StringComparison.Ordinal)
            || normalizedCandidate.Contains(normalizedLocation, StringComparison.Ordinal);
    }

    private static TransportPlanSuggestionDto? BuildTransportSuggestion(BusSchedule? bus)
    {
        if (bus == null)
        {
            return null;
        }

        return new TransportPlanSuggestionDto
        {
            ScheduleId = bus.Id,
            FromDestinationId = bus.FromDestId,
            FromDestinationName = bus.FromDest?.Name,
            ToDestinationId = bus.ToDestId,
            ToDestinationName = bus.ToDest?.Name,
            CompanyName = bus.Company?.Name ?? "Xe khach",
            Price = bus.Price,
            DepartureTime = bus.DepartureTime,
            ArrivalTime = bus.ArrivalTime,
            TotalSeats = bus.TotalSeats
        };
    }

    private static ItineraryCostBreakdownDto BuildCostBreakdown(
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays,
        int travelerCount,
        string? currency)
    {
        var headCount = Math.Max(1, travelerCount);
        var nights = Math.Max(1, requestedDays - 1);
        var roomsNeeded = GetEstimatedRoomCount(hotel, headCount);
        var hotelCost = hotel == null
            ? null
            : GetEstimatedStayCost(GetLowestHotelPrice(hotel), nights) * roomsNeeded;
        var transportCost = bus?.Price * headCount;
        var foodCost = 180000m * headCount * Math.Max(1, requestedDays);
        var activityCost = 140000m * headCount * Math.Max(1, requestedDays);
        var totalCost = (hotelCost ?? 0) + (transportCost ?? 0) + foodCost + activityCost;

        return new ItineraryCostBreakdownDto
        {
            HotelCost = hotelCost,
            TransportCost = transportCost,
            FoodCost = foodCost,
            ActivityCost = activityCost,
            TotalCost = totalCost,
            Currency = string.IsNullOrWhiteSpace(currency) ? "VND" : currency!
        };
    }

    private static string BuildBudgetSummaryLabel(
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays,
        int travelerCount,
        string? currency,
        decimal? budget)
    {
        var cost = BuildCostBreakdown(hotel, bus, requestedDays, travelerCount, currency);
        var totalText = FormatCurrency(cost.TotalCost, currency);

        if (budget.HasValue)
        {
            var status = cost.TotalCost.HasValue && cost.TotalCost.Value <= budget.Value
                ? "sat ngan sach"
                : "can nhac them ngan sach";
            return $"Tong du kien {totalText} cho {travelerCount} nguoi, {status}";
        }

        return $"Tong du kien {totalText} cho {travelerCount} nguoi";
    }

    private static List<ItineraryDayDto> BuildItineraryDays(
        Destination destination,
        Hotel? hotel,
        BusSchedule? bus,
        int requestedDays,
        int travelerCount,
        string? currency,
        string? origin)
    {
        var totalDays = Math.Max(1, requestedDays);
        var headCount = Math.Max(1, travelerCount);
        var hotelNightly = GetLowestHotelPrice(hotel);
        var roomsNeeded = GetEstimatedRoomCount(hotel, headCount);
        var hotelNightlyTotal = hotelNightly.HasValue
            ? hotelNightly.Value * roomsNeeded
            : (decimal?)null;
        var transportTotal = bus?.Price.HasValue == true
            ? bus.Price!.Value * headCount
            : (decimal?)null;
        var mealCost = 90000m * headCount;
        var dinnerCost = 120000m * headCount;
        var cafeCost = 60000m * headCount;
        var activityCost = 140000m * headCount;
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
                            Title = bus != null
                                ? $"{bus.Company?.Name ?? "Xe khach"} den {destination.Name}"
                                : $"Di chuyen den {destination.Name}",
                            Description = bus != null
                                ? $"Tuyen {origin ?? bus.FromDest?.Name ?? "diem khoi hanh"} -> {bus.ToDest?.Name ?? destination.Name}, khoi hanh {FormatDateTime(bus.DepartureTime)}."
                                : $"Khoi hanh tu {origin ?? "diem xuat phat"} de den {destination.Name}.",
                            Icon = "transport",
                            EstimatedCost = FormatCurrency(transportTotal, currency)
                        },
                        new()
                        {
                            Time = "14:00",
                            Title = !string.IsNullOrWhiteSpace(hotel?.Name)
                                ? $"Nhan phong tai {hotel!.Name}"
                                : "Nhan phong va nghi ngoi",
                            Description = !string.IsNullOrWhiteSpace(hotel?.Name)
                                ? BuildHotelDayDescription(hotel!, roomsNeeded)
                                : "Nhan phong tai khach san phu hop gan trung tam.",
                            Icon = "hotel",
                            EstimatedCost = hotelNightlyTotal == null
                                ? null
                                : $"{FormatCurrency(hotelNightlyTotal, currency)} / dem"
                        },
                        new()
                        {
                            Time = "19:00",
                            Title = "An toi va di dao buoi toi",
                            Description = $"Thu mon dac trung ngay khi den {destination.Name} va dao khu trung tam de de canh dep.",
                            Icon = "restaurant",
                            EstimatedCost = FormatCurrency(dinnerCost, currency)
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
                            Time = "08:30",
                            Title = "An sang va check-out",
                            Description = !string.IsNullOrWhiteSpace(hotel?.Name)
                                ? $"Dung bua sang, tra phong tai {hotel.Name} va kiem tra hanh ly truoc khi roi {destination.Name}."
                                : $"Dung bua sang va tra phong truoc khi ket thuc hanh trinh tai {destination.Name}.",
                            Icon = "hotel",
                            EstimatedCost = FormatCurrency(mealCost, currency)
                        },
                        new()
                        {
                            Time = "10:30",
                            Title = "Mua dac san va chup anh lan cuoi",
                            Description = $"Danh it thoi gian ghe cho dac san hoac quan ca phe view dep de co them anh ky niem.",
                            Icon = "shopping",
                            EstimatedCost = FormatCurrency(cafeCost + activityCost, currency)
                        },
                        new()
                        {
                            Time = "13:30",
                            Title = "Di chuyen ve",
                            Description = $"Ket thuc lich trinh {totalDays} ngay tai {destination.Name} va quay ve {origin ?? "diem xuat phat"}.",
                            Icon = "transport",
                            EstimatedCost = FormatCurrency(transportTotal, currency)
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
                        Time = "07:30",
                        Title = "An sang dia phuong",
                        Description = $"Thu bua sang dac trung tai khu trung tam {destination.Name} de bat dau ngay moi.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(mealCost, currency)
                    },
                    new()
                    {
                        Time = "09:30",
                        Title = $"Tham quan diem noi bat cua {destination.Name}",
                        Description = destination.Description ?? $"Uu tien cac diem check-in, ngam canh va trai nghiem dac trung cua {destination.Name}.",
                        Icon = "attraction",
                        EstimatedCost = FormatCurrency(activityCost, currency)
                    },
                    new()
                    {
                        Time = "12:30",
                        Title = "An trua",
                        Description = "Chon quan an duoc danh gia tot, uu tien mon dac san va khau phan vua tam cho nhom.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(dinnerCost, currency)
                    },
                    new()
                    {
                        Time = "15:30",
                        Title = "Ca phe, nghi chan va chup hinh",
                        Description = "Danh mot khoang nhe buoi chieu de nghi ngoi, ngam view va tranh lich qua day.",
                        Icon = "entertainment",
                        EstimatedCost = FormatCurrency(cafeCost, currency)
                    },
                    new()
                    {
                        Time = "18:30",
                        Title = "An toi va dao choi buoi toi",
                        Description = $"Ket hop an toi, di bo, tham quan khu vui choi hoac cho dem tai {destination.Name}.",
                        Icon = "restaurant",
                        EstimatedCost = FormatCurrency(dinnerCost, currency)
                    }
                }
            });
        }

        return days;
    }

    private static string BuildHotelDayDescription(Hotel hotel, int roomsNeeded)
    {
        var room = hotel.Rooms
            .Where(item => item.PricePerNight.HasValue)
            .OrderBy(item => item.PricePerNight)
            .FirstOrDefault();

        var roomType = string.IsNullOrWhiteSpace(room?.RoomType)
            ? "phong tieu chuan"
            : room!.RoomType;
        var roomCountLabel = roomsNeeded > 1 ? $"{roomsNeeded} phong" : "1 phong";

        return $"{roomCountLabel} {roomType}, dia chi {hotel.Address ?? "dang cap nhat"}, phu hop de nghi trua va di chuyen cac diem gan trung tam.";
    }

    private static int GetEstimatedRoomCount(Hotel? hotel, int travelerCount)
    {
        var capacity = hotel == null
            ? 0
            : hotel.Rooms
                .Where(room => room.Capacity.HasValue && room.Capacity.Value > 0)
                .OrderByDescending(room => room.Capacity ?? 0)
                .Select(room => room.Capacity ?? 0)
                .FirstOrDefault();

        if (capacity <= 0)
        {
            capacity = 2;
        }

        return Math.Max(1, (int)Math.Ceiling(travelerCount / (double)capacity));
    }

    private static decimal? GetLowestHotelPrice(Hotel? hotel)
    {
        if (hotel == null)
        {
            return null;
        }

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

    private static string FormatCurrency(decimal? amount, string? currency = "VND")
    {
        if (!amount.HasValue)
        {
            return "lien he";
        }

        if (string.Equals(currency, "USD", StringComparison.OrdinalIgnoreCase))
        {
            var usdAmount = decimal.Round(amount.Value / 25000m, 0, MidpointRounding.AwayFromZero);
            return $"~{usdAmount:N0} USD";
        }

        return $"{amount.Value:N0} VND";
    }

    private static string FormatDateTime(DateTime? dateTime)
    {
        return dateTime.HasValue
            ? dateTime.Value.ToLocalTime().ToString("dd/MM HH:mm")
            : "chua cap nhat";
    }
}
