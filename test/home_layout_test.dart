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
import 'package:my_tracking_app/widgets/week_bars.dart';

final _now = DateTime(2026, 9, 25, 17);

Map<String, dynamic> _product(String id, String name) => <String, dynamic>{
      'id': id,
      'name': name,
      'totalCost': 6.0,
      'pieces': 20,
      'minutesLost': 11,
      'dailyLimit': 10,
      'packRemaining': 13,
      'tracksInventory': true,
      'isArchived': false,
    };

String _entry(String id, DateTime t) => jsonEncode(<String, dynamic>{
      'id': id,
      'timestamp': t.toIso8601String(),
      'costDeducted': 0.3,
      'minutesLost': 11,
      'productId': 'p1',
    });

void main() {
  setUpAll(() => appNow = () => _now);
  tearDownAll(() => appNow = DateTime.now);

  // Il caso piu' affollato: due prodotti (selettore in alto), scorta,
  // limite superato (banner), suggerimento e card dei 7 giorni, sullo
  // schermo del Motorola Edge 50 Fusion con barre di sistema.
  testWidgets('HO USATO resta intero sopra la card dei 7 giorni', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tracked_products_v1': jsonEncode([
        _product('p1', 'Sigarette'),
        _product('p2', 'Svapo'),
      ]),
      'active_product_id': 'p1',
      'smoke_entries': [
        for (var i = 0; i < 14; i++) _entry('t$i', _now),
        for (var i = 0; i < 5; i++)
          _entry('y$i', _now.subtract(const Duration(days: 1))),
      ],
    });
    final provider = MyTrackingProvider();
    await tester.runAsync(() => provider.init());
    provider.setForeground(false);

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 110, bottom: 60);
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

    expect(provider.dailyLimitReached, isTrue);
    final button = tester.getRect(find.byType(ActionButton));
    final week = tester.getRect(
      find
          .ancestor(of: find.byType(WeekBars), matching: find.byType(Container))
          .first,
    );
    // La card ha 8 di margine sopra: il bordo visibile e' a week.top + 8.
    expect(
      week.top + 8 - button.bottom,
      greaterThanOrEqualTo(8),
      reason: 'fra HO USATO e la card dei 7 giorni devono restare almeno 8dp',
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
