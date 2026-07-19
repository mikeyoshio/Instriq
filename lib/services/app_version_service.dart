import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  final String minVersion;
  final String latestVersion;
  final String? message;
  final String? androidUrl;
  final String? iosUrl;

  const AppConfig({
    required this.minVersion,
    required this.latestVersion,
    this.message,
    this.androidUrl,
    this.iosUrl,
  });

  factory AppConfig.fromRow(Map<String, dynamic> row) {
    return AppConfig(
      minVersion: row['min_version'] as String? ?? '1.0.0',
      latestVersion: row['latest_version'] as String? ?? '1.0.0',
      message: row['message'] as String?,
      androidUrl: row['android_url'] as String?,
      iosUrl: row['ios_url'] as String?,
    );
  }
}

class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<AppConfig?> fetchConfig() async {
    final row = await _client.from('app_config').select().eq('id', 1).maybeSingle();
    if (row == null) return null;
    return AppConfig.fromRow(row);
  }

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Compara versiones "major.minor.patch". Devuelve true si [current] es
  /// estrictamente menor que [reference]. Ignora formatos no numéricos
  /// (los trata como 0) en vez de lanzar, para no romper el arranque de la app.
  bool isOlderThan(String current, String reference) {
    final currentParts = _parts(current);
    final referenceParts = _parts(reference);
    for (var i = 0; i < 3; i++) {
      if (currentParts[i] != referenceParts[i]) {
        return currentParts[i] < referenceParts[i];
      }
    }
    return false;
  }

  List<int> _parts(String version) {
    final segments = version.split('.');
    return List.generate(3, (i) => i < segments.length ? int.tryParse(segments[i]) ?? 0 : 0);
  }
}
