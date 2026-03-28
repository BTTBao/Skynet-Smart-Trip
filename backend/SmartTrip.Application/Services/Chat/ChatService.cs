using SmartTrip.Application.DTOs.Chat;
using SmartTrip.Application.Interfaces.Chat;

namespace SmartTrip.Application.Services.Chat;

public class ChatService : IChatService
{
    public async Task<ChatResponseDto> GetAiResponseAsync(string userMessage)
    {
        // TRANG THÁI MOCK: Trong tương lai sẽ gọi OpenAI hoặc Gemini API tại đây
        await Task.Delay(1000); // Giả lập AI đang suy nghĩ

        string responseText = GetMockAiResponse(userMessage);

        return new ChatResponseDto
        {
            Response = responseText,
            Timestamp = DateTime.UtcNow
        };
    }

    private string GetMockAiResponse(string message)
    {
        message = message.ToLower();
        if (message.Contains("xin chào")) return "Chào bạn! Tôi là Sky, bạn cần tư vấn du lịch vùng nào hôm nay?";
        if (message.Contains("đà lạt")) return "Đà Lạt đang có hội chợ hoa rất đẹp, bạn nên đi vào cuối tuần này!";
        if (message.Contains("phú quốc")) return "Phú Quốc đang vào mùa biển đẹp nhất, lặn ngắm san hô là tuyệt nhất đấy.";
        
        return "Skynet ghi nhận yêu cầu của bạn. Tôi đang tìm kiếm thêm thông tin về '" + message + "'...";
    }
}
