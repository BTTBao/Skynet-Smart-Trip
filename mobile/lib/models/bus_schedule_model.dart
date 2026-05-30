class BusScheduleModel {
  final int id;
  final int? companyId;
  final String companyName;
  final String companyLogoUrl;
  final String companyHotline;
  final int? fromDestId;
  final String fromDestName;
  final int? toDestId;
  final String toDestName;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String duration;
  final double price;
  final int spotsLeft;
  final int totalSeats;
  final double rating;
  final int reviewCount;

  BusScheduleModel({
    required this.id,
    this.companyId,
    required this.companyName,
    required this.companyLogoUrl,
    required this.companyHotline,
    this.fromDestId,
    required this.fromDestName,
    this.toDestId,
    required this.toDestName,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.spotsLeft,
    required this.totalSeats,
    required this.rating,
    required this.reviewCount,
  });

  factory BusScheduleModel.fromJson(Map<String, dynamic> json) {
    return BusScheduleModel(
      id: json['id'] as int,
      companyId: json['companyId'] as int?,
      companyName: json['companyName'] as String? ?? 'Chưa xác định',
      companyLogoUrl: json['companyLogoUrl'] as String? ?? '',
      companyHotline: json['companyHotline'] as String? ?? '',
      fromDestId: json['fromDestId'] as int?,
      fromDestName: json['fromDestName'] as String? ?? '',
      toDestId: json['toDestId'] as int?,
      toDestName: json['toDestName'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      duration: json['duration'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      spotsLeft: json['spotsLeft'] as int? ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }
}

class BusSeatModel {
  final int id;
  final String seatNumber;
  final String status; // available, booked, locked

  BusSeatModel({
    required this.id,
    required this.seatNumber,
    required this.status,
  });

  factory BusSeatModel.fromJson(Map<String, dynamic> json) {
    return BusSeatModel(
      id: json['id'] as int,
      seatNumber: json['seatNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'available',
    );
  }

  bool get isAvailable => status == 'available';
  bool get isBooked => status == 'booked';
  bool get isLocked => status == 'locked';
}
