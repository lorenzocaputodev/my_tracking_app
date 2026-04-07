import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/my_tracking_provider.dart';
import 'services/product_notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/product_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final provider = MyTrackingProvider();

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const MyTrackingApp()),
  );
}

Future<void> _initializeMobileAdsIfSupported() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  try {
    await MobileAds.instance.initialize();
  } catch (_) {}
}

enum _BootstrapTarget { onboarding, setup, home }

class MyTrackingApp extends StatefulWidget {
  const MyTrackingApp({super.key});

  @override
  State<MyTrackingApp> createState() => _MyTrackingAppState();

  static ThemeMode _themeMode(AppThemePreference p) {
    switch (p) {
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }
}

class _MyTrackingAppState extends State<MyTrackingApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<MyTrackingProvider>().drainOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyTrackingProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'My Tracking App',
          debugShowCheckedModeBanner: false,
          themeMode: MyTrackingApp._themeMode(provider.themePreference),
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('it'), Locale('en')],
          home: const _AppBootstrapScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const darkPrimary = Color(0xFF00CED1);
    const lightPrimary = Color(0xFF00686B);
    final primary = isDark ? darkPrimary : lightPrimary;
    const lightScaffold = Color(0xFFF3F7F7);
    const lightSurface = Colors.white;
    const lightText = Color(0xFF132222);
    const lightMuted = Color(0xFF556B6D);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0A0A0A) : lightScaffold,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark ? const Color(0xFF161B1B) : lightSurface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE8F0F0),
        hintStyle: GoogleFonts.dmSans(color: isDark ? Colors.grey : lightMuted),
        labelStyle: GoogleFonts.dmSans(
          color: isDark ? Colors.grey : lightMuted,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.22),
        selectionHandleColor: primary,
      ),
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.08),
      iconTheme: IconThemeData(color: isDark ? Colors.white : lightText),
    );
  }
}

class _AppBootstrapScreen extends StatefulWidget {
  const _AppBootstrapScreen();

  @override
  State<_AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<_AppBootstrapScreen> {
  late Future<_BootstrapTarget> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeMobileAdsIfSupported());
    });
  }

  Future<_BootstrapTarget> _bootstrap() async {
    final provider = context.read<MyTrackingProvider>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final hasCompletedSetup = prefs.getBool('hasCompletedSetup') ?? false;

    await Future.wait<dynamic>([
      initializeDateFormatting('it_IT', null),
      ProductNotificationService.ensureInitialized(),
      provider.init(),
    ]);

    if (!onboardingDone) {
      return _BootstrapTarget.onboarding;
    }
    if (!hasCompletedSetup || provider.activeProducts.isEmpty) {
      return _BootstrapTarget.setup;
    }
    return _BootstrapTarget.home;
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapTarget>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _BootstrapErrorScreen(
            error: snapshot.error,
            onRetry: _retryBootstrap,
          );
        }

        final target = snapshot.data;
        if (target == null) {
          return const _BootstrapLoadingScreen();
        }

        switch (target) {
          case _BootstrapTarget.onboarding:
            return const OnboardingScreen();
          case _BootstrapTarget.setup:
            return const ProductSetupScreen();
          case _BootstrapTarget.home:
            return const HomeScreen();
        }
      },
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Caricamento...',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _BootstrapErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Avvio non completato',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si \u00E8 verificato un problema durante il caricamento iniziale. Puoi riprovare senza chiudere l\'app.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  if (kDebugMode && error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Riprova'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
