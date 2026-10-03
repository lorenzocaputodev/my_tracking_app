import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/screens/home_screen.dart';
import 'package:my_tracking_app/theme/app_theme.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:my_tracking_app/widgets/action_button.dart';

Future<void> _settleAsync(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() => appNow = () => DateTime(2026, 10, 2, 17));
  tearDownAll(() => appNow = DateTime.now);

  testWidgets("anche l'ultima unita della confezione si puo annullare", (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': jsonEncode([
        <String, dynamic>{
          'id': 'p1',
          'name': 'Sigarette',
          'totalCost': 6.0,
          'pieces': 20,
          'packRemaining': 1,
        },
      ]),
      'active_product_id': 'p1',
    });
    final provider = MyTrackingProvider();
    await tester.runAsync(() => provider.init());
    provider.setForeground(false);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<MyTrackingProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.of(Brightness.dark),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('it')],
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ActionButton));
    await _settleAsync(tester);
    expect(provider.packRemaining, 0);
    expect(find.text('Annulla'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await _settleAsync(tester);
    expect(provider.packRemaining, 1);
    expect(provider.entries, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
