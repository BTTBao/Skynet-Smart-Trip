using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.Infrastructure.Services.AI;

public class GrokAiService : IGrokAiService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _baseUrl;
    private readonly string _model;
    private readonly int _maxTokens;
    private readonly ILogger<GrokAiService> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        WriteIndented = false
    };

    public GrokAiService(HttpClient httpClient, IConfiguration configuration, ILogger<GrokAiService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _apiKey = NormalizeSecret(configuration["Grok:ApiKey"]) ?? string.Empty;
        _baseUrl = (NormalizeConfigValue(configuration["Grok:BaseUrl"]) ?? "https://api.groq.com/openai/v1").TrimEnd('/');
        _model = NormalizeConfigValue(configuration["Grok:Model"]) ?? "openai/gpt-oss-120b";
        _maxTokens = int.TryParse(configuration["Grok:MaxTokens"], out var maxTokens) ? maxTokens : 2048;
    }

    public async Task<ChatResponseDto> GenerateResponseAsync(ChatContextDto context)
    {
        if (string.IsNullOrWhiteSpace(_apiKey)
            || _apiKey == "YOUR_GROK_API_KEY"
            || _apiKey == "YOUR_GROQ_API_KEY")
        {
            return BuildFallbackResponse(context);
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/chat/completions");
            request.Headers.Authorization = new("Bearer", _apiKey);
            request.Headers.Accept.ParseAdd("application/json");
            request.Content = new StringContent(
                JsonSerializer.Serialize(BuildRequestBody(context), JsonOptions),
                Encoding.UTF8,
                "application/json");

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Groq API error: {StatusCode} - {Body}", response.StatusCode, responseBody);
                return BuildFallbackResponse(context);
            }

            return ParseGrokResponse(responseBody, context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Groq API");
            return BuildFallbackResponse(context);
        }
    }

    private object BuildRequestBody(ChatContextDto context)
    {
        var messages = new List<object>
        {
            new
            {
                role = "system",
                content = BuildSystemPrompt(context)
            }
        };

        foreach (var item in context.ConversationHistory.TakeLast(10))
        {
            messages.Add(new
            {
                role = item.Role == "user" ? "user" : "assistant",
                content = item.Content
            });
        }

        messages.Add(new
        {
            role = "user",
            content = BuildUserPrompt(context)
        });

        return new
        {
            model = _model,
            messages,
            temperature = 0.7,
            max_tokens = _maxTokens
        };
    }

    private string BuildSystemPrompt(ChatContextDto context)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Ban la Sky, tro ly du lich AI cua Skynet Smart Trip.");
        sb.AppendLine("Luon tra loi bang tieng Viet, tru khi nguoi dung noi tieng Anh.");
        sb.AppendLine("Tra loi bang JSON hop le theo schema sau, khong them markdown:");
        sb.AppendLine(@"{
  ""text"": ""Noi dung tra loi chinh"",
  ""responseType"": ""text|destination_card|itinerary|hotel_list|weather"",
  ""destinationCards"": [{ ""name"": """", ""description"": """", ""rating"": 4.5, ""bestSeason"": """", ""estimatedBudget"": """", ""isHot"": false }],
  ""suggestedItinerary"": { ""title"": """", ""destination"": """", ""totalDays"": 3, ""estimatedBudget"": """", ""days"": [{ ""dayNumber"": 1, ""theme"": """", ""activities"": [{ ""time"": ""08:00"", ""title"": """", ""description"": """", ""icon"": ""restaurant|attraction|transport|hotel|shopping|entertainment"", ""estimatedCost"": """" }] }] },
  ""hotelCards"": [{ ""name"": """", ""address"": """", ""starRating"": 4, ""description"": """", ""pricePerNight"": 500000, ""destinationName"": """", ""amenities"": [""WiFi"", ""Pool""] }],
  ""quickActions"": [{ ""label"": ""Goi y text"", ""icon"": ""explore|hotel|restaurant|calendar|weather|map"", ""actionPayload"": ""Cau gui khi user tap"" }]
}");
        sb.AppendLine("Lua chon responseType dung voi ngu canh va luon kem 2-4 quickActions.");
        sb.AppendLine("Nhan quick action co the ngan gon, nhung actionPayload phai la cau tieng Viet tu nhien ma nguoi dung thuc su se gui.");
        sb.AppendLine("Tuyet doi khong tra ve ma ky thuat, token noi bo, hay chuoi dang SHOW_DETAILS_HOIAN, OPEN_HOTEL, DETAIL_ID_123.");
        sb.AppendLine("Ngu gon, huu ich, mang goc nhin local guide Viet Nam.");

        if (!string.IsNullOrWhiteSpace(context.DatabaseContext))
        {
            sb.AppendLine();
            sb.AppendLine("DATABASE CONTEXT:");
            sb.AppendLine(context.DatabaseContext);
        }

        return sb.ToString();
    }

    private string BuildUserPrompt(ChatContextDto context)
    {
        var sb = new StringBuilder(context.UserMessage);

        if (!string.IsNullOrWhiteSpace(context.DetectedIntent))
        {
            sb.AppendLine();
            sb.AppendLine($"[Intent detected: {context.DetectedIntent}]");
        }

        return sb.ToString();
    }

    private ChatResponseDto ParseGrokResponse(string responseBody, ChatContextDto context)
    {
        try
        {
            using var doc = JsonDocument.Parse(responseBody);
            var content = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString() ?? string.Empty;
            var normalizedContent = NormalizeModelContent(content);

            try
            {
                var structured = JsonSerializer.Deserialize<ChatResponseDto>(normalizedContent, JsonOptions);
                if (structured != null)
                {
                    structured.Timestamp = DateTime.UtcNow;
                    structured.QuickActions ??= BuildDefaultQuickActions();
                    if (structured.QuickActions.Count == 0)
                    {
                        structured.QuickActions = BuildDefaultQuickActions();
                    }

                    return structured;
                }
            }
            catch (JsonException)
            {
                // Wrap plain text below.
            }

            return new ChatResponseDto
            {
                Text = normalizedContent,
                ResponseType = "text",
                QuickActions = BuildDefaultQuickActions(),
                Timestamp = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error parsing Groq response");
            return BuildFallbackResponse(context);
        }
    }

    private ChatResponseDto BuildFallbackResponse(ChatContextDto context)
    {
        var responseType = context.DetectedIntent switch
        {
            "destination_query" => "destination_card",
            "hotel_query" => "hotel_list",
            "weather_query" => "weather",
            "itinerary_request" => "itinerary",
            _ => "text"
        };

        return new ChatResponseDto
        {
            Text = BuildFriendlyFallbackText(context),
            ResponseType = responseType,
            QuickActions = BuildDefaultQuickActions(),
            Timestamp = DateTime.UtcNow
        };
    }

    private static string NormalizeModelContent(string content)
    {
        var trimmed = content.Trim();

        if (trimmed.StartsWith("```", StringComparison.Ordinal))
        {
            trimmed = trimmed
                .Replace("```json", string.Empty, StringComparison.OrdinalIgnoreCase)
                .Replace("```", string.Empty, StringComparison.OrdinalIgnoreCase)
                .Trim();
        }

        return trimmed;
    }

    private static string BuildFriendlyFallbackText(ChatContextDto context)
    {
        return context.DetectedIntent switch
        {
            "promotion_query" => "Minh dang chuyen sang che do tra loi tu du lieu he thong de goi y khuyen mai cho ban.",
            "bus_query" => "Minh dang chuyen sang du lieu he thong de tim tuyen xe phu hop cho ban.",
            "hotel_query" => "Minh dang lay nhanh danh sach khach san phu hop tu he thong.",
            "itinerary_request" => "Minh dang dung du lieu san co de lap lich trinh tham khao cho ban.",
            "budget_query" => "Minh dang tong hop chi phi tham khao tu du lieu he thong cho ban.",
            _ => "Minh dang su dung du lieu san co cua he thong de ho tro ban ngay luc nay."
        };
    }

    private static List<QuickActionDto> BuildDefaultQuickActions()
    {
        return new List<QuickActionDto>
        {
            new() { Label = "Goi y diem den", Icon = "explore", ActionPayload = "Goi y diem den dep o Viet Nam" },
            new() { Label = "Lap lich trinh", Icon = "calendar", ActionPayload = "Lap lich trinh du lich cho toi" },
            new() { Label = "Tim khach san", Icon = "hotel", ActionPayload = "Tim khach san tot nhat" }
        };
    }

    private static string? NormalizeConfigValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim().Trim('"');
    }

    private static string? NormalizeSecret(string? value)
    {
        var normalized = NormalizeConfigValue(value);
        if (normalized == null)
        {
            return null;
        }

        return normalized.Replace(" ", string.Empty);
    }
}
