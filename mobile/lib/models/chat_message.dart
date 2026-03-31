import 'chat_response.dart';

enum MessageSender { user, bot }
enum MessageType { text, destinationCard, itinerary, hotelList, weather, loading }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageType type;
  final ChatResponse? richData;
  final String? id;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.type = MessageType.text,
    this.richData,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  /// Create a bot message from a ChatResponse
  factory ChatMessage.fromResponse(ChatResponse response) {
    MessageType type;
    switch (response.responseType) {
      case 'destination_card':
        type = MessageType.destinationCard;
        break;
      case 'itinerary':
        type = MessageType.itinerary;
        break;
      case 'hotel_list':
        type = MessageType.hotelList;
        break;
      case 'weather':
        type = MessageType.weather;
        break;
      default:
        type = MessageType.text;
    }

    return ChatMessage(
      text: response.text,
      sender: MessageSender.bot,
      timestamp: response.timestamp,
      type: type,
      richData: response,
    );
  }
}
