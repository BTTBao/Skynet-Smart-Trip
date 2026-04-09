class CreateTripItineraryRequest {
  const CreateTripItineraryRequest({
    required this.dayNumber,
    required this.serviceType,
    required this.serviceId,
    this.quantity = 1,
    this.bookedPrice,
    this.bookedCommissionRate,
    this.serviceDate,
    this.departureTime,
    this.serviceAddress,
  });

  final int dayNumber;
  final String serviceType;
  final int serviceId;
  final int quantity;
  final double? bookedPrice;
  final double? bookedCommissionRate;
  final DateTime? serviceDate;
  final String? departureTime;
  final String? serviceAddress;

  Map<String, dynamic> toJson() {
    final date = serviceDate;
    final dateText = date == null
        ? null
        : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return {
      'dayNumber': dayNumber,
      'serviceType': serviceType,
      'serviceId': serviceId,
      'quantity': quantity,
      'bookedPrice': bookedPrice,
      'bookedCommissionRate': bookedCommissionRate,
      if (dateText != null) 'serviceDate': dateText,
      if ((departureTime ?? '').trim().isNotEmpty) 'departureTime': departureTime,
      if ((serviceAddress ?? '').trim().isNotEmpty) 'serviceAddress': serviceAddress,
    };
  }
}
