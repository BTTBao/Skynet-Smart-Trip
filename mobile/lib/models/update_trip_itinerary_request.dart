class UpdateTripItineraryRequest {
  final int? dayNumber;
  final int? quantity;
  final double? bookedPrice;
  final double? bookedCommissionRate;

  UpdateTripItineraryRequest({
    this.dayNumber,
    this.quantity,
    this.bookedPrice,
    this.bookedCommissionRate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (dayNumber != null) 'dayNumber': dayNumber,
      if (quantity != null) 'quantity': quantity,
      if (bookedPrice != null) 'bookedPrice': bookedPrice,
      if (bookedCommissionRate != null) 'bookedCommissionRate': bookedCommissionRate,
    };
  }
}
