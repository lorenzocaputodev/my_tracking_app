import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'archive keeps product history and moves product to archived list',
    () async {
      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.5,
        pieces: 20,
        packRemaining: 20,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 6.0,
        pieces: 20,
        packRemaining: 20,
      );

      await provider.addProduct(first);
      await provider.addProduct(second);
      await provider.logEntry(productId: first.id);

      final archived = await provider.archiveProduct(first.id);

      expect(archived, isTrue);
      expect(
        provider.activeProducts.map((product) => product.id),
        isNot(contains(first.id)),
      );
      expect(
        provider.archivedProducts.map((product) => product.id),
        contains(first.id),
      );
      expect(provider.entriesForProduct(first.id), hasLength(1));

      provider.dispose();
    },
  );

  test('archiving active product reassigns the active product', () async {
    final provider = MyTrackingProvider();
    const first = TrackedProduct(
      id: 'p1',
      name: 'Prodotto 1',
      totalCost: 5.5,
      pieces: 20,
      packRemaining: 20,
    );
    const second = TrackedProduct(
      id: 'p2',
      name: 'Prodotto 2',
      totalCost: 6.0,
      pieces: 20,
      packRemaining: 20,
    );

    await provider.addProduct(first);
    await provider.addProduct(second);

    expect(provider.activeProduct.id, second.id);

    final archived = await provider.archiveProduct(second.id);

    expect(archived, isTrue);
    expect(provider.activeProduct.id, first.id);

    provider.dispose();
  });

  test('cannot archive the last active product', () async {
    final provider = MyTrackingProvider();
    const product = TrackedProduct(
      id: 'p1',
      name: 'Prodotto 1',
      totalCost: 5.5,
      pieces: 20,
      packRemaining: 20,
    );

    await provider.addProduct(product);

    final archived = await provider.archiveProduct(product.id);

    expect(archived, isFalse);
    expect(provider.activeProducts, hasLength(1));
    expect(provider.archivedProducts, isEmpty);

    provider.dispose();
  });

  test('stockless products can log entries without changing pack data',
      () async {
    final provider = MyTrackingProvider();
    const product = TrackedProduct(
      id: 'p1',
      name: 'Prodotto libero',
      totalCost: 5.5,
      pieces: 20,
      packRemaining: 0,
      tracksInventory: false,
      directUnitCost: 1.25,
    );

    await provider.addProduct(product);
    await provider.logEntry();

    expect(provider.entriesForProduct(product.id), hasLength(1));
    expect(provider.dailyCost, 1.25);
    expect(provider.activeProduct.packRemaining, 0);

    final entryId = provider.entriesForProduct(product.id).first.id;
    await provider.deleteEntry(entryId);

    expect(provider.entriesForProduct(product.id), isEmpty);
    expect(provider.activeProduct.packRemaining, 0);

    provider.dispose();
  });

  test('migrates legacy per-product reminders into a single global reminder',
      () async {
    const legacyProductsJson = '''
[
  {
    "id":"p1",
    "name":"Prodotto 1",
    "totalCost":5.5,
    "pieces":20,
    "minutesLost":11,
    "dailyLimit":0,
    "packRemaining":20,
    "tracksInventory":true,
    "isArchived":false,
    "notificationSettings":{
      "periodicReminderEnabled":true,
      "periodicReminderMinutes":60,
      "dailySummaryEnabled":false,
      "dailySummaryHour":21,
      "dailySummaryMinute":0
    }
  },
  {
    "id":"p2",
    "name":"Prodotto 2",
    "totalCost":6.0,
    "pieces":20,
    "minutesLost":11,
    "dailyLimit":0,
    "packRemaining":20,
    "tracksInventory":true,
    "isArchived":false,
    "notificationSettings":{
      "periodicReminderEnabled":true,
      "periodicReminderMinutes":60,
      "dailySummaryEnabled":true,
      "dailySummaryHour":22,
      "dailySummaryMinute":15
    }
  }
]
''';

    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': legacyProductsJson,
      'active_product_id': 'p1',
    });

    final provider = MyTrackingProvider();
    await provider.init();

    expect(provider.globalReminderSettings.enabled, isTrue);
    expect(provider.globalReminderSettings.intervalMinutes, 60);
    expect(provider.products, hasLength(2));

    provider.dispose();
  });
}
