import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/minutes_lost_selector.dart';
import '../widgets/tracking_input_decoration.dart';
import '../theme/app_decorations.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'pill_selector.dart';
import 'product_form_state.dart';
import '../l10n/l10n.dart';

class ProductConfigurationForm extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String title;
  final String subtitle;
  final ProductFormState form;
  final VoidCallback onChanged;

  const ProductConfigurationForm({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.onChanged,
  });

  void _update(VoidCallback change) {
    change();
    onChanged();
  }

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
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 13, color: context.colors.textMuted),
          ),
          const SizedBox(height: 28),
        ],
        _sectionLabel(context.l10n.productNameLabel, accentColor),
        const SizedBox(height: 10),
        TextFormField(
          controller: form.name,
          style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(
            hint: context.l10n.productNameHint,
            icon: Icons.label_outline_rounded,
            isDark: isDark,
            accentColor: accentColor,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.enterName;
            }
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 28),
        _sectionLabel(context.l10n.productModeLabel, accentColor),
        const SizedBox(height: 10),
        _TrackingModeSection(
          tracksInventory: form.tracksInventory,
          onChanged: (value) => _update(() => form.tracksInventory = value),
        ),
        const SizedBox(height: 28),
        if (form.tracksInventory) ...[
          _sectionLabel(context.l10n.packCostLabel, accentColor),
          const SizedBox(height: 10),
          TextFormField(
            key: const ValueKey('packCost'),
            controller: form.packCost,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            decoration: _inputDecoration(
              hint: context.l10n.packCostHint,
              icon: Icons.euro_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n.enterAmount;
              }
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) {
                return context.l10n.invalidAmount;
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 28),
          _sectionLabel(context.l10n.unitsPerPackLabel, accentColor),
          const SizedBox(height: 10),
          TextFormField(
            key: const ValueKey('pieces'),
            controller: form.pieces,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hint: context.l10n.unitsPerPackHint,
              icon: Icons.format_list_numbered_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.l10n.enterNumber;
              }
              final parsed = int.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return context.l10n.invalidNumber;
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.unitsPerPackHelp,
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: context.colors.textMuted),
          ),
        ] else ...[
          _sectionLabel(context.l10n.costPerUseLabel, accentColor),
          const SizedBox(height: 10),
          TextFormField(
            key: const ValueKey('directCost'),
            controller: form.directCost,
            style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w500),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            decoration: _inputDecoration(
              hint: context.l10n.costPerUseHint,
              icon: Icons.euro_rounded,
              isDark: isDark,
              accentColor: accentColor,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed < 0) {
                return context.l10n.invalidAmount;
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.costPerUseHelp,
            style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: context.colors.textMuted),
          ),
        ],
        const SizedBox(height: 28),
        _sectionLabel(context.l10n.minutesLostLabel, accentColor),
        const SizedBox(height: 10),
        MinutesLostSelector(
          isDark: isDark,
          accentColor: accentColor,
          controller: form.minutes,
          selectedPresetMinutes: form.selectedPresetMinutes,
          customMode: form.minutesCustomMode,
          onPresetSelected: (value) =>
              _update(() => form.selectMinutesPreset(value)),
          onCustomChanged: (_) => onChanged(),
          validator: (value) {
            if (form.minutesCustomMode && (value == null || value.trim().isEmpty)) {
              return context.l10n.enterValue;
            }
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed < 0) {
              return context.l10n.invalidNumber;
            }
            return null;
          },
        ),
        const SizedBox(height: 28),
        _sectionLabel(context.l10n.dailyGoalLabel, accentColor),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                form.dailyGoal == 0
                    ? context.l10n.noDailyLimit
                    : context.l10n.dailyGoalText(form.dailyGoal),
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              '${form.dailyGoal}',
              style: TextStyle(fontFamily: AppFonts.sans,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ],
        ),
        Slider(
          value: form.dailyGoal.toDouble(),
          min: 0,
          max: 50,
          divisions: 50,
          activeColor: accentColor,
          inactiveColor: accentColor.withValues(alpha: 0.15),
          label: form.dailyGoal == 0
              ? context.l10n.noLimit
              : '${form.dailyGoal}',
          onChanged: (value) => _update(() => form.dailyGoal = value.round()),
        ),
        Text(
          context.l10n.zeroNoLimit,
          style: TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: context.colors.textMuted),
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
            options: {
              true: context.l10n.withStock,
              false: context.l10n.noStock,
            },
            value: tracksInventory,
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          Text(
            tracksInventory
                ? context.l10n.withStockHelp
                : context.l10n.noStockHelp,
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
