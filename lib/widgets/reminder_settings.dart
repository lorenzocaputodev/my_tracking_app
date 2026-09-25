import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import 'option_sheet.dart';
import 'settings_rows.dart';

class ReminderIntervalOption {
  final int minutes;
  final String label;

  const ReminderIntervalOption({required this.minutes, required this.label});
}

const List<ReminderIntervalOption> reminderIntervalOptions = [
  ReminderIntervalOption(minutes: 30, label: '30 minuti'),
  ReminderIntervalOption(minutes: 60, label: '1 ora'),
  ReminderIntervalOption(minutes: 120, label: '2 ore'),
  ReminderIntervalOption(minutes: 240, label: '4 ore'),
  ReminderIntervalOption(minutes: 480, label: '8 ore'),
  ReminderIntervalOption(minutes: 720, label: '12 ore'),
];

String _intervalLabel(int minutes) => reminderIntervalOptions
    .firstWhere(
      (o) => o.minutes == minutes,
      orElse: () => reminderIntervalOptions[2],
    )
    .label;

/// Righe "Promemoria" e "Frequenza", da mettere in un [SettingsGroup]. Le
/// usano sia la configurazione iniziale sia le impostazioni, e si salvano
/// subito: non c'e' un pulsante da premere.
List<Widget> reminderRows(BuildContext context) {
  final provider = context.watch<MyTrackingProvider>();
  final reminders = provider.globalReminderSettings;
  final supported = ProductNotificationService.isSupported;
  final colors = context.colors;

  Future<void> setEnabled(bool value) async {
    if (value) {
      final messenger = ScaffoldMessenger.of(context);
      final warning = context.stats.warning;
      final granted = await ProductNotificationService.ensurePermission();
      if (!granted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Permesso notifiche non concesso.'),
            backgroundColor: warning,
          ),
        );
        return;
      }
    }
    await provider.updateGlobalReminderSettings(
      provider.globalReminderSettings.copyWith(enabled: value),
    );
  }

  Future<void> pickInterval() async {
    final current = provider.globalReminderSettings.intervalMinutes;
    final picked = await showOptionSheet<int>(
      context,
      title: 'Ricordamelo ogni',
      selected: current,
      options: [
        for (final option in reminderIntervalOptions)
          SheetOption(option.minutes, option.label),
      ],
    );
    if (picked == null || picked == current) return;
    await provider.updateGlobalReminderSettings(
      provider.globalReminderSettings.copyWith(intervalMinutes: picked),
    );
  }

  return [
    SettingsRow(
      icon: Icons.notifications_rounded,
      title: 'Promemoria',
      subtitle: supported
          ? 'Ti ricorda di registrare'
          : 'Disponibile solo su Android',
      enabled: supported,
      trailing: Switch(
        value: supported && reminders.enabled,
        onChanged: supported ? setEnabled : null,
      ),
    ),
    if (supported && reminders.enabled)
      SettingsRow(
        icon: Icons.schedule_rounded,
        title: 'Frequenza',
        onTap: pickInterval,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ogni ${_intervalLabel(reminders.intervalMinutes)}',
              style: TextStyle(
                fontFamily: AppFonts.sans,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.accent,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textFaint),
          ],
        ),
      ),
  ];
}
