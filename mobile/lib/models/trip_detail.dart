import 'trip_timeline_entry.dart';

class TripDetail {
  const TripDetail({
    required this.tripId,
    required this.title,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.destinationName,
    required this.destinationDescription,
    required this.itineraries,
    this.destinationId,
    this.totalAmount,
    this.totalProfit,
  });

  final int tripId;
  final int? destinationId;
  final String title;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String destinationName;
  final String? destinationDescription;
  final double? totalAmount;
  final double? totalProfit;
  final List<TripTimelineEntry> itineraries;

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    final itineraries = (json['itineraries'] as List<dynamic>? ?? [])
        .map((item) => TripTimelineEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) {
        final dayCompare = (a.dayNumber ?? 0).compareTo(b.dayNumber ?? 0);
        if (dayCompare != 0) {
          return dayCompare;
        }

        return (a.itineraryId ?? 0).compareTo(b.itineraryId ?? 0);
      });

    return TripDetail(
      tripId: (json['tripId'] as num?)?.toInt() ?? 0,
      destinationId: (json['destinationId'] as num?)?.toInt(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'DRAFT').toString().toUpperCase(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()) ??
          DateTime.now(),
      endDate: DateTime.tryParse((json['endDate'] ?? '').toString()) ??
          DateTime.now(),
      destinationName: (json['destinationName'] ?? 'Chua cap nhat').toString(),
      destinationDescription: json['destinationDescription']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      totalProfit: (json['totalProfit'] as num?)?.toDouble(),
      itineraries: itineraries,
    );
  }
}
