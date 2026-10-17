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
    final enabledMinutes = <num?>[];
    for (final item in rawProducts) {
      if (item is! Map) continue;
      final rawSettings = item['notificationSettings'];
      if (rawSettings is! Map) continue;
      if (rawSettings['periodicReminderEnabled'] as bool? ?? false) {
        enabledMinutes.add(rawSettings['periodicReminderMinutes'] as num?);
      }
    }
    return fromLegacyIntervals(enabledMinutes);
  }

  static AppReminderSettings fromLegacyIntervals(
      Iterable<num?> enabledMinutes) {
    final distinctIntervals = enabledMinutes
        .map(
          (minutes) => AppReminderSettings.fromJson(
            <String, dynamic>{'enabled': true, 'intervalMinutes': minutes},
          ).intervalMinutes,
        )
        .toSet();
    if (distinctIntervals.length != 1) return defaults;
    return AppReminderSettings(
      enabled: true,
      intervalMinutes: distinctIntervals.first,
    );
  }

  static const AppReminderSettings defaults = AppReminderSettings();
}
