import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospital.dart';
import 'auth_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? _hospitalId;
  String? _hospitalName;

  String? get hospitalId => _hospitalId;
  String? get hospitalName => _hospitalName;
  bool get hasHospital => _hospitalId != null;

  Future<void> loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _hospitalId = null;
      _hospitalName = null;
      return;
    }
    final row = await _client
        .from('profiles')
        .select('hospital_id, hospitals(name)')
        .eq('id', user.id)
        .maybeSingle();
    _hospitalId = row?['hospital_id'] as String?;
    _hospitalName = (row?['hospitals'] as Map<String, dynamic>?)?['name'] as String?;
  }

  /// Busca el hospital por código de invitación y liga el perfil del usuario actual.
  /// Devuelve el hospital si el código es válido, o null si no existe.
  Future<Hospital?> joinHospitalWithCode(String inviteCode) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;

    final hospitalRow = await _client
        .from('hospitals')
        .select()
        .eq('invite_code', inviteCode.trim())
        .maybeSingle();
    if (hospitalRow == null) return null;

    final hospital = Hospital.fromRow(hospitalRow);
    await _client.from('profiles').upsert({
      'id': user.id,
      'hospital_id': hospital.id,
    });
    _hospitalId = hospital.id;
    _hospitalName = hospital.name;
    return hospital;
  }
}
