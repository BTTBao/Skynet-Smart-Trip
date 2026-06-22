import 'dart:convert';

/// Structured response from Sky Assistant backend.
String _repairVietnameseText(dynamic value) {
  if (value is! String) return value?.toString() ?? '';
  if (!value.contains('Ã') && !value.contains('Ä') && !value.contains('Â') && !value.contains('Æ') && !value.contains('á')) {
    return value;
  }
  try {
    return utf8.decode(latin1.encode(value));
  } catch (_) {
    return value;
  }
}

class ChatResponse {
  final String text;
  final String responseType;
  final String? sessionId;
  final List<DestinationCard>? destinationCards;
  final SuggestedItinerary? suggestedItinerary;
  final List<QuickAction>? quickActions;
  final WeatherInfo? weatherInfo;
  final List<HotelCard>? hotelCards;
  final List<TransportCard>? transportCards;
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
    this.transportCards,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final normalizedJson = _normalizeChatPayload(json);

    return ChatResponse(
      text: _repairVietnameseText(normalizedJson['text']),
      responseType: _repairVietnameseText(normalizedJson['responseType']).isEmpty ? 'text' : _repairVietnameseText(normalizedJson['responseType']),
      sessionId: _repairVietnameseText(normalizedJson['sessionId']).isEmpty ? null : _repairVietnameseText(normalizedJson['sessionId']),
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
      transportCards: normalizedJson['transportCards'] != null
          ? (normalizedJson['transportCards'] as List)
                .map((e) => TransportCard.fromJson(e))
                .toList()
          : null,
      timestamp: normalizedJson['timestamp'] != null ? DateTime.tryParse(normalizedJson['timestamp']) : null,
    );
  }

  static Map<String, dynamic> _normalizeChatPayload(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    final decodedPayload = _tryDecodeJsonMap(normalized['text']);

    if (decodedPayload == null) {
      return normalized;
    }

    final merged = Map<String, dynamic>.from(normalized)..addAll(decodedPayload);
    final decodedText = decodedPayload['text'];

    if (decodedText is String && decodedText.trim().isNotEmpty) {
      merged['text'] = decodedText.trim();
    } else if (_hasRichContent(decodedPayload)) {
      merged['text'] = '';
    }

    return merged;
  }

  static Map<String, dynamic>? _tryDecodeJsonMap(dynamic value) {
    dynamic current = value;

    for (var attempt = 0; attempt < 2; attempt++) {
      if (current is Map) {
        return Map<String, dynamic>.from(current);
      }

      if (current is! String) {
        return null;
      }

      final trimmed = current.trim();
      if (!_looksLikeJsonObject(trimmed)) {
        return null;
      }

      try {
        current = jsonDecode(trimmed);
      } catch (_) {
        return null;
      }
    }

    if (current is Map) {
      return Map<String, dynamic>.from(current);
    }

    return null;
  }

  static bool _looksLikeJsonObject(String text) {
    return text.startsWith('{') && text.endsWith('}');
  }

  static bool _hasRichContent(Map<String, dynamic> payload) {
    return (payload['destinationCards'] is List &&
            (payload['destinationCards'] as List).isNotEmpty) ||
        (payload['hotelCards'] is List &&
            (payload['hotelCards'] as List).isNotEmpty) ||
        (payload['transportCards'] is List &&
            (payload['transportCards'] as List).isNotEmpty) ||
        payload['suggestedItinerary'] != null ||
        payload['weatherInfo'] != null;
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
      name: _repairVietnameseText(json['name']),
      description: _repairVietnameseText(json['description']),
      imageUrl: _repairVietnameseText(json['imageUrl']),
      rating: (json['rating'] as num?)?.toDouble(),
      bestSeason: _repairVietnameseText(json['bestSeason']),
      estimatedBudget: _repairVietnameseText(json['estimatedBudget']),
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
  final int? destinationId;
  final List<String>? amenities;
  final bool? isAvailable;
  final List<HotelRoomCard>? rooms;

  HotelCard({
    this.id,
    required this.name,
    this.address,
    this.starRating,
    this.description,
    this.pricePerNight,
    this.destinationName,
    this.destinationId,
    this.amenities,
    this.isAvailable,
    this.rooms,
  });

  factory HotelCard.fromJson(Map<String, dynamic> json) {
    return HotelCard(
      id: json['id'],
      name: _repairVietnameseText(json['name']),
      address: _repairVietnameseText(json['address']),
      starRating: json['starRating'],
      description: _repairVietnameseText(json['description']),
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      destinationName: _repairVietnameseText(json['destinationName']),
      destinationId: json['destinationId'],
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      isAvailable: json['isAvailable'],
      rooms: json['rooms'] != null
          ? (json['rooms'] as List)
              .map((e) => HotelRoomCard.fromJson(e))
              .toList()
          : null,
    );
  }
}

