using SmartTrip.Application.DTOs.Chat;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Layer 1 — Entity extraction and text normalization utilities.
/// Extracts structured data (location, days, budget, travelers, etc.) from user messages.
/// Supports selective history merge to avoid context contamination.
/// </summary>
public class EntityExtractor
{
    // ──────────────────────────────────────────────
    // PUBLIC: Extract all entities from a single message
    // ──────────────────────────────────────────────

    public ChatEntitiesDto ExtractAll(string message)
    {
        var normalized = NormalizeText(message);
        return new ChatEntitiesDto
        {
            Destination = ExtractExplicitTripDestination(message),
            Origin = ExtractDeparturePoint(message, []),
            Days = ExtractRequestedDays(message) is var d && d > 0 ? d : null,
            Budget = ExtractBudgetAmount(message),
            PassengerCount = ExtractTravelerCount(message),
            HotelName = ExtractHotelNameFromMessage(normalized),
            DepartureDate = ExtractDepartureDate(normalized)
        };
    }

    // ──────────────────────────────────────────────
    // PUBLIC: Selective entity merge from history
    // ──────────────────────────────────────────────

    /// <summary>
    /// Merges entities from conversation history into current entities.
    /// Rules:
    ///   1. Only fill MISSING fields (current message entities always win)
    ///   2. Only take from history within last 3 turns
    ///   3. Only take from messages with SAME or compatible intent type
    /// </summary>
    public ChatEntitiesDto MergeEntitiesFromHistory(
        ChatEntitiesDto currentEntities,
        List<ChatHistoryItemDto> history,
        string currentIntent)
    {
        if (history.Count == 0)
        {
            return currentEntities;
        }

        // Only look at last 3 user messages for entity context
        var recentUserMessages = history
            .Where(item => item.Role == "user" && !string.IsNullOrWhiteSpace(item.Content))
            .TakeLast(3)
            .ToList();

        if (recentUserMessages.Count == 0)
        {
            return currentEntities;
        }

        // For itinerary_request: merge missing fields from recent context
        if (currentIntent == "itinerary_request")
        {
            foreach (var msg in recentUserMessages)
            {
                var historyEntities = ExtractAll(msg.Content);

                if (string.IsNullOrWhiteSpace(currentEntities.Destination)
                    && !string.IsNullOrWhiteSpace(historyEntities.Destination))
                {
                    currentEntities.Destination = historyEntities.Destination;
                }

                if (string.IsNullOrWhiteSpace(currentEntities.Origin)
                    && !string.IsNullOrWhiteSpace(historyEntities.Origin))
                {
                    currentEntities.Origin = historyEntities.Origin;
                }

                if (!currentEntities.Days.HasValue && historyEntities.Days.HasValue)
                {
                    currentEntities.Days = historyEntities.Days;
                }

                if (!currentEntities.Budget.HasValue && historyEntities.Budget.HasValue)
                {
                    currentEntities.Budget = historyEntities.Budget;
                }

                if (!currentEntities.PassengerCount.HasValue && historyEntities.PassengerCount.HasValue)
                {
                    currentEntities.PassengerCount = historyEntities.PassengerCount;
                }

                if (string.IsNullOrWhiteSpace(currentEntities.HotelName)
                    && !string.IsNullOrWhiteSpace(historyEntities.HotelName))
                {
                    currentEntities.HotelName = historyEntities.HotelName;
                }
            }
        }

        // For hotel_query: try to extract selected hotel name from history
        if (currentIntent == "hotel_query"
            && string.IsNullOrWhiteSpace(currentEntities.HotelName))
        {
            var selectedHotel = TryExtractSelectedHotelName(
                currentEntities.HotelName ?? string.Empty, history);
            if (!string.IsNullOrWhiteSpace(selectedHotel))
            {
                currentEntities.HotelName = selectedHotel;
            }
        }

        return currentEntities;
    }

    // ──────────────────────────────────────────────
    // ENTITY EXTRACTORS (from original ChatService)
    // ──────────────────────────────────────────────

    public int ExtractRequestedDays(string text)
    {
        var normalized = NormalizeText(text);
        var dayMatch = Regex.Match(normalized, @"(\d+)\s*ngày");
        if (dayMatch.Success && int.TryParse(dayMatch.Groups[1].Value, out var days) && days > 0)
        {
            return days;
        }

        var nightMatch = Regex.Match(normalized, @"(\d+)\s*đêm");
        if (nightMatch.Success && int.TryParse(nightMatch.Groups[1].Value, out var nights) && nights >= 0)
        {
            return nights + 1;
        }

        return 0;
    }

