
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final String avatarUrl;
  final String memberTier;
  final int tripsCount;
  final int coins;
  final int vouchers;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.avatarUrl,
    required this.memberTier,
    required this.tripsCount,
    required this.coins,
    required this.vouchers,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? birthDate,
    String? avatarUrl,
    String? memberTier,
    int? tripsCount,
    int? coins,
    int? vouchers,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberTier: memberTier ?? this.memberTier,
      tripsCount: tripsCount ?? this.tripsCount,
      coins: coins ?? this.coins,
      vouchers: vouchers ?? this.vouchers,
    );
  }

  // Chuyển từ JSON (từ Backend .NET) sang Model
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['userId'] ?? json['id'])?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'] ?? 'https://i.pravatar.cc/150?u=skynet',
      memberTier: json['memberTier'] ?? 'Thành viên mới',
      tripsCount: json['tripsCount'] ?? 0,
      coins: json['coins'] ?? 0,
      vouchers: json['vouchers'] ?? 0,
      birthDate: json['birthDate'] ?? '',
    );
  }

  // Chuyển từ Model sang JSON (để gửi lên Backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'memberTier': memberTier,
      'tripsCount': tripsCount,
      'coins': coins,
      'vouchers': vouchers,
      'birthDate': birthDate,
    };
  }
}
