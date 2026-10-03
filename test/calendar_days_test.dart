import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:my_tracking_app/utils/calendar_days.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _entry(String id, DateTime timestamp) => jsonEncode(<String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'costDeducted': 0.25,
      'minutesLost': 11,
      'productId': 'p1',
    });

Future<MyTrackingProvider> _providerWith(List<DateTime> timestamps) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'tracked_products_v1': jsonEncode([
      <String, dynamic>{
        'id': 'p1',
        'name': 'Prodotto 1',
        'totalCost': 5.0,
        'pieces': 20,
        'packRemaining': 20,
        'dailyLimit': 5,
      },
    ]),
    'active_product_id': 'p1',
    'smoke_entries': <String>[
      for (var i = 0; i < timestamps.length; i++) _entry('e$i', timestamps[i]),
    ],
  });
  final provider = MyTrackingProvider();
  await provider.init();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => appNow = DateTime.now);

  group('giorni di calendario', () {
    test('addDays attraversa il cambio dell\'ora legale', () {
      expect(addDays(DateTime(2026, 3, 30), -1), DateTime(2026, 3, 29));
      expect(addDays(DateTime(2026, 3, 29), 1), DateTime(2026, 3, 30));
      expect(addDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
    });

    test('daysBetween conta i giorni anche se uno dura 23 o 25 ore', () {
      expect(daysBetween(DateTime(2026, 3, 27), DateTime(2026, 4, 2)), 6);
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 27)), 3);
    });
  });

  group('voci registrate dal widget', () {
    test('una voce salvata in UTC dopo mezzanotte conta per oggi', () async {
      final now = DateTime(2026, 10, 2, 0, 30);
      appNow = () => now;
      final provider = await _providerWith([now.toUtc()]);

      expect(provider.dailyCount, 1);
      expect(provider.todayEntries, hasLength(1));
      expect(provider.dailyCost, 0.25);

      provider.dispose();
    });
  });

  group('statistiche a cavallo dell\'ora legale', () {
    test('la serie non salta il giorno del cambio d\'ora', () async {
      appNow = () => DateTime(2026, 3, 30, 12);
      final provider = await _providerWith([
        DateTime(2026, 3, 28, 12),
        DateTime(2026, 3, 30, 10),
      ]);

      expect(provider.currentStreakForProduct('p1'), 1);

      provider.dispose();
    });

    test('la media di una settimana divide per sette giorni', () async {
      appNow = () => DateTime(2026, 4, 2, 12);
      final provider = await _providerWith([
        for (var day = 27; day <= 31; day++) DateTime(2026, 3, day, 12),
        DateTime(2026, 4, 1, 12),
        DateTime(2026, 4, 2, 9),
      ]);

      expect(
        provider.averageDailyCountForRange(
          productId: 'p1',
          start: DateTime(2026, 3, 27),
          end: DateTime(2026, 4, 2),
        ),
        1.0,
      );

      provider.dispose();
    });

    test('il giorno sotto il limite dopo il cambio d\'ora conta', () async {
      appNow = () => DateTime(2026, 3, 31, 12);
      final provider = await _providerWith([
        for (var i = 0; i < 5; i++) DateTime(2026, 3, 28, 10 + i),
        DateTime(2026, 3, 29, 12),
        DateTime(2026, 3, 30, 10),
      ]);

      expect(provider.underLimitStreakForProduct('p1'), 2);

      provider.dispose();
    });
  });

  group('giorni sotto il limite', () {
    test('la giornata in corso non conta finche non e finita', () async {
      appNow = () => DateTime(2026, 10, 2, 8);
      final provider = await _providerWith([DateTime(2026, 10, 2, 7)]);

      expect(provider.underLimitStreakForProduct('p1'), 0);
      expect(
        provider.unlockedAchievements.map((a) => a.id.name),
        isNot(contains('underLimit1')),
      );

      provider.dispose();
    });

    test('oltre il limite gia oggi la serie si azzera', () async {
      appNow = () => DateTime(2026, 10, 2, 20);
      final provider = await _providerWith([
        DateTime(2026, 10, 1, 12),
        for (var i = 0; i < 5; i++) DateTime(2026, 10, 2, 10 + i),
      ]);

      expect(provider.underLimitStreakForProduct('p1'), 0);

      provider.dispose();
    });
  });
}
