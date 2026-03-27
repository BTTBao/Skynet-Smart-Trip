import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _apiService = ProfileService();
  
  UserProfile? _profileData;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;

  UserProfile? get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
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

  // Lưu toàn bộ thông tin (gửi lên Mock API)
  Future<bool> updateProfile(Map<String, dynamic> newData) async {
    _isUpdating = true;
    notifyListeners();

    try {
      // Giả lập gọi API PUT/PATCH
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (_profileData != null) {
        final json = _profileData!.toJson();
        json.addAll(newData);
        _profileData = UserProfile.fromJson(json);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
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
