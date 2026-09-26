import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_fonts.dart';
import '../theme/app_stat_colors.dart';

InputDecoration trackingInputDecoration({
  required String hint,
  required IconData icon,
  required bool isDark,
  required Color accentColor,
}) {
  final colors = isDark ? AppColors.dark : AppColors.light;
  final danger = (isDark ? AppStatColors.dark : AppStatColors.light).danger;

  OutlineInputBorder border(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.field),
        borderSide: side,
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: AppFonts.sans, color: colors.textMuted),
    prefixIcon: Icon(icon, size: 20, color: colors.textMuted),
    filled: true,
    fillColor: colors.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border(BorderSide.none),
    enabledBorder: border(BorderSide.none),
    focusedBorder: border(BorderSide(color: accentColor, width: 1.5)),
    errorBorder: border(BorderSide(color: danger)),
    focusedErrorBorder: border(BorderSide(color: danger, width: 1.5)),
  );
}
