import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/main.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';

String _products() => jsonEncode([
      <String, dynamic>{
        'id': 'p1',
        'name': 'Sigarette',
        'totalCost': 6.0,
        'pieces': 20,
        'minutesLost': 11,
        'dailyLimit': 0,
        'packRemaining': 14,
        'tracksInventory': true,
        'isArchived': false,
      },
    ]);

void main() {
  testWidgets('il tema segue la preferenza e i ThemeData non si ricostruiscono',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_done': true,
      'hasCompletedSetup': true,
      'tracked_products_v1': _products(),
      'active_product_id': 'p1',
      'app_theme_preference': 'light',
    });

    final provider = MyTrackingProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<MyTrackingProvider>.value(
        value: provider,
        child: const MyTrackingApp(),
      ),
    );
    await tester.pump();

    final first = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(first.themeMode, ThemeMode.light);

    await provider.setThemePreference(AppThemePreference.dark);
    await tester.pump();

    final second = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(second.themeMode, ThemeMode.dark);

    expect(identical(second.theme, first.theme), isTrue);
    expect(identical(second.darkTheme, first.darkTheme), isTrue);

    await provider.setThemePreference(AppThemePreference.system);
    await tester.pump();

    final third = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(third.themeMode, ThemeMode.system);
    expect(identical(third.theme, first.theme), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets('il ticker si ferma quando l app lascia il primo piano',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = MyTrackingProvider();

    var notifications = 0;
    provider.addListener(() => notifications++);

    await tester.pump(const Duration(minutes: 1));
    final whileForeground = notifications;
    expect(whileForeground, greaterThan(0));

    provider.setForeground(false);
    notifications = 0;
    await tester.pump(const Duration(minutes: 3));
    expect(notifications, 0);

    provider.setForeground(true);
    await tester.pump(const Duration(minutes: 1));
    expect(notifications, greaterThan(0));

    provider.dispose();
  });
}
