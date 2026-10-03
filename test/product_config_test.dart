import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_tracking_app/models/pack_config.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('svuotare il costo per utilizzo lo toglie davvero', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': 'p1',
          'name': 'Svapo',
          'totalCost': 0.0,
          'pieces': 1,
          'tracksInventory': false,
          'directUnitCost': 0.10,
        },
      ]),
      'active_product_id': 'p1',
    });
    final provider = MyTrackingProvider();
    await provider.init();

    await provider.updateProductConfig(
      const PackConfig(
        name: 'Svapo',
        totalCost: 0,
        pieces: 1,
        tracksInventory: false,
      ),
    );

    expect(provider.activeProduct.directUnitCost, isNull);
    expect(provider.activeProduct.unitCost, 0);
    provider.dispose();
  });
}
