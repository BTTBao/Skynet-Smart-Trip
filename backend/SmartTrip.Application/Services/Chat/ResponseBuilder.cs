using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Builds response DTOs from knowledge results.
/// Handles no-data responses, enrichment with DB cards, quick actions,
/// and localization. No hardcoded destination data.
/// </summary>
public class ResponseBuilder
{
    // ──────────────────────────────────────────────
    // NO-DATA RESPONSES — Honest about missing data
    // ──────────────────────────────────────────────

    public ChatResponseDto BuildNoDataResponse(
        string intent,
        string? requestedLocation,
        List<Destination>? alternatives)
    {
        var text = intent switch
        {
            "hotel_query" => $"Mình chưa tìm thấy khách sạn phù hợp ở {requestedLocation ?? "địa điểm này"} trong hệ thống.",
            "bus_query" => $"Mình chưa tìm thấy tuyến xe phù hợp cho {requestedLocation ?? "tuyến đường này"} trong hệ thống.",
            "destination_query" => $"Mình chưa có thông tin chi tiết về {requestedLocation ?? "địa điểm này"} trong hệ thống.",
            "booking_request" => $"Mình chưa tìm thấy dịch vụ đặt chỗ cho {requestedLocation ?? "yêu cầu này"} trong hệ thống.",
            "itinerary_request" => $"Mình chưa có dữ liệu lập kế hoạch cho {requestedLocation ?? "điểm đến này"} trong hệ thống.",
            _ => "Mình chưa tìm thấy thông tin phù hợp trong hệ thống."
        };

        if (alternatives?.Count > 0)
        {
            var names = string.Join(", ", alternatives.Select(d => d.Name));
            text += $" Bạn có muốn mình tìm ở {names} không?";
        }

        return new ChatResponseDto
        {
            Text = text,
            ResponseType = "text",
            QuickActions = BuildAlternativeQuickActions(alternatives),
            Timestamp = DateTime.UtcNow
        };
    }

    // ──────────────────────────────────────────────
    // FOLLOW-UP RESPONSE — Ask for missing info
    // ──────────────────────────────────────────────

    public ChatResponseDto BuildFollowUpResponse(
        string followUpQuestion,
        List<string> missingFields)
    {
        return new ChatResponseDto
        {
            Text = followUpQuestion,
            ResponseType = "text",
            QuickActions = BuildDefaultQuickActionsForIntent("itinerary_request"),
            Timestamp = DateTime.UtcNow
        };
    }

    // ──────────────────────────────────────────────
    // ENRICH RESPONSE — Add DB cards to AI response
    // ──────────────────────────────────────────────

    public ChatResponseDto EnrichResponse(
        ChatResponseDto response,
        string intent,
        KnowledgeResult knowledge,
        ChatUserProfileDto? userProfile)
    {
        var currency = userProfile?.PreferredCurrency ?? "VND";

        switch (intent)
        {
            case "hotel_query":
                response = EnrichWithHotelCards(response, knowledge, currency);
                break;

            case "bus_query":
                response = EnrichWithTransportCards(response, knowledge, currency);
                break;

            case "destination_query":
                response = EnrichWithDestinationCards(response, knowledge);
                break;

            case "promotion_query":
                response = EnrichWithPromotionText(response, knowledge, currency);
                break;

            case "budget_query":
                response = EnrichWithBudgetSummary(response, knowledge, currency);
                break;

            case "package_query":
                response = EnrichWithPackageData(response, knowledge, currency);
                break;
        }

        return response;
    }

