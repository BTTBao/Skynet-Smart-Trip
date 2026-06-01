class Destination {
  final int id;
  final String name;
  final String description;
  final String coverImageUrl;
  final bool isHot;

  const Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.isHot,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? '',
      isHot: json['isHot'] ?? false,
    );
  }
}
