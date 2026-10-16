import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/my_tracking_provider.dart';
import '../services/product_notification_service.dart';
import '../theme/app_fonts.dart';
import '../theme/theme_context.dart';
import 'option_sheet.dart';
import 'settings_rows.dart';
import '../l10n/l10n.dart';

const List<int> reminderIntervalOptions = [30, 60, 120, 240, 480, 720];

String _intervalLabel(AppLocalizations l10n, int minutes) {
  final value = reminderIntervalOptions.contains(minutes) ? minutes : 120;
  return value < 60
      ? l10n.durationMinutes(value)
      : l10n.durationHours(value ~/ 60);
}

List<Widget> reminderRows(BuildContext context) {
  final provider = context.watch<MyTrackingProvider>();
  final reminders = provider.globalReminderSettings;
  final supported = ProductNotificationService.isSupported;
  final colors = context.colors;
  final l10n = context.l10n;

  Future<void> setEnabled(bool value) async {
    if (value) {
      final messenger = ScaffoldMessenger.of(context);
      final warning = context.stats.warning;
      final granted = await ProductNotificationService.ensurePermission();
      if (!granted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.notificationPermissionDenied),
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
      title: l10n.remindMeEvery,
      selected: current,
      options: [
        for (final minutes in reminderIntervalOptions)
          SheetOption(minutes, _intervalLabel(l10n, minutes)),
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
      title: l10n.reminders,
      subtitle: supported
          ? l10n.remindersSubtitle
          : l10n.androidOnly,
      enabled: supported,
      trailing: Switch(
        value: supported && reminders.enabled,
        onChanged: supported ? setEnabled : null,
      ),
    ),
    if (supported && reminders.enabled)
      SettingsRow(
        icon: Icons.schedule_rounded,
        title: l10n.frequency,
        onTap: pickInterval,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.every(_intervalLabel(l10n, reminders.intervalMinutes)),
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
