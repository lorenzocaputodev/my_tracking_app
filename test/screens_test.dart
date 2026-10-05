import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_tracking_app/providers/my_tracking_provider.dart';
import 'package:my_tracking_app/screens/history_screen.dart';
import 'package:my_tracking_app/screens/home_screen.dart';
import 'package:my_tracking_app/screens/product_settings_screen.dart';
import 'package:my_tracking_app/screens/product_setup_screen.dart';
import 'package:my_tracking_app/screens/settings_screen.dart';
import 'package:my_tracking_app/theme/app_theme.dart';
import 'package:my_tracking_app/utils/app_clock.dart';
import 'package:my_tracking_app/widgets/save_bar.dart';
import 'package:my_tracking_app/widgets/stats_card.dart';

final _now = DateTime(2026, 9, 25, 17);

Map<String, dynamic> _product(
  String id,
  String name, {
  double totalCost = 6.0,
  int minutesLost = 11,
  bool tracksInventory = true,
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'totalCost': totalCost,
      'pieces': 20,
      'minutesLost': minutesLost,
      'dailyLimit': 10,
      'packRemaining': 13,
      'tracksInventory': tracksInventory,
      'isArchived': false,
    };

String _entry(String id, String productId, DateTime t) =>
    jsonEncode(<String, dynamic>{
      'id': id,
      'timestamp': t.toIso8601String(),
      'costDeducted': 0.3,
      'minutesLost': 11,
      'productId': productId,
    });

Future<void> _settleAsync(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize * (fontSize < 20 ? 1.6 : 1.15);

  @override
  double get textScaleFactor => 1.3;
}

Future<MyTrackingProvider> _pump(
  WidgetTester tester,
  Widget screen,
  Map<String, Object> prefs, {
  TextScaler? textScaler,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
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
        builder: textScaler == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

Future<void> _dispose(WidgetTester tester, MyTrackingProvider provider) async {
  await tester.pumpWidget(const SizedBox.shrink());
  provider.dispose();
}

void main() {
  setUpAll(() async {
    appNow = () => _now;
    await initializeDateFormatting('it_IT');
  });
  tearDownAll(() => appNow = DateTime.now);

  // --- Configurazione iniziale ---

  testWidgets('la configurazione offre il ripristino e parte senza stima', (
    tester,
  ) async {
    final provider = await _pump(
      tester,
      const ProductSetupScreen(),
      <String, Object>{'onboarding_done': true},
    );

    expect(find.text('Ho già un backup'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nessuna stima'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Nessuna stima'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Es. Sigarette'),
      'Svapo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Es. 6,00'),
      '8',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Es. 20'), '10');
    await tester.pump();
    await tester.tap(find.text('Inizia a tracciare'));
    await _settleAsync(tester);

    expect(provider.activeProducts, hasLength(1));
    expect(provider.activeProduct.name, 'Svapo');
    expect(provider.activeProduct.minutesLost, 0);
    expect(find.byType(HomeScreen), findsOneWidget);

    await _dispose(tester, provider);
  });

  testWidgets("cambiare modalità non porta errori da un campo all'altro", (
    tester,
  ) async {
    final provider = await _pump(
      tester,
      const ProductSetupScreen(),
      <String, Object>{'onboarding_done': true},
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Es. Sigarette'),
      'Svapo',
    );
    await tester.pump();
    await tester.tap(find.text('Senza scorta'));
    await tester.pumpAndSettle();
    expect(find.text('Inserisci un importo'), findsNothing);

    await tester.tap(find.text('Con scorta'));
    await tester.pumpAndSettle();
    expect(find.text('Importo non valido'), findsNothing);

    await _dispose(tester, provider);
  });

  // --- Home ---

  testWidgets('la home nasconde costi e minuti non impostati', (tester) async {
    final provider = await _pump(
      tester,
      const HomeScreen(),
      <String, Object>{
        'tracked_products_v1': jsonEncode([
          _product('p1', 'Svapo', minutesLost: 0, tracksInventory: false),
        ]),
        'active_product_id': 'p1',
      },
    );

    expect(find.byType(StatsCard), findsNothing);
    expect(find.textContaining('Costo per utilizzo'), findsNothing);

    await _dispose(tester, provider);
  });

  testWidgets('la home mostra costi e minuti quando ci sono', (tester) async {
    final provider = await _pump(
      tester,
      const HomeScreen(),
      <String, Object>{
        'tracked_products_v1': jsonEncode([_product('p1', 'Sigarette')]),
        'active_product_id': 'p1',
      },
    );

    expect(find.byType(StatsCard), findsNWidgets(3));
    expect(find.text('VITA PERSA OGGI'), findsOneWidget);

    await _dispose(tester, provider);
  });

  testWidgets('la home regge il testo ingrandito dal sistema', (tester) async {
    final provider = await _pump(
      tester,
      const HomeScreen(),
      <String, Object>{
        'tracked_products_v1': jsonEncode([_product('p1', 'Sigarette')]),
        'active_product_id': 'p1',
        'smoke_entries': [
          for (var d = 0; d < 7; d++)
            _entry('a$d', 'p1', _now.subtract(Duration(days: d))),
        ],
      },
      textScaler: const _NonLinearScaler(),
    );

    expect(tester.takeException(), isNull);
    final heights = tester
        .widgetList<StatsCard>(find.byType(StatsCard))
        .map((card) => tester.getSize(find.byWidget(card)).height)
        .toSet();
    expect(heights, hasLength(1));

    await _dispose(tester, provider);
  });

  testWidgets('i pulsanti della home hanno un nome per TalkBack', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final provider = await _pump(
      tester,
      const HomeScreen(),
      <String, Object>{
        'tracked_products_v1': jsonEncode([_product('p1', 'Sigarette')]),
        'active_product_id': 'p1',
      },
    );

    expect(find.byTooltip('Cronologia'), findsOneWidget);
    expect(find.byTooltip('Obiettivi e badge'), findsOneWidget);
    expect(find.byTooltip('Impostazioni'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp('HO USATO'))),
      matchesSemantics(
        label: 'HO USATO',
        isButton: true,
        hasTapAction: true,
      ),
    );

    await _dispose(tester, provider);
    semantics.dispose();
  });

  // --- Cronologia ---

  Map<String, Object> twoProducts() => <String, Object>{
        'tracked_products_v1': jsonEncode([
          _product('p1', 'Sigarette'),
          _product('p2', 'Svapo'),
        ]),
        'active_product_id': 'p1',
        'smoke_entries': [
          for (var d = 0; d < 5; d++)
            _entry('a$d', 'p1', _now.subtract(Duration(days: d))),
          for (var d = 0; d < 5; d++)
            _entry('b$d', 'p2', _now.subtract(Duration(days: d, hours: 2))),
        ],
      };

  testWidgets('con tutti i prodotti la cronologia non somma le medie', (
    tester,
  ) async {
    final provider = await _pump(tester, const HistoryScreen(), twoProducts());

    await tester.tap(find.text('Panoramica periodo'));
    await tester.pumpAndSettle();

    expect(find.text('Media periodo/g'), findsNothing);
    expect(find.text('10 registrazioni'), findsOneWidget);
    expect(find.textContaining('Prodotti diversi non si sommano'), findsOne);

    await _dispose(tester, provider);
  });

  testWidgets('con un prodotto scelto la cronologia mostra le medie', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final provider = await _pump(tester, const HistoryScreen(), twoProducts());

    await tester.tap(find.bySemanticsLabel(RegExp('^Prodotto')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Svapo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panoramica periodo'));
    await tester.pumpAndSettle();

    expect(find.text('Media periodo/g'), findsOneWidget);
    expect(find.textContaining('Prodotti diversi'), findsNothing);

    await _dispose(tester, provider);
    semantics.dispose();
  });

  // --- Impostazioni ---

  testWidgets('dalle impostazioni si cambia tema e si aggiunge un prodotto', (
    tester,
  ) async {
    final provider = await _pump(
      tester,
      const SettingsScreen(),
      <String, Object>{
        'tracked_products_v1': jsonEncode([_product('p1', 'Sigarette')]),
        'active_product_id': 'p1',
      },
    );

    await tester.tap(find.text('Chiaro'));
    await _settleAsync(tester);
    expect(provider.themePreference, AppThemePreference.light);

    await tester.tap(find.text('Aggiungi prodotto'));
    await tester.pumpAndSettle();
    expect(find.text('Nessuna stima'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Es. Sigarette'),
      'Svapo',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Es. 6,00'), '8');
    await tester.enterText(find.widgetWithText(TextFormField, 'Es. 20'), '10');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aggiungi prodotto'));
    await _settleAsync(tester);
    await tester.pumpAndSettle();

    expect(provider.activeProducts, hasLength(2));
    expect(provider.activeProduct.name, 'Svapo');
    expect(provider.activeProduct.minutesLost, 0);
    expect(find.text('Svapo aggiunto e in uso'), findsOneWidget);

    await _dispose(tester, provider);
  });

  // --- Impostazioni del prodotto ---

  testWidgets('la pagina del prodotto salva e annulla le modifiche', (
    tester,
  ) async {
    final provider = await _pump(
      tester,
      const ProductSettingsScreen(productId: 'p1'),
      <String, Object>{
        'tracked_products_v1': jsonEncode([_product('p1', 'Sigarette')]),
        'active_product_id': 'p1',
      },
    );

    expect(find.byType(SaveBar), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sigarette'),
      'Rosse',
    );
    await tester.pump();
    expect(find.byType(SaveBar), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pump();
    expect(find.byType(SaveBar), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Sigarette'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sigarette'),
      'Rosse',
    );
    await tester.tap(find.text('Senza scorta'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Facoltativo, es. 0,10'),
      '0,15',
    );
    await tester.pump();
    await tester.tap(find.text('Salva'));
    await _settleAsync(tester);
    await tester.pumpAndSettle();

    final saved = provider.products.single;
    expect(saved.name, 'Rosse');
    expect(saved.tracksInventory, isFalse);
    expect(saved.directUnitCost, 0.15);
    expect(saved.minutesLost, 11);
    expect(saved.dailyLimit, 10);
    expect(find.byType(SaveBar), findsNothing);
    expect(find.text('Modifiche salvate'), findsOneWidget);

    await _dispose(tester, provider);
  });
}
