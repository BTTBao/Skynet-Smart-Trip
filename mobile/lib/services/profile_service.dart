import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../models/user_favorite.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'api_service_base.dart';

class ProfileService extends ApiService {
  Future<UserProfile> getProfile() async {
    final response = await getWithFallback(
      '/user/me',
      requireAuth: true,
    );
    final data = handleResponse(response);
    return UserProfile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> updateProfile(UserProfile profile) async {
    final response = await putWithFallback(
      '/user/me',
      requireAuth: true,
      body: jsonEncode(profile.toUpdateJson()),
    );
    handleResponse(response);
    return true;
  }

  Future<String?> uploadAvatar(XFile file) async {
    final response = await multipartPostWithFallback(
      '/user/me/upload-avatar',
      fileField: 'file',
      file: file,
      requireAuth: true,
    );
    final data = handleResponse(response);
    return data['avatarUrl'];
  }

  Future<List<UserFavorite>> getFavorites() async {
    final response = await getWithFallback(
      '/user/me/favorites',
      requireAuth: true,
    );
    final data = handleResponse(response) as List<dynamic>? ?? [];
    return data
        .map((item) => UserFavorite.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> removeFavorite(int wishId) async {
    final response = await deleteWithFallback(
      '/user/me/favorites/$wishId',
      requireAuth: true,
    );
    handleResponse(response);
  }

  Future<UserSettings> getSettings() async {
    final response = await getWithFallback(
      '/user/me/settings',
      requireAuth: true,
    );
    return UserSettings.fromJson(
      Map<String, dynamic>.from(handleResponse(response)),
    );
  }

  Future<UserSettings> updateSettings(UserSettings settings) async {
    final response = await putWithFallback(
      '/user/me/settings',
      requireAuth: true,
      body: jsonEncode(settings.toJson()),
    );
    return UserSettings.fromJson(
      Map<String, dynamic>.from(handleResponse(response)),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await postWithFallback(
      '/user/me/change-password',
      requireAuth: true,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      }),
    );
    handleResponse(response);
  }
}
