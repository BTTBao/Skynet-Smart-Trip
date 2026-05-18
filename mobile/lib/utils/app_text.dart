import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';

extension AppTextContext on BuildContext {
  String tr({
    required String vi,
    required String en,
  }) {
    return watch<AppSettingsProvider>().text(vi: vi, en: en);
  }

  String trRead({
    required String vi,
    required String en,
  }) {
    return read<AppSettingsProvider>().text(vi: vi, en: en);
  }

  AppSettingsProvider get appSettings => read<AppSettingsProvider>();
}
