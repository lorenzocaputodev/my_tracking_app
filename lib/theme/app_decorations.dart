import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

abstract final class AppDecorations {
  static BoxDecoration card(
    AppColors colors, {
    double radius = AppRadii.card,
  }) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.cardBorder),
    );
  }

  static BoxDecoration cardSubtle(
    AppColors colors, {
    double radius = AppRadii.card,
  }) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.subtleBorder),
    );
  }

  static BoxDecoration surface(
    AppColors colors, {
    double radius = AppRadii.card,
  }) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration tintPanel(Color accent, {double radius = AppRadii.card}) {
    return BoxDecoration(
      color: accent.withValues(alpha: AppAlphas.tintPanel),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: accent.withValues(alpha: AppAlphas.tintBorder)),
    );
  }

  static BoxDecoration statTile(Color accent, {required bool isDark}) {
    return BoxDecoration(
      color: accent.withValues(
        alpha: isDark ? AppAlphas.statFillDark : AppAlphas.statFillLight,
      ),
      borderRadius: BorderRadius.circular(AppRadii.chip),
      border: Border.all(
        color: accent.withValues(
          alpha: isDark ? AppAlphas.statBorderDark : AppAlphas.statBorderLight,
        ),
      ),
    );
  }
}
