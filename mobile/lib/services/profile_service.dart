import 'dart:convert';

import '../models/user_favorite.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import 'api_service_base.dart';

class ProfileService extends ApiService {
  // Giả lập chế độ Mock (Để bạn vẫn chạy được app khi chưa có DB thật)
  final bool _useMock = false; 

  Future<UserProfile?> getProfile() async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return UserProfile(
        id: '1',
         name: 'Nguyen Subin',
         email: 'subin@skynet.com',
         phone: '0987654321',
         avatarUrl: 'https://i.pravatar.cc/150?u=skynet',
         isEmailVerified: true,
         memberTier: 'Gold Member',
         tripsCount: 12,
         coins: 450,
        vouchers: 15,
        birthDate: '15/08/1995',
      );
    } else {
      // CODE CHO BACKEND THẬT .NET
      try {
        final response = await getWithFallback('/user/me', requireAuth: true);
        return UserProfile.fromJson(handleResponse(response));
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } else {
      // CODE CHO BACKEND THẬT .NET
      try {
        final response = await putWithFallback(
          '/user/me',
          requireAuth: true,
          body: jsonEncode(profile.toUpdateJson()),
        );
        handleResponse(response);
        return true;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<String?> uploadAvatar(String filePath) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return 'https://i.pravatar.cc/150?u=mock_upload';
    } else {
      try {
        final response = await multipartPostWithFallback(
          '/user/me/upload-avatar',
          fileField: 'file',
          filePath: filePath,
          requireAuth: true,
        );

        final data = handleResponse(response);
        return data['avatarUrl'];
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<List<UserFavorite>> getFavorites() async {
    final response = await getWithFallback('/user/me/favorites', requireAuth: true);
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
    final response = await getWithFallback('/user/me/settings', requireAuth: true);
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
