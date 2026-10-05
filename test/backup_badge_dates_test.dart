import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/models/app_reminder_settings.dart';
import 'package:my_tracking_app/models/reduction_plan.dart';
import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 9, 25, 17);

const _product = TrackedProduct(
  id: 'p1',
  name: 'Sigarette',
  totalCost: 6,
  pieces: 20,
  minutesLost: 11,
  dailyLimit: 3,
  packRemaining: 20,
);

List<SmokeEntry> _twoPerDay({required DateTime from, required int days}) => [
      for (var d = 0; d < days; d++)
        for (final hour in const [9, 15])
          SmokeEntry(
            id: 'e$d-$hour',
            timestamp: DateTime(from.year, from.month, from.day + d, hour),
            costDeducted: 0.3,
            minutesLost: 11,
            productId: 'p1',
          ),
    ];

String _backup({
  required List<SmokeEntry> entries,
  List<Achievement> achievements = const [],
}) {
  return AppBackupCsv.encode(
    AppBackupData(
      backupVersion: AppBackupCsv.backupVersion,
      exportedAt: _now.toUtc(),
      activeProductId: 'p1',
      themePreferenceName: 'dark',
      onboardingDone: true,
      hasCompletedSetup: true,
      globalReminderSettings: AppReminderSettings.defaults,
      products: const [_product],
      entries: entries,
      achievements: achievements,
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

DateTime? _unlockedAt(MyTrackingProvider provider, AchievementId id) =>
    provider.allAchievements.firstWhere((a) => a.id == id).unlockedAt;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    appNow = () => _now;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  tearDown(() => appNow = DateTime.now);

  test('i badge sbloccati dall\'import prendono la data dalla cronologia',
      () async {
    final provider = await _bootedProvider();
    await provider.importFullBackupCsv(
      _backup(entries: _twoPerDay(from: DateTime(2026, 9, 16), days: 10)),
    );

    expect(
      _unlockedAt(provider, AchievementId.firstEntry),
      DateTime(2026, 9, 16, 9),
    );
    expect(
      _unlockedAt(provider, AchievementId.streak3),
      DateTime(2026, 9, 18, 9),
    );
    expect(
      _unlockedAt(provider, AchievementId.streak7),
      DateTime(2026, 9, 22, 9),
    );
    expect(
      _unlockedAt(provider, AchievementId.tracked7days),
      DateTime(2026, 9, 22, 9),
    );
    expect(
      _unlockedAt(provider, AchievementId.underLimit1),
      DateTime(2026, 9, 17),
    );
    expect(
      _unlockedAt(provider, AchievementId.underLimit7),
      DateTime(2026, 9, 23),
    );
    expect(_unlockedAt(provider, AchievementId.streak14), isNull);
  });

  test('le date dei badge restano quelle del backup', () async {
    final provider = await _bootedProvider();
    final original = DateTime.utc(2026, 8, 1, 10);
    await provider.importFullBackupCsv(
      _backup(
        entries: _twoPerDay(from: DateTime(2026, 9, 16), days: 10),
        achievements: [
          Achievement.definition(AchievementId.streak3).unlock(original),
        ],
      ),
    );

    expect(_unlockedAt(provider, AchievementId.streak3), original);
  });

  test('un badge sbloccato senza data non finisce nel 1970', () async {
    final provider = await _bootedProvider();
    await provider.importFullBackupCsv(
      _backup(
        entries: _twoPerDay(from: DateTime(2026, 9, 16), days: 10),
        achievements: [
          Achievement.definition(AchievementId.firstEntry)
              .unlock(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
        ],
      ),
    );

    expect(
      _unlockedAt(provider, AchievementId.firstEntry),
      DateTime(2026, 9, 16, 9),
    );
  });

  test('le date ricostruite sopravvivono al riavvio', () async {
    final first = await _bootedProvider();
    await first.importFullBackupCsv(
      _backup(entries: _twoPerDay(from: DateTime(2026, 9, 16), days: 10)),
    );

    final second = await _bootedProvider();

    expect(
      _unlockedAt(second, AchievementId.streak3),
      DateTime(2026, 9, 18, 9),
    );
  });

  test('un badge raggiunto oggi prende l\'ora della registrazione', () async {
    final provider = await _bootedProvider();
    await provider.importFullBackupCsv(
      _backup(entries: _twoPerDay(from: DateTime(2026, 9, 23), days: 2)),
    );
    appNow = () => DateTime(2026, 9, 25, 9, 30);
    expect(_unlockedAt(provider, AchievementId.streak3), isNull);

    await provider.logEntry();

    expect(
      _unlockedAt(provider, AchievementId.streak3),
      DateTime(2026, 9, 25, 9, 30),
    );
  });
}
