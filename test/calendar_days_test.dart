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
      appNow = () => DateTime(2026, 3, 30, 12);
      final provider = await _providerWith([
        for (var i = 0; i < 5; i++) DateTime(2026, 3, 28, 10 + i),
        DateTime(2026, 3, 29, 12),
        DateTime(2026, 3, 30, 10),
      ]);

      expect(provider.underLimitStreakForProduct('p1'), 2);

      provider.dispose();
    });
  });
}
