using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;
using SmartTrip.Domain.Entities;

namespace SmartTrip.Application.Services.Chat;

/// <summary>
/// Layer 2 — Database-first data retrieval with location guardrails.
/// Core principle: NEVER guess when the DB can be queried.
/// NEVER return results from a different location than what the user asked for.
/// </summary>
public class KnowledgeService
{
    private readonly IChatRepository _chatRepo;

    public KnowledgeService(IChatRepository chatRepo)
    {
        _chatRepo = chatRepo;
    }

    // ──────────────────────────────────────────────
    // LOCATION RESOLUTION WITH GUARDRAIL
    // ──────────────────────────────────────────────

    /// <summary>
    /// Resolves location against DB destinations.
    /// Returns exact matches if found.
    /// If no match: returns empty matches + nearby alternatives for suggestions.
    /// NEVER falls back to user preference or random destinations.
    /// </summary>
    public async Task<LocationMatchResult> ResolveLocation(
        string? locationName,
        ChatEntitiesDto? entities)
    {
        var requestedLocation = locationName ?? entities?.Destination;
        var result = new LocationMatchResult
        {
            RequestedLocation = requestedLocation
        };

        var destinations = await _chatRepo.GetDestinationsAsync(20);
        result.AllDestinations = destinations;

        if (string.IsNullOrWhiteSpace(requestedLocation))
        {
            // No specific location requested — don't match anything
            result.ExactMatches = [];
            return result;
        }

        // Step 1: Exact match
        var normalizedRequest = EntityExtractor.NormalizeText(requestedLocation);
        var exactMatches = destinations
            .Where(d =>
            {
                var normalizedName = EntityExtractor.NormalizeText(d.Name);
                return normalizedName.Contains(normalizedRequest, StringComparison.Ordinal)
                    || normalizedRequest.Contains(normalizedName, StringComparison.Ordinal);
            })
            .DistinctBy(d => d.Id)
            .ToList();

        result.ExactMatches = exactMatches;

        // Step 2: If no match, suggest popular alternatives (but DON'T use them as results)
        if (exactMatches.Count == 0)
        {
            result.NearbyAlternatives = destinations
                .Where(d => d.IsHot == true)
                .Take(3)
                .ToList();
        }

        return result;
    }

    // ──────────────────────────────────────────────
    // INTENT-BASED DB QUERY DISPATCHER
    // ──────────────────────────────────────────────

    public async Task<KnowledgeResult> QueryByIntent(
        string intent,
        LocationMatchResult location,
        ChatEntitiesDto? entities)
    {
        return intent switch
        {
            "hotel_query" => await QueryHotels(location, entities),
            "bus_query" => await QueryBusSchedules(location, entities),
            "promotion_query" => await QueryPromotions(),
            "budget_query" => await QueryBudgetData(location, entities),
            "destination_query" => QueryDestinations(location),
            "itinerary_request" => await QueryPlanningData(location, entities),
            "package_query" => await QueryPackageData(location),
            "booking_request" => await QueryHotels(location, entities),
            _ => KnowledgeResult.Empty(intent)
        };
    }

