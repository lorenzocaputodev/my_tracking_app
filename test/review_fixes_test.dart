import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _product({
  int pieces = 20,
  int packRemaining = 20,
  bool tracksInventory = true,
}) =>
    <String, dynamic>{
      'id': 'p1',
      'name': 'Prodotto',
      'totalCost': 5.0,
      'pieces': pieces,
      'minutesLost': 11,
      'dailyLimit': 0,
      'packRemaining': packRemaining,
      'tracksInventory': tracksInventory,
      'isArchived': false,
    };

Map<String, dynamic> _entryMap(String id, DateTime timestamp) =>
    <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'costDeducted': 0.25,
      'minutesLost': 11,
      'productId': 'p1',
    };

String _entry(String id, DateTime timestamp) =>
    jsonEncode(_entryMap(id, timestamp));

String _csv({required String products, required String plans}) => '''
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
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining
$products
__SECTION__,entries
id,timestamp,costDeducted,minutesLost,productId
__SECTION__,achievements
id,isUnlocked,unlockedAt
__SECTION__,reduction_plan
productId,startAverage,targetPerDay,totalWeeks,startDate
$plans
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => appNow = DateTime.now);

  group('voci registrate dal widget', () {
    test('la scorta viene scalata quando la voce viene unita', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([_product(packRemaining: 10)]),
        'active_product_id': 'p1',
        'widget_pending_entries_v1': jsonEncode([
          {..._entryMap('w1', now), 'deductStock': true},
          _entryMap('w-vecchia', now),
        ]),
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.entries.map((e) => e.id), containsAll(['w1', 'w-vecchia']));
      expect(provider.packRemaining, 9);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('widget_pending_entries_v1'), '[]');
      expect(
        (jsonDecode(prefs.getString('tracked_products_v1')!) as List)
            .first['packRemaining'],
        9,
      );
      provider.dispose();
    });
  });

  group('cancellazione di una voce', () {
    test('una voce di una confezione finita non rimette scorta', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([_product(packRemaining: 18)]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry('vecchia', now.subtract(const Duration(days: 14))),
          _entry('a', now.subtract(const Duration(hours: 2))),
          _entry('b', now.subtract(const Duration(hours: 1))),
        ],
      });
      final provider = MyTrackingProvider();
      await provider.init();

      final old = await provider.deleteEntry('vecchia');
      expect(old!.stockReturned, isFalse);
      expect(provider.packRemaining, 18);

      final recent = await provider.deleteEntry('a');
      expect(recent!.stockReturned, isTrue);
      expect(provider.packRemaining, 19);
      provider.dispose();
    });
  });

  group('piano di riduzione', () {
    test('aggiornare il piano mantiene inizio e media di partenza', () async {
      var now = DateTime(2026, 9, 1, 20);
      appNow = () => now;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1':
            jsonEncode([_product(tracksInventory: false)]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          for (var d = 0; d < 14; d++)
            for (var i = 0; i < 10; i++)
              _entry('e$d-$i', DateTime(2026, 8, 19 + d, 8 + i)),
        ],
      });
      final provider = MyTrackingProvider();
      await provider.init();

      await provider.setReductionPlan(targetPerDay: 4, totalWeeks: 8);
      final first = provider.reductionPlanForProduct('p1')!;

      now = DateTime(2026, 9, 20, 20);
      await provider.setReductionPlan(targetPerDay: 4, totalWeeks: 10);
      final updated = provider.reductionPlanForProduct('p1')!;

      expect(updated.startDate, first.startDate);
      expect(updated.startAverage, first.startAverage);
      expect(updated.totalWeeks, 10);
      provider.dispose();
    });

    test('senza dati iniziali i badge di riduzione restano bloccati',
        () async {
      var now = DateTime(2026, 9, 1, 20);
      appNow = () => now;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1':
            jsonEncode([_product(tracksInventory: false)]),
        'active_product_id': 'p1',
      });
      final provider = MyTrackingProvider();
      await provider.init();

      await provider.setReductionPlan(targetPerDay: 0, totalWeeks: 4);
      now = DateTime(2026, 9, 9, 20);
      await provider.logEntry();

      final unlocked = provider.unlockedAchievements.map((a) => a.id).toSet();
      expect(unlocked, isNot(contains(AchievementId.reduction10pct)));
      provider.dispose();
    });
  });

  group('import CSV', () {
    test('una riga del piano incompleta dà un errore leggibile', () {
      final csv = _csv(
        products: 'p1,Prodotto,5.5,20,11,10,6',
        plans: 'p1,12,7,8',
      );
      expect(
        () => AppBackupCsv.decode(csv),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Riga piano di riduzione incompleta.',
          ),
        ),
      );
    });

    test('un valore non numerico dà un errore in italiano', () {
      final csv = _csv(products: 'p1,Prodotto,abc,20,11,10,6', plans: '');
      expect(
        () => AppBackupCsv.decode(csv),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Valore non valido'),
          ),
        ),
      );
    });
  });
}
