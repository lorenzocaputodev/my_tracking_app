import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/theme/app_theme.dart';
import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/screens/achievements_screen.dart';
import 'package:my_tracking_app/screens/home_screen.dart';
import 'package:my_tracking_app/widgets/stats_card.dart';

const _productId = 'p1';

String _products({bool tracksInventory = true}) => jsonEncode([
      <String, dynamic>{
        'id': _productId,
        'name': 'Sigarette',
        'totalCost': 6.0,
        'pieces': 20,
        'minutesLost': 11,
        'dailyLimit': 10,
        'packRemaining': 17,
        'tracksInventory': tracksInventory,
        'isArchived': false,
      },
    ]);

List<String> _entriesToday(int count) {
  final now = DateTime.now();
  return List.generate(
    count,
    (i) => jsonEncode(<String, dynamic>{
      'id': 'e$i',
      'timestamp': now.toIso8601String(),
      'costDeducted': 0.3,
      'minutesLost': 11,
      'productId': _productId,
    }),
  );
}

String _achievements() => jsonEncode([
      <String, dynamic>{
        'id': 'firstEntry',
        'unlockedAt': '2026-04-27T10:00:00.000',
      },
      <String, dynamic>{
        'id': 'underLimit1',
        'unlockedAt': '2026-05-07T10:00:00.000',
      },
    ]);

Future<MyTrackingProvider> _seed(
  WidgetTester tester,
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  final provider = MyTrackingProvider();
  await tester.runAsync(() => provider.init());
  provider.setForeground(false);
  return provider;
}

Future<void> _pumpScene(
  WidgetTester tester, {
  required MyTrackingProvider provider,
  required Widget screen,
  required Brightness brightness,
  Size physicalSize = const Size(1080, 2400),
  double devicePixelRatio = 2.75,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider<MyTrackingProvider>.value(
      value: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.of(brightness),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('it'), Locale('en')],
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('golden home $suffix', (tester) async {
      final provider = await _seed(tester, <String, Object>{
        'tracked_products_v1': _products(),
        'active_product_id': _productId,
        'smoke_entries': _entriesToday(3),
      });

      await _pumpScene(
        tester,
        provider: provider,
        screen: const HomeScreen(),
        brightness: brightness,
      );
      await _shoot(tester, 'home_$suffix');

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });

    testWidgets('golden achievements $suffix', (tester) async {
      final provider = await _seed(tester, <String, Object>{
        'tracked_products_v1': _products(),
        'active_product_id': _productId,
        'smoke_entries': _entriesToday(3),
        'achievements_v2': _achievements(),
      });

      await _pumpScene(
        tester,
        provider: provider,
        screen: const AchievementsScreen(),
        brightness: brightness,
      );
      await _shoot(tester, 'achievements_$suffix');

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });

    testWidgets('golden achievements stretto $suffix', (tester) async {
      final provider = await _seed(tester, <String, Object>{
        'tracked_products_v1': _products(),
        'active_product_id': _productId,
        'smoke_entries': _entriesToday(3),
        'achievements_v2': _achievements(),
      });

      await _pumpScene(
        tester,
        provider: provider,
        screen: const AchievementsScreen(),
        brightness: brightness,
        physicalSize: const Size(1080, 2400),
        devicePixelRatio: 3.0,
      );
      await _shoot(tester, 'achievements_stretto_$suffix');

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });

    testWidgets('golden stats card $suffix', (tester) async {
      final provider = await _seed(tester, <String, Object>{});

      await _pumpScene(
        tester,
        provider: provider,
        screen: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.euro_rounded,
                      label: 'Oggi',
                      value: '0,90 €',
                      accent: Color(0xFF00CED1),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.timer_rounded,
                      label: 'Vita persa oggi',
                      value: '33m',
                      accent: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        brightness: brightness,
      );
      await _shoot(tester, 'stats_card_$suffix');

      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }
}