    // ──────────────────────────────────────────────
    // HOTEL QUERY — NO FALLBACK TO OTHER LOCATIONS
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryHotels(
        LocationMatchResult location,
        ChatEntitiesDto? entities)
    {
        var result = new KnowledgeResult { Intent = "hotel_query" };

        // Case 1: User specified a hotel name
        if (!string.IsNullOrWhiteSpace(entities?.HotelName))
        {
            var allHotels = await _chatRepo.GetAvailableHotelsAsync(50);
            var normalizedHotelName = EntityExtractor.NormalizeText(entities.HotelName);
            var matched = allHotels
                .Where(h => EntityExtractor.NormalizeText(h.Name)
                    .Contains(normalizedHotelName, StringComparison.Ordinal)
                    || normalizedHotelName.Contains(
                        EntityExtractor.NormalizeText(h.Name), StringComparison.Ordinal))
                .Take(10)
                .ToList();

            result.Hotels = matched;
            result.HasData = matched.Count > 0;
            if (!result.HasData)
            {
                result.NoDataReason = $"Không tìm thấy khách sạn '{entities.HotelName}' trong hệ thống";
            }
            result.Alternatives = location.NearbyAlternatives;
            return result;
        }

        // Case 2: Location matched in DB
        if (location.IsExactMatch)
        {
            var hotels = await _chatRepo.SearchDestinationsHotelsAsync(
                location.ExactMatches.Select(d => d.Id), 10);
            result.Hotels = hotels;
            result.HasData = hotels.Count > 0;
            if (!result.HasData)
            {
                result.NoDataReason = $"Điểm đến {location.ExactMatches[0].Name} chưa có khách sạn trong hệ thống";
            }
            return result;
        }

        // Case 3: Location NOT in DB → DO NOT return hotels from other locations
        result.HasData = false;
        result.NoDataReason = $"Không tìm thấy khách sạn ở {location.RequestedLocation ?? "địa điểm này"} trong hệ thống";
        result.Alternatives = location.NearbyAlternatives;
        return result;
    }

    // ──────────────────────────────────────────────
    // BUS QUERY — FUTURE SCHEDULES ONLY
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryBusSchedules(
        LocationMatchResult location,
        ChatEntitiesDto? entities)
    {
        var result = new KnowledgeResult { Intent = "bus_query" };
        var now = DateTime.Now;

        var destinationIds = location.IsExactMatch
            ? location.ExactMatches.Select(d => d.Id)
            : Enumerable.Empty<int>();

        var routes = (await _chatRepo.GetBusSchedulesAsync(10, destinationIds))
            .Where(r => r.DepartureTime.HasValue
                && r.DepartureTime.Value.ToLocalTime() >= now)
            .OrderBy(r => r.DepartureTime)
            .ToList();

        // Filter by departure date if specified
        if (entities?.DepartureDate != null
            && DateOnly.TryParse(entities.DepartureDate, out var targetDate))
        {
            routes = routes
                .Where(r => DateOnly.FromDateTime(
                    r.DepartureTime!.Value.ToLocalTime()) == targetDate)
                .ToList();
        }

        result.BusSchedules = routes.Take(4).ToList();
        result.HasData = result.BusSchedules.Count > 0;

        if (!result.HasData)
        {
            result.NoDataReason = location.IsExactMatch
                ? $"Không tìm thấy tuyến xe phù hợp cho {location.RequestedLocation}"
                : $"Không tìm thấy tuyến xe đến {location.RequestedLocation ?? "điểm này"} trong hệ thống";
        }

        result.Alternatives = location.NearbyAlternatives;
        return result;
    }

    // ──────────────────────────────────────────────
    // PROMOTION QUERY
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryPromotions()
    {
        var result = new KnowledgeResult { Intent = "promotion_query" };
        var promotions = await _chatRepo.GetActivePromotionsAsync(5);
        result.Promotions = promotions;
        result.HasData = promotions.Count > 0;
        if (!result.HasData)
        {
            result.NoDataReason = "Hiện tại chưa có khuyến mãi đang hoạt động";
        }
        return result;
    }

    // ──────────────────────────────────────────────
    // BUDGET QUERY
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryBudgetData(
        LocationMatchResult location,
        ChatEntitiesDto? entities)
    {
        var result = new KnowledgeResult { Intent = "budget_query" };

        if (location.IsExactMatch)
        {
            var destIds = location.ExactMatches.Select(d => d.Id);
            result.Hotels = await _chatRepo.SearchDestinationsHotelsAsync(destIds, 3);
            result.BusSchedules = (await _chatRepo.GetBusSchedulesAsync(3, destIds))
                .Where(r => r.DepartureTime.HasValue
                    && r.DepartureTime.Value.ToLocalTime() >= DateTime.Now)
                .ToList();
        }
        else if (string.IsNullOrWhiteSpace(location.RequestedLocation))
        {
            result.Hotels = await _chatRepo.GetAvailableHotelsAsync(3);
            result.BusSchedules = (await _chatRepo.GetBusSchedulesAsync(3))
                .Where(r => r.DepartureTime.HasValue
                    && r.DepartureTime.Value.ToLocalTime() >= DateTime.Now)
                .ToList();
        }
        else
        {
            result.Alternatives = location.NearbyAlternatives;
            result.NoDataReason = $"Chưa có dữ liệu ngân sách cho {location.RequestedLocation} trong hệ thống";
        }

        result.Promotions = await _chatRepo.GetActivePromotionsAsync(2);
        result.HasData = (result.Hotels?.Count > 0) || (result.BusSchedules?.Count > 0);
        return result;
    }

