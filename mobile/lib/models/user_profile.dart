class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final String? identityNumber;
  final String? identityCardPhotoUrl;
  final String avatarUrl;
  final bool isEmailVerified;
  final String memberTier;
  final int tripsCount;
  final int coins;
  final double walletBalance;
  final int vouchers;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    this.identityNumber,
    this.identityCardPhotoUrl,
    required this.avatarUrl,
    required this.isEmailVerified,
    required this.memberTier,
    required this.tripsCount,
    required this.coins,
    required this.walletBalance,
    required this.vouchers,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? birthDate,
    Object? identityNumber = _sentinel,
    Object? identityCardPhotoUrl = _sentinel,
    String? avatarUrl,
    bool? isEmailVerified,
    String? memberTier,
    int? tripsCount,
    int? coins,
    double? walletBalance,
    int? vouchers,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      identityNumber: identityNumber == _sentinel
          ? this.identityNumber
          : identityNumber as String?,
      identityCardPhotoUrl: identityCardPhotoUrl == _sentinel
          ? this.identityCardPhotoUrl
          : identityCardPhotoUrl as String?,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      memberTier: memberTier ?? this.memberTier,
      tripsCount: tripsCount ?? this.tripsCount,
      coins: coins ?? this.coins,
      walletBalance: walletBalance ?? this.walletBalance,
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
      avatarUrl: (json['avatarUrl'] ?? '').toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      memberTier: json['memberTier'] ?? 'Thành viên mới',
      tripsCount: json['tripsCount'] ?? 0,
      coins: json['coins'] ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      vouchers: json['vouchers'] ?? 0,
      birthDate: json['birthDate'] ?? '',
      identityNumber: json['identityNumber'] as String?,
      identityCardPhotoUrl: json['identityCardPhotoUrl'] as String?,
    );
  }

  factory UserProfile.mock() {
    return UserProfile(
      id: '1',
      name: 'Nguyễn Văn A',
      email: 'user@smarttrip.vn',
      phone: '0901234567',
      birthDate: '1995-01-01',
      avatarUrl: '',
      isEmailVerified: true,
      memberTier: 'Gold Member',
      tripsCount: 5,
      coins: 320,
      walletBalance: 500000.0,
      vouchers: 3,
      identityNumber: null,
      identityCardPhotoUrl: null,
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
      'isEmailVerified': isEmailVerified,
      'memberTier': memberTier,
      'tripsCount': tripsCount,
      'coins': coins,
      'walletBalance': walletBalance,
      'vouchers': vouchers,
      'birthDate': birthDate,
      'identityNumber': identityNumber,
      'identityCardPhotoUrl': identityCardPhotoUrl,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'phone': phone,
      'birthDate': birthDate,
      'identityNumber': identityNumber,
    };
  }
}

const _sentinel = Object();
