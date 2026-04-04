/// Structured response from Sky Assistant backend.
class ChatResponse {
  final String text;
  final String responseType;
  final List<DestinationCard>? destinationCards;
  final SuggestedItinerary? suggestedItinerary;
  final List<QuickAction>? quickActions;
  final WeatherInfo? weatherInfo;
  final List<HotelCard>? hotelCards;
  final DateTime timestamp;

  ChatResponse({
    required this.text,
    this.responseType = 'text',
    this.destinationCards,
    this.suggestedItinerary,
    this.quickActions,
    this.weatherInfo,
    this.hotelCards,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      text: json['text'] ?? '',
      responseType: json['responseType'] ?? 'text',
      destinationCards: json['destinationCards'] != null
          ? (json['destinationCards'] as List).map((e) => DestinationCard.fromJson(e)).toList()
          : null,
      suggestedItinerary: json['suggestedItinerary'] != null
          ? SuggestedItinerary.fromJson(json['suggestedItinerary'])
          : null,
      quickActions: json['quickActions'] != null
          ? (json['quickActions'] as List).map((e) => QuickAction.fromJson(e)).toList()
          : null,
      weatherInfo: json['weatherInfo'] != null
          ? WeatherInfo.fromJson(json['weatherInfo'])
          : null,
      hotelCards: json['hotelCards'] != null
          ? (json['hotelCards'] as List).map((e) => HotelCard.fromJson(e)).toList()
          : null,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
    );
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

  QuickAction({
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
