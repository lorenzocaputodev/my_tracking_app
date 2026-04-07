import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/models/app_reminder_settings.dart';
import 'package:my_tracking_app/models/reduction_plan.dart';
import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';

void main() {
  test('detects full backup CSV marker', () {
    const csv = '__MY_TRACKING_APP_BACKUP__,1\n__SECTION__,meta\nkey,value';
    expect(AppBackupCsv.detectKind(csv), BackupFileKind.fullBackup);
  });

  test('flags non-backup CSV as invalid', () {
    const csv =
        'id,timestamp,costDeducted,minutesLost,productId,productName\n1,2026-04-03T10:00:00.000Z,0.5,11,p1,Prodotto';
    expect(AppBackupCsv.detectKind(csv), BackupFileKind.invalid);
  });

  test('encodes and decodes a full backup roundtrip', () {
    const product = TrackedProduct(
      id: 'p1',
      name: 'Prodotto 1',
      totalCost: 5.5,
      pieces: 20,
      minutesLost: 11,
      dailyLimit: 10,
      packRemaining: 6,
      tracksInventory: false,
      directUnitCost: 1.25,
      isArchived: true,
    );
    final entry = SmokeEntry(
      id: 'e1',
      timestamp: DateTime.parse('2026-04-03T08:15:00.000Z'),
      costDeducted: 0.275,
      minutesLost: 11,
      productId: 'p1',
    );
    final data = AppBackupData(
      backupVersion: AppBackupCsv.backupVersion,
      exportedAt: DateTime.parse('2026-04-03T08:30:00.000Z'),
      activeProductId: 'p1',
      themePreferenceName: 'light',
      onboardingDone: true,
      hasCompletedSetup: true,
      globalReminderSettings: const AppReminderSettings(
        enabled: true,
        intervalMinutes: 240,
      ),
      products: <TrackedProduct>[product],
      entries: <SmokeEntry>[entry],
      achievements: <Achievement>[
        Achievement.definition(AchievementId.firstEntry).unlock(),
        Achievement.definition(AchievementId.tracked7days),
      ],
      reductionPlan: ReductionPlan(
        productId: 'p1',
        startAverage: 12,
        targetPerDay: 7,
        totalWeeks: 8,
        startDate: DateTime.parse('2026-04-01T00:00:00.000Z'),
      ),
    );

    final csv = AppBackupCsv.encode(data);
    final decoded = AppBackupCsv.decode(csv);

    expect(decoded.backupVersion, AppBackupCsv.backupVersion);
    expect(decoded.activeProductId, 'p1');
    expect(decoded.themePreferenceName, 'light');
    expect(decoded.onboardingDone, isTrue);
    expect(decoded.hasCompletedSetup, isTrue);
    expect(decoded.globalReminderSettings.enabled, isTrue);
    expect(decoded.globalReminderSettings.intervalMinutes, 240);
    expect(decoded.products, hasLength(1));
    expect(decoded.entries, hasLength(1));
    expect(decoded.products.first.name, 'Prodotto 1');
    expect(decoded.products.first.isArchived, isTrue);
    expect(decoded.products.first.tracksInventory, isFalse);
    expect(decoded.products.first.directUnitCost, 1.25);
    expect(decoded.entries.first.productId, 'p1');
    expect(
      decoded.achievements
          .firstWhere((a) => a.id == AchievementId.firstEntry)
          .isUnlocked,
      isTrue,
    );
    expect(decoded.reductionPlan, isNotNull);
    expect(decoded.reductionPlan!.productId, 'p1');
    expect(decoded.reductionPlan!.targetPerDay, 7);
  });

  test('throws on full backup entries referencing missing products', () {
    const csv = '''
__MY_TRACKING_APP_BACKUP__,1
__SECTION__,meta
key,value
backupVersion,1
exportedAtIso,2026-04-03T08:30:00.000Z
activeProductId,p1
themePreference,dark
onboardingDone,true
hasCompletedSetup,true
__SECTION__,products
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining
__SECTION__,entries
id,timestamp,costDeducted,minutesLost,productId
e1,2026-04-03T08:15:00.000Z,0.275,11,p1
__SECTION__,achievements
id,isUnlocked,unlockedAt
__SECTION__,reduction_plan
productId,startAverage,targetPerDay,totalWeeks,startDate
''';

    expect(() => AppBackupCsv.decode(csv), throwsFormatException);
  });

  test('decodes legacy product rows without isArchived', () {
    const csv = '''
__MY_TRACKING_APP_BACKUP__,1
__SECTION__,meta
key,value
backupVersion,1
exportedAtIso,2026-04-03T08:30:00.000Z
activeProductId,p1
themePreference,dark
onboardingDone,true
hasCompletedSetup,true
__SECTION__,products
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining
p1,Prodotto 1,5.5,20,11,10,6
__SECTION__,entries
id,timestamp,costDeducted,minutesLost,productId
e1,2026-04-03T08:15:00.000Z,0.275,11,p1
__SECTION__,achievements
id,isUnlocked,unlockedAt
__SECTION__,reduction_plan
productId,startAverage,targetPerDay,totalWeeks,startDate
p1,12,7,8,2026-04-01T00:00:00.000Z
''';

    final decoded = AppBackupCsv.decode(csv);

    expect(decoded.products, hasLength(1));
    expect(decoded.products.first.isArchived, isFalse);
  });

  test('migrates legacy periodic reminders to global reminder when unambiguous',
      () {
    const csv = '''
__MY_TRACKING_APP_BACKUP__,2
__SECTION__,meta
key,value
backupVersion,2
exportedAtIso,2026-04-03T08:30:00.000Z
activeProductId,p1
themePreference,dark
onboardingDone,true
hasCompletedSetup,true
__SECTION__,products
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining,tracksInventory,directUnitCost,periodicReminderEnabled,periodicReminderMinutes,dailySummaryEnabled,dailySummaryHour,dailySummaryMinute,isArchived
p1,Prodotto 1,5.5,20,11,10,6,true,,true,60,false,21,0,false
p2,Prodotto 2,6.0,20,11,10,10,true,,true,60,true,22,15,false
__SECTION__,entries
id,timestamp,costDeducted,minutesLost,productId
e1,2026-04-03T08:15:00.000Z,0.275,11,p1
__SECTION__,achievements
id,isUnlocked,unlockedAt
__SECTION__,reduction_plan
productId,startAverage,targetPerDay,totalWeeks,startDate
''';

    final decoded = AppBackupCsv.decode(csv);

    expect(decoded.globalReminderSettings.enabled, isTrue);
    expect(decoded.globalReminderSettings.intervalMinutes, 60);
  });

  test('ignores legacy daily summary data while keeping backup readable', () {
    const csv = '''
__MY_TRACKING_APP_BACKUP__,4
__SECTION__,meta
key,value
backupVersion,4
exportedAtIso,2026-04-03T08:30:00.000Z
activeProductId,p1
themePreference,dark
onboardingDone,true
hasCompletedSetup,true
__SECTION__,global_reminder
enabled,intervalMinutes
true,120
__SECTION__,global_daily_summary
enabled,hour,minute
true,22,15
__SECTION__,products
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining,tracksInventory,directUnitCost,periodicReminderEnabled,periodicReminderMinutes,dailySummaryEnabled,dailySummaryHour,dailySummaryMinute,isArchived
p1,Prodotto 1,5.5,20,11,10,6,true,,false,60,true,22,15,false
__SECTION__,entries
id,timestamp,costDeducted,minutesLost,productId
e1,2026-04-03T08:15:00.000Z,0.275,11,p1
__SECTION__,achievements
id,isUnlocked,unlockedAt
__SECTION__,reduction_plan
productId,startAverage,targetPerDay,totalWeeks,startDate
''';

    final decoded = AppBackupCsv.decode(csv);

    expect(decoded.globalReminderSettings.enabled, isTrue);
    expect(decoded.globalReminderSettings.intervalMinutes, 120);
    expect(decoded.products, hasLength(1));
    expect(decoded.products.first.name, 'Prodotto 1');
  });
}
