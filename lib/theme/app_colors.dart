import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color scaffold;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color cardBorder;
  final Color subtleBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color textFaint;
  final Color inputFill;

  const AppColors({
    required this.scaffold,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.cardBorder,
    required this.subtleBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.inputFill,
  });

  static final AppColors dark = AppColors(
    scaffold: const Color(0xFF0A0A0A),
    surface: const Color(0xFF161B1B),
    surfaceElevated: const Color(0xFF1C1C1E),
    surfaceSunken: const Color(0xFF1E2A2A),
    cardBorder: Colors.white.withValues(alpha: 0.05),
    subtleBorder: Colors.white.withValues(alpha: 0.03),
    textPrimary: Colors.white,
    textMuted: Colors.grey,
    textFaint: Colors.white38,
    inputFill: Colors.white.withValues(alpha: 0.06),
  );

  static final AppColors light = AppColors(
    scaffold: const Color(0xFFF3F7F7),
    surface: Colors.white,
    surfaceElevated: Colors.white,
    surfaceSunken: Colors.white,
    cardBorder: Colors.black.withValues(alpha: 0.05),
    subtleBorder: Colors.black.withValues(alpha: 0.06),
    textPrimary: const Color(0xFF132222),
    textMuted: const Color(0xFF556B6D),
    textFaint: const Color(0xFF607274),
    inputFill: const Color(0xFFE8F0F0),
  );

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? cardBorder,
    Color? subtleBorder,
    Color? textPrimary,
    Color? textMuted,
    Color? textFaint,
    Color? inputFill,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}