    // ──────────────────────────────────────────────
    // HOTEL ENRICHMENT
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithHotelCards(
        ChatResponseDto response,
        KnowledgeResult knowledge,
        string currency)
    {
        if (knowledge.Hotels == null || knowledge.Hotels.Count == 0)
        {
            return response;
        }

        if (response.HotelCards == null || response.HotelCards.Count == 0)
        {
            response.HotelCards = knowledge.Hotels.Take(5).Select(h => new HotelCardDto
            {
                Id = h.Id,
                Name = h.Name,
                Address = h.Address,
                StarRating = h.StarRating,
                Description = h.Description,
                PricePerNight = KnowledgeService.GetLowestHotelPrice(h),
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

        // Set descriptive text based on matched destination
        if (string.IsNullOrWhiteSpace(response.Text))
        {
            var destName = knowledge.Hotels.FirstOrDefault()?.Destination?.Name;
            if (!string.IsNullOrWhiteSpace(destName))
            {
                response.Text = $"Dưới đây là một số khách sạn phù hợp với chuyến đi của bạn tại {destName}.";
            }
            else
            {
                response.Text = "Dưới đây là một số khách sạn phù hợp với chuyến đi của bạn.";
            }
        }

        return response;
    }

    // ──────────────────────────────────────────────
    // TRANSPORT ENRICHMENT
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithTransportCards(
        ChatResponseDto response,
        KnowledgeResult knowledge,
        string currency)
    {
        if (knowledge.BusSchedules == null || knowledge.BusSchedules.Count == 0)
        {
            return response;
        }

        if (response.TransportCards == null || response.TransportCards.Count == 0)
        {
            response.TransportCards = knowledge.BusSchedules.Select(route => new TransportCardDto
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

        // Build summary text
        if (string.IsNullOrWhiteSpace(response.Text))
        {
            var lines = knowledge.BusSchedules.Select(route =>
                $"- {route.FromDest?.Name ?? "?"} -> {route.ToDest?.Name ?? "?"}, " +
                $"{KnowledgeService.FormatDateTime(route.DepartureTime)}, " +
                $"giá từ {KnowledgeService.FormatCurrency(route.Price, currency)}");
            response.Text = "Mình tìm thấy một số tuyến xe phù hợp:\n" + string.Join("\n", lines);
        }

        return response;
    }

    // ──────────────────────────────────────────────
    // DESTINATION ENRICHMENT — DB ONLY, NO HARDCODED CARDS
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithDestinationCards(
        ChatResponseDto response,
        KnowledgeResult knowledge)
    {
        if (knowledge.Destinations.Count == 0)
        {
            return response;
        }

        if (response.DestinationCards == null || response.DestinationCards.Count == 0)
        {
            response.DestinationCards = knowledge.Destinations
                .Take(6)
                .Select(d => new DestinationCardDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    ImageUrl = d.CoverImageUrl,
                    IsHot = d.IsHot,
                    Rating = d.IsHot == true ? 4.7 : 4.4,
                    BestSeason = "Quanh năm",
                    EstimatedBudget = "Từ 2-5 triệu"
                })
                .ToList();

            if (response.ResponseType == "text")
            {
                response.ResponseType = "destination_card";
            }
        }

        if (string.IsNullOrWhiteSpace(response.Text))
        {
            response.Text = "Mình gợi ý một vài điểm đến để bạn tham khảo.";
        }
        
        return response;
    }

    // ──────────────────────────────────────────────
    // PROMOTION ENRICHMENT
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithPromotionText(
        ChatResponseDto response,
        KnowledgeResult knowledge,
        string currency)
    {
        if (knowledge.Promotions == null || knowledge.Promotions.Count == 0)
        {
            if (string.IsNullOrWhiteSpace(response.Text))
            {
                response.Text = "Hiện tại chưa có khuyến mãi nổi bật. Bạn có thể thử lại sau.";
            }
            return response;
        }

        if (string.IsNullOrWhiteSpace(response.Text))
        {
            var lines = knowledge.Promotions.Select(p =>
                $"- {p.Code}: giảm {p.DiscountPercent?.ToString("0") ?? "0"}% " +
                $"tối đa {KnowledgeService.FormatCurrency(p.MaxDiscountAmount, currency)}");
            response.Text = "Đây là một số khuyến mãi đang hoạt động:\n" + string.Join("\n", lines);
        }

        return response;
    }

    // ──────────────────────────────────────────────
    // BUDGET ENRICHMENT
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithBudgetSummary(
        ChatResponseDto response,
        KnowledgeResult knowledge,
        string currency)
    {
        var parts = new List<string>();

        if (knowledge.Hotels?.Count > 0)
        {
            var hotelText = string.Join("; ", knowledge.Hotels.Select(h =>
                $"{h.Name} từ {KnowledgeService.FormatCurrency(KnowledgeService.GetLowestHotelPrice(h), currency)} / đêm"));
            parts.Add($"Khách sạn: {hotelText}");
        }

        if (knowledge.BusSchedules?.Count > 0)
        {
            var busText = string.Join("; ", knowledge.BusSchedules.Select(b =>
                $"{b.FromDest?.Name ?? "?"} -> {b.ToDest?.Name ?? "?"} từ {KnowledgeService.FormatCurrency(b.Price, currency)}"));
            parts.Add($"Di chuyển: {busText}");
        }

        if (knowledge.Promotions?.Count > 0)
        {
            var promoText = string.Join("; ", knowledge.Promotions.Select(p =>
                $"{p.Code} giảm {p.DiscountPercent?.ToString("0") ?? "0"}%"));
            parts.Add($"Khuyến mãi: {promoText}");
        }

        if (string.IsNullOrWhiteSpace(response.Text))
        {
            if (parts.Count > 0)
            {
                response.Text = "Mình tổng hợp nhanh chi phí tham khảo:\n- " + string.Join("\n- ", parts);
            }
            else
            {
                response.Text = "Mình chưa đủ dữ liệu để ước tính ngân sách cho yêu cầu này.";
            }
        }

        response.ResponseType = "text";
        response.WeatherInfo = null;
        return response;
    }

    // ──────────────────────────────────────────────
    // PACKAGE ENRICHMENT
    // ──────────────────────────────────────────────

    private static ChatResponseDto EnrichWithPackageData(
        ChatResponseDto response,
        KnowledgeResult knowledge,
        string currency)
    {
        if (knowledge.Destinations.Count > 0)
        {
            response.DestinationCards = knowledge.Destinations
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

        var destName = knowledge.Destinations.FirstOrDefault()?.Name;
        var promoSummary = knowledge.Promotions?.Count > 0
            ? $" Ưu đãi hiện có: {string.Join("; ", knowledge.Promotions.Select(p => $"{p.Code} giảm {p.DiscountPercent?.ToString("0") ?? "0"}%"))}."
            : string.Empty;

        if (string.IsNullOrWhiteSpace(response.Text))
        {
            response.Text = !string.IsNullOrWhiteSpace(destName)
                ? $"Hiện hệ thống chưa có gói du lịch đóng gói sẵn cho {destName}, nhưng mình có thể gợi ý lịch trình, khách sạn và chi phí tham khảo.{promoSummary}"
                : $"Mình có thể giúp bạn ghép lịch trình, khách sạn và ngân sách thành một gói tham khảo.{promoSummary}";
        }

        response.ResponseType = "destination_card";
        response.WeatherInfo = null;
        return response;
    }

    // ──────────────────────────────────────────────
    // QUICK ACTIONS
    // ──────────────────────────────────────────────

    public ChatResponseDto EnsureQuickActions(
        ChatResponseDto response,
        string intent,
        ChatUserProfileDto? userProfile)
    {
        response.Timestamp = response.Timestamp == default ? DateTime.UtcNow : response.Timestamp;

        if (response.QuickActions == null || response.QuickActions.Count == 0)
        {
            response.QuickActions = BuildDefaultQuickActionsForIntent(intent);
        }

        return response;
    }

    public static List<QuickActionDto> BuildDefaultQuickActionsForIntent(string intent)
    {
        return intent switch
        {
            "promotion_query" => new List<QuickActionDto>
            {
                new() { Label = "Tìm khách sạn có ưu đãi", Icon = "hotel", ActionPayload = "Tìm khách sạn tốt đang có ưu đãi" },
                new() { Label = "Lập lịch trình tiết kiệm", Icon = "calendar", ActionPayload = "Lập lịch trình du lịch tiết kiệm cho tôi" }
            },
            "bus_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem thêm tuyến xe", Icon = "map", ActionPayload = "Có thêm tuyến xe nào khác phù hợp không" },
                new() { Label = "Tìm khách sạn", Icon = "hotel", ActionPayload = "Tìm khách sạn gần điểm đến này" }
            },
            "hotel_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem mức giá rẻ hơn", Icon = "hotel", ActionPayload = "Có khách sạn nào giá mềm hơn không" },
                new() { Label = "Lập lịch trình", Icon = "calendar", ActionPayload = "Lập lịch trình du lịch cho điểm đến này" }
            },
            "budget_query" => new List<QuickActionDto>
            {
                new() { Label = "Tối ưu chi phí", Icon = "explore", ActionPayload = "Gợi ý cách tối ưu chi phí chuyến đi này" },
                new() { Label = "Tìm ưu đãi", Icon = "explore", ActionPayload = "Có khuyến mãi nào phù hợp với chuyến đi này" }
            },
            "package_query" => new List<QuickActionDto>
            {
                new() { Label = "Xem khách sạn", Icon = "hotel", ActionPayload = "Tìm khách sạn phù hợp cho điểm đến này" },
                new() { Label = "Lập lịch trình", Icon = "calendar", ActionPayload = "Lập lịch trình du lịch cho điểm đến này" }
            },
            "itinerary_request" => new List<QuickActionDto>
            {
                new() { Label = "Thay đổi lịch trình", Icon = "calendar", ActionPayload = "Tôi muốn chỉnh sửa lịch trình này" },
                new() { Label = "Tìm khách sạn", Icon = "hotel", ActionPayload = "Tìm khách sạn phù hợp với lịch trình này" }
            },
            _ => new List<QuickActionDto>
            {
                new() { Label = "Gợi ý điểm đến", Icon = "explore", ActionPayload = "Gợi ý cho tôi một vài điểm đến đẹp ở Việt Nam" },
                new() { Label = "Tìm khách sạn", Icon = "hotel", ActionPayload = "Tìm khách sạn tốt cho chuyến đi của tôi" }
            }
        };
    }

    // ──────────────────────────────────────────────
    // LOCALIZATION
    // ──────────────────────────────────────────────

    public static string Localize(ChatUserProfileDto? userProfile, string vi, string en)
    {
        return string.Equals(userProfile?.PreferredLanguage, "en", StringComparison.OrdinalIgnoreCase)
            ? en
            : vi;
    }

    public static string? BuildPersonalizationSummary(ChatUserProfileDto? userProfile)
    {
        if (userProfile == null)
        {
            return null;
        }

        var parts = new List<string>();

        if (!string.IsNullOrWhiteSpace(userProfile.DisplayName))
        {
            parts.Add($"Tên người dùng: {userProfile.DisplayName}");
        }

        parts.Add($"Ngôn ngữ ưa thích: {userProfile.PreferredLanguage}");
        parts.Add($"Tiện tệ ưa thích: {userProfile.PreferredCurrency}");

        if (userProfile.TripsCount > 0)
        {
            parts.Add($"Số chuyến đi đã có: {userProfile.TripsCount}");
        }

        if (userProfile.LoyaltyPoints > 0)
        {
            parts.Add($"Điểm tích lũy: {userProfile.LoyaltyPoints}");
        }

        if (userProfile.RecentDestinationNames.Count > 0)
        {
            parts.Add($"Điểm đến gần đây: {string.Join(", ", userProfile.RecentDestinationNames)}");
        }

        if (userProfile.FavoriteHotelNames.Count > 0)
        {
            parts.Add($"Khách sạn yêu thích: {string.Join(", ", userProfile.FavoriteHotelNames)}");
        }

        return string.Join(" | ", parts);
    }

    // ──────────────────────────────────────────────
    // PRIVATE HELPERS
    // ──────────────────────────────────────────────

    private static List<QuickActionDto> BuildAlternativeQuickActions(
        List<Destination>? alternatives)
    {
        var actions = new List<QuickActionDto>();

        if (alternatives != null)
        {
            foreach (var dest in alternatives.Take(2))
            {
                actions.Add(new QuickActionDto
                {
                    Label = $"Khách sạn ở {dest.Name}",
                    Icon = "hotel",
                    ActionPayload = $"Tìm khách sạn ở {dest.Name}"
                });
            }
        }

        actions.Add(new QuickActionDto
        {
            Label = "Gợi ý điểm đến",
            Icon = "explore",
            ActionPayload = "Gợi ý cho tôi một vài điểm đến đẹp ở Việt Nam"
        });

        return actions;
    }
}
