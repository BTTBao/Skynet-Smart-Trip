class UpdateTripItineraryRequest {
  final int? dayNumber;
  final int? quantity;
  final double? bookedPrice;
  final double? bookedCommissionRate;
  final DateTime? serviceDate;
  final String? departureTime;
  final String? serviceAddress;

  UpdateTripItineraryRequest({
    this.dayNumber,
    this.quantity,
    this.bookedPrice,
    this.bookedCommissionRate,
    this.serviceDate,
    this.departureTime,
    this.serviceAddress,
  });

  Map<String, dynamic> toJson() {
    final date = serviceDate;
    final dateText = date == null
        ? null
        : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return {
      if (dayNumber != null) 'dayNumber': dayNumber,
      if (quantity != null) 'quantity': quantity,
      if (bookedPrice != null) 'bookedPrice': bookedPrice,
      if (bookedCommissionRate != null) 'bookedCommissionRate': bookedCommissionRate,
      if (dateText != null) 'serviceDate': dateText,
      if ((departureTime ?? '').trim().isNotEmpty) 'departureTime': departureTime,
      if (serviceAddress != null) 'serviceAddress': serviceAddress,
    };
  }
}
