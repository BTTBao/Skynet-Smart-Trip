import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ChatService extends ApiService {
  Future<String> getBotResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Chat/send'),
        headers: await getHeaders(),
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        return "Sky đang gặp chút lỗi kết nối (Status: ${response.statusCode}). Bạn thử lại sau nhé!";
      }
    } catch (e) {
      return "Lỗi: Không thể kết nối tới máy chủ. ($e)";
    }
  }
}
