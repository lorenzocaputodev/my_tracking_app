import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/main.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';

void main() {
  testWidgets('MyTrackingApp shows bootstrap loading shell', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'hasCompletedSetup': false,
    });

    final provider = MyTrackingProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<MyTrackingProvider>.value(
        value: provider,
        child: const MyTrackingApp(),
      ),
    );

    expect(find.text('Caricamento...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
