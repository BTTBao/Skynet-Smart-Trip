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

        var response = await _aiService.GenerateResponseAsync(context);
        response = await EnrichWithDatabaseData(response, intent, request.Message);
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

        if (ContainsAny(lower, "gia", "chi phi", "budget", "tiet kiem", "bao nhieu tien"))
            return "budget_query";

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

        if (intent is "hotel_query" or "destination_query" or "booking_request" or "budget_query")
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

        if (intent is "itinerary_request" or "general" or "bus_query" or "budget_query")
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

        if (intent is "promotion_query" or "budget_query" or "booking_request")
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

        if (intent == "destination_query" && (response.DestinationCards == null || response.DestinationCards.Count == 0))
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
            response.Text = await BuildBudgetSummaryAsync(response.Text, matchedDestinations);
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

    private async Task<string> BuildBudgetSummaryAsync(string fallbackText, List<Destination> matchedDestinations)
    {
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
                $"{h.Name} tu {FormatCurrency(GetLowestHotelPrice(h))} / dem"));
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

        return "Minh tong hop nhanh chi phi tham khao cho ban:\n- " + string.Join("\n- ", parts);
    }

    private async Task<ItineraryDto?> BuildSuggestedItineraryAsync(List<Destination> matchedDestinations)
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
            TotalDays = 3,
            EstimatedBudget = hotels.Any()
                ? $"Tu {FormatCurrency(GetLowestHotelPrice(hotels[0]))} / dem"
                : "Lien he de nhan bao gia",
            TravelStyle = "Linh hoat",
            Days = new List<ItineraryDayDto>
            {
                new()
                {
                    DayNumber = 1,
                    Theme = "Di chuyen va nhan phong",
                    Activities = new List<ItineraryActivityDto>
                    {
                        new()
                        {
                            Time = "08:00",
                            Title = $"Di chuyen den {destination.Name}",
                            Description = buses.FirstOrDefault() is BusSchedule bus
                                ? $"Co the tham khao tuyen {bus.FromDest?.Name ?? "diem khoi hanh"} -> {bus.ToDest?.Name ?? destination.Name} vao {FormatDateTime(bus.DepartureTime)}"
                                : $"Bat dau hanh trinh den {destination.Name}",
                            Icon = "map"
                        },
                        new()
                        {
                            Time = "14:00",
                            Title = "Nhan phong va nghi ngoi",
                            Description = hotels.FirstOrDefault()?.Name is string hotelName && !string.IsNullOrWhiteSpace(hotelName)
                                ? $"Goi y luu tru tai {hotelName}"
                                : "Nhan phong tai khach san phu hop",
                            Icon = "hotel"
                        }
                    }
                },
                new()
                {
                    DayNumber = 2,
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
                },
                new()
                {
                    DayNumber = 3,
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
                            Description = "Ket thuc lich trinh goi y 3 ngay 2 dem",
                            Icon = "car"
                        }
                    }
                }
            }
        };
    }

    private static decimal? GetLowestHotelPrice(Hotel hotel)
    {
        return hotel.Rooms
            .Where(room => room.PricePerNight.HasValue)
            .Select(room => room.PricePerNight)
            .Min();
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
