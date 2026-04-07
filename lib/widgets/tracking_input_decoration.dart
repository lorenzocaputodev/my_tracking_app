import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration trackingInputDecoration({
  required String hint,
  required IconData icon,
  required bool isDark,
  required Color accentColor,
  String? label,
  Color? fillColorOverride,
  Color? enabledBorderColor,
}) {
  final mutedColor = isDark ? Colors.grey : const Color(0xFF5B7072);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: mutedColor),
    labelStyle: GoogleFonts.dmSans(color: mutedColor),
    prefixIcon: Icon(icon, size: 20, color: mutedColor),
    filled: true,
    fillColor: fillColorOverride ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE8F0F0)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: enabledBorderColor == null
          ? BorderSide.none
          : BorderSide(color: enabledBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: enabledBorderColor == null
          ? BorderSide.none
          : BorderSide(color: enabledBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: accentColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );
}
