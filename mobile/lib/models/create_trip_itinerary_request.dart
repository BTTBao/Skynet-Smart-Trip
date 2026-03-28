class CreateTripItineraryRequest {
  const CreateTripItineraryRequest({
    required this.dayNumber,
    required this.serviceType,
    required this.serviceId,
    this.quantity = 1,
    this.bookedPrice,
    this.bookedCommissionRate,
  });

  final int dayNumber;
  final String serviceType;
  final int serviceId;
  final int quantity;
  final double? bookedPrice;
  final double? bookedCommissionRate;

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'serviceType': serviceType,
      'serviceId': serviceId,
      'quantity': quantity,
      'bookedPrice': bookedPrice,
      'bookedCommissionRate': bookedCommissionRate,
    };
  }
}