class HotelRoomCard {
  final int id;
  final String roomType;
  final double pricePerNight;
  final int capacity;
  final int availableQty;

  const HotelRoomCard({
    required this.id,
    required this.roomType,
    required this.pricePerNight,
    required this.capacity,
    required this.availableQty,
  });

  factory HotelRoomCard.fromJson(Map<String, dynamic> json) {
    return HotelRoomCard(
      id: json['id'] ?? 0,
      roomType: _repairVietnameseText(json['roomType']) ?? 'Standard',
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      capacity: json['capacity'] ?? 2,
      availableQty: json['availableQty'] ?? 0,
    );
  }
}

class TransportCard {
  final int? scheduleId;
  final int? fromDestinationId;
  final String? fromDestinationName;
  final int? toDestinationId;
  final String? toDestinationName;
  final String companyName;
  final double? price;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int? totalSeats;

  TransportCard({
    this.scheduleId,
    this.fromDestinationId,
    this.fromDestinationName,
    this.toDestinationId,
    this.toDestinationName,
    required this.companyName,
    this.price,
    this.departureTime,
    this.arrivalTime,
    this.totalSeats,
  });

  factory TransportCard.fromJson(Map<String, dynamic> json) {
    return TransportCard(
      scheduleId: json['scheduleId'],
      fromDestinationId: json['fromDestinationId'],
      fromDestinationName: json['fromDestinationName'],
      toDestinationId: json['toDestinationId'],
      toDestinationName: json['toDestinationName'],
      companyName: _repairVietnameseText(json['companyName']),
      price: (json['price'] as num?)?.toDouble(),
      departureTime: json['departureTime'] != null
          ? DateTime.tryParse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.tryParse(json['arrivalTime'])
          : null,
      totalSeats: json['totalSeats'],
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
      label: _repairVietnameseText(json['label']),
      icon: _repairVietnameseText(json['icon']).isEmpty ? 'chat' : _repairVietnameseText(json['icon']),
      actionPayload: _repairVietnameseText(json['actionPayload']),
    );
  }
}

// === ITINERARY ===

class SuggestedItinerary {
  final String title;
  final String destination;
  final int? destinationId;
  final int totalDays;
  final String? estimatedBudget;
  final String? travelStyle;
  final HotelPlanSuggestion? hotelSuggestion;
  final TransportPlanSuggestion? transportSuggestion;
  final ItineraryCostBreakdown? costBreakdown;
  final List<ItineraryDay> days;

  SuggestedItinerary({
    required this.title,
    required this.destination,
    this.destinationId,
    required this.totalDays,
    this.estimatedBudget,
    this.travelStyle,
    this.hotelSuggestion,
    this.transportSuggestion,
    this.costBreakdown,
    required this.days,
  });

