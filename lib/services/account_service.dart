import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

/// Derechos GDPR sobre la cuenta propia: exportar los datos personales y
/// eliminar la cuenta. Ambas operaciones se hacen vía funciones `security
/// definer` en Supabase (ver supabase/schema_v9_gdpr.sql) — la exportación
/// no puede depender de las políticas RLS normales (basadas en el rol
/// actual en cada espacio) porque alguien puede haber perdido acceso a un
/// espacio y aun así tener derecho a ver lo que él mismo creó allí.
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> exportMyData() async {
    final result = await _client.rpc('export_my_account_data');
    return result as Map<String, dynamic>;
  }

  /// Elimina la cuenta y cierra la sesión local. Lanza [PostgrestException]
  /// con un mensaje explicativo si la persona es propietaria de un grupo
  /// con más miembros (debe transferir la propiedad antes).
  Future<void> deleteMyAccount() async {
    await _client.rpc('delete_my_account');
    await _client.auth.signOut();
    // Fuerza la limpieza del caché de grupo/espacios en memoria: loadProfile()
    // detecta que ya no hay sesión y resetea el estado (mismo camino que ya
    // existe para cualquier cierre de sesión).
    await ProfileService.instance.loadProfile();
  }
}
