import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/minutes_presets.dart';
import 'option_sheet.dart';
import 'select_field.dart';
import 'tracking_input_decoration.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import '../l10n/l10n.dart';

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
    final l10n = context.l10n;
    final dropdownValue =
        customMode ? customMinutesPresetValue : (selectedPresetMinutes ?? 0);

    final baseTextStyle = TextStyle(fontFamily: AppFonts.sans,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: context.colors.textPrimary,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectField<int>(
          icon: Icons.timer_rounded,
          sheetTitle: l10n.minutesLostSheetTitle,
          value: dropdownValue,
          onChanged: onPresetSelected,
          options: [
            for (final preset in minutesPresets)
              preset.minutes == 0
                  ? SheetOption(
                      0,
                      l10n.noEstimate,
                      subtitle: l10n.noEstimateSubtitle,
                      fieldLabel: l10n.noEstimate,
                    )
                  : SheetOption(
                      preset.minutes,
                      l10n.minutesPresetName(preset.minutes),
                      subtitle: l10n.minutesEstimate(preset.minutes),
                      fieldLabel: l10n.minutesPresetLabel(
                        l10n.minutesPresetName(preset.minutes),
                        l10n.minutesEstimate(preset.minutes),
                      ),
                    ),
            SheetOption(customMinutesPresetValue, l10n.custom),
          ],
        ),
        if (customMode) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: validator,
            onChanged: onCustomChanged,
            style: baseTextStyle,
            decoration: trackingInputDecoration(
              hint: l10n.minutesPerUse,
              icon: Icons.edit_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ).copyWith(
              suffixText: 'min',
              suffixStyle: TextStyle(fontFamily: AppFonts.sans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
