import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('una registrazione durante il ritorno in primo piano non va persa',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': 'p1',
          'name': 'Prodotto 1',
          'totalCost': 5.0,
          'pieces': 20,
          'packRemaining': 20,
        },
      ]),
      'active_product_id': 'p1',
    });
    final provider = MyTrackingProvider();
    await provider.init();

    final drain = provider.drainOnResume();
    final entry = await provider.logEntry();
    await drain;

    expect(provider.entries.map((e) => e.id), [entry!.id]);
    expect(provider.packRemaining, 19);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getStringList('smoke_entries'), hasLength(1));

    provider.dispose();
  });
}
