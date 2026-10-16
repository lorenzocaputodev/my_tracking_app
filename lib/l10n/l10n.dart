import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../models/achievement.dart';
import '../providers/my_tracking_provider.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

// --- Lingua ---

enum AppLanguagePreference { italian, english, system }

const appLanguagePreferenceKey = 'app_language';

AppLanguagePreference parseLanguagePreference(String? name) {
  for (final v in AppLanguagePreference.values) {
    if (v.name == name) return v;
  }
  return AppLanguagePreference.system;
}

Locale? localeForPreference(AppLanguagePreference preference) {
  switch (preference) {
    case AppLanguagePreference.italian:
      return const Locale('it');
    case AppLanguagePreference.english:
      return const Locale('en');
    case AppLanguagePreference.system:
      return null;
  }
}

Locale resolveSystemLocale(Iterable<Locale>? systemLocales) {
  for (final locale in systemLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'it') return const Locale('it');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}

Locale resolveAppLocale(AppLanguagePreference preference) =>
    localeForPreference(preference) ??
    resolveSystemLocale(PlatformDispatcher.instance.locales);

// --- Accesso ai testi ---

class L10n {
  static AppLocalizations current = lookupAppLocalizations(const Locale('it'));

  static bool get isItalian => current.localeName == 'it';
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeName => AppLocalizations.of(this).localeName;
}

// --- Badge ---

extension AchievementTexts on AppLocalizations {
  String achievementTitle(AchievementId id) => switch (id) {
        AchievementId.firstEntry => achFirstEntryTitle,
        AchievementId.tracked7days => achTracked7Title,
        AchievementId.tracked30days => achTracked30Title,
        AchievementId.streak3 => achStreak3Title,
        AchievementId.streak7 => achStreak7Title,
        AchievementId.streak14 => achStreak14Title,
        AchievementId.streak30 => achStreak30Title,
        AchievementId.underLimit1 => achUnderLimit1Title,
        AchievementId.underLimit3 => achUnderLimit3Title,
        AchievementId.underLimit7 => achUnderLimit7Title,
        AchievementId.underLimit30 => achUnderLimit30Title,
        AchievementId.reduction10pct => achReduction10Title,
        AchievementId.reduction25pct => achReduction25Title,
        AchievementId.reduction50pct => achReduction50Title,
      };

  String achievementDescription(AchievementId id) => switch (id) {
        AchievementId.firstEntry => achFirstEntryDesc,
        AchievementId.tracked7days => achTracked7Desc,
        AchievementId.tracked30days => achTracked30Desc,
        AchievementId.streak3 => achStreak3Desc,
        AchievementId.streak7 => achStreak7Desc,
        AchievementId.streak14 => achStreak14Desc,
        AchievementId.streak30 => achStreak30Desc,
        AchievementId.underLimit1 => achUnderLimit1Desc,
        AchievementId.underLimit3 => achUnderLimit3Desc,
        AchievementId.underLimit7 => achUnderLimit7Desc,
        AchievementId.underLimit30 => achUnderLimit30Desc,
        AchievementId.reduction10pct => achReduction10Desc,
        AchievementId.reduction25pct => achReduction25Desc,
        AchievementId.reduction50pct => achReduction50Desc,
      };
}

// --- Testi composti ---

extension ComposedTexts on AppLocalizations {
  String timeAgo(Duration? elapsed) {
    if (elapsed == null) return never;
    if (elapsed.inDays > 0) return daysAgo(elapsed.inDays);
    if (elapsed.inHours > 0) {
      final minutes = elapsed.inMinutes.remainder(60);
      return minutes == 0
          ? hoursAgo(elapsed.inHours)
          : hoursMinutesAgo(elapsed.inHours, minutes);
    }
    if (elapsed.inMinutes > 0) return minutesAgo(elapsed.inMinutes);
    return justNow;
  }

  String homeInsight(HomeInsight insight) => switch (insight.type) {
        HomeInsightType.planAhead => insightPlanAhead,
        HomeInsightType.planOnTrack => insightPlanOnTrack,
        HomeInsightType.planBehind => insightPlanBehind,
        HomeInsightType.limitRemaining => insightLimitRemaining(insight.value),
        HomeInsightType.comparedToYesterday => insightComparedToYesterday(
            switch (insight.value) {
              > 0 => '+${insight.value}',
              < 0 => '${insight.value}',
              _ => '=',
            },
          ),
      };
}

// --- Stime dei minuti ---

extension MinutesPresetTexts on AppLocalizations {
  String minutesPresetName(int minutes) => switch (minutes) {
        11 => presetCigarette,
        5 => presetEcigarette,
        6 => presetHeatedTobacco,
        30 => presetCigar,
        20 => presetHookah,
        _ => noEstimate,
      };
}