    // ──────────────────────────────────────────────
    // DESTINATION QUERY — DB ONLY
    // ──────────────────────────────────────────────

    private static KnowledgeResult QueryDestinations(LocationMatchResult location)
    {
        var result = new KnowledgeResult { Intent = "destination_query" };

        if (location.IsExactMatch)
        {
            result.Destinations = location.ExactMatches;
            result.HasData = true;
            return result;
        }

        if (string.IsNullOrWhiteSpace(location.RequestedLocation) && location.AllDestinations.Count > 0)
        {
            result.Destinations = location.AllDestinations.Take(5).ToList();
            result.HasData = result.Destinations.Count > 0;
            return result;
        }

        result.HasData = false;
        result.NoDataReason = $"Không tìm thấy điểm đến {location.RequestedLocation ?? "này"} trong hệ thống";
        result.Alternatives = location.NearbyAlternatives;
        return result;
    }

    // ──────────────────────────────────────────────
    // PLANNING DATA — AGGREGATED DB RETRIEVAL
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryPlanningData(
        LocationMatchResult location,
        ChatEntitiesDto? entities)
    {
        var result = new KnowledgeResult { Intent = "itinerary_request" };

        if (!location.IsExactMatch)
        {
            result.HasData = false;
            result.NoDataReason = $"Chưa có dữ liệu lập kế hoạch cho {location.RequestedLocation ?? "điểm đến này"}";
            result.Alternatives = location.NearbyAlternatives;
            return result;
        }

        var destIds = location.ExactMatches.Select(d => d.Id);
        result.Destinations = location.ExactMatches;
        result.Hotels = await _chatRepo.SearchDestinationsHotelsAsync(destIds, 6);
        
        var routes = (await _chatRepo.GetBusSchedulesAsync(10, destIds))
            .Where(r => r.DepartureTime.HasValue
                && r.DepartureTime.Value.ToLocalTime() >= DateTime.Now)
            .OrderBy(r => r.DepartureTime)
            .ToList();

        if (entities?.DepartureDate != null
            && DateOnly.TryParse(entities.DepartureDate, out var targetDate))
        {
            routes = routes
                .Where(r => DateOnly.FromDateTime(
                    r.DepartureTime!.Value.ToLocalTime()) == targetDate)
                .ToList();
        }

        result.BusSchedules = routes.Take(4).ToList();
        result.Promotions = await _chatRepo.GetActivePromotionsAsync(3);

        result.HasData = result.Hotels.Count > 0 || result.BusSchedules.Count > 0;
        return result;
    }

    // ──────────────────────────────────────────────
    // PACKAGE QUERY
    // ──────────────────────────────────────────────

    private async Task<KnowledgeResult> QueryPackageData(LocationMatchResult location)
    {
        var result = new KnowledgeResult { Intent = "package_query" };

        if (location.IsExactMatch)
        {
            result.Destinations = location.ExactMatches;
        }
        else if (string.IsNullOrWhiteSpace(location.RequestedLocation))
        {
            result.Destinations = location.AllDestinations.Take(5).ToList();
        }
        else
        {
            result.Alternatives = location.NearbyAlternatives;
            result.NoDataReason = $"Chưa có gói du lịch cho {location.RequestedLocation} trong hệ thống";
        }

        result.Promotions = await _chatRepo.GetActivePromotionsAsync(2);
        result.HasData = result.Destinations.Count > 0;
        return result;
    }

    // ──────────────────────────────────────────────
    // DATABASE CONTEXT STRING BUILDER (for AI prompt)
    // ──────────────────────────────────────────────

