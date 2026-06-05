class CreateHotelBookingRequest {
  const CreateHotelBookingRequest({
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.title,
    required this.checkInDate,
    required this.checkOutDate,
    required this.quantity,
    this.adultCount = 1,
    this.childCount = 0,
    this.infantCount = 0,
    this.destinationId,
    this.destinationName,
  });

  final int userId;
  final int hotelId;
  final int roomId;
  final int? destinationId;
  final String? destinationName;
  final String title;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int quantity;
  final int adultCount;
  final int childCount;
  final int infantCount;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'title': title,
      'checkInDate': _formatDate(checkInDate),
      'checkOutDate': _formatDate(checkOutDate),
      'quantity': quantity,
      'adultCount': adultCount,
      'childCount': childCount,
      'infantCount': infantCount,
    };
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
