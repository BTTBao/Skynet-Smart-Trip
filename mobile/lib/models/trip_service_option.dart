class TripServiceOption {
  const TripServiceOption({
    required this.serviceId,
    required this.serviceType,
    required this.title,
    this.subtitle,
    this.defaultPrice,
    this.defaultCommissionRate,
  });

  final int serviceId;
  final String serviceType;
  final String title;
  final String? subtitle;
  final double? defaultPrice;
  final double? defaultCommissionRate;

  factory TripServiceOption.fromJson(Map<String, dynamic> json) {
    return TripServiceOption(
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceType: (json['serviceType'] ?? '').toString().toUpperCase(),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble(),
      defaultCommissionRate: (json['defaultCommissionRate'] as num?)?.toDouble(),
    );
  }
}
