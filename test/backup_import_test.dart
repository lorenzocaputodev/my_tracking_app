import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/models/app_reminder_settings.dart';
import 'package:my_tracking_app/models/reduction_plan.dart';
import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _product = TrackedProduct(
  id: 'p1',
  name: 'terea turchesi',
  totalCost: 5.5,
  pieces: 20,
  minutesLost: 6,
  dailyLimit: 10,
  packRemaining: 11,
);

String _backupCsv({required int entryCount}) {
  final entries = <SmokeEntry>[
    for (var i = 0; i < entryCount; i++)
      SmokeEntry(
        id: 'e$i',
        timestamp: DateTime.utc(2026, 4, 4).add(Duration(hours: i)),
        costDeducted: 0.275,
        minutesLost: 6,
        productId: 'p1',
      ),
  ];

  return AppBackupCsv.encode(
    AppBackupData(
      backupVersion: AppBackupCsv.backupVersion,
      exportedAt: DateTime.utc(2026, 9, 26),
      activeProductId: 'p1',
      themePreferenceName: 'light',
      onboardingDone: true,
      hasCompletedSetup: true,
      globalReminderSettings:
          const AppReminderSettings(enabled: true, intervalMinutes: 120),
      products: const <TrackedProduct>[_product],
      entries: entries,
      achievements: <Achievement>[
        Achievement.definition(AchievementId.firstEntry).unlock(),
      ],
      reductionPlans: const <ReductionPlan>[],
    ),
  );
}

Future<MyTrackingProvider> _bootedProvider() async {
  final provider = MyTrackingProvider();
  await provider.init();
  provider.setForeground(false);
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('l\'import riferisce quante registrazioni ha davvero ripristinato',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = await _bootedProvider();

    final outcome = await provider.importFullBackupCsv(_backupCsv(entryCount: 1513));

    expect(outcome.entries, 1513);
    expect(outcome.products, 1);
    expect(outcome.unlockedAchievements, 1);
  });

  test('un backup senza cronologia si riconosce prima di sostituire i dati',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = await _bootedProvider();

    final data = provider.readBackupCsv(_backupCsv(entryCount: 0));

    expect(data.entries, isEmpty);
    expect(data.products, hasLength(1));

    final outcome = await provider.restoreBackup(data);
    expect(outcome.entries, 0);
    expect(outcome.products, 1);
  });

  test('la cronologia importata sopravvive al riavvio dell\'app', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final first = await _bootedProvider();
    await first.importFullBackupCsv(_backupCsv(entryCount: 1513));

    final second = await _bootedProvider();

    expect(second.entries, hasLength(1513));
    expect(second.visibleEntries, hasLength(1513));
    expect(second.activeProduct.name, 'terea turchesi');
  });
}
