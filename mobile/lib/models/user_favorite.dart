class UserFavorite {
  const UserFavorite({
    required this.wishId,
    required this.itemType,
    required this.itemId,
    required this.title,
    required this.subtitle,
    this.description,
    this.priceLabel,
    this.statusLabel,
    this.createdAt,
  });

  final int wishId;
  final String itemType;
  final int itemId;
  final String title;
  final String subtitle;
  final String? description;
  final String? priceLabel;
  final String? statusLabel;
  final DateTime? createdAt;

  factory UserFavorite.fromJson(Map<String, dynamic> json) {
    return UserFavorite(
      wishId: (json['wishId'] as num?)?.toInt() ?? 0,
      itemType: (json['itemType'] ?? '').toString(),
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      description: json['description']?.toString(),
      priceLabel: json['priceLabel']?.toString(),
      statusLabel: json['statusLabel']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
