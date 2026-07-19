import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/app_root.dart';
import 'screens/auth/reset_password_screen.dart';
import 'services/app_version_service.dart';
import 'services/auth_service.dart';
import 'services/progress_service.dart';
import 'services/supabase_config.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.init();
  await ThemeService.instance.init();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  runApp(const InstriqApp());
}

class InstriqApp extends StatefulWidget {
  const InstriqApp({super.key});

  @override
  State<InstriqApp> createState() => _InstriqAppState();
}

class _InstriqAppState extends State<InstriqApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AuthService.instance.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final config = await AppVersionService.instance.fetchConfig();
      if (config == null) return;
      final current = await AppVersionService.instance.currentVersion();
      if (!AppVersionService.instance.isOlderThan(current, config.latestVersion)) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissedKey = 'dismissed_version_notice_${config.latestVersion}';
      if (prefs.getBool(dismissedKey) == true) return;

      final context = _navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nueva versión disponible'),
          content: Text(
            config.message ?? 'Hay una versión más reciente de Instriq disponible.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                prefs.setBool(dismissedKey, true);
                Navigator.pop(ctx);
              },
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                final url = Platform.isAndroid ? config.androidUrl : config.iosUrl;
                if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                Navigator.pop(ctx);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Si falla la comprobación (sin red, tabla no disponible, etc.) no
      // interrumpimos el arranque de la app por esto.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Instriq',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          home: const AppRoot(),
        );
      },
    );
  }
}
