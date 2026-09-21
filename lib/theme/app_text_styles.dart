import 'package:flutter/material.dart';

import 'app_fonts.dart';

abstract final class AppTextStyles {
  static TextStyle sectionLabel(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: color,
      );

  static TextStyle cardTitle(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle statValue(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle statLabel(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle microCaps(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 12,
        color: color,
      );

  static TextStyle hint(Color color) => TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 11,
        color: color,
      );
}
