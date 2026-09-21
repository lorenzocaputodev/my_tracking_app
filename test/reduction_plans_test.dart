import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/models/app_reminder_settings.dart';
import 'package:my_tracking_app/models/reduction_plan.dart';
import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_backup_csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _plansKey = 'reduction_plans_v2';
const _legacyPlanKey = 'reduction_plan';

Map<String, dynamic> _product({
  required String id,
  required String name,
  bool isArchived = false,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'totalCost': 5.0,
      'pieces': 20,
      'minutesLost': 11,
      'dailyLimit': 0,
      'packRemaining': 20,
      'tracksInventory': true,
      'isArchived': isArchived,
    };

String _legacyPlan({required String productId}) => jsonEncode(<String, dynamic>{
      'productId': productId,
      'startAverage': 12.0,
      'targetPerDay': 6.0,
      'totalWeeks': 8,
      'startDate': DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String(),
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('piani per prodotto', () {
    test('due prodotti possono avere ciascuno il proprio piano', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      await provider.addProduct(first);
      await provider.addProduct(second);

      await provider.setReductionPlan(
        productId: 'p1',
        targetPerDay: 3,
        totalWeeks: 6,
      );
      await provider.setReductionPlan(
        productId: 'p2',
        targetPerDay: 9,
        totalWeeks: 12,
      );

      expect(provider.reductionPlans, hasLength(2));
      expect(provider.reductionPlanForProduct('p1')!.targetPerDay, 3);
      expect(provider.reductionPlanForProduct('p1')!.totalWeeks, 6);
      expect(provider.reductionPlanForProduct('p2')!.targetPerDay, 9);
      expect(provider.reductionPlanForProduct('p2')!.totalWeeks, 12);

      provider.dispose();
    });

    test('eliminare un piano non tocca quello dell altro prodotto', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      await provider.addProduct(first);
      await provider.addProduct(second);
      await provider.setReductionPlan(
        productId: 'p1',
        targetPerDay: 3,
        totalWeeks: 6,
      );
      await provider.setReductionPlan(
        productId: 'p2',
        targetPerDay: 9,
        totalWeeks: 12,
      );

      await provider.deleteReductionPlan(productId: 'p1');

      expect(provider.reductionPlanForProduct('p1'), isNull);
      expect(provider.reductionPlanForProduct('p2'), isNotNull);

      provider.dispose();
    });

    test('il piano di un prodotto archiviato non risulta attivo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      await provider.addProduct(first);
      await provider.addProduct(second);
      await provider.setReductionPlan(
        productId: 'p1',
        targetPerDay: 3,
        totalWeeks: 6,
      );

      await provider.archiveProduct('p1');
      expect(provider.reductionPlanForProduct('p1'), isNull);

      await provider.restoreProduct('p1');
      expect(provider.reductionPlanForProduct('p1'), isNotNull);

      provider.dispose();
    });

    test('eliminare definitivamente un prodotto rimuove il suo piano',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      await provider.addProduct(first);
      await provider.addProduct(second);
      await provider.setReductionPlan(
        productId: 'p1',
        targetPerDay: 3,
        totalWeeks: 6,
      );
      await provider.archiveProduct('p1');

      await provider.deleteArchivedProduct('p1');

      expect(provider.reductionPlans, isEmpty);

      provider.dispose();
    });
  });

  group('migrazione dal piano singolo', () {
    test('il piano legacy finisce nella mappa e la vecchia chiave sparisce',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([
          _product(id: 'p1', name: 'Prodotto 1'),
          _product(id: 'p2', name: 'Prodotto 2'),
        ]),
        'active_product_id': 'p1',
        _legacyPlanKey: _legacyPlan(productId: 'p2'),
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.reductionPlanForProduct('p2'), isNotNull);
      expect(provider.reductionPlanForProduct('p2')!.targetPerDay, 6.0);
      expect(provider.reductionPlanForProduct('p1'), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_legacyPlanKey), isFalse);
      expect(prefs.getString(_plansKey), isNotNull);

      final stored =
          (jsonDecode(prefs.getString(_plansKey)!) as Map).cast<String, dynamic>();
      expect(stored.keys, <String>['p2']);

      provider.dispose();
    });

    test('un piano legacy senza productId si lega al prodotto attivo',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([
          _product(id: 'p1', name: 'Prodotto 1'),
        ]),
        'active_product_id': 'p1',
        _legacyPlanKey: _legacyPlan(productId: ''),
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.reductionPlanForProduct('p1'), isNotNull);
      expect(provider.reductionPlanForProduct('p1')!.productId, 'p1');

      provider.dispose();
    });

    test('un piano che punta a un prodotto inesistente viene scartato',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([
          _product(id: 'p1', name: 'Prodotto 1'),
        ]),
        'active_product_id': 'p1',
        _legacyPlanKey: _legacyPlan(productId: 'sparito'),
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.reductionPlans, isEmpty);
      expect(provider.reductionPlanForProduct('p1'), isNull);

      provider.dispose();
    });

    test('i piani sopravvivono a un riavvio', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': jsonEncode([
          _product(id: 'p1', name: 'Prodotto 1'),
          _product(id: 'p2', name: 'Prodotto 2'),
        ]),
        'active_product_id': 'p1',
      });

      final first = MyTrackingProvider();
      await first.init();
      await first.setReductionPlan(
        productId: 'p1',
        targetPerDay: 4,
        totalWeeks: 10,
      );
      await first.setReductionPlan(
        productId: 'p2',
        targetPerDay: 2,
        totalWeeks: 5,
      );
      first.dispose();

      final prefs = await SharedPreferences.getInstance();
      final snapshot = <String, Object>{
        'tracked_products_v1': prefs.getString('tracked_products_v1')!,
        'active_product_id': prefs.getString('active_product_id')!,
        _plansKey: prefs.getString(_plansKey)!,
      };
      SharedPreferences.setMockInitialValues(snapshot);

      final second = MyTrackingProvider();
      await second.init();

      expect(second.reductionPlans, hasLength(2));
      expect(second.reductionPlanForProduct('p1')!.totalWeeks, 10);
      expect(second.reductionPlanForProduct('p2')!.totalWeeks, 5);

      second.dispose();
    });
  });

  group('backup CSV con piu piani', () {
    AppBackupData buildData(List<ReductionPlan> plans) => AppBackupData(
          backupVersion: AppBackupCsv.backupVersion,
          exportedAt: DateTime.parse('2026-09-21T08:30:00.000Z'),
          activeProductId: 'p1',
          themePreferenceName: 'dark',
          onboardingDone: true,
          hasCompletedSetup: true,
          globalReminderSettings: const AppReminderSettings(),
          products: const <TrackedProduct>[
            TrackedProduct(
              id: 'p1',
              name: 'Prodotto 1',
              totalCost: 5.0,
              pieces: 20,
              packRemaining: 20,
            ),
            TrackedProduct(
              id: 'p2',
              name: 'Prodotto 2',
              totalCost: 6.0,
              pieces: 20,
              packRemaining: 20,
            ),
          ],
          entries: <SmokeEntry>[
            SmokeEntry(
              id: 'e1',
              timestamp: DateTime.parse('2026-09-20T08:15:00.000Z'),
              costDeducted: 0.25,
              minutesLost: 11,
              productId: 'p1',
            ),
          ],
          achievements: <Achievement>[
            Achievement.definition(AchievementId.firstEntry).unlock(),
          ],
          reductionPlans: plans,
        );

    test('roundtrip di due piani', () {
      final data = buildData(<ReductionPlan>[
        ReductionPlan(
          productId: 'p1',
          startAverage: 12,
          targetPerDay: 7,
          totalWeeks: 8,
          startDate: DateTime.parse('2026-09-01T00:00:00.000Z'),
        ),
        ReductionPlan(
          productId: 'p2',
          startAverage: 5,
          targetPerDay: 2,
          totalWeeks: 4,
          startDate: DateTime.parse('2026-09-10T00:00:00.000Z'),
        ),
      ]);

      final decoded = AppBackupCsv.decode(AppBackupCsv.encode(data));

      expect(decoded.reductionPlans, hasLength(2));
      final byProduct = <String, ReductionPlan>{
        for (final plan in decoded.reductionPlans) plan.productId: plan,
      };
      expect(byProduct['p1']!.targetPerDay, 7);
      expect(byProduct['p1']!.totalWeeks, 8);
      expect(byProduct['p2']!.targetPerDay, 2);
      expect(byProduct['p2']!.totalWeeks, 4);
    });

    test('un backup senza piani resta valido', () {
      final decoded = AppBackupCsv.decode(
        AppBackupCsv.encode(buildData(const <ReductionPlan>[])),
      );
      expect(decoded.reductionPlans, isEmpty);
    });

    test('un piano che punta a un prodotto assente viene scartato', () {
      final csv = AppBackupCsv.encode(
        buildData(<ReductionPlan>[
          ReductionPlan(
            productId: 'p1',
            startAverage: 12,
            targetPerDay: 7,
            totalWeeks: 8,
            startDate: DateTime.parse('2026-09-01T00:00:00.000Z'),
          ),
        ]),
      ).replaceFirst('\np1,12.0,7.0,8,', '\nsparito,12.0,7.0,8,');

      final decoded = AppBackupCsv.decode(csv);

      expect(decoded.products, hasLength(2));
      expect(decoded.entries, hasLength(1));
      expect(decoded.reductionPlans, isEmpty);
    });

    test('un backup di formato precedente con un solo piano resta leggibile',
        () {
      const csv = '''
__MY_TRACKING_APP_BACKUP__,5
__SECTION__,meta
key,value
backupVersion,5
exportedAtIso,2026-04-03T08:30:00.000Z
activeProductId,p1
themePreference,dark
onboardingDone,true
hasCompletedSetup,true
__SECTION__,global_reminder
enabled,intervalMinutes
false,120
__SECTION__,products
id,name,totalCost,pieces,minutesLost,dailyLimit,packRemaining,tracksInventory,directUnitCost,isArchived
p1,Prodotto 1,5.5,20,11,10,6,true,,false
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

      expect(decoded.reductionPlans, hasLength(1));
      expect(decoded.reductionPlans.first.productId, 'p1');
      expect(decoded.reductionPlans.first.targetPerDay, 7);
    });
  });
}
