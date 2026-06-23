using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.API.Utilities;

public class ChatbotEvalRunner
{
    private readonly IChatService _chatService;
    private readonly IGrokAiService _aiService;

    public ChatbotEvalRunner(IChatService chatService, IGrokAiService aiService)
    {
        _chatService = chatService;
        _aiService = aiService;
    }

    public async Task RunEvaluationAsync()
    {
        Console.WriteLine("======================================================================");
        Console.WriteLine("🚀 BẮT ĐẦU ĐÁNH GIÁ CHẤT LƯỢNG CHATBOT DU LỊCH (35 KỊCH BẢN)");
        Console.WriteLine("======================================================================");

        var testCases = GetTestCases();
        var results = new List<EvalResult>();
        int count = 0;

        foreach (var tc in testCases)
        {
            count++;
            Console.Write($"[{count}/{testCases.Count}] Đang chạy câu hỏi: \"{tc.Question}\"...");

            var sw = Stopwatch.StartNew();
            ChatResponseDto? response = null;
            ChatIntentResultDto? classification = null;
            bool isJsonValid = false;
            bool isFallbackUsed = false;
            string? errorMsg = null;

            try
            {
                // Gọi API phân loại ý định độc lập để kiểm định (Phase 1)
                classification = await _aiService.ClassifyIntentAsync(tc.Question, new List<ChatHistoryItemDto>());

                // Gọi toàn bộ luồng ChatService
                response = await _chatService.GetAiResponseAsync(new ChatRequestDto
                {
                    Message = tc.Question,
                    UserId = 1, // Demo User ID
                    SessionId = "eval-session-123",
                    Latitude = 16.047079, // Đà Nẵng
                    Longitude = 108.206230
                });

                sw.Stop();

                // Kiểm định tính hợp lệ của cấu trúc phản hồi
                isFallbackUsed = response.Text?.StartsWith("Sky dang tam thoi", StringComparison.OrdinalIgnoreCase) == true
                    || response.Text?.StartsWith("Minh co the giup ban", StringComparison.OrdinalIgnoreCase) == true;

                // Kiểm định xem có parse được payload tương ứng với ResponseType không
                isJsonValid = ValidateResponsePayload(response);
            }
            catch (Exception ex)
            {
                sw.Stop();
                errorMsg = ex.Message;
                isFallbackUsed = true;
                isJsonValid = false;
            }

            var actualIntent = classification?.Intent ?? "Unknown";
            var intentMatched = string.Equals(actualIntent, tc.ExpectedIntent, StringComparison.OrdinalIgnoreCase);

            var result = new EvalResult
            {
                Question = tc.Question,
                ExpectedIntent = tc.ExpectedIntent,
                ActualIntent = actualIntent,
                IntentMatched = intentMatched,
                LatencyMs = (int)sw.ElapsedMilliseconds,
                IsJsonValid = isJsonValid,
                IsFallbackUsed = isFallbackUsed,
                ErrorMessage = errorMsg
            };

            results.Add(result);
            Console.WriteLine(intentMatched ? " ✅ ĐÚNG Ý ĐỊNH" : $" ❌ SAI Ý ĐỊNH (Kỳ vọng: {tc.ExpectedIntent}, Thực tế: {actualIntent})");
        }

        PrintSummaryReport(results);
    }

    private bool ValidateResponsePayload(ChatResponseDto response)
    {
        if (response == null) return false;

        switch (response.ResponseType?.ToLower())
        {
            case "hotel_list":
                return response.HotelCards != null && response.HotelCards.Any();
            case "transport_list":
                return response.TransportCards != null && response.TransportCards.Any();
            case "itinerary":
                return response.SuggestedItinerary != null && response.SuggestedItinerary.Days != null;
            case "destination_card":
                return response.DestinationCards != null && response.DestinationCards.Any();
            case "weather":
                // Thời tiết có thể có weatherInfo hoặc fallback text
                return response.Text != null;
            default:
                return !string.IsNullOrEmpty(response.Text);
        }
    }

    private void PrintSummaryReport(List<EvalResult> results)
    {
        Console.WriteLine("\n======================================================================");
        Console.WriteLine("📊 BÁO CÁO TỔNG HỢP KẾT QUẢ ĐÁNH GIÁ CHATBOT");
        Console.WriteLine("======================================================================");

        int total = results.Count;
        int correctIntents = results.Count(r => r.IntentMatched);
        int validJson = results.Count(r => r.IsJsonValid);
        int fallbackUsed = results.Count(r => r.IsFallbackUsed);
        double avgLatency = results.Average(r => r.LatencyMs);

        double intentAccuracy = (double)correctIntents / total * 100;
        double jsonSuccessRate = (double)validJson / total * 100;
        double fallbackRate = (double)fallbackUsed / total * 100;

        Console.WriteLine($"| Tổng số kịch bản test : {total,-43} |");
        Console.WriteLine($"| Độ chính xác Ý định  : {intentAccuracy:F2}% ({correctIntents}/{total}){"",-29} |");
        Console.WriteLine($"| Hợp lệ Cấu trúc JSON : {jsonSuccessRate:F2}% ({validJson}/{total}){"",-29} |");
        Console.WriteLine($"| Tỷ lệ kích hoạt Fallback : {fallbackRate:F2}% ({fallbackUsed}/{total}){"",-28} |");
        Console.WriteLine($"| Độ trễ trung bình    : {avgLatency:F2} ms{"",-38} |");
        Console.WriteLine("----------------------------------------------------------------------");

        Console.WriteLine("\nChi tiết các trường hợp sai lệch hoặc lỗi:");
        var failures = results.Where(r => !r.IntentMatched || !r.IsJsonValid || r.IsFallbackUsed).ToList();
        if (!failures.Any())
        {
            Console.WriteLine("🎉 Tuyệt vời! Không có trường hợp lỗi nào.");
        }
        else
        {
            foreach (var f in failures)
            {
                Console.WriteLine($"- Câu hỏi: \"{f.Question}\"");
                Console.WriteLine($"  * Ý định kỳ vọng: {f.ExpectedIntent} | Thực tế: {f.ActualIntent}");
                Console.WriteLine($"  * Hợp lệ JSON: {f.IsJsonValid} | Kích hoạt Fallback: {f.IsFallbackUsed} | Độ trễ: {f.LatencyMs}ms");
                if (f.ErrorMessage != null)
                {
                    Console.WriteLine($"  * Lỗi ngoại lệ: {f.ErrorMessage}");
                }
                Console.WriteLine();
            }
        }
        Console.WriteLine("======================================================================\n");
    }

