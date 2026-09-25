import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/achievement.dart';
import 'package:my_tracking_app/models/pack_config.dart';
import 'package:my_tracking_app/models/tracked_product.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _productsJson(List<Map<String, dynamic>> products) =>
    jsonEncode(products);

Map<String, dynamic> _product({
  required String id,
  required String name,
  double totalCost = 5.0,
  int pieces = 20,
  int minutesLost = 11,
  int dailyLimit = 0,
  int packRemaining = 20,
  bool tracksInventory = true,
  bool isArchived = false,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'totalCost': totalCost,
      'pieces': pieces,
      'minutesLost': minutesLost,
      'dailyLimit': dailyLimit,
      'packRemaining': packRemaining,
      'tracksInventory': tracksInventory,
      'isArchived': isArchived,
    };

String _entry({
  required String id,
  required String productId,
  required DateTime timestamp,
  double costDeducted = 0.25,
  int minutesLost = 11,
}) =>
    jsonEncode(<String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'costDeducted': costDeducted,
      'minutesLost': minutesLost,
      'productId': productId,
    });

DateTime _daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 12).subtract(
    Duration(days: days),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('conservazione della cronologia', () {
    test('le voci oltre i 365 giorni sopravvivono al caricamento', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Prodotto 1'),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry(id: 'vecchia', productId: 'p1', timestamp: _daysAgo(400)),
          _entry(id: 'recente', productId: 'p1', timestamp: _daysAgo(1)),
        ],
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(
        provider.entries.map((e) => e.id),
        containsAll(<String>['vecchia', 'recente']),
      );

      provider.dispose();
    });

    test('una voce corrotta non impedisce il caricamento delle altre',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Prodotto 1'),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          'non e json',
          _entry(id: 'buona', productId: 'p1', timestamp: _daysAgo(1)),
        ],
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.entries, hasLength(1));
      expect(provider.entries.first.id, 'buona');

      provider.dispose();
    });

    test('le voci vengono caricate in ordine cronologico', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Prodotto 1'),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry(id: 'terza', productId: 'p1', timestamp: _daysAgo(1)),
          _entry(id: 'prima', productId: 'p1', timestamp: _daysAgo(10)),
          _entry(id: 'seconda', productId: 'p1', timestamp: _daysAgo(5)),
        ],
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(
        provider.entries.map((e) => e.id).toList(),
        <String>['prima', 'seconda', 'terza'],
      );

      provider.dispose();
    });
  });

  group('reset della cronologia', () {
    test('clearHistory cancella le voci ma conserva la scorta', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const product = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 5.0,
        pieces: 20,
        packRemaining: 20,
      );
      await provider.addProduct(product);
      await provider.logEntry();
      await provider.logEntry();

      expect(provider.entries, hasLength(2));
      expect(provider.activeProduct.packRemaining, 18);

      await provider.clearHistory();

      expect(provider.entries, isEmpty);
      expect(provider.activeProduct.packRemaining, 18);

      provider.dispose();
    });
  });

  group('totali della schermata principale', () {
    test('totalCost e totalTimeLost contano solo il prodotto attivo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = MyTrackingProvider();
      const first = TrackedProduct(
        id: 'p1',
        name: 'Prodotto 1',
        totalCost: 10.0,
        pieces: 10,
        minutesLost: 5,
        packRemaining: 10,
      );
      const second = TrackedProduct(
        id: 'p2',
        name: 'Prodotto 2',
        totalCost: 20.0,
        pieces: 10,
        minutesLost: 7,
        packRemaining: 10,
      );

      await provider.addProduct(first);
      await provider.addProduct(second);
      await provider.setActiveProduct(first.id);

      await provider.logEntry(productId: first.id);
      await provider.logEntry(productId: second.id);
      await provider.logEntry(productId: second.id);

      expect(provider.activeProduct.id, first.id);
      expect(provider.totalCost, closeTo(1.0, 1e-9));
      expect(provider.totalTimeLost, const Duration(minutes: 5));

      await provider.setActiveProduct(second.id);

      expect(provider.totalCost, closeTo(4.0, 1e-9));
      expect(provider.totalTimeLost, const Duration(minutes: 14));

      provider.dispose();
    });
  });

  group('achievement', () {
    test('le streak considerano anche i prodotti non attivi', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Attivo'),
          _product(id: 'p2', name: 'Secondario', dailyLimit: 5),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry(id: 'e0', productId: 'p2', timestamp: _daysAgo(0)),
          _entry(id: 'e1', productId: 'p2', timestamp: _daysAgo(1)),
          _entry(id: 'e2', productId: 'p2', timestamp: _daysAgo(2)),
        ],
      });

      final provider = MyTrackingProvider();
      await provider.init();

      expect(provider.activeProduct.id, 'p1');
      expect(provider.currentStreakForProduct('p1'), 0);

      final unlocked =
          provider.unlockedAchievements.map((a) => a.id).toSet();
      expect(unlocked, contains(AchievementId.streak3));
      expect(unlocked, contains(AchievementId.underLimit3));

      provider.dispose();
    });

    test('gli sblocchi avvenuti all avvio vengono salvati', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Prodotto 1', dailyLimit: 5),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry(id: 'e0', productId: 'p1', timestamp: _daysAgo(0)),
          _entry(id: 'e1', productId: 'p1', timestamp: _daysAgo(1)),
          _entry(id: 'e2', productId: 'p1', timestamp: _daysAgo(2)),
        ],
      });

      final provider = MyTrackingProvider();
      await provider.init();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('achievements_v2');
      expect(raw, isNotNull);

      final saved = (jsonDecode(raw!) as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toSet();
      expect(saved, contains(AchievementId.firstEntry.name));
      expect(saved, contains(AchievementId.streak3.name));

      provider.dispose();
    });

    test('la data di sblocco non cambia a ogni avvio', () async {
      final initial = <String, Object>{
        'tracked_products_v1': _productsJson([
          _product(id: 'p1', name: 'Prodotto 1', dailyLimit: 5),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': <String>[
          _entry(id: 'e0', productId: 'p1', timestamp: _daysAgo(0)),
          _entry(id: 'e1', productId: 'p1', timestamp: _daysAgo(1)),
          _entry(id: 'e2', productId: 'p1', timestamp: _daysAgo(2)),
        ],
      };
      SharedPreferences.setMockInitialValues(initial);

      final first = MyTrackingProvider();
      await first.init();
      final firstUnlock = first
          .allAchievements
          .firstWhere((a) => a.id == AchievementId.streak3)
          .unlockedAt;
      expect(firstUnlock, isNotNull);
      first.dispose();

      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getString('achievements_v2');
      SharedPreferences.setMockInitialValues(<String, Object>{
        ...initial,
        'achievements_v2': persisted!,
      });

      final second = MyTrackingProvider();
      await second.init();
      final secondUnlock = second
          .allAchievements
          .firstWhere((a) => a.id == AchievementId.streak3)
          .unlockedAt;

      expect(secondUnlock, firstUnlock);

      second.dispose();
    });
  });

  test('un prodotto non in uso si modifica e si reintegra senza toccare '
      'quello attivo', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': _productsJson([
        _product(id: 'p1', name: 'Attivo', packRemaining: 12),
        _product(id: 'p2', name: 'Altro', packRemaining: 3),
      ]),
      'active_product_id': 'p1',
    });
    final provider = MyTrackingProvider();
    await provider.init();

    await provider.updateProductConfig(
      const PackConfig(
        name: 'Rinominato',
        totalCost: 8.0,
        pieces: 10,
        minutesLost: 5,
        dailyLimit: 4,
      ),
      productId: 'p2',
    );
    await provider.correctPackRemaining(7, productId: 'p2');
    TrackedProduct byId(String id) =>
        provider.products.firstWhere((p) => p.id == id);
    expect(byId('p2').name, 'Rinominato');
    expect(byId('p2').packRemaining, 7);

    await provider.openNewPack(productId: 'p2');
    expect(byId('p2').packRemaining, 10);

    expect(provider.activeProduct.id, 'p1');
    expect(byId('p1').name, 'Attivo');
    expect(byId('p1').packRemaining, 12);
    provider.dispose();
  });

  test('annullare una cancellazione rimette la voce e riprende la scorta',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': _productsJson([
        _product(id: 'p1', name: 'Prodotto', packRemaining: 10),
      ]),
      'active_product_id': 'p1',
      'smoke_entries': <String>[
        _entry(id: 'a', productId: 'p1', timestamp: _daysAgo(2)),
        _entry(id: 'b', productId: 'p1', timestamp: _daysAgo(1)),
      ],
    });
    final provider = MyTrackingProvider();
    await provider.init();

    final deleted = await provider.deleteEntry('a');
    expect(deleted, isNotNull);
    expect(provider.packRemaining, 11);
    expect(provider.entries.map((e) => e.id), ['b']);

    await provider.restoreEntry(deleted!);
    expect(provider.packRemaining, 10);
    expect(provider.entries.map((e) => e.id), ['a', 'b'],
        reason: 'la voce torna al suo posto in ordine cronologico');
    provider.dispose();
  });
}