  factory SuggestedItinerary.fromJson(Map<String, dynamic> json) {
    return SuggestedItinerary(
      title: _repairVietnameseText(json['title']),
      destination: _repairVietnameseText(json['destination']),
      destinationId: json['destinationId'],
      totalDays: json['totalDays'] ?? 0,
      estimatedBudget: _repairVietnameseText(json['estimatedBudget']),
      travelStyle: _repairVietnameseText(json['travelStyle']),
      hotelSuggestion: json['hotelSuggestion'] != null
          ? HotelPlanSuggestion.fromJson(json['hotelSuggestion'])
          : null,
      transportSuggestion: json['transportSuggestion'] != null
          ? TransportPlanSuggestion.fromJson(json['transportSuggestion'])
          : null,
      costBreakdown: json['costBreakdown'] != null
          ? ItineraryCostBreakdown.fromJson(json['costBreakdown'])
          : null,
      days: json['days'] != null
          ? (json['days'] as List).map((e) => ItineraryDay.fromJson(e)).toList()
          : [],
    );
  }
}

class HotelPlanSuggestion {
  final int? hotelId;
  final int? roomId;
  final String name;
  final String? roomType;
  final String? address;
  final String? destinationName;
  final double? pricePerNight;
  final int? capacity;
  final int? availableQty;

  HotelPlanSuggestion({
    this.hotelId,
    this.roomId,
    required this.name,
    this.roomType,
    this.address,
    this.destinationName,
    this.pricePerNight,
    this.capacity,
    this.availableQty,
  });

  factory HotelPlanSuggestion.fromJson(Map<String, dynamic> json) {
    return HotelPlanSuggestion(
      hotelId: json['hotelId'],
      roomId: json['roomId'],
      name: _repairVietnameseText(json['name']),
      roomType: _repairVietnameseText(json['roomType']),
      address: _repairVietnameseText(json['address']),
      destinationName: _repairVietnameseText(json['destinationName']),
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      capacity: json['capacity'],
      availableQty: json['availableQty'],
    );
  }
}

class TransportPlanSuggestion {
  final int? scheduleId;
  final int? fromDestinationId;
  final String? fromDestinationName;
  final int? toDestinationId;
  final String? toDestinationName;
  final String companyName;
  final double? price;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int? totalSeats;

  TransportPlanSuggestion({
    this.scheduleId,
    this.fromDestinationId,
    this.fromDestinationName,
    this.toDestinationId,
    this.toDestinationName,
    required this.companyName,
    this.price,
    this.departureTime,
    this.arrivalTime,
    this.totalSeats,
  });

  factory TransportPlanSuggestion.fromJson(Map<String, dynamic> json) {
    return TransportPlanSuggestion(
      scheduleId: json['scheduleId'],
      fromDestinationId: json['fromDestinationId'],
      fromDestinationName: json['fromDestinationName'],
      toDestinationId: json['toDestinationId'],
      toDestinationName: json['toDestinationName'],
      companyName: _repairVietnameseText(json['companyName']),
      price: (json['price'] as num?)?.toDouble(),
      departureTime: json['departureTime'] != null
          ? DateTime.tryParse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.tryParse(json['arrivalTime'])
          : null,
      totalSeats: json['totalSeats'],
    );
  }
}

class ItineraryCostBreakdown {
  final double? transportCost;
  final double? hotelCost;
  final double? foodCost;
  final double? activityCost;
  final double? totalCost;
  final String currency;

  ItineraryCostBreakdown({
    this.transportCost,
    this.hotelCost,
    this.foodCost,
    this.activityCost,
    this.totalCost,
    this.currency = 'VND',
  });

  factory ItineraryCostBreakdown.fromJson(Map<String, dynamic> json) {
    return ItineraryCostBreakdown(
      transportCost: (json['transportCost'] as num?)?.toDouble(),
      hotelCost: (json['hotelCost'] as num?)?.toDouble(),
      foodCost: (json['foodCost'] as num?)?.toDouble(),
      activityCost: (json['activityCost'] as num?)?.toDouble(),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'VND',
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
      theme: _repairVietnameseText(json['theme']),
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
      time: _repairVietnameseText(json['time']),
      title: _repairVietnameseText(json['title']),
      description: _repairVietnameseText(json['description']),
      icon: _repairVietnameseText(json['icon']).isEmpty ? 'location' : _repairVietnameseText(json['icon']),
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
