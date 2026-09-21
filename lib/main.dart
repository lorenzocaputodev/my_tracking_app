import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/my_tracking_provider.dart';
import 'services/product_notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/product_setup_screen.dart';
import 'theme/app_theme.dart';

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
  late final ThemeData _lightTheme;
  late final ThemeData _darkTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lightTheme = AppTheme.of(Brightness.light);
    _darkTheme = AppTheme.of(Brightness.dark);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final provider = context.read<MyTrackingProvider>();
    provider.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(provider.drainOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<MyTrackingProvider, AppThemePreference>(
      selector: (_, provider) => provider.themePreference,
      builder: (context, themePreference, child) {
        return MaterialApp(
          title: 'My Tracking App',
          debugShowCheckedModeBanner: false,
          themeMode: MyTrackingApp._themeMode(themePreference),
          theme: _lightTheme,
          darkTheme: _darkTheme,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('it'), Locale('en')],
          home: child,
        );
      },
      child: const _AppBootstrapScreen(),
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
