class UpdateTripRequest {
  final String? title;
  final int? destinationId;
  final String? destinationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  UpdateTripRequest({
    this.title,
    this.destinationId,
    this.destinationName,
    this.startDate,
    this.endDate,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (destinationId != null) 'destinationId': destinationId,
      if (destinationName != null) 'destinationName': destinationName,
      if (startDate != null) 'startDate': startDate!.toIso8601String().split('T')[0],
      if (endDate != null) 'endDate': endDate!.toIso8601String().split('T')[0],
      if (status != null) 'status': status,
    };
  }
}
