import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color primaryBlue;
  final Color primaryBlueLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color lightGrey;
  final Color borderLight;
  final Color cardBlue;
  final Color cardPink;
  final Color iconPink;
  final Color iconOrange;
  final Color progressRed;
  final Color progressOrange;
  final Color purple;
  final Color info;
  final Color error;
  final Color success;

  AppThemeExtension({
    required this.primaryBlue,
    required this.primaryBlueLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.lightGrey,
    required this.borderLight,
    required this.cardBlue,
    required this.cardPink,
    required this.iconPink,
    required this.iconOrange,
    required this.progressRed,
    required this.progressOrange,
    required this.purple,
    required this.info,
    required this.error,
    required this.success,
  });

  // Light theme
  static AppThemeExtension light = AppThemeExtension(
    primaryBlue: AppColors.primaryBlue,
    primaryBlueLight: AppColors.primaryBlueLight,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    lightGrey: AppColors.lightGrey,
    borderLight: AppColors.borderLight,
    cardBlue: AppColors.cardBlue,
    cardPink: AppColors.cardPink,
    iconPink: AppColors.iconPink,
    iconOrange: AppColors.iconOrange,
    progressRed: AppColors.progressRed,
    progressOrange: AppColors.progressOrange,
    purple: AppColors.purple,
    info: AppColors.info,
    error: AppColors.error,
    success: AppColors.success,
  );

  // Dark theme
  static AppThemeExtension dark = AppThemeExtension(
    primaryBlue: AppColors.primaryBlueLight,
    primaryBlueLight: AppColors.primaryBlueLight,
    textPrimary: Colors.white,
    textSecondary: Colors.grey[400]!,
    lightGrey: const Color(0xFF2A2A2A),
    borderLight: const Color(0xFF3A3A3A),
    cardBlue: const Color(0xFF1E3A5F),
    cardPink: const Color(0xFF3A1E2A),
    iconPink: AppColors.iconPink,
    iconOrange: AppColors.iconOrange,
    progressRed: AppColors.progressRed,
    progressOrange: AppColors.progressOrange,
    purple: AppColors.purple,
    info: AppColors.info,
    error: AppColors.error,
    success: AppColors.success,
  );

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? primaryBlue,
    Color? primaryBlueLight,
    Color? textPrimary,
    Color? textSecondary,
    Color? lightGrey,
    Color? borderLight,
    Color? cardBlue,
    Color? cardPink,
    Color? iconPink,
    Color? iconOrange,
    Color? progressRed,
    Color? progressOrange,
    Color? purple,
    Color? info,
    Color? error,
    Color? success,
  }) {
    return AppThemeExtension(
      primaryBlue: primaryBlue ?? this.primaryBlue,
      primaryBlueLight: primaryBlueLight ?? this.primaryBlueLight,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      lightGrey: lightGrey ?? this.lightGrey,
      borderLight: borderLight ?? this.borderLight,
      cardBlue: cardBlue ?? this.cardBlue,
      cardPink: cardPink ?? this.cardPink,
      iconPink: iconPink ?? this.iconPink,
      iconOrange: iconOrange ?? this.iconOrange,
      progressRed: progressRed ?? this.progressRed,
      progressOrange: progressOrange ?? this.progressOrange,
      purple: purple ?? this.purple,
      info: info ?? this.info,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      primaryBlueLight: Color.lerp(primaryBlueLight, other.primaryBlueLight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      lightGrey: Color.lerp(lightGrey, other.lightGrey, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      cardBlue: Color.lerp(cardBlue, other.cardBlue, t)!,
      cardPink: Color.lerp(cardPink, other.cardPink, t)!,
      iconPink: Color.lerp(iconPink, other.iconPink, t)!,
      iconOrange: Color.lerp(iconOrange, other.iconOrange, t)!,
      progressRed: Color.lerp(progressRed, other.progressRed, t)!,
      progressOrange: Color.lerp(progressOrange, other.progressOrange, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

// Extension to easily access theme colors
extension AppThemeExtensionHelper on BuildContext {
  AppThemeExtension get appColors {
    final extension = Theme.of(this).extension<AppThemeExtension>();
    if (extension != null) {
      return extension;
    }
    // Fallback to light theme if extension is not found
    return AppThemeExtension.light;
  }
}
