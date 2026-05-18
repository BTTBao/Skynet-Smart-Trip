class UserSettings {
  const UserSettings({
    required this.email,
    required this.isEmailVerified,
    required this.pushNotificationEnabled,
    required this.emailOfferEnabled,
    required this.darkModeEnabled,
    required this.language,
    required this.currency,
  });

  final String email;
  final bool isEmailVerified;
  final bool pushNotificationEnabled;
  final bool emailOfferEnabled;
  final bool darkModeEnabled;
  final String language;
  final String currency;

  UserSettings copyWith({
    String? email,
    bool? isEmailVerified,
    bool? pushNotificationEnabled,
    bool? emailOfferEnabled,
    bool? darkModeEnabled,
    String? language,
    String? currency,
  }) {
    return UserSettings(
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      pushNotificationEnabled:
          pushNotificationEnabled ?? this.pushNotificationEnabled,
      emailOfferEnabled: emailOfferEnabled ?? this.emailOfferEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      currency: currency ?? this.currency,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      email: (json['email'] ?? '').toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      pushNotificationEnabled: json['pushNotificationEnabled'] != false,
      emailOfferEnabled: json['emailOfferEnabled'] == true,
      darkModeEnabled: json['darkModeEnabled'] == true,
      language: (json['language'] ?? 'vi').toString(),
      currency: (json['currency'] ?? 'VND').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationEnabled': pushNotificationEnabled,
      'emailOfferEnabled': emailOfferEnabled,
      'darkModeEnabled': darkModeEnabled,
      'language': language,
      'currency': currency,
    };
  }
}
