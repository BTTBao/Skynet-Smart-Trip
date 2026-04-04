import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import 'destination_card_bubble.dart';
import 'hotel_card_bubble.dart';
import 'itinerary_bubble.dart';
import 'weather_bubble.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == MessageSender.user;
    const primaryColor = Color(0xFF80ed99);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF0F2F5),
                child: Icon(Icons.smart_toy_outlined, size: 18, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text bubble
                _buildTextBubble(isUser, primaryColor),
                // Rich content (below text)
                if (!isUser && message.richData != null)
                  _buildRichContent(),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTextBubble(bool isUser, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? primaryColor : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isUser ? 20 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildRichContent() {
    final data = message.richData!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination cards
          if (data.destinationCards != null && data.destinationCards!.isNotEmpty)
            DestinationCardBubble(cards: data.destinationCards!),

          // Hotel cards
          if (data.hotelCards != null && data.hotelCards!.isNotEmpty)
            HotelCardBubble(cards: data.hotelCards!),

          // Itinerary
          if (data.suggestedItinerary != null)
            ItineraryBubble(itinerary: data.suggestedItinerary!),

          // Weather
          if (data.weatherInfo != null)
            WeatherBubble(weather: data.weatherInfo!),
        ],
      ),
    );
  }
}
