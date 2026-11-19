import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password, emailRedirectTo: appBaseUrl);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Proveïdors d'inici de sessió que l'app sap mostrar, en ordre.
  static const oauthProviders = [OAuthProvider.google, OAuthProvider.azure, OAuthProvider.apple];

  /// Retorn a l'app nativa després del login al navegador (Android:
  /// intent-filter a AndroidManifest; iOS: CFBundleURLTypes a Info.plist).
  /// S'ha d'afegir a Authentication -> URL Configuration -> Redirect URLs.
  static const _nativeRedirect = 'instriq://login-callback';

  /// Windows no té encara la tornada des del navegador (caldria registrar el
  /// protocol instriq:// al paquet MSIX): allà només correu i contrasenya.
  bool get oauthSupported => kIsWeb || defaultTargetPlatform != TargetPlatform.windows;

  /// Quins proveïdors estan activats al panell de Supabase (Authentication
  /// -> Sign In / Providers). Endpoint públic de GoTrue: activar-ne un al
  /// panell fa aparèixer el botó a l'app sense publicar cap versió nova.
  Future<List<OAuthProvider>> enabledOAuthProviders() async {
    if (!oauthSupported) return const [];
    try {
      final res = await http.get(Uri.parse('$supabaseUrl/auth/v1/settings'), headers: {'apikey': supabaseAnonKey});
      final external = (jsonDecode(res.body) as Map)['external'] as Map? ?? const {};
      return [for (final p in oauthProviders) if (external[p.name] == true) p];
    } catch (_) {
      return const [];
    }
  }

  /// Google (també comptes de Google Workspace), Microsoft (comptes personals
  /// i de feina/escola d'Entra ID) i Apple. Si el correu ja té compte amb
  /// contrasenya, Supabase hi vincula la identitat nova: és el mateix usuari.
  /// A la web la pàgina marxa al proveïdor i torna a appBaseUrl amb la sessió.
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? appBaseUrl : _nativeRedirect,
      // Entra ID no envia el correu si no es demana explícitament.
      scopes: provider == OAuthProvider.azure ? 'email' : null,
      // Deixa triar compte (personal o de feina) en lloc d'entrar amb l'últim.
      queryParams: provider == OAuthProvider.apple ? null : const {'prompt': 'select_account'},
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim(), redirectTo: appBaseUrl);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Auditoría de login (ver supabase/schema_v21). Fire-and-forget a
  /// propósito: un fallo aquí (p.ej. sin red en el instante del login) no
  /// debe impedir que la persona entre en la app.
  Future<void> logLoginEvent() async {
    try {
      await _client.rpc('log_login_event');
    } catch (_) {}
  }
}
