import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/main.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';

void main() {
  testWidgets('MyTrackingApp shows bootstrap loading shell', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('it', 'IT')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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

  testWidgets('MyTrackingApp follows a non-Italian system language in English', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
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

    expect(find.text('Loading...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
