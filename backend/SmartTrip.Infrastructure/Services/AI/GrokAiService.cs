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

    public async Task<ChatResponseDto> GenerateResponseWithJsonModeAsync(ChatContextDto context)
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
                JsonSerializer.Serialize(BuildRequestBody(context, forceJsonMode: true), JsonOptions),
                Encoding.UTF8,
                "application/json");

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Groq API error (JSON Mode): {StatusCode} - {Body}", response.StatusCode, responseBody);
                return BuildFallbackResponse(context);
            }

            return ParseGrokResponse(responseBody, context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Groq API in JSON Mode");
            return BuildFallbackResponse(context);
        }
    }

    public async Task<ChatIntentResultDto> ClassifyIntentAsync(string message, List<ChatHistoryItemDto> history)
    {
        if (string.IsNullOrWhiteSpace(_apiKey)
            || _apiKey == "YOUR_GROK_API_KEY"
            || _apiKey == "YOUR_GROQ_API_KEY")
        {
            return new ChatIntentResultDto { Intent = "general" };
        }

        try
        {
            var systemPrompt = @"Phân tích tin nhắn của người dùng và lịch sử chat để xác định ý định (intent) của họ và trích xuất các thông tin tham số (entities).

QUAN TRỌNG — QUY TẮC PHÂN LOẠI INTENT:
1. Luôn xác định intent DỰA TRÊN câu hỏi HIỆN TẠI của người dùng, KHÔNG phải lịch sử.
2. KHÔNG BAO GIỜ tự ý đổi intent thành itinerary_request chỉ vì lịch sử có lập kế hoạch.
3. Nếu người dùng hỏi về khách sạn → hotel_query, bất kể trước đó họ đang làm gì.
4. Nếu người dùng hỏi về xe → bus_query, bất kể trước đó họ đang làm gì.
5. Lịch sử chỉ dùng để bổ sung entities (ví dụ: destination từ câu trước), KHÔNG dùng để thay đổi intent.

Hãy chọn MỘT intent phù hợp nhất từ danh sách sau:
- package_query (nếu muốn hỏi tour du lịch trọn gói, combo)
- budget_query (hỏi về chi phí, ngân sách du lịch, giá rẻ, bao nhiêu tiền)
- promotion_query (tìm mã giảm giá, voucher, ưu đãi)
- bus_query (tìm vé xe khách, xe limousine, lịch xe chạy)
- hotel_query (tìm chỗ nghỉ, phòng khách sạn, homestay, resort)
- weather_query (hỏi thời tiết nắng mưa nhiệt độ)
- itinerary_request (yêu cầu lập kế hoạch/lịch trình chi tiết)
- destination_query (hỏi gợi ý đi đâu chơi, địa điểm hot nhất, cảnh đẹp)
- nearby_query (tìm địa điểm ăn uống, vui chơi xung quanh vị trí hiện tại)
- booking_request (yêu cầu đặt phòng khách sạn hoặc vé xe cụ thể)
- food_query (hỏi ăn gì ở đâu, nhà hàng, quán ăn ngon)
- general (các tin nhắn chào hỏi, cảm ơn, nói chuyện phiếm thông thường)

Trích xuất các thực thể sau nếu có nhắc đến trong câu chat hoặc ngữ cảnh gần nhất:
- destination: Điểm đến (thành phố, địa danh du lịch, ví dụ: Đà Nẵng, Nha Trang, Phú Quốc)
- origin: Điểm xuất phát (ví dụ: Hà Nội, Sài Gòn, Hải Phòng)
- days: Số ngày đi chơi (kiểu số nguyên, ví dụ: 3)
- budget: Ngân sách tối đa của người dùng (kiểu số, ví dụ: 5000000)
- passengerCount: Số lượng người đi (kiểu số nguyên, ví dụ: 2)
- hotelName: Tên khách sạn cụ thể mà họ nhắc tới
- departureDate: Ngày khởi hành (định dạng yyyy-MM-dd nếu trích xuất được)

Trả về kết quả dưới dạng một đối tượng JSON duy nhất theo schema sau, không kèm bất kỳ thẻ markdown hay giải thích nào khác:
{
  ""intent"": ""hotel_query|bus_query|weather_query|itinerary_request|promotion_query|budget_query|destination_query|general"",
  ""entities"": {
    ""destination"": null,
    ""origin"": null,
    ""days"": null,
    ""budget"": null,
    ""passengerCount"": null,
    ""hotelName"": null,
    ""departureDate"": null
  }
}";

            var messages = new List<object>
            {
                new { role = "system", content = systemPrompt }
            };

            foreach (var item in history.TakeLast(5))
            {
                messages.Add(new
                {
                    role = item.Role == "user" ? "user" : "assistant",
                    content = item.Content
                });
            }

            messages.Add(new { role = "user", content = message });

            var requestBody = new
            {
                model = _model,
                messages,
                temperature = 0.1,
                max_tokens = 500,
                response_format = new { type = "json_object" }
            };

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_baseUrl}/chat/completions");
            request.Headers.Authorization = new("Bearer", _apiKey);
            request.Headers.Accept.ParseAdd("application/json");
            request.Content = new StringContent(
                JsonSerializer.Serialize(requestBody, JsonOptions),
                Encoding.UTF8,
                "application/json");

            var response = await _httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Groq API error in ClassifyIntentAsync: {StatusCode} - {Body}", response.StatusCode, responseBody);
                return new ChatIntentResultDto { Intent = "general" };
            }

            return ParseIntentResponse(responseBody);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ClassifyIntentAsync");
            return new ChatIntentResultDto { Intent = "general" };
        }
    }

    private ChatIntentResultDto ParseIntentResponse(string responseBody)
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
            var parsed = JsonSerializer.Deserialize<ChatIntentResultDto>(normalizedContent, JsonOptions);
            return parsed ?? new ChatIntentResultDto { Intent = "general" };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error parsing intent classification response");
            return new ChatIntentResultDto { Intent = "general" };
        }
    }

    private string LoadSkillFile()
    {
        try
        {
            var assemblyPath = Path.GetDirectoryName(typeof(GrokAiService).Assembly.Location);
            var skillPath = Path.Combine(assemblyPath ?? string.Empty, "Services", "AI", "skill.md");
            if (File.Exists(skillPath))
            {
                var content = File.ReadAllText(skillPath, Encoding.UTF8);
                if (!LooksLikeMojibake(content))
                {
                    return content;
                }
            }

            var currentDir = AppContext.BaseDirectory;
            while (!string.IsNullOrEmpty(currentDir))
            {
                var checkPath = Path.Combine(currentDir, "Services", "AI", "skill.md");
                if (File.Exists(checkPath))
                {
                    var content = File.ReadAllText(checkPath, Encoding.UTF8);
                    if (!LooksLikeMojibake(content))
                    {
                        return content;
                    }
                }

                var parent = Directory.GetParent(currentDir);
                if (parent == null || parent.FullName == currentDir) break;
                currentDir = parent.FullName;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to read skill.md");
        }

        return BuildDefaultSkillPrompt();
    }

    private static bool LooksLikeMojibake(string content)
    {
        return content.Contains('\u00c3')
            || content.Contains('\u00c2')
            || content.Contains('\u00c6')
            || content.Contains('\u00c4')
            || content.Contains('\u00ba')
            || content.Contains('\u00bb');
    }

    private static string BuildDefaultSkillPrompt()
    {
        return "B\u1ea1n l\u00e0 Sky, tr\u1ee3 l\u00fd du l\u1ecbch AI c\u1ee7a Skynet Smart Trip.\n"
            + "Lu\u00f4n tr\u1ea3 l\u1eddi b\u1eb1ng ti\u1ebfng Vi\u1ec7t c\u00f3 d\u1ea5u, tr\u1eeb khi ng\u01b0\u1eddi d\u00f9ng ch\u1ee7 \u0111\u1ed9ng h\u1ecfi b\u1eb1ng ti\u1ebfng Anh.\n"
            + "Khi c\u00f3 DATABASE CONTEXT, \u01b0u ti\u00ean d\u1eef li\u1ec7u trong h\u1ec7 th\u1ed1ng v\u00e0 kh\u00f4ng b\u1ecba t\u00ean kh\u00e1ch s\u1ea1n, tuy\u1ebfn xe, gi\u00e1 ho\u1eb7c khuy\u1ebfn m\u00e3i.\n"
            + "Tr\u1ea3 v\u1ec1 m\u1ed9t JSON object h\u1ee3p l\u1ec7 duy nh\u1ea5t theo schema: text, responseType, destinationCards, suggestedItinerary, hotelCards, transportCards, weatherInfo, quickActions.\n"
            + "Kh\u00f4ng d\u00f9ng markdown, kh\u00f4ng th\u00eam gi\u1ea3i th\u00edch ngo\u00e0i JSON, v\u00e0 lu\u00f4n k\u00e8m 2-4 quickActions b\u1eb1ng ti\u1ebfng Vi\u1ec7t c\u00f3 d\u1ea5u.";
    }

    private object BuildRequestBody(ChatContextDto context, bool forceJsonMode = false)
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

        if (forceJsonMode)
        {
            return new
            {
                model = _model,
                messages,
                temperature = 0.2,
                max_tokens = _maxTokens,
                response_format = new { type = "json_object" }
            };
        }

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
        var basePrompt = LoadSkillFile();
        var sb = new StringBuilder();
        sb.AppendLine(basePrompt);

        if (string.Equals(context.PreferredLanguage, "en", StringComparison.OrdinalIgnoreCase))
        {
            sb.AppendLine("User preferred language is English. However, adhere to the language rules: only reply in English if the user messaged in English. Default is accented Vietnamese.");
        }

        sb.AppendLine($"User preferred currency: {context.PreferredCurrency}.");

        if (!string.IsNullOrWhiteSpace(context.DatabaseContext))
        {
            sb.AppendLine();
            sb.AppendLine("DATABASE CONTEXT (ƯU TIÊN DỮ LIỆU NÀY HƠN CẢ):");
            sb.AppendLine(context.DatabaseContext);
        }

        if (!string.IsNullOrWhiteSpace(context.PersonalizationSummary))
        {
            sb.AppendLine();
            sb.AppendLine("USER PROFILE CONTEXT:");
            sb.AppendLine(context.PersonalizationSummary);
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
            "promotion_query" => "\u0110\u1ec3 m\u00ecnh xem nhanh c\u00e1c \u01b0u \u0111\u00e3i ph\u00f9 h\u1ee3p cho b\u1ea1n nh\u00e9.",
            "bus_query" => "\u0110\u1ec3 m\u00ecnh t\u00ecm nhanh c\u00e1c tuy\u1ebfn xe ph\u00f9 h\u1ee3p cho b\u1ea1n nh\u00e9.",
            "hotel_query" => "\u0110\u1ec3 m\u00ecnh l\u1ecdc nhanh m\u1ed9t v\u00e0i kh\u00e1ch s\u1ea1n ph\u00f9 h\u1ee3p cho b\u1ea1n nh\u00e9.",
            "itinerary_request" => "\u0110\u1ec3 m\u00ecnh l\u00ean nhanh m\u1ed9t l\u1ecbch tr\u00ecnh tham kh\u1ea3o \u0111\u1ec3 b\u1ea1n d\u1ec5 h\u00ecnh dung h\u01a1n nh\u00e9.",
            "budget_query" => "\u0110\u1ec3 m\u00ecnh \u01b0\u1edbc t\u00ednh nhanh chi ph\u00ed tham kh\u1ea3o cho b\u1ea1n nh\u00e9.",
            _ => "\u0110\u1ec3 m\u00ecnh xem nhanh th\u00f4ng tin ph\u00f9 h\u1ee3p cho b\u1ea1n nh\u00e9."
        };
    }

    private static List<QuickActionDto> BuildDefaultQuickActions()
    {
        return new List<QuickActionDto>
        {
            new() { Label = "G\u1ee3i \u00fd \u0111i\u1ec3m \u0111\u1ebfn", Icon = "explore", ActionPayload = "G\u1ee3i \u00fd \u0111i\u1ec3m \u0111\u1ebfn \u0111\u1eb9p \u1edf Vi\u1ec7t Nam" },
            new() { Label = "L\u1eadp l\u1ecbch tr\u00ecnh", Icon = "calendar", ActionPayload = "L\u1eadp l\u1ecbch tr\u00ecnh du l\u1ecbch cho t\u00f4i" },
            new() { Label = "T\u00ecm kh\u00e1ch s\u1ea1n", Icon = "hotel", ActionPayload = "T\u00ecm kh\u00e1ch s\u1ea1n t\u1ed1t nh\u1ea5t" }
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
