import 'dart:convert';

/// Structured response from Sky Assistant backend.
class ChatResponse {
  final String text;
  final String responseType;
  final String? sessionId;
  final List<DestinationCard>? destinationCards;
  final SuggestedItinerary? suggestedItinerary;
  final List<QuickAction>? quickActions;
  final WeatherInfo? weatherInfo;
  final List<HotelCard>? hotelCards;
  final DateTime timestamp;

  ChatResponse({
    required this.text,
    this.responseType = 'text',
    this.sessionId,
    this.destinationCards,
    this.suggestedItinerary,
    this.quickActions,
    this.weatherInfo,
    this.hotelCards,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final normalizedJson = _normalizeChatPayload(json);

    return ChatResponse(
      text: normalizedJson['text'] ?? '',
      responseType: normalizedJson['responseType'] ?? 'text',
      sessionId: normalizedJson['sessionId']?.toString(),
      destinationCards: normalizedJson['destinationCards'] != null
          ? (normalizedJson['destinationCards'] as List)
              .map((e) => DestinationCard.fromJson(e))
              .toList()
          : null,
      suggestedItinerary: normalizedJson['suggestedItinerary'] != null
          ? SuggestedItinerary.fromJson(normalizedJson['suggestedItinerary'])
          : null,
      quickActions: normalizedJson['quickActions'] != null
          ? (normalizedJson['quickActions'] as List).map((e) => QuickAction.fromJson(e)).toList()
          : null,
      weatherInfo: normalizedJson['weatherInfo'] != null
          ? WeatherInfo.fromJson(normalizedJson['weatherInfo'])
          : null,
      hotelCards: normalizedJson['hotelCards'] != null
          ? (normalizedJson['hotelCards'] as List).map((e) => HotelCard.fromJson(e)).toList()
          : null,
      timestamp: normalizedJson['timestamp'] != null ? DateTime.tryParse(normalizedJson['timestamp']) : null,
    );
  }

  static Map<String, dynamic> _normalizeChatPayload(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final rawText = normalized['text'];

    if (rawText is! String) {
      return normalized;
    }

    final trimmed = rawText.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return normalized;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return normalized;
      }

      final merged = Map<String, dynamic>.from(normalized)..addAll(decoded);
      final decodedText = decoded['text'];
      final hasRichContent = (decoded['destinationCards'] is List && (decoded['destinationCards'] as List).isNotEmpty) ||
          decoded['hotelCards'] is List ||
          decoded['suggestedItinerary'] != null ||
          decoded['weatherInfo'] != null;

      if (hasRichContent && decodedText is String) {
        merged['text'] = decodedText.trim();
      }

      return merged;
    } catch (_) {
      return normalized;
    }
  }
}

// === DESTINATION CARD ===

class DestinationCard {
  final int? id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? rating;
  final String? bestSeason;
  final String? estimatedBudget;
  final bool? isHot;

  DestinationCard({
    this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.rating,
    this.bestSeason,
    this.estimatedBudget,
    this.isHot,
  });

  factory DestinationCard.fromJson(Map<String, dynamic> json) {
    return DestinationCard(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
      bestSeason: json['bestSeason'],
      estimatedBudget: json['estimatedBudget'],
      isHot: json['isHot'],
    );
  }
}

// === HOTEL CARD ===

class HotelCard {
  final int? id;
  final String name;
  final String? address;
  final int? starRating;
  final String? description;
  final double? pricePerNight;
  final String? destinationName;
  final List<String>? amenities;
  final bool? isAvailable;

  HotelCard({
    this.id,
    required this.name,
    this.address,
    this.starRating,
    this.description,
    this.pricePerNight,
    this.destinationName,
    this.amenities,
    this.isAvailable,
  });

  factory HotelCard.fromJson(Map<String, dynamic> json) {
    return HotelCard(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      starRating: json['starRating'],
      description: json['description'],
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      destinationName: json['destinationName'],
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      isAvailable: json['isAvailable'],
    );
  }
}

// === QUICK ACTION ===

class QuickAction {
  final String label;
  final String icon;
  final String actionPayload;

  const QuickAction({
    required this.label,
    this.icon = 'chat',
    required this.actionPayload,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      label: json['label'] ?? '',
      icon: json['icon'] ?? 'chat',
      actionPayload: json['actionPayload'] ?? '',
    );
  }
}

// === ITINERARY ===

class SuggestedItinerary {
  final String title;
  final String destination;
  final int totalDays;
  final String? estimatedBudget;
  final String? travelStyle;
  final List<ItineraryDay> days;

  SuggestedItinerary({
    required this.title,
    required this.destination,
    required this.totalDays,
    this.estimatedBudget,
    this.travelStyle,
    required this.days,
  });

  factory SuggestedItinerary.fromJson(Map<String, dynamic> json) {
    return SuggestedItinerary(
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      estimatedBudget: json['estimatedBudget'],
      travelStyle: json['travelStyle'],
      days: json['days'] != null
          ? (json['days'] as List).map((e) => ItineraryDay.fromJson(e)).toList()
          : [],
    );
  }
}

class ItineraryDay {
  final int dayNumber;
  final String? theme;
  final List<ItineraryActivity> activities;

  ItineraryDay({
    required this.dayNumber,
    this.theme,
    required this.activities,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      dayNumber: json['dayNumber'] ?? 0,
      theme: json['theme'],
      activities: json['activities'] != null
          ? (json['activities'] as List).map((e) => ItineraryActivity.fromJson(e)).toList()
          : [],
    );
  }
}

class ItineraryActivity {
  final String time;
  final String title;
  final String? description;
  final String icon;
  final String? estimatedCost;

  ItineraryActivity({
    required this.time,
    required this.title,
    this.description,
    this.icon = 'location',
    this.estimatedCost,
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) {
    return ItineraryActivity(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? 'location',
      estimatedCost: json['estimatedCost'],
    );
  }
}

// === WEATHER INFO ===

class WeatherInfo {
  final String location;
  final double? temperature;
  final String? condition;
  final String? icon;
  final int? humidity;
  final double? windSpeed;
  final String? travelAdvice;
  final List<WeatherForecastDay>? forecast;

  WeatherInfo({
    required this.location,
    this.temperature,
    this.condition,
    this.icon,
    this.humidity,
    this.windSpeed,
    this.travelAdvice,
    this.forecast,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      location: json['location'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
      condition: json['condition'],
      icon: json['icon'],
      humidity: json['humidity'],
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      travelAdvice: json['travelAdvice'],
      forecast: json['forecast'] != null
          ? (json['forecast'] as List).map((e) => WeatherForecastDay.fromJson(e)).toList()
          : null,
    );
  }
}

class WeatherForecastDay {
  final String day;
  final double? tempHigh;
  final double? tempLow;
  final String? condition;
  final String? icon;

  WeatherForecastDay({
    required this.day,
    this.tempHigh,
    this.tempLow,
    this.condition,
    this.icon,
  });

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) {
    return WeatherForecastDay(
      day: json['day'] ?? '',
      tempHigh: (json['tempHigh'] as num?)?.toDouble(),
      tempLow: (json['tempLow'] as num?)?.toDouble(),
      condition: json['condition'],
      icon: json['icon'],
    );
  }
}
