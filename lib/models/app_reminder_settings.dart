class AppReminderSettings {
  final bool enabled;
  final int intervalMinutes;

  const AppReminderSettings({
    this.enabled = false,
    this.intervalMinutes = 120,
  });

  AppReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
  }) {
    return AppReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'intervalMinutes': intervalMinutes,
      };

  factory AppReminderSettings.fromJson(Map<String, dynamic> json) {
    int clampInterval(num? value) {
      if (value == null) return 120;
      final parsed = value.toInt();
      if (parsed < 30) return 30;
      if (parsed > 720) return 720;
      return parsed;
    }

    return AppReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      intervalMinutes: clampInterval(json['intervalMinutes'] as num?),
    );
  }

  static AppReminderSettings migrateFromLegacyProductMaps(
    List<dynamic> rawProducts,
  ) {
    final enabledIntervals = <int>[];
    var sawLegacyReminder = false;

    for (final item in rawProducts) {
      if (item is! Map) continue;
      final product = item.cast<String, dynamic>();
      final rawSettings = product['notificationSettings'];
      if (rawSettings is! Map) continue;
      final settings = rawSettings.cast<String, dynamic>();
      if (!settings.containsKey('periodicReminderEnabled') &&
          !settings.containsKey('periodicReminderMinutes')) {
        continue;
      }

      sawLegacyReminder = true;
      final enabled = settings['periodicReminderEnabled'] as bool? ?? false;
      if (!enabled) continue;

      enabledIntervals.add(
        AppReminderSettings.fromJson(
          <String, dynamic>{
            'enabled': true,
            'intervalMinutes': settings['periodicReminderMinutes'],
          },
        ).intervalMinutes,
      );
    }

    if (!sawLegacyReminder || enabledIntervals.isEmpty) {
      return defaults;
    }

    final distinctIntervals = enabledIntervals.toSet();
    if (distinctIntervals.length != 1) {
      return defaults;
    }

    return AppReminderSettings(
      enabled: true,
      intervalMinutes: distinctIntervals.first,
    );
  }

  static const AppReminderSettings defaults = AppReminderSettings();
}
