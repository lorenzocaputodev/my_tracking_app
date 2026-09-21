import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_stat_colors.dart';

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppStatColors get stats => Theme.of(this).extension<AppStatColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  Color get accent => Theme.of(this).colorScheme.primary;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
