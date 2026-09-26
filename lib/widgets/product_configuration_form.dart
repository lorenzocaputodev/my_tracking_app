import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/minutes_lost_selector.dart';
import '../widgets/tracking_input_decoration.dart';
import '../theme/app_decorations.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'pill_selector.dart';


class ProductConfigurationForm extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String title;
  final String subtitle;
  final TextEditingController nameController;
  final TextEditingController packCostController;
  final TextEditingController piecesController;
  final TextEditingController directCostController;
  final TextEditingController minutesController;
  final bool tracksInventory;
  final ValueChanged<bool> onTracksInventoryChanged;
  final int dailyGoal;
  final ValueChanged<int> onDailyGoalChanged;
  final int? selectedPresetMinutes;
  final bool minutesCustomMode;
  final ValueChanged<int> onMinutesPresetSelected;
  final VoidCallback onChanged;

  const ProductConfigurationForm({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.nameController,
    required this.packCostController,
    required this.piecesController,
    required this.directCostController,
    required this.minutesController,
    required this.tracksInventory,
    required this.onTracksInventoryChanged,
    required this.dailyGoal,
    required this.onDailyGoalChanged,
    required this.selectedPresetMinutes,
    required this.minutesCustomMode,
    required this.onMinutesPresetSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.colors.textHeading,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontFamily: AppFonts.sans, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 28),
        ],
        _sectionLabel('NOME PRODOTTO', accentColor),
        const SizedBox(height: 10),
        TextFormField(
          controller: nameController,
          style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            hint: 'Es. Sigarette',
            icon: Icons.label_outline_rounded,
            isDark: isDark,
            accentColor: accentColor,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci un nome';
            }
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 28),
        _sectionLabel('MODALIT\u00C0 PRODOTTO', accentColor),
        const SizedBox(height: 10),
        _TrackingModeSection(
          tracksInventory: tracksInventory,
          onChanged: onTracksInventoryChanged,
        ),
        const SizedBox(height: 28),
        if (tracksInventory) ...[
          _sectionLabel('COSTO CONFEZIONE', accentColor),
          const SizedBox(height: 10),
          TextFormField(
            controller: packCostController,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            decoration: _inputDecoration(
              hint: 'Es. 6,00',
              icon: Icons.euro_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci un importo';
              }
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) {
                return 'Importo non valido';
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 28),
          _sectionLabel(
            'UNIT\u00C0 / USI STIMATI PER CONFEZIONE',
            accentColor,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: piecesController,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hint: 'Es. 20',
              icon: Icons.format_list_numbered_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci un numero';
              }
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'Numero non valido';
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Puoi inserire anche il numero medio di usi ottenibili da una confezione.',
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: Colors.grey),
          ),
        ] else ...[
          _sectionLabel('COSTO PER UTILIZZO', accentColor),
          const SizedBox(height: 10),
          TextFormField(
            controller: directCostController,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            decoration: _inputDecoration(
              hint: 'Facoltativo, es. 0,10',
              icon: Icons.euro_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return 'Importo non valido';
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lascia vuoto se vuoi registrare solo gli utilizzi, senza calcolare costi.',
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 28),
        _sectionLabel('MINUTI DI VITA PERSI PER UTILIZZO', accentColor),
        const SizedBox(height: 10),
        MinutesLostSelector(
          isDark: isDark,
          accentColor: accentColor,
          controller: minutesController,
          selectedPresetMinutes: selectedPresetMinutes,
          customMode: minutesCustomMode,
          onPresetSelected: onMinutesPresetSelected,
          onCustomChanged: (_) => onChanged(),
          validator: (value) {
            if (minutesCustomMode && (value == null || value.trim().isEmpty)) {
              return 'Inserisci un valore';
            }
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed < 0) {
              return 'Numero non valido';
            }
            return null;
          },
        ),
        const SizedBox(height: 28),
        _sectionLabel('OBIETTIVO GIORNALIERO', accentColor),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                dailyGoal == 0
                    ? 'Nessun limite giornaliero'
                    : 'Voglio stare sotto $dailyGoal al giorno',
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              '$dailyGoal',
              style: TextStyle(fontFamily: AppFonts.sans,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
        Slider(
          value: dailyGoal.toDouble(),
          min: 0,
          max: 50,
          divisions: 50,
          activeColor: accentColor,
          inactiveColor: accentColor.withValues(alpha: 0.15),
          label: dailyGoal == 0 ? 'Nessun limite' : '$dailyGoal',
          onChanged: (value) => onDailyGoalChanged(value.round()),
        ),
        const Text(
          '0 = nessun limite impostato',
          style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _TrackingModeSection extends StatelessWidget {
  final bool tracksInventory;
  final ValueChanged<bool> onChanged;

  const _TrackingModeSection({
    required this.tracksInventory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSubtle(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillSelector<bool>(
            expand: true,
            options: const {true: 'Con scorta', false: 'Senza scorta'},
            value: tracksInventory,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Text(
            tracksInventory
                ? 'Il prodotto usa una scorta residua e pu\u00F2 essere reintegrato quando termina.'
                : 'Il prodotto registra solo gli utilizzi, senza gestire confezioni o residuo.',
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 12,
              height: 1.5,
              color: context.colors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _sectionLabel(String text, Color accentColor) =>
    Text(text, style: AppTextStyles.sectionLabel(accentColor));

InputDecoration _inputDecoration({
  required String hint,
  required IconData icon,
  required bool isDark,
  required Color accentColor,
}) {
  return trackingInputDecoration(
    hint: hint,
    icon: icon,
    isDark: isDark,
    accentColor: accentColor,
  );
}
