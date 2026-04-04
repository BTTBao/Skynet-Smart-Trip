import 'dart:convert';
import '../models/user_profile.dart';
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
        memberTier: 'Gold Member',
        tripsCount: 12,
        coins: 450,
        vouchers: 15,
        birthDate: '15/08/1995',
      );
    } else {
      // CODE CHO BACKEND THẬT .NET
      try {
        final response = await getWithFallback('/user/1');
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
        final userId = profile.id.isNotEmpty ? profile.id : '1';
        final response = await putWithFallback(
          '/user/$userId',
          body: jsonEncode(profile.toJson()),
        );
        handleResponse(response);
        return true;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<String?> uploadAvatar(String filePath, {String userId = '1'}) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return 'https://i.pravatar.cc/150?u=mock_upload';
    } else {
      try {
        final response = await multipartPostWithFallback(
          '/user/$userId/upload-avatar',
          fileField: 'file',
          filePath: filePath,
        );

        final data = handleResponse(response);
        return data['avatarUrl'];
      } catch (e) {
        rethrow;
      }
    }
  }
}
