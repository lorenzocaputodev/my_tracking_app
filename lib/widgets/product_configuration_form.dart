import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_reminder_settings.dart';
import '../widgets/minutes_lost_selector.dart';
import '../widgets/tracking_input_decoration.dart';
import '../theme/app_decorations.dart';
import '../theme/app_fonts.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'pill_selector.dart';

enum FormSubmitPlacement { afterNotifications, bottom, none }

class ProductConfigurationForm extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String widgetMessage;
  final String submitLabel;
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
  final bool notificationsSupported;
  final bool showNotificationsSection;
  final bool showWidgetHomeSection;
  final AppReminderSettings globalReminderSettings;
  final Future<void> Function(bool value)? onGlobalReminderEnabledChanged;
  final ValueChanged<int>? onGlobalReminderMinutesChanged;
  final VoidCallback? onSubmit;
  final bool submitEnabled;
  final bool isSubmitting;
  final FormSubmitPlacement submitPlacement;

  const ProductConfigurationForm({
    super.key,
    required this.isDark,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.widgetMessage,
    required this.submitLabel,
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
    required this.notificationsSupported,
    this.showNotificationsSection = false,
    this.showWidgetHomeSection = true,
    this.globalReminderSettings = AppReminderSettings.defaults,
    this.onGlobalReminderEnabledChanged,
    this.onGlobalReminderMinutesChanged,
    required this.onSubmit,
    required this.submitEnabled,
    required this.isSubmitting,
    this.submitPlacement = FormSubmitPlacement.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final reminderLabel = reminderIntervalOptions
        .firstWhere(
          (option) => option.minutes == globalReminderSettings.intervalMinutes,
          orElse: () => reminderIntervalOptions[2],
        )
        .label;

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
          isDark: isDark,
          accentColor: accentColor,
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
        if (showNotificationsSection) ...[
          const SizedBox(height: 28),
          _sectionLabel('NOTIFICHE', accentColor),
          const SizedBox(height: 10),
          if (!notificationsSupported)
            _NotificationsUnavailableCard(
              isDark: isDark,
              accentColor: accentColor,
            )
          else
            _buildNotificationsSection(reminderLabel),
          if (submitPlacement == FormSubmitPlacement.afterNotifications) ...[
            const SizedBox(height: 28),
            _buildSubmitButton(),
          ],
        ],
        if (showWidgetHomeSection) ...[
          const SizedBox(height: 28),
          _sectionLabel('WIDGET HOME', accentColor),
          const SizedBox(height: 10),
          _WidgetHomeSection(
            isDark: isDark,
            accentColor: accentColor,
            message: widgetMessage,
            tracksInventory: tracksInventory,
          ),
        ],
        if (submitPlacement == FormSubmitPlacement.bottom) ...[
          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ],
    );
  }

  Widget _buildNotificationsSection(String reminderLabel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationToggleTile(
            isDark: isDark,
            accentColor: accentColor,
            title: 'Promemoria registrazione',
            subtitle: globalReminderSettings.enabled
                ? 'Attivo circa ogni $reminderLabel'
                : 'Ti ricorda di registrare i prodotti tracciati circa ogni intervallo scelto.',
            value: globalReminderSettings.enabled,
            onChanged: onGlobalReminderEnabledChanged,
          ),
          if (globalReminderSettings.enabled) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: globalReminderSettings.intervalMinutes,
              decoration: _notificationDecoration(
                hint: 'Intervallo promemoria',
                icon: Icons.schedule_rounded,
              ),
              items: reminderIntervalOptions
                  .map(
                    (option) => DropdownMenuItem<int>(
                      value: option.minutes,
                      child: Text(
                        option.label,
                        style: const TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onGlobalReminderMinutesChanged?.call(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: submitEnabled ? onSubmit : null,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: isDark ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                submitLabel,
                style: const TextStyle(fontFamily: AppFonts.sans,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  InputDecoration _notificationDecoration({
    required String hint,
    required IconData icon,
  }) {
    return trackingInputDecoration(
      hint: hint,
      icon: icon,
      isDark: isDark,
      accentColor: accentColor,
      fillColorOverride:
          isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      enabledBorderColor: isDark
          ? accentColor.withValues(alpha: 0.12)
          : accentColor.withValues(alpha: 0.20),
    );
  }
}

class _TrackingModeSection extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final bool tracksInventory;
  final ValueChanged<bool> onChanged;

  const _TrackingModeSection({
    required this.isDark,
    required this.accentColor,
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

class _NotificationToggleTile extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool value)? onChanged;

  const _NotificationToggleTile({
    required this.isDark,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.08)
            : accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: AppFonts.sans,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: AppFonts.sans,
                    fontSize: 12,
                    height: 1.45,
                    color: context.colors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: accentColor,
            onChanged:
                onChanged == null ? null : (next) async => onChanged!(next),
          ),
        ],
      ),
    );
  }
}

class _NotificationsUnavailableCard extends StatelessWidget {
  final bool isDark;
  final Color accentColor;

  const _NotificationsUnavailableCard({
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_rounded, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Disponibile su Android. Le notifiche possono essere configurate e usate solo sui dispositivi Android.',
              style: TextStyle(fontFamily: AppFonts.sans,
                fontSize: 13,
                height: 1.5,
                color: context.colors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetHomeSection extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final String message;
  final bool tracksInventory;

  const _WidgetHomeSection({
    required this.isDark,
    required this.accentColor,
    required this.message,
    required this.tracksInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Widget Home Android',
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.colors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 13,
              height: 1.55,
              color: context.colors.textBody,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _WidgetFeatureBox(
                  isDark: isDark,
                  accentColor: accentColor,
                  icon: Icons.touch_app_rounded,
                  title: 'Tap rapido',
                  subtitle: 'Segna un utilizzo in un tap',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WidgetFeatureBox(
                  isDark: isDark,
                  accentColor: accentColor,
                  icon: tracksInventory
                      ? Icons.inventory_2_rounded
                      : Icons.insights_rounded,
                  title: 'Sempre attivo',
                  subtitle: tracksInventory
                      ? 'Mostra residuo e costo aggiornati'
                      : 'Mostra conteggio e costo aggiornati',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WidgetFeatureBox extends StatelessWidget {
  final bool isDark;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;

  const _WidgetFeatureBox({
    required this.isDark,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.08)
            : accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontFamily: AppFonts.sans,
              fontSize: 12,
              height: 1.45,
              color: context.colors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderIntervalOption {
  final int minutes;
  final String label;

  const ReminderIntervalOption({
    required this.minutes,
    required this.label,
  });
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

const List<ReminderIntervalOption> reminderIntervalOptions = [
  ReminderIntervalOption(minutes: 30, label: '30 minuti'),
  ReminderIntervalOption(minutes: 60, label: '1 ora'),
  ReminderIntervalOption(minutes: 120, label: '2 ore'),
  ReminderIntervalOption(minutes: 240, label: '4 ore'),
  ReminderIntervalOption(minutes: 480, label: '8 ore'),
  ReminderIntervalOption(minutes: 720, label: '12 ore'),
];
