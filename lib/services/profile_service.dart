import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospital.dart';
import '../utils/invite_code.dart';
import 'auth_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? _hospitalId;
  String? _hospitalName;
  String? _hospitalCif;
  String? _inviteCode;
  bool _isAdmin = false;

  String? get hospitalId => _hospitalId;
  String? get hospitalName => _hospitalName;
  String? get hospitalCif => _hospitalCif;
  String? get inviteCode => _inviteCode;
  bool get isAdmin => _isAdmin;
  bool get hasHospital => _hospitalId != null;

  Future<void> loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _resetHospitalState();
      return;
    }
    final row = await _client
        .from('profiles')
        .select('hospital_id, is_admin, hospitals(name, cif, invite_code)')
        .eq('id', user.id)
        .maybeSingle();
    _hospitalId = row?['hospital_id'] as String?;
    _isAdmin = row?['is_admin'] as bool? ?? false;
    final hospitalRow = row?['hospitals'] as Map<String, dynamic>?;
    _hospitalName = hospitalRow?['name'] as String?;
    _hospitalCif = hospitalRow?['cif'] as String?;
    _inviteCode = hospitalRow?['invite_code'] as String?;
  }

  void _resetHospitalState() {
    _hospitalId = null;
    _hospitalName = null;
    _hospitalCif = null;
    _inviteCode = null;
    _isAdmin = false;
  }

  /// Busca el hospital por código de invitación y liga el perfil del usuario actual.
  /// Devuelve el hospital si el código es válido, o null si no existe.
  Future<Hospital?> joinHospitalWithCode(String inviteCode, {String? displayName}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;

    final normalized = normalizeInviteCode(inviteCode);
    final hospitalRow = await _client
        .from('hospitals')
        .select()
        .eq('invite_code', normalized)
        .maybeSingle();
    if (hospitalRow == null) return null;

    final hospital = Hospital.fromRow(hospitalRow);
    await _client.from('profiles').upsert({
      'id': user.id,
      'hospital_id': hospital.id,
      'is_admin': false,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    });
    _hospitalId = hospital.id;
    _hospitalName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _isAdmin = false;
    return hospital;
  }

  /// Registra un hospital nuevo (autoservicio) y lo liga como admin al usuario actual.
  /// Lanza [StateError] si el CIF ya está registrado.
  Future<Hospital> registerHospital({
    required String name,
    required String cif,
    String? displayName,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay sesión activa.');

    final normalizedCif = cif.trim().toUpperCase();
    final existing = await _client.from('hospitals').select().eq('cif', normalizedCif).maybeSingle();
    if (existing != null) {
      throw StateError('Ya existe un hospital registrado con ese CIF.');
    }

    String code = generateInviteCode();
    Map<String, dynamic>? inserted;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        inserted = await _client
            .from('hospitals')
            .insert({
              'name': name.trim(),
              'cif': normalizedCif,
              'invite_code': code,
              'created_by': user.id,
            })
            .select()
            .single();
        break;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          code = generateInviteCode();
          continue;
        }
        rethrow;
      }
    }
    if (inserted == null) {
      throw StateError('No se pudo generar un código de invitación único. Inténtalo de nuevo.');
    }

    final hospital = Hospital.fromRow(inserted);
    await _client.from('profiles').upsert({
      'id': user.id,
      'hospital_id': hospital.id,
      'is_admin': true,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    });
    _hospitalId = hospital.id;
    _hospitalName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _isAdmin = true;
    return hospital;
  }

  /// Genera un nuevo código de invitación para el hospital actual (solo admin).
  Future<String> regenerateInviteCode() async {
    if (_hospitalId == null) throw StateError('No perteneces a ningún hospital.');
    String code = generateInviteCode();
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _client.from('hospitals').update({'invite_code': code}).eq('id', _hospitalId!);
        _inviteCode = code;
        return code;
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          code = generateInviteCode();
          continue;
        }
        rethrow;
      }
    }
    throw StateError('No se pudo generar un código único. Inténtalo de nuevo.');
  }

  Future<List<HospitalMember>> fetchMembers() async {
    if (_hospitalId == null) return [];
    final rows = await _client
        .from('profiles')
        .select('id, display_name, is_admin')
        .eq('hospital_id', _hospitalId!);
    return (rows as List<dynamic>)
        .map((r) => HospitalMember.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Expulsa a un miembro del hospital (solo admin, vía RLS).
  Future<void> removeMember(String userId) async {
    await _client.from('profiles').update({'hospital_id': null, 'is_admin': false}).eq('id', userId);
  }
}
