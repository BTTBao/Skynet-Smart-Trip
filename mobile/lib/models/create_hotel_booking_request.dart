class CreateHotelBookingRequest {
  const CreateHotelBookingRequest({
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.title,
    required this.checkInDate,
    required this.checkOutDate,
    required this.quantity,
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
    };
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
