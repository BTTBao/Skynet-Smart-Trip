class CreateTripItineraryRequest {
  const CreateTripItineraryRequest({
    required this.dayNumber,
    required this.serviceType,
    required this.serviceId,
    this.quantity = 1,
    this.bookedPrice,
    this.bookedCommissionRate,
    this.serviceDate,
    this.hotelCheckOutDate,
    this.departureTime,
    this.serviceAddress,
    this.selectedSeats,
    this.adultCount = 1,
    this.childCount = 0,
    this.infantCount = 0,
  });

  final int dayNumber;
  final String serviceType;
  final int serviceId;
  final int quantity;
  final double? bookedPrice;
  final double? bookedCommissionRate;
  final DateTime? serviceDate;
  final DateTime? hotelCheckOutDate;
  final String? departureTime;
  final String? serviceAddress;
  final String? selectedSeats;
  final int adultCount;
  final int childCount;
  final int infantCount;

  Map<String, dynamic> toJson() {
    final serviceDateValue = serviceDate;
    final checkOutDateValue = hotelCheckOutDate;
    final dateText = serviceDateValue == null
        ? null
        : _formatDate(serviceDateValue);
    final checkOutDateText = checkOutDateValue == null
        ? null
        : _formatDate(checkOutDateValue);

    return {
      'dayNumber': dayNumber,
      'serviceType': serviceType,
      'serviceId': serviceId,
      'quantity': quantity,
      'bookedPrice': bookedPrice,
      'bookedCommissionRate': bookedCommissionRate,
      if (dateText != null) 'serviceDate': dateText,
      if (checkOutDateText != null) 'hotelCheckOutDate': checkOutDateText,
      if ((departureTime ?? '').trim().isNotEmpty)
        'departureTime': departureTime,
      if ((serviceAddress ?? '').trim().isNotEmpty)
        'serviceAddress': serviceAddress,
      if ((selectedSeats ?? '').trim().isNotEmpty)
        'selectedSeats': selectedSeats,
      'adultCount': adultCount,
      'childCount': childCount,
      'infantCount': infantCount,
    };
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
