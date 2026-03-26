import 'package:flutter/material.dart';
import '../services/mock_api_service.dart';

class ProfileProvider with ChangeNotifier {
  final MockApiService _apiService = MockApiService();
  
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileData = await _apiService.getProfileData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
