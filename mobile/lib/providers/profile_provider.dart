import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_favorite.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../services/api_service_base.dart';
import '../services/fcm_service.dart';
import '../services/profile_service.dart';

class PersonalVoucher {
  final String code;
  final String title;
  final String description;
  final String expiry;
  int quantity;

  PersonalVoucher({
    required this.code,
    required this.title,
    required this.description,
    required this.expiry,
    required this.quantity,
  });
}

class ProfileProvider with ChangeNotifier {
  final ProfileService _apiService = ProfileService();

  UserProfile? _profileData;
  UserSettings? _settings;
  List<UserFavorite> _favorites = const [];
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingIdentityPhoto = false;
  bool _isLoadingFavorites = false;
  bool _isLoadingSettings = false;
  bool _isSavingSettings = false;
  bool _isChangingPassword = false;
  String? _error;
  int? _lastStatusCode;

  final List<PersonalVoucher> _myVouchers = [
    PersonalVoucher(
      code: 'SUMMER15',
      title: 'Khuyến mãi hè rực rỡ (15% OFF)',
      description: 'Áp dụng cho mọi dịch vụ. Giảm giá 15% tổng hóa đơn.',
      expiry: 'Hạn dùng: 30/09/2026',
      quantity: 2,
    ),
    PersonalVoucher(
      code: 'LIMOSMART',
      title: 'Trải nghiệm tiện nghi (-30k)',
      description: 'Giảm 30.000đ trực tiếp vào hóa đơn dịch vụ.',
      expiry: 'Hạn dùng: 31/08/2026',
      quantity: 5,
    ),
  ];

  List<PersonalVoucher> get myVouchers => _myVouchers;

  int get totalVoucherCount =>
      _myVouchers.fold(0, (sum, v) => sum + v.quantity);

  void useVoucher(String code) {
    for (var v in _myVouchers) {
      if (v.code == code && v.quantity > 0) {
        v.quantity--;
        if (_profileData != null) {
          _profileData = _profileData!.copyWith(vouchers: totalVoucherCount);
        }
        notifyListeners();
        break;
      }
    }
  }

  UserProfile? get profileData => _profileData;
  UserSettings? get settings => _settings;
  List<UserFavorite> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isUploadingIdentityPhoto => _isUploadingIdentityPhoto;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoadingSettings => _isLoadingSettings;
  bool get isSavingSettings => _isSavingSettings;
  bool get isChangingPassword => _isChangingPassword;
  String? get error => _error;
  bool get hasSessionExpired =>
      _lastStatusCode == 401 || _lastStatusCode == 404;

  Future<void> fetchProfile({bool forceRefresh = true}) async {
    if (!forceRefresh && (_profileData != null || _isLoading)) {
      return;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      _profileData = await _apiService.getProfile();
      if (_profileData != null) {
        _profileData = _profileData!.copyWith(vouchers: totalVoucherCount);
      }
    } catch (error) {
      _setError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    _isUpdating = true;
    _clearError();
    notifyListeners();

    try {
      final success = await _apiService.updateProfile(profile);
      if (success) {
        _profileData = profile;
      }
      return success;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar(XFile file) async {
    _isUploadingAvatar = true;
    _clearError();
    notifyListeners();

    try {
      final newUrl = await _apiService.uploadAvatar(file);
      if (newUrl != null && _profileData != null) {
        _profileData = _profileData!.copyWith(avatarUrl: newUrl);
        return true;
      }
      return false;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<bool> uploadIdentityCardPhoto(XFile file) async {
    _isUploadingIdentityPhoto = true;
    _clearError();
    notifyListeners();

    try {
      final newUrl = await _apiService.uploadIdentityCardPhoto(file);
      if (newUrl != null && _profileData != null) {
        _profileData = _profileData!.copyWith(identityCardPhotoUrl: newUrl);
        return true;
      }
      return false;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isUploadingIdentityPhoto = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites({bool forceRefresh = true}) async {
    if (!forceRefresh && (_favorites.isNotEmpty || _isLoadingFavorites)) {
      return;
    }

    _isLoadingFavorites = true;
    _clearError();
    notifyListeners();

    try {
      _favorites = await _apiService.getFavorites();
    } catch (error) {
      _setError(error);
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<bool> removeFavorite(int wishId) async {
    _clearError();
    notifyListeners();

    try {
      await _apiService.removeFavorite(wishId);
      _favorites = _favorites.where((item) => item.wishId != wishId).toList();
      notifyListeners();
      return true;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSettings({bool forceRefresh = true}) async {
    if (!forceRefresh && (_settings != null || _isLoadingSettings)) {
      return;
    }

    _isLoadingSettings = true;
    _clearError();
    notifyListeners();

    try {
      _settings = await _apiService.getSettings();
    } catch (error) {
      _setError(error);
    } finally {
      _isLoadingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings(UserSettings settings) async {
    _isSavingSettings = true;
    _clearError();
    notifyListeners();

    try {
      final previousPushEnabled = _settings?.pushNotificationEnabled ?? true;
      _settings = await _apiService.updateSettings(settings);
      final currentPushEnabled = _settings?.pushNotificationEnabled ?? true;

      if (previousPushEnabled != currentPushEnabled) {
        if (currentPushEnabled) {
          await FcmService.instance.registerCurrentToken();
        } else {
          await FcmService.instance.unregisterCurrentToken();
        }
      }

      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _isChangingPassword = true;
    _clearError();
    notifyListeners();

    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }

  void logout() {
    _profileData = null;
    _settings = null;
    _favorites = const [];
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _lastStatusCode = null;
  }

  void _setError(Object error) {
    if (error is ApiException) {
      _lastStatusCode = error.statusCode;
      _error = error.isUnauthorized || error.statusCode == 404
          ? 'Phien dang nhap khong con hop le. Vui long dang nhap lai.'
          : error.message;
      return;
    }

    _lastStatusCode = null;
    _error = error.toString().replaceFirst('Exception: ', '');
  }
}
