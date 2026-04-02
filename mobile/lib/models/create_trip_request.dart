class CreateTripRequest {
  const CreateTripRequest({
    required this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.destinationId,
    this.destinationName,
    this.status,
  });

  final int userId;
  final int? destinationId;
  final String? destinationName;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? status;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'title': title,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'status': status,
    };
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;
}