    /// <summary>
    /// Builds a human-readable database context string for the AI system prompt.
    /// </summary>
    public string BuildDatabaseContextString(
        KnowledgeResult knowledge,
        ChatUserProfileDto? userProfile)
    {
        var parts = new List<string>();
        var currency = userProfile?.PreferredCurrency ?? "VND";

        if (knowledge.Destinations.Count > 0)
        {
            var destList = string.Join(", ", knowledge.Destinations.Select(d =>
                $"{d.Name}{(d.IsHot == true ? " (HOT)" : string.Empty)}"));
            parts.Add($"Điểm đến trong hệ thống: {destList}");
        }

        if (knowledge.Hotels?.Count > 0)
        {
            var hotelList = string.Join("; ", knowledge.Hotels.Select(h =>
                $"{h.Name} ({h.StarRating} sao, " +
                $"{h.Destination?.Name ?? string.Empty}, " +
                $"tu {FormatCurrency(GetLowestHotelPrice(h), currency)} / đêm)"));
            parts.Add($"Khách sạn phù hợp: {hotelList}");
        }

        if (knowledge.BusSchedules?.Count > 0)
        {
            var routeList = string.Join("; ", knowledge.BusSchedules.Select(s =>
                $"{s.FromDest?.Name ?? "?"} -> {s.ToDest?.Name ?? "?"} " +
                $"({FormatCurrency(s.Price, currency)}, " +
                $"{FormatDateTime(s.DepartureTime)})"));
            parts.Add($"Tuyến xe hiện có: {routeList}");
        }

        if (knowledge.Promotions?.Count > 0)
        {
            var promoList = string.Join("; ", knowledge.Promotions.Select(p =>
                $"{p.Code}: giảm {p.DiscountPercent?.ToString("0") ?? "0"}% " +
                $"tối đa {FormatCurrency(p.MaxDiscountAmount, currency)}"));
            parts.Add($"Khuyến mãi đang họat động: {promoList}");
        }

        return parts.Count > 0 ? string.Join("\n", parts) : string.Empty;
    }

    // ──────────────────────────────────────────────
    // STATIC HELPERS
    // ──────────────────────────────────────────────

    public static decimal? GetLowestHotelPrice(Hotel? hotel)
    {
        return hotel?.Rooms
            .Where(room => room.PricePerNight.HasValue)
            .Select(room => room.PricePerNight)
            .Min();
    }

    public static string FormatCurrency(decimal? amount, string? currency = "VND")
    {
        if (!amount.HasValue)
        {
            return "liên hệ";
        }

        if (string.Equals(currency, "USD", StringComparison.OrdinalIgnoreCase))
        {
            var usdAmount = decimal.Round(amount.Value / 25000m, 0, MidpointRounding.AwayFromZero);
            return $"~{usdAmount:N0} USD";
        }

        return $"{amount.Value:N0} VND";
    }

    public static string FormatDateTime(DateTime? dateTime)
    {
        return dateTime.HasValue
            ? dateTime.Value.ToLocalTime().ToString("dd/MM HH:mm")
            : "chưa cập nhật";
    }
}

// ──────────────────────────────────────────────
// RESULT MODELS
// ──────────────────────────────────────────────

public class LocationMatchResult
{
    public List<Destination> ExactMatches { get; set; } = [];
    public List<Destination> NearbyAlternatives { get; set; } = [];
    public List<Destination> AllDestinations { get; set; } = [];
    public bool IsExactMatch => ExactMatches.Count > 0;
    public string? RequestedLocation { get; set; }
}

public class KnowledgeResult
{
    public string Intent { get; set; } = "general";
    public bool HasData { get; set; }
    public string? NoDataReason { get; set; }

    public List<Destination> Destinations { get; set; } = [];
    public List<Hotel>? Hotels { get; set; }
    public List<BusSchedule>? BusSchedules { get; set; }
    public List<Promotion>? Promotions { get; set; }
    public List<Destination>? Alternatives { get; set; }

    public static KnowledgeResult Empty(string intent = "general")
    {
        return new KnowledgeResult { Intent = intent, HasData = false };
    }
}
