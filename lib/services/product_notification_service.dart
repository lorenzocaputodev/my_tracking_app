import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/app_reminder_settings.dart';

@pragma('vm:entry-point')
void productNotificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await ProductNotificationService.ensureBackgroundInitialized();
    return ProductNotificationService.handleBackgroundTask(task, inputData);
  });
}

class ProductNotificationService {
  static const String reminderChannelId = 'tracking_reminders';
  static const String reminderChannelName = 'Promemoria registrazione';
  static const String reminderChannelDescription =
      'Promemoria generali per ricordare di registrare i prodotti tracciati.';

  static const String _globalReminderTask = 'global_app_reminder';
  static const String _globalReminderWorkName = 'global_tracking_reminder';
  static const String _legacyDailySummaryWorkName = 'global_daily_summary';

  static const String _globalReminderSettingsKey =
      'global_reminder_settings_v1';
  static const String _globalReminderFingerprintKey =
      'notification_global_reminder_fingerprint_v1';
  static const String _globalReminderNextAtKey =
      'notification_global_reminder_next_at_v1';
  static const String _globalReminderLastShownKey =
      'notification_global_reminder_last_shown_at_v1';
  static const String _legacyDailySummarySettingsKey =
      'global_daily_summary_settings_v1';
  static const String _legacyDailySummaryFingerprintKey =
      'notification_global_daily_summary_fingerprint_v1';
  static const String _legacyDailySummaryNextAtKey =
      'notification_global_daily_summary_next_at_v1';

  static const int _globalReminderNotificationId = 904001;
  static const int _legacyDailySummaryNotificationId = 904002;
  static const int _duplicateGuardMs = 2 * 60 * 1000;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _mainInitialized = false;
  static bool _backgroundInitialized = false;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static AppReminderSettings defaultGlobalReminderSettings() =>
      AppReminderSettings.defaults;

  static Future<void> ensureInitialized() async {
    if (!isSupported || _mainInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    try {
      await _plugin.initialize(initializationSettings);
      await Workmanager().initialize(productNotificationCallbackDispatcher);
      await _createChannels();
      _mainInitialized = true;
    } catch (_) {}
  }

  static Future<void> ensureBackgroundInitialized() async {
    if (_backgroundInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    try {
      await _plugin.initialize(initializationSettings);
      await _createChannels();
      _backgroundInitialized = true;
    } catch (_) {}
  }

  static Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannelId,
        reminderChannelName,
        description: reminderChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  static Future<bool> ensurePermission() async {
    if (!isSupported) return false;
    await ensureInitialized();
    if (!_mainInitialized) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  static Future<void> syncAll({
    required AppReminderSettings globalReminderSettings,
  }) async {
    if (!isSupported) return;
    await ensureInitialized();
    if (!_mainInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    await _cleanupLegacyDailySummaryArtifacts(prefs);
    await _syncGlobalReminder(globalReminderSettings, prefs: prefs);
  }

  static Future<bool> handleBackgroundTask(
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    try {
      switch (task) {
        case _globalReminderTask:
          await _handleGlobalReminderTask();
          return true;
        default:
          return true;
      }
    } catch (_) {
      return true;
    }
  }

  static Future<void> _syncGlobalReminder(
    AppReminderSettings settings, {
    required SharedPreferences prefs,
  }) async {
    if (!settings.enabled) {
      await Workmanager().cancelByUniqueName(_globalReminderWorkName);
      await _plugin.cancel(_globalReminderNotificationId);
      await prefs.remove(_globalReminderFingerprintKey);
      await prefs.remove(_globalReminderNextAtKey);
      return;
    }

    final fingerprint = 'on:${settings.intervalMinutes}';
    final storedFingerprint = prefs.getString(_globalReminderFingerprintKey);
    final nextAtMs = prefs.getInt(_globalReminderNextAtKey);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final needsSchedule = storedFingerprint != fingerprint ||
        nextAtMs == null ||
        nextAtMs <= nowMs;

    if (!needsSchedule) return;

    await _scheduleGlobalReminder(
      settings,
      prefs: prefs,
      delay: Duration(minutes: settings.intervalMinutes),
    );
  }

  static Future<void> _handleGlobalReminderTask() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = _loadGlobalReminderSettings(prefs);
    if (!settings.enabled) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastShownMs = prefs.getInt(_globalReminderLastShownKey) ?? 0;
    if (nowMs - lastShownMs > _duplicateGuardMs) {
      await _plugin.show(
        _globalReminderNotificationId,
        '\u{1F4CD} Promemoria',
        'Ricordati di registrare i prodotti tracciati.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            reminderChannelName,
            channelDescription: reminderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      await prefs.setInt(_globalReminderLastShownKey, nowMs);
    }

    await _scheduleGlobalReminder(
      settings,
      prefs: prefs,
      delay: Duration(minutes: settings.intervalMinutes),
    );
  }

  static Future<void> _scheduleGlobalReminder(
    AppReminderSettings settings, {
    required SharedPreferences prefs,
    required Duration delay,
  }) async {
    await Workmanager().registerOneOffTask(
      _globalReminderWorkName,
      _globalReminderTask,
      initialDelay: delay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    await prefs.setString(
      _globalReminderFingerprintKey,
      'on:${settings.intervalMinutes}',
    );
    await prefs.setInt(
      _globalReminderNextAtKey,
      DateTime.now().add(delay).millisecondsSinceEpoch,
    );
  }

  static AppReminderSettings _loadGlobalReminderSettings(
    SharedPreferences prefs,
  ) {
    final raw = prefs.getString(_globalReminderSettingsKey);
    if (raw == null || raw.trim().isEmpty) {
      return AppReminderSettings.defaults;
    }

    try {
      return AppReminderSettings.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return AppReminderSettings.defaults;
    }
  }

  static Future<void> _cleanupLegacyDailySummaryArtifacts(
    SharedPreferences prefs,
  ) async {
    await Workmanager().cancelByUniqueName(_legacyDailySummaryWorkName);
    await _plugin.cancel(_legacyDailySummaryNotificationId);
    await prefs.remove(_legacyDailySummarySettingsKey);
    await prefs.remove(_legacyDailySummaryFingerprintKey);
    await prefs.remove(_legacyDailySummaryNextAtKey);
  }
}
