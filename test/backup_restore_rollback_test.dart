import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _DroppingEntriesStore extends InMemorySharedPreferencesStore {
  _DroppingEntriesStore.withData(super.data) : super.withData();

  bool dropEntries = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (dropEntries && key == 'flutter.smoke_entries') return true;
    return super.setValue(valueType, key, value);
  }
}

Map<String, Object> _state(String productId, String name, int entries) =>
    <String, Object>{
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': productId,
          'name': name,
          'totalCost': 5.0,
          'pieces': 20,
          'packRemaining': 20,
        },
      ]),
      'active_product_id': productId,
      'smoke_entries': <String>[
        for (var i = 0; i < entries; i++)
          jsonEncode(<String, dynamic>{
            'id': '$productId-$i',
            'timestamp': DateTime(2026, 9, 1 + i, 12).toIso8601String(),
            'costDeducted': 0.25,
            'minutesLost': 11,
            'productId': productId,
          }),
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('se il salvataggio del backup fallisce restano i dati di prima',
      () async {
    SharedPreferences.setMockInitialValues(_state('nuovo', 'Dal backup', 3));
    final source = MyTrackingProvider();
    await source.init();
    final csv = await source.exportFullBackupCsv();
    source.dispose();

    final initial = _state('vecchio', 'Attuale', 2);
    SharedPreferences.setMockInitialValues(initial);
    final store = _DroppingEntriesStore.withData({
      for (final e in initial.entries) 'flutter.${e.key}': e.value,
    });
    SharedPreferencesStorePlatform.instance = store;
    final provider = MyTrackingProvider();
    await provider.init();

    store.dropEntries = true;
    await expectLater(
      provider.importFullBackupCsv(csv),
      throwsA(isA<BackupRestoreException>()),
    );
    store.dropEntries = false;

    expect(provider.products.map((p) => p.id), ['vecchio']);
    expect(provider.entries, hasLength(2));
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getString('tracked_products_v1'), contains('vecchio'));
    expect(prefs.getStringList('smoke_entries'), hasLength(2));

    provider.dispose();
  });
}
