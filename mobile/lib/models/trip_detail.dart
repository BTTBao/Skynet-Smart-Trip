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
    final startDate = DateTime.tryParse((json['startDate'] ?? '').toString()) ??
        DateTime.now();
    final endDate = DateTime.tryParse((json['endDate'] ?? '').toString()) ??
        DateTime.now();

    final itineraries = (json['itineraries'] as List<dynamic>? ?? [])
        .map((item) => TripTimelineEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) {
        final aDate = _resolveEntryDate(a, startDate);
        final bDate = _resolveEntryDate(b, startDate);
        final dayCompare = aDate.compareTo(bDate);
        if (dayCompare != 0) {
          return dayCompare;
        }

        final aTime = _resolveMinutesOfDay(a.departureTime);
        final bTime = _resolveMinutesOfDay(b.departureTime);
        final timeCompare = aTime.compareTo(bTime);
        if (timeCompare != 0) {
          return timeCompare;
        }

        return (a.itineraryId ?? 0).compareTo(b.itineraryId ?? 0);
      });

    return TripDetail(
      tripId: (json['tripId'] as num?)?.toInt() ?? 0,
      destinationId: (json['destinationId'] as num?)?.toInt(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? 'DRAFT').toString().toUpperCase(),
      startDate: startDate,
      endDate: endDate,
      destinationName: (json['destinationName'] ?? 'Chua cap nhat').toString(),
      destinationDescription: json['destinationDescription']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      totalProfit: (json['totalProfit'] as num?)?.toDouble(),
      itineraries: itineraries,
    );
  }

  static DateTime _resolveEntryDate(TripTimelineEntry entry, DateTime tripStartDate) {
    if (entry.serviceDate != null) {
      return DateTime(
        entry.serviceDate!.year,
        entry.serviceDate!.month,
        entry.serviceDate!.day,
      );
    }

    final dayOffset = (entry.dayNumber ?? 1) - 1;
    return DateTime(
      tripStartDate.year,
      tripStartDate.month,
      tripStartDate.day,
    ).add(Duration(days: dayOffset < 0 ? 0 : dayOffset));
  }

  static int _resolveMinutesOfDay(String? time) {
    final raw = (time ?? '').trim();
    if (raw.isEmpty) {
      return 24 * 60;
    }

    final parts = raw.split(':');
    if (parts.length < 2) {
      return 24 * 60;
    }

    final hour = int.tryParse(parts[0]) ?? 24;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }
}
