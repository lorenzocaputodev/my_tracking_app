import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_fonts.dart';
import 'app_stat_colors.dart';

abstract final class AppTheme {
  static const Color darkPrimary = Color(0xFF00CED1);
  static const Color lightPrimary = Color(0xFF00686B);

  static ThemeData of(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final statColors = isDark ? AppStatColors.dark : AppStatColors.light;
    final primary = isDark ? darkPrimary : lightPrimary;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[colors, statColors],
      textTheme: ThemeData(brightness: brightness)
          .textTheme
          .apply(fontFamily: AppFonts.sans),
      scaffoldBackgroundColor: colors.scaffold,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        color: colors.surface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colors.surfaceElevated : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontSize: 14,
          height: 1.4,
          color: colors.textBody,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.scaffold,
        modalBackgroundColor: colors.scaffold,
        dragHandleColor: colors.textFaint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.action,
          foregroundColor: colors.onAction,
          textStyle: const TextStyle(
            fontFamily: AppFonts.sans,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      // Il default Material e' chiaro anche nel tema scuro: qui l'avviso
      // resta una superficie dell'app, con l'azione nel colore d'azione.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? colors.surfaceElevated : colors.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.sans,
          fontWeight: FontWeight.w600,
          color: isDark ? colors.textPrimary : Colors.white,
        ),
        actionTextColor: colors.action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        hintStyle: TextStyle(
          fontFamily: AppFonts.sans,
          color: colors.textMuted,
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.sans,
          color: colors.textMuted,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.22),
        selectionHandleColor: primary,
      ),
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.08),
      iconTheme: IconThemeData(color: colors.textPrimary),
    );
  }
}
