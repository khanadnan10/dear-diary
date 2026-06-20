import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  static const _securityChannel = MethodChannel('com.deardiary/security');

  @override
  void initState() {
    super.initState();
    _applyInitialScreenshotPrevention();
  }

  /// Ensures screenshot prevention is applied immediately on start if enabled (EC-UI-06)
  Future<void> _applyInitialScreenshotPrevention() async {
    final enabled = ref.read(screenshotPreventionProvider);
    if (enabled && Platform.isAndroid) {
      try {
        await _securityChannel.invokeMethod('setSecureMode', {'enabled': true});
      } catch (e) {
        debugPrint('Error applying startup FLAG_SECURE: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'Dear Diary',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Listens to native OS App Lifecycle events to handle automatic locks and timeouts (EC-AS-05)
class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> with WidgetsBindingObserver {
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
    final authNotifier = ref.read(authStateProvider.notifier);
    if (state == AppLifecycleState.paused) {
      // Record pause timestamp (backgrounded)
      authNotifier.recordPause();
    } else if (state == AppLifecycleState.resumed) {
      // Check if session timeout duration elapsed (resumed)
      authNotifier.checkTimeout();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
