import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'api_service.dart';

class ProfileService extends ApiService {
  // Giả lập chế độ Mock (Để bạn vẫn chạy được app khi chưa có DB thật)
  final bool _useMock = true; 

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
        final response = await http.get(
          Uri.parse('$baseUrl/profile'),
          headers: await getHeaders(),
        );
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
        final response = await http.put(
          Uri.parse('$baseUrl/profile/update'),
          headers: await getHeaders(),
          body: jsonEncode(profile.toJson()),
        );
        handleResponse(response);
        return true;
      } catch (e) {
        rethrow;
      }
    }
  }
}
