import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'design_system/instriq_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'navigation/router.dart';
import 'screens/app_root.dart';
import 'screens/auth/reset_password_screen.dart';
import 'services/app_version_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/locale_service.dart';
import 'services/progress_service.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_config.dart';
import 'services/sync_queue_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.init();
  await ThemeService.instance.init();
  await LocaleService.instance.init();
  await ConnectivityService.instance.init();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  await SyncQueueService.instance.init();
  try {
    // Las notificaciones son un extra: si Firebase no está disponible en
    // esta plataforma/entorno (p. ej. Windows de escritorio en desarrollo),
    // no debe impedir que la app arranque.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  runApp(const InstriqApp());
}

class InstriqApp extends StatefulWidget {
  const InstriqApp({super.key});

  @override
  State<InstriqApp> createState() => _InstriqAppState();
}

class _InstriqAppState extends State<InstriqApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  // Construido una sola vez: reconstruirlo en cada build tiraría el estado
  // de navegación de las 5 ramas del shell (ver navigation/router.dart).
  late final GoRouter _router = buildRouter(_navigatorKey);

  @override
  void initState() {
    super.initState();
    AuthService.instance.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession) {
        if (state.session != null) PushNotificationService.instance.initForCurrentUser();
      }
      if (state.event == AuthChangeEvent.signedOut) {
        PushNotificationService.instance.unregisterCurrentToken();
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
      final l10n = AppLocalizations.of(context)!;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.newVersionAvailableTitle),
          content: Text(config.message ?? l10n.newVersionDefaultMessage),
          actions: [
            TextButton(
              onPressed: () {
                prefs.setBool(dismissedKey, true);
                Navigator.pop(ctx);
              },
              child: Text(l10n.notNow),
            ),
            FilledButton(
              onPressed: () {
                final url = Platform.isAndroid ? config.androidUrl : config.iosUrl;
                if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                Navigator.pop(ctx);
              },
              child: Text(l10n.update),
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
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.instance.locale,
          builder: (context, locale, _) {
            return AppRoot(
              child: MaterialApp.router(
                routerConfig: _router,
                onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                theme: InstriqTheme.light,
                darkTheme: InstriqTheme.dark,
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            );
          },
        );
      },
    );
  }
}
