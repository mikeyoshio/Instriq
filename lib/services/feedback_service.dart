import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_version_service.dart';

enum FeedbackCategory { bug, suggestion, other }

extension FeedbackCategoryValue on FeedbackCategory {
  String get dbValue => switch (this) {
        FeedbackCategory.bug => 'bug',
        FeedbackCategory.suggestion => 'suggestion',
        FeedbackCategory.other => 'other',
      };
}

/// Envío de feedback/soporte desde la app (`submit_app_feedback`, ver
/// supabase/schema_v56_app_feedback.sql) -- deliberadamente sin pantalla de
/// lectura: el propietario del proyecto lo consulta por Supabase Studio. El
/// RPC está concedido también a `anon`, así que esto funciona igual en modo
/// invitado que con sesión iniciada.
class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> submit({required FeedbackCategory category, required String message}) async {
    final appVersion = await AppVersionService.instance.currentVersion();
    await _client.rpc('submit_app_feedback', params: {
      'p_category': category.dbValue,
      'p_message': message,
      'p_app_version': appVersion,
      'p_platform': _platformName(),
    });
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