    private List<TestCase> GetTestCases()
    {
        return new List<TestCase>
        {
            // 1. Hotel Query (Khách sạn)
            new("tìm khách sạn ở đà nẵng", "hotel_query"),
            new("phòng khách sạn 3 sao tại vũng tàu", "hotel_query"),
            new("có khách sạn nào gần biển nha trang không", "hotel_query"),
            new("khách sạn mường thanh đà lạt giá bao nhiêu", "hotel_query"),
            new("kiếm homestay đẹp ở sapa", "hotel_query"),

            // 2. Bus Query (Tuyến xe)
            new("tìm vé xe limousine từ hà nội đi sapa", "bus_query"),
            new("có chuyến xe nào từ sài gòn đi đà lạt ngày mai không", "bus_query"),
            new("lịch xe chạy từ huế vào đà nẵng", "bus_query"),
            new("giá vé xe khách đi nha trang bao nhiêu", "bus_query"),
            new("tuyến limousine sài gòn vũng tàu", "bus_query"),

            // 3. Weather Query (Thời tiết)
            new("thời tiết phú quốc hôm nay thế nào", "weather_query"),
            new("ngày mai đà nẵng có mưa không", "weather_query"),
            new("nhiệt độ sapa lúc này là bao nhiêu", "weather_query"),
            new("cuối tuần này sài gòn có nắng không", "weather_query"),
            new("dự báo thời tiết hà nội 3 ngày tới", "weather_query"),

            // 4. Itinerary Request (Lập lịch trình)
            new("lên kế hoạch đi nha trang 3 ngày 2 đêm từ sài gòn ngân sách 5 triệu cho 2 người", "itinerary_request"),
            new("lập lịch trình đi sapa 2 ngày cho gia đình khởi hành từ hà nội", "itinerary_request"),
            new("lên plan đi đà lạt tự túc 3 ngày", "itinerary_request"),
            new("thiết kế chuyến đi phú quốc 4 ngày 3 đêm cho cặp đôi", "itinerary_request"),
            new("lên lịch trình du lịch vũng tàu cuối tuần này", "itinerary_request"),

            // 5. Promotion Query (Khuyến mãi)
            new("có mã giảm giá nào đang chạy không", "promotion_query"),
            new("tìm khuyến mãi đặt phòng khách sạn", "promotion_query"),
            new("app có voucher ưu đãi nào cho người mới không", "promotion_query"),
            new("mã giảm giá xe limousine", "promotion_query"),

            // 6. Budget Query (Ngân sách)
            new("đi du lịch tự túc phú quốc hết khoảng bao nhiêu tiền", "budget_query"),
            new("hướng dẫn đi đà nẵng tiết kiệm nhất", "budget_query"),
            new("ngân sách khoảng 3 triệu đi đâu chơi được", "budget_query"),
            new("chi phí đi sapa 3 ngày 2 đêm tự túc", "budget_query"),

            // 7. Destination Query (Điểm đến gợi ý)
            new("hè này nên đi du lịch ở đâu tránh nóng", "destination_query"),
            new("gợi ý 3 điểm đến đẹp nhất miền trung", "destination_query"),
            new("những địa điểm tham quan hot nhất đà lạt", "destination_query"),

            // 8. Food Query (Ẩm thực)
            new("đến hội an thì ăn món gì ngon", "food_query"),
            new("quán ăn ngon giá rẻ ở vũng tàu", "food_query"),

            // 9. General (Nói chuyện phiếm)
            new("xin chào trợ lý ảo", "general"),
            new("cảm ơn bạn rất nhiều", "general")
        };
    }

    private class TestCase
    {
        public string Question { get; }
        public string ExpectedIntent { get; }

        public TestCase(string question, string expectedIntent)
        {
            Question = question;
            ExpectedIntent = expectedIntent;
        }
    }

    private class EvalResult
    {
        public string Question { get; set; } = null!;
        public string ExpectedIntent { get; set; } = null!;
        public string ActualIntent { get; set; } = null!;
        public bool IntentMatched { get; set; }
        public int LatencyMs { get; set; }
        public bool IsJsonValid { get; set; }
        public bool IsFallbackUsed { get; set; }
        public string? ErrorMessage { get; set; }
    }
}
