import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/l10n/l10n.dart';
import 'package:my_tracking_app/models/app_reminder_settings.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/screens/settings_screen.dart';
import 'package:my_tracking_app/theme/app_theme.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:my_tracking_app/utils/app_formatters.dart';

Map<String, Object> _prefs() => <String, Object>{
      'onboarding_done': true,
      'hasCompletedSetup': true,
      'active_product_id': 'p1',
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': 'p1',
          'name': 'Prodotto',
          'totalCost': 6.0,
          'pieces': 20,
          'minutesLost': 11,
          'dailyLimit': 10,
          'packRemaining': 13,
          'tracksInventory': true,
          'isArchived': false,
        },
      ]),
    };

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final it = lookupAppLocalizations(const Locale('it'));

  // --- Scelta della lingua ---

  group('lingua di sistema', () {
    test('italiano resta italiano, le altre lingue passano all\'inglese', () {
      expect(
          resolveSystemLocale(const [Locale('it', 'IT')]), const Locale('it'));
      expect(
          resolveSystemLocale(const [Locale('en', 'GB')]), const Locale('en'));
      expect(resolveSystemLocale(const [Locale('fr')]), const Locale('en'));
      expect(
        resolveSystemLocale(const [Locale('fr'), Locale('it')]),
        const Locale('it'),
      );
      expect(resolveSystemLocale(null), const Locale('en'));
    });

    test('la preferenza esplicita vince sulla lingua di sistema', () {
      expect(
        localeForPreference(AppLanguagePreference.italian),
        const Locale('it'),
      );
      expect(
        localeForPreference(AppLanguagePreference.english),
        const Locale('en'),
      );
      expect(localeForPreference(AppLanguagePreference.system), isNull);
      expect(parseLanguagePreference(null), AppLanguagePreference.system);
      expect(parseLanguagePreference('boh'), AppLanguagePreference.system);
    });

    test('il provider salva e rilegge la lingua', () async {
      SharedPreferences.setMockInitialValues(_prefs());
      final provider = MyTrackingProvider();
      await provider.init();
      expect(provider.languagePreference, AppLanguagePreference.system);

      await provider.setLanguagePreference(AppLanguagePreference.english);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(appLanguagePreferenceKey), 'english');
      provider.dispose();

      final reloaded = MyTrackingProvider();
      await reloaded.init();
      expect(reloaded.languagePreference, AppLanguagePreference.english);
      reloaded.dispose();
    });
  });

  // --- Proiezione del mese ---

  test('la proiezione del mese conta solo i giorni tracciati', () async {
    addTearDown(() => appNow = DateTime.now);
    final now = DateTime(2026, 10, 16, 14);
    appNow = () => now;
    final prefs = _prefs()
      ..['smoke_entries'] = [
        for (var i = 0; i < 2; i++)
          jsonEncode(<String, dynamic>{
            'id': 'e$i',
            'timestamp': now.subtract(Duration(minutes: i)).toIso8601String(),
            'costDeducted': 0.3,
            'minutesLost': 11,
            'productId': 'p1',
          }),
      ];
    SharedPreferences.setMockInitialValues(prefs);
    final provider = MyTrackingProvider();
    await provider.init();
    expect(provider.projectedMonthlyUnits(productId: 'p1'), 62);
    expect(
        provider.projectedMonthlyCost(productId: 'p1'), closeTo(18.6, 0.001));
    provider.dispose();
  });

  // --- Backup ---

  group('backup', () {
    AppBackupData data(String? language) => AppBackupData(
          backupVersion: AppBackupCsv.backupVersion,
          exportedAt: DateTime.parse('2026-10-15T08:00:00.000Z'),
          activeProductId: '',
          themePreferenceName: 'dark',
          languagePreferenceName: language,
          onboardingDone: true,
          hasCompletedSetup: true,
          globalReminderSettings: AppReminderSettings.defaults,
          products: const [],
          entries: const [],
          achievements: const [],
          reductionPlans: const [],
        );

    test('la lingua passa dal backup', () {
      final decoded = AppBackupCsv.decode(AppBackupCsv.encode(data('english')));
      expect(decoded.languagePreferenceName, 'english');
    });

    test('un backup vecchio non porta la lingua', () {
      final decoded = AppBackupCsv.decode(AppBackupCsv.encode(data(null)));
      expect(decoded.languagePreferenceName, isNull);
    });
  });

  // --- Testi ---

  group('testi', () {
    test('i file di traduzione hanno le stesse chiavi', () {
      Set<String> keys(String path) =>
          (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
              .keys
              .where((k) => !k.startsWith('@'))
              .toSet();
      expect(keys('lib/l10n/app_en.arb'), keys('lib/l10n/app_it.arb'));
    });

    test('testi composti in inglese', () {
      expect(en.timeAgo(null), 'Never');
      expect(en.timeAgo(const Duration(hours: 2, minutes: 5)), '2h 5m ago');
      expect(it.timeAgo(const Duration(days: 3)), '3g fa');
      expect(
        en.homeInsight(
          const HomeInsight(type: HomeInsightType.limitRemaining, value: 1),
        ),
        '1 unit left before the limit',
      );
      expect(
        it.homeInsight(
          const HomeInsight(type: HomeInsightType.limitRemaining, value: 3),
        ),
        'Mancano 3 unità al limite',
      );
      expect(
        en.homeInsight(
          const HomeInsight(
            type: HomeInsightType.comparedToYesterday,
            value: -2,
          ),
        ),
        '-2 compared to yesterday',
      );
      expect(en.entriesCount(1), '1 entry');
      expect(it.entriesCount(4), '4 registrazioni');
    });

    test('sette giorni della settimana in ogni lingua', () {
      expect(it.weekdaysShort.split(','), hasLength(7));
      expect(en.weekdaysShort.split(','), hasLength(7));
    });

    test('il widget ha le stesse stringhe in tutte le lingue', () {
      Set<String> names(String path) => RegExp(r'<string name="(\w+)"')
          .allMatches(File(path).readAsStringSync())
          .map((m) => m.group(1)!)
          .where((n) => n != 'app_name')
          .toSet();
      const res = 'android/app/src/main/res';
      final base = names('$res/values/strings.xml');
      expect(names('$res/values-en/strings.xml'), base);
      expect(names('$res/values-it/strings.xml'), base);
    });

    test('importi nel formato della lingua', () {
      addTearDown(() => L10n.current = it);
      L10n.current = it;
      expect(formatMoney(1.5), '1,50 €');
      L10n.current = en;
      expect(formatMoney(1.5), '€1.50');
      expect(formatDecimal(2.5, decimals: 1), '2.5');
    });

    test('importi nella valuta scelta', () {
      addTearDown(() {
        L10n.current = it;
        L10n.currency = AppCurrency.eur;
      });
      L10n.currency = AppCurrency.usd;
      L10n.current = it;
      expect(formatMoney(1.5), r'1,50 $');
      L10n.current = en;
      expect(formatMoney(1.5), r'$1.50');
      L10n.currency = AppCurrency.gbp;
      expect(formatMoney(12, decimals: 0), '£12');
      expect(parseCurrency('gbp'), AppCurrency.gbp);
      expect(parseCurrency(null), AppCurrency.eur);
      expect(parseCurrency('jpy'), AppCurrency.eur);
    });
  });

  // --- Impostazioni ---

  testWidgets('le impostazioni in inglese mostrano la scelta della lingua', (
    tester,
  ) async {
    addTearDown(() => L10n.currency = AppCurrency.eur);
    SharedPreferences.setMockInitialValues(_prefs());
    final provider = MyTrackingProvider();
    await tester.runAsync(() => provider.init());
    provider.setForeground(false);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<MyTrackingProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.of(Brightness.dark),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('LANGUAGE AND CURRENCY'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);

    await tester.tap(find.text('Italiano'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(provider.languagePreference, AppLanguagePreference.italian);

    await tester.tap(find.text(r'$'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(provider.currency, AppCurrency.usd);
    expect(L10n.currency, AppCurrency.usd);

    await tester.scrollUntilVisible(find.text('Check for updates'), 300);
    expect(find.text('No backup yet: save a CSV file with all your data'),
        findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
