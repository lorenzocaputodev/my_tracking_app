import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/l10n/l10n.dart';
import 'package:my_tracking_app/models/smoke_entry.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 10, 17, 12);

Map<String, Object> _prefs({String? currency}) => <String, Object>{
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': 'p1',
          'name': 'Sigarette',
          'totalCost': 6.0,
          'pieces': 20,
          'minutesLost': 11,
          'dailyLimit': 10,
          'packRemaining': 20,
          'tracksInventory': true,
          'isArchived': false,
        },
      ]),
      'active_product_id': 'p1',
      if (currency != null) 'app_currency': currency,
    };

SmokeEntry _entry(String id, DateTime timestamp) => SmokeEntry(
      id: id,
      timestamp: timestamp,
      costDeducted: 0.3,
      minutesLost: 11,
      productId: 'p1',
    );

Future<MyTrackingProvider> _load(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final provider = MyTrackingProvider();
  await provider.init();
  provider.setForeground(false);
  return provider;
}

void main() {
  setUp(() => appNow = () => _now);
  tearDown(() {
    appNow = DateTime.now;
    L10n.currency = AppCurrency.eur;
  });

  // --- Valuta ---

  group('valuta', () {
    test('senza scelta salvata resta l euro', () async {
      final provider = await _load(_prefs());
      expect(provider.currency, AppCurrency.eur);
      expect(L10n.currency, AppCurrency.eur);
      provider.dispose();
    });

    test('la scelta si salva e si rilegge', () async {
      final provider = await _load(_prefs());
      await provider.setCurrency(AppCurrency.gbp);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_currency'), 'gbp');
      provider.dispose();

      L10n.currency = AppCurrency.eur;
      final reloaded = await _load(_prefs(currency: 'gbp'));
      expect(reloaded.currency, AppCurrency.gbp);
      expect(L10n.currency, AppCurrency.gbp);
      reloaded.dispose();
    });

    test('la valuta passa dal backup', () async {
      final source = await _load(_prefs(currency: 'usd'));
      final csv = await source.exportFullBackupCsv();
      source.dispose();

      final target = await _load(_prefs());
      expect(target.currency, AppCurrency.eur);
      await target.restoreBackup(target.readBackupCsv(csv));
      expect(target.currency, AppCurrency.usd);
      expect(L10n.currency, AppCurrency.usd);
      target.dispose();
    });
  });

  // --- Ultimo backup ---

  test('la data dell ultimo backup si salva', () async {
    final provider = await _load(_prefs());
    expect(provider.lastBackupAt, isNull);
    await provider.markBackupExported();
    expect(provider.lastBackupAt, _now);
    provider.dispose();

    final reloaded = await _load(<String, Object>{
      ..._prefs(),
      'last_backup_export': _now.toIso8601String(),
    });
    expect(reloaded.lastBackupAt, _now);
    reloaded.dispose();
  });

  // --- Giorno migliore e peggiore ---

  test('con un solo giorno non ci sono giorno migliore e peggiore', () async {
    final provider = await _load(_prefs());
    final oneDay = [_entry('a', _now), _entry('b', _now)];
    expect(provider.bestDayForEntries(oneDay), isNull);
    expect(provider.worstDayForEntries(oneDay), isNull);

    final twoDays = [
      ...oneDay,
      _entry('c', _now.subtract(const Duration(days: 1))),
    ];
    expect(provider.bestDayForEntries(twoDays)?.value, 1);
    expect(provider.worstDayForEntries(twoDays)?.value, 2);
    provider.dispose();
  });
}