    public string? ExtractExplicitTripDestination(string text)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(?:lap ke hoach|lap lich trinh|tao plan|plan|du lich)(?:\s+cho|\s+di|\s+den|\s+toi|\s+tai)?\s+([\p{L}\p{N}\s]+?)(?=(?:\s+(?:tu|voi|gom|co|ngan sach|budget|trong|vao|tu ngay|ngay|dem)\b)|[,\.\n]|$)"
        };

        foreach (var pattern in patterns)
        {
            var match = Regex.Match(normalized, pattern);
            if (!match.Success)
            {
                continue;
            }

            var candidate = match.Groups[1].Value.Trim();
            if (string.IsNullOrWhiteSpace(candidate) || candidate.Length <= 2)
            {
                continue;
            }

            // Remove noise words
            candidate = Regex.Replace(candidate,
                @"\b(du lich|du lịch|nao|nào|tot|tốt|dep|đẹp|re|rẻ|nhat|nhất|phu hop|phù hợp|cho toi|cho tôi|cho minh|cho mình|cho ban|cho bạn|khong|không|nhe|nhé|nha|nhà|a|ạ|di|đi|u|ừ|duoc|được|voi|với)\b",
                string.Empty).Trim();

            if (!string.IsNullOrWhiteSpace(candidate) && candidate.Length > 2)
            {
                return ToDisplayText(candidate);
            }
        }

        return null;
    }

    public string? ExtractDeparturePoint(string text, IReadOnlyList<string> destinationNames)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(?:đi từ|di tu|xuất phát từ|xuat phat tu|khởi hành từ|khoi hanh tu|bay từ|bay tu)\s+([\p{L}\p{N}\s]+?)(?=(?:\s+(?:với|voi|gồm|gom|ngân sách|budget|đến|den|tới|toi|trong|vào|vao|từ ngày|tu ngay|ngày|ngay|đêm|dem)\b)|[,\.\n]|$)",

            @"(?:^|[,\.\n])\s*(?:từ|tu)\s+([\p{L}\p{N}\s]+?)(?=(?:\s+(?:với|voi|gồm|gom|ngân sách|budget|đến|den|tới|toi|trong|vào|vao|từ ngày|tu ngay|ngày|ngay|đêm|dem)\b)|[,\.\n]|$)"
        };

        foreach (var pattern in patterns)
        {
            var match = Regex.Match(normalized, pattern);
            if (!match.Success)
            {
                continue;
            }

            var candidate = match.Groups[1].Value.Trim();
            if (string.IsNullOrWhiteSpace(candidate))
            {
                continue;
            }

            // Skip if candidate is actually a destination (not origin)
            if (destinationNames.Any(name =>
                NormalizeText(name).Contains(candidate, StringComparison.Ordinal)
                || candidate.Contains(NormalizeText(name), StringComparison.Ordinal)))
            {
                continue;
            }

            return ToDisplayText(candidate);
        }

        return null;
    }

    public int? ExtractTravelerCount(string text)
    {
        var normalized = NormalizeText(text);
        var patterns = new[]
        {
            @"(\d+)\s*(nguoi|người|khach|khách|thanh vien|thành viên|nguoi lon|người lớn|ban|bạn)",

            @"(nhom|nhóm)\s*(\d+)",

            @"(gia dinh|gia đình)\s*(\d+)"
        };

        foreach (var pattern in patterns)
        {
            var match = Regex.Match(normalized, pattern);
            if (match.Success && int.TryParse(match.Groups[1].Value, out var count) && count > 0)
            {
                return count;
            }
        }

        return null;
    }

    public decimal? ExtractBudgetAmount(string text)
    {
        var normalized = NormalizeText(text);
        var match = Regex.Match(
            normalized,
            @"(\d+(?:[\.,]\d+)?)\s*(trieu|triệu|cu|củ|k|nghin|nghìn|vnd|d|đ)");

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
            "trieu" or "triệu" => amount * 1_000_000m,
            "cu" or "củ"       => amount * 1_000_000m,
            "k"                => amount * 1_000m,
            "nghin" or "nghìn" => amount * 1_000m,
            _ => amount
        };
    }

    public string? ExtractWeatherLocation(string userMessage)
    {
        var normalized = NormalizeText(userMessage);
        var match = Regex.Match(
            normalized,
            @"(?:thời tiết|thoi tiet|weather|dự báo|du bao|nhiệt độ|nhiet do)(?:\s+ở|\s+o|\s+tại|\s+tai|\s+cho)?\s+([\p{L}\p{N}\s\.]+)$");

        if (!match.Success)
        {
            match = Regex.Match(
                normalized,
                @"^([\p{L}\p{N}\s\.]+?)\s+(?:thời tiết|thoi tiet|weather|dự báo|du bao|nhiệt độ|nhiet do)(?:\s+hôm nay|\s+hom nay|\s+ngày mai|\s+ngay mai|\s+tối nay|\s+toi nay|\s+cuối tuần này|\s+cuoi tuan nay|\s+tuần này|\s+tuan nay)?$");
        }

        if (!match.Success)
        {
            return null;
        }

        var candidate = match.Groups[1].Value.Trim();
        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        candidate = Regex.Replace(
            candidate,
            @"\b(hôm nay|hom nay|ngày mai|ngay mai|ngày kia|ngay kia|tối nay|toi nay|sáng mai|sang mai|chiều nay|chieu nay|cuối tuần này|cuoi tuan nay|tuần này|tuan nay)\b",
            string.Empty)
            .Trim();

        candidate = Regex.Replace(candidate, @"\b(ở|o|tại|tai|cho|tại đây|tai day)\b", string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        return ToDisplayText(candidate);
    }

    public int? ExtractRequestedDestinationCount(string userMessage)
    {
        var normalized = NormalizeText(userMessage);
        var match = Regex.Match(normalized, @"(\d+)\s*(cái|cai|nơi|noi|điểm|diem|điểm đến|diem den)");
        if (match.Success && int.TryParse(match.Groups[1].Value, out var count))
        {
            return count;
        }

        return null;
    }

    // ──────────────────────────────────────────────
    // HOTEL NAME EXTRACTION
    // ──────────────────────────────────────────────

    public string? TryExtractSelectedHotelName(string message, List<ChatHistoryItemDto> history)
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

    // ──────────────────────────────────────────────
    // TEXT NORMALIZATION UTILITIES
    // ──────────────────────────────────────────────

    public static string NormalizeText(string text)
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

    public static string ToDisplayText(string normalizedText)
    {
        var canonical = TryCanonicalizeLocationName(normalizedText);
        if (!string.IsNullOrWhiteSpace(canonical))
        {
            return canonical;
        }

        return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(normalizedText.Trim());
    }

    public static string? TryCanonicalizeLocationName(string? rawText)
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
            "nha trang"
                => "Nha Trang",
            "ha long" or "vinh ha long"
                => "Hạ Long",
            "hoi an"
                => "Hội An",
            "hue" or "tp hue"
                => "Huế",
            "vung tau"
                => "Vũng Tàu",
            "quy nhon"
                => "Quy Nhơn",
            _ => null
        };
    }

    public static bool ContainsAny(string text, params string[] keywords)
    {
        return keywords.Any(keyword => text.Contains(keyword, StringComparison.OrdinalIgnoreCase));
    }

    // ──────────────────────────────────────────────
    // PRIVATE HELPERS
    // ──────────────────────────────────────────────

    private static string? ExtractHotelNameFromMessage(string normalizedMessage)
    {
        var match = Regex.Match(
            normalizedMessage,
            @"(?:khách sạn|hotel|resort|homestay)\s+([\p{L}\p{N}\s]+?)(?=(?:\s+(?:ở|o|tại|tai|giá|gia|bao nhiêu|bao nhieu|phòng|phong)\b)|[,\.\n]|$)");

        if (match.Success)
        {
            var candidate = match.Groups[1].Value.Trim();
            // Filter out generic words that are not hotel names
            if (!string.IsNullOrWhiteSpace(candidate)
                && candidate.Length > 3
                && !ContainsAny(candidate, "tot", "dep", "re", "nhat", "phu hop", "nao", "o"))
            {
                return ToDisplayText(candidate);
            }
        }

        return null;
    }

    private static string? ExtractDepartureDate(string normalizedMessage)
    {
        var match = Regex.Match(normalizedMessage, @"(\d{4})-(\d{2})-(\d{2})");
        if (match.Success)
        {
            return match.Value;
        }

        var dmMatch = Regex.Match(normalizedMessage, @"(\d{1,2})/(\d{1,2})(?:/(\d{4}))?");
        if (dmMatch.Success)
        {
            var day = dmMatch.Groups[1].Value;
            var month = dmMatch.Groups[2].Value;
            var year = dmMatch.Groups[3].Success ? dmMatch.Groups[3].Value : DateTime.Now.Year.ToString();
            return $"{year}-{month.PadLeft(2, '0')}-{day.PadLeft(2, '0')}";
        }

        if (Regex.IsMatch(normalizedMessage, @"\b(?:hôm nay|hom nay)\b"))
        {
            return DateTime.UtcNow.ToString("yyyy-MM-dd");
        }
        
        if (Regex.IsMatch(normalizedMessage, @"\b(?:ngày mai|ngay mai|mai)\b"))
        {
            return DateTime.UtcNow.AddDays(1).ToString("yyyy-MM-dd");
        }

        if (Regex.IsMatch(normalizedMessage, @"\b(?:ngày kia|ngay kia|mốt|mot|ngày mốt|ngay mot)\b"))
        {
            return DateTime.UtcNow.AddDays(2).ToString("yyyy-MM-dd");
        }

        return null;
    }

    private static string? ExtractChoiceCandidate(string normalizedMessage)
    {
        var match = Regex.Match(
            normalizedMessage,
            @"(?:chọn|chon|đổi sang|doi sang|lấy|lay|muốn ở|muon o|book|đặt|dat)\s+([\p{L}\p{N}\s]+)$");

        return match.Success ? match.Groups[1].Value.Trim() : null;
    }
}
