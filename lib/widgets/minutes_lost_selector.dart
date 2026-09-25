import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/minutes_presets.dart';
import 'option_sheet.dart';
import 'select_field.dart';
import 'tracking_input_decoration.dart';
import '../theme/app_fonts.dart';

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

    final baseTextStyle = TextStyle(fontFamily: AppFonts.sans,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectField<int>(
          icon: Icons.timer_rounded,
          sheetTitle: 'Minuti di vita persi',
          value: dropdownValue,
          onChanged: onPresetSelected,
          options: [
            for (final preset in minutesPresets)
              preset.minutes == 0
                  ? SheetOption(
                      0,
                      'Nessuna stima',
                      subtitle: 'Non conta la vita persa',
                      fieldLabel: preset.label,
                    )
                  : SheetOption(
                      preset.minutes,
                      preset.label.split(' — ').first,
                      subtitle: preset.label.split(' — ').last,
                      fieldLabel: preset.label,
                    ),
            const SheetOption(customMinutesPresetValue, 'Personalizzato…'),
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
              hint: 'Minuti per utilizzo',
              icon: Icons.edit_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ).copyWith(
              suffixText: 'min',
              suffixStyle: const TextStyle(fontFamily: AppFonts.sans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
