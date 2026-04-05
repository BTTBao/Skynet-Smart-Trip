class ActivityHistory {
  final List<BookingHistoryItem> bookings;
  final List<HotelHistoryItem> hotels;
  final List<BusHistoryItem> buses;
  final List<PaymentHistoryItem> payments;

  const ActivityHistory({
    required this.bookings,
    required this.hotels,
    required this.buses,
    required this.payments,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      bookings: (json['bookings'] as List? ?? [])
          .map((e) => BookingHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hotels: (json['hotels'] as List? ?? [])
          .map((e) => HotelHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      buses: (json['buses'] as List? ?? [])
          .map((e) => BusHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List? ?? [])
          .map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BookingHistoryItem {
  final int tripId;
  final String title;
  final String destinationName;
  final String? startDate;
  final String? endDate;
  final double totalAmount;
  final String status;
  final String? createdAt;
  final String? invoiceNumber;

  const BookingHistoryItem({
    required this.tripId,
    required this.title,
    required this.destinationName,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.invoiceNumber,
  });

  factory BookingHistoryItem.fromJson(Map<String, dynamic> json) {
    return BookingHistoryItem(
      tripId: json['tripId'] ?? 0,
      title: json['title'] ?? '',
      destinationName: json['destinationName'] ?? '',
      startDate: json['startDate'],
      endDate: json['endDate'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: json['createdAt'],
      invoiceNumber: json['invoiceNumber'],
    );
  }
}

class HotelHistoryItem {
  final int tripId;
  final int itineraryId;
  final int serviceId;
  final String tripTitle;
  final String hotelName;
  final String address;
  final String destinationName;
  final String? checkInDate;
  final String? checkOutDate;
  final int quantity;
  final double bookedPrice;
  final String status;

  const HotelHistoryItem({
    required this.tripId,
    required this.itineraryId,
    required this.serviceId,
    required this.tripTitle,
    required this.hotelName,
    required this.address,
    required this.destinationName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.quantity,
    required this.bookedPrice,
    required this.status,
  });

  factory HotelHistoryItem.fromJson(Map<String, dynamic> json) {
    return HotelHistoryItem(
      tripId: json['tripId'] ?? 0,
      itineraryId: json['itineraryId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      tripTitle: json['tripTitle'] ?? '',
      hotelName: json['hotelName'] ?? '',
      address: json['address'] ?? '',
      destinationName: json['destinationName'] ?? '',
      checkInDate: json['checkInDate'],
      checkOutDate: json['checkOutDate'],
      quantity: json['quantity'] ?? 0,
      bookedPrice: (json['bookedPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class BusHistoryItem {
  final int tripId;
  final int itineraryId;
  final int serviceId;
  final String tripTitle;
  final String companyName;
  final String fromDestination;
  final String toDestination;
  final String? departureTime;
  final String? arrivalTime;
  final int quantity;
  final double bookedPrice;
  final String status;

  const BusHistoryItem({
    required this.tripId,
    required this.itineraryId,
    required this.serviceId,
    required this.tripTitle,
    required this.companyName,
    required this.fromDestination,
    required this.toDestination,
    required this.departureTime,
    required this.arrivalTime,
    required this.quantity,
    required this.bookedPrice,
    required this.status,
  });

  factory BusHistoryItem.fromJson(Map<String, dynamic> json) {
    return BusHistoryItem(
      tripId: json['tripId'] ?? 0,
      itineraryId: json['itineraryId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      tripTitle: json['tripTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      fromDestination: json['fromDestination'] ?? '',
      toDestination: json['toDestination'] ?? '',
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
      quantity: json['quantity'] ?? 0,
      bookedPrice: (json['bookedPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class PaymentHistoryItem {
  final int paymentId;
  final int tripId;
  final String tripTitle;
  final double amount;
  final String paymentMethod;
  final String status;
  final String? paidAt;
  final String? transactionId;
  final String? invoiceNumber;
  final String? invoicePdfUrl;

  const PaymentHistoryItem({
    required this.paymentId,
    required this.tripId,
    required this.tripTitle,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paidAt,
    required this.transactionId,
    required this.invoiceNumber,
    required this.invoicePdfUrl,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      paymentId: json['paymentId'] ?? 0,
      tripId: json['tripId'] ?? 0,
      tripTitle: json['tripTitle'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      paidAt: json['paidAt'],
      transactionId: json['transactionId'],
      invoiceNumber: json['invoiceNumber'],
      invoicePdfUrl: json['invoicePdfUrl'],
    );
  }
}
