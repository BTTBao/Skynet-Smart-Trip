import 'package:flutter/material.dart';

/// Centralized design tokens for Skynet Smart Trip.
/// Use these constants everywhere — never hardcode colors or styles.
class AppColors {
  AppColors._();

  // Brand palette
  static const Color primaryLight = Color(0xFF80ED99);
  static const Color primary = Color(0xFF57CC99);
  static const Color primaryDark = Color(0xFF38A3A5);

  // Neutral palette (slate)
  static const Color bgPage = Color(0xFFF8FAFC);
  static const Color bgCard = Colors.white;
  static const Color borderDefault = Color(0xFFE2E8F0);
  static const Color textHeading = Color(0xFF1E293B);
  static const Color textBody = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandVertical = LinearGradient(
    colors: [AppColors.primaryLight, AppColors.primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppBorders {
  AppBorders._();

  static const double radiusCard = 24.0;
  static const double radiusInput = 16.0;
  static const double radiusButton = 16.0;
  static const double radiusIcon = 16.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textHeading,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textHeading,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    color: AppColors.textMuted,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle linkPrimary = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration authCard = BoxDecoration(
    color: AppColors.bgCard,
    borderRadius: BorderRadius.circular(AppBorders.radiusCard),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 30,
        spreadRadius: 0,
        offset: const Offset(0, 12),
      ),
    ],
  );

  static BoxDecoration iconBadge({Color? bg}) => BoxDecoration(
        color: bg ?? AppColors.successBg,
        borderRadius: BorderRadius.circular(AppBorders.radiusIcon),
      );

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? errorText,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.bgPage,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusInput),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusInput),
          borderSide: const BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusInput),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusInput),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusInput),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      );
}
