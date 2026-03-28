import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'api_service.dart';

class ProfileService extends ApiService {
  Uri _buildUserUri(String userId) => Uri.parse('$baseUrl/user/$userId');

  Uri _buildUploadAvatarUri(String userId) =>
      Uri.parse('$baseUrl/user/$userId/upload-avatar');
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
        final response = await http.get(
          _buildUserUri('1'),
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
        final userId = profile.id.isNotEmpty ? profile.id : '1';
        final response = await http.put(
          _buildUserUri(userId),
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

  Future<String?> uploadAvatar(String filePath, {String userId = '1'}) async {
    if (_useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return 'https://i.pravatar.cc/150?u=mock_upload';
    } else {
      try {
        var request = http.MultipartRequest(
          'POST',
          _buildUploadAvatarUri(userId),
        );
        
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        
        final data = handleResponse(response);
        return data['avatarUrl'];
      } catch (e) {
        rethrow;
      }
    }
  }
}
