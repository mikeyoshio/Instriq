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
