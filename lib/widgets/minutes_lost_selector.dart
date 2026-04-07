import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/minutes_presets.dart';
import 'tracking_input_decoration.dart';

class MinutesLostSelector extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final TextEditingController controller;
  final int? selectedPresetMinutes;
  final bool customMode;
  final ValueChanged<int> onPresetSelected;
  final ValueChanged<String> onCustomChanged;
  final String? Function(String?)? validator;

  const MinutesLostSelector({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.controller,
    required this.selectedPresetMinutes,
    required this.customMode,
    required this.onPresetSelected,
    required this.onCustomChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final dropdownValue =
        customMode ? customMinutesPresetValue : (selectedPresetMinutes ?? 0);

    final baseTextStyle = GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: dropdownValue,
                isExpanded: true,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: accentColor,
                  size: 20,
                ),
                style: baseTextStyle,
                dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                items: [
                  ...minutesPresets.map(
                    (preset) => DropdownMenuItem<int>(
                      value: preset.minutes,
                      child: Text(
                        preset.label,
                        style: baseTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DropdownMenuItem<int>(
                    value: customMinutesPresetValue,
                    child: Text(
                      'Personalizzato...',
                      style: baseTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onPresetSelected(value);
                  }
                },
              ),
            ),
          ),
          if (customMode) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validator,
                onChanged: onCustomChanged,
                style: baseTextStyle,
                decoration: trackingInputDecoration(
                  hint: 'Inserisci minuti personalizzati',
                  icon: Icons.favorite_border_rounded,
                  isDark: isDark,
                  accentColor: accentColor,
                  fillColorOverride: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.94),
                  enabledBorderColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ).copyWith(
                  suffixText: 'min',
                  suffixStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
