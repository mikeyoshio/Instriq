import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospital.dart';
import '../utils/invite_code.dart';
import 'auth_service.dart';
import 'group_document_service.dart';
import 'preference_card_service.dart';
import 'workspace_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? _hospitalId;
  String? _hospitalName;
  String? _hospitalCif;
  String? _inviteCode;
  bool _isAdmin = false;
  bool _isOwner = false;
  String? _ownerId;

  String? get hospitalId => _hospitalId;
  String? get hospitalName => _hospitalName;
  String? get hospitalCif => _hospitalCif;
  String? get inviteCode => _inviteCode;
  bool get isAdmin => _isAdmin;
  bool get isOwner => _isOwner;
  String? get ownerId => _ownerId;
  bool get hasHospital => _hospitalId != null;

  Future<void> loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _resetHospitalState();
      return;
    }
    final row = await _client
        .from('profiles')
        .select('hospital_id, is_admin, hospitals(name, cif, invite_code, owner_id)')
        .eq('id', user.id)
        .maybeSingle();
    final newHospitalId = row?['hospital_id'] as String?;
    if (newHospitalId != _hospitalId) {
      _clearGroupContentCaches();
    }
    _hospitalId = newHospitalId;
    _isAdmin = row?['is_admin'] as bool? ?? false;
    final hospitalRow = row?['hospitals'] as Map<String, dynamic>?;
    _hospitalName = hospitalRow?['name'] as String?;
    _hospitalCif = hospitalRow?['cif'] as String?;
    _inviteCode = hospitalRow?['invite_code'] as String?;
    _ownerId = hospitalRow?['owner_id'] as String?;
    _isOwner = _ownerId == user.id;
  }

  void _resetHospitalState() {
    _hospitalId = null;
    _hospitalName = null;
    _hospitalCif = null;
    _inviteCode = null;
    _isAdmin = false;
    _isOwner = false;
    _ownerId = null;
    _clearGroupContentCaches();
  }

  /// Al cambiar de grupo (unirse, crear uno nuevo, cerrar sesión) hay que
  /// limpiar el caché en memoria de todo el contenido del grupo anterior:
  /// si no, un espacio/documento/tarjeta del grupo previo puede quedar
  /// cacheado y usarse por error junto con el hospital_id del grupo nuevo.
  void _clearGroupContentCaches() {
    WorkspaceService.instance.clear();
    GroupDocumentService.instance.clear();
    PreferenceCardService.instance.clear();
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
    _clearGroupContentCaches();
    _hospitalId = hospital.id;
    _hospitalName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _ownerId = hospital.ownerId;
    _isAdmin = false;
    _isOwner = false;
    return hospital;
  }

  /// Registra un hospital nuevo (autoservicio) y lo liga como admin al usuario actual.
  Future<Hospital> registerHospital({
    required String name,
    String? displayName,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay sesión activa.');

    String code = generateInviteCode();
    Map<String, dynamic>? inserted;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        inserted = await _client
            .from('hospitals')
            .insert({
              'name': name.trim(),
              'invite_code': code,
              'created_by': user.id,
              'owner_id': user.id,
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
    _clearGroupContentCaches();
    _hospitalId = hospital.id;
    _hospitalName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _ownerId = hospital.ownerId;
    _isAdmin = true;
    _isOwner = true;
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

  /// Transfiere la propiedad del grupo a otro miembro (solo la propietaria/el
  /// propietario actual, vía función security definer).
  Future<void> transferOwnership(String newOwnerUserId) async {
    await _client.rpc('transfer_hospital_ownership', params: {'new_owner_id': newOwnerUserId});
    _isOwner = false;
  }
}
