import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _apiService = ProfileService();
  
  UserProfile? _profileData;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isUploadingAvatar = false;
  String? _error;

  UserProfile? get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileData = await _apiService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật một trường duy nhất (local)
  void updateField(String key, dynamic value) {
    if (_profileData != null) {
      final json = _profileData!.toJson();
      json[key] = value;
      _profileData = UserProfile.fromJson(json);
      notifyListeners();
    }
  }

  // Lưu toàn bộ thông tin (gửi lên Backend .NET)
  Future<bool> updateProfile(UserProfile profile) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateProfile(profile);
      if (success) {
        _profileData = profile;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    _isUploadingAvatar = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _profileData?.id.isNotEmpty == true ? _profileData!.id : '1';
      final newUrl = await _apiService.uploadAvatar(filePath, userId: userId);
      if (newUrl != null && _profileData != null) {
        _profileData = _profileData!.copyWith(avatarUrl: newUrl);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  // Đăng xuất: xóa dữ liệu
  void logout() {
    _profileData = null;
    _error = null;
    notifyListeners();
  }
}
