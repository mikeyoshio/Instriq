import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospital.dart';
import '../models/work_mode.dart';
import '../utils/invite_code.dart';
import 'auth_service.dart';
import 'group_document_service.dart';
import 'preference_card_service.dart';
import 'surgeon_service.dart';
import 'team_service.dart';
import 'tray_service.dart';
import 'workspace_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  String? _organizationId;
  String? _organizationName;
  String? _hospitalCif;
  String? _inviteCode;
  bool _isAdmin = false;
  bool _isOwner = false;
  String? _ownerId;
  bool _canApproveAnyWorkspace = false;

  /// Reactivo a propósito: el selector de modo de trabajo de la capçalera
  /// (ver work_mode_header.dart) necesita repintarse a l'instant en cualquier
  /// punto de la app al cambiar de modo, sin pasar por un `setState` manual
  /// de cada pantalla que lo consulte.
  final ValueNotifier<WorkMode?> activeWorkModeNotifier = ValueNotifier<WorkMode?>(null);

  String? get organizationId => _organizationId;
  String? get organizationName => _organizationName;
  String? get hospitalCif => _hospitalCif;
  String? get inviteCode => _inviteCode;
  bool get isAdmin => _isAdmin;
  bool get isOwner => _isOwner;
  String? get ownerId => _ownerId;
  bool get hasHospital => _organizationId != null;

  /// `true` si el usuario actual es `approver` (o `administrator`, aunque ese
  /// valor nunca se guarda como fila) en al menos un espacio de trabajo, sin
  /// importar de cuál. Junto con `isAdmin`, es la condición real para mostrar
  /// la pestaña de Actividad/cola de revisión — `isAdmin` solo no basta porque
  /// `approver` es un rol por espacio (`workspace_members`), no un flag global.
  bool get canApproveAnyWorkspace => _canApproveAnyWorkspace;

  Future<void> loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _resetHospitalState();
      return;
    }
    final row = await _client
        .from('profiles')
        .select('organization_id, is_admin, active_work_mode, organizations(name, cif, invite_code, owner_id)')
        .eq('id', user.id)
        .maybeSingle();
    final newOrganizationId = row?['organization_id'] as String?;
    if (newOrganizationId != _organizationId) {
      _clearGroupContentCaches();
    }
    _organizationId = newOrganizationId;
    _isAdmin = row?['is_admin'] as bool? ?? false;
    final hospitalRow = row?['organizations'] as Map<String, dynamic>?;
    _organizationName = hospitalRow?['name'] as String?;
    _hospitalCif = hospitalRow?['cif'] as String?;
    _inviteCode = hospitalRow?['invite_code'] as String?;
    _ownerId = hospitalRow?['owner_id'] as String?;
    _isOwner = _ownerId == user.id;
    activeWorkModeNotifier.value = WorkModeLabel.fromDb(row?['active_work_mode'] as String?);

    // Consulta barata (RLS ya permite leer las filas propias de
    // workspace_members, ver "workspace_members_select" en schema_v7): solo
    // existencia, no hace falta RPC ni traer contenido.
    final approverRow = await _client
        .from('workspace_members')
        .select('id')
        .eq('user_id', user.id)
        .inFilter('role', ['approver', 'administrator'])
        .limit(1)
        .maybeSingle();
    _canApproveAnyWorkspace = approverRow != null;
  }

  /// Guarda la preferencia de modo de trabajo (update directo a `profiles`,
  /// sin RPC ni auditoría: es solo una preferencia de visualización, no una
  /// acción sensible — ver schema_v18).
  Future<void> setActiveWorkMode(WorkMode? mode) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({'active_work_mode': mode?.dbValue}).eq('id', user.id);
    activeWorkModeNotifier.value = mode;
  }

  void _resetHospitalState() {
    _organizationId = null;
    _organizationName = null;
    _hospitalCif = null;
    _inviteCode = null;
    _isAdmin = false;
    _isOwner = false;
    _ownerId = null;
    _canApproveAnyWorkspace = false;
    activeWorkModeNotifier.value = null;
    _clearGroupContentCaches();
  }

  /// Al cambiar de grupo (unirse, crear uno nuevo, cerrar sesión) hay que
  /// limpiar el caché en memoria de todo el contenido del grupo anterior:
  /// si no, un espacio/documento/tarjeta del grupo previo puede quedar
  /// cacheado y usarse por error junto con el organization_id del grupo nuevo.
  void _clearGroupContentCaches() {
    WorkspaceService.instance.clear();
    GroupDocumentService.instance.clear();
    PreferenceCardService.instance.clear();
    TrayService.instance.clear();
    SurgeonService.instance.clear();
    TeamService.instance.clear();
  }

  /// Busca el hospital por código de invitación y liga el perfil del usuario actual.
  /// Devuelve el hospital si el código es válido, o null si no existe.
  ///
  /// Vía RPC (`join_hospital_with_code`, ver schema_v31_profile_security_hardening.sql):
  /// antes esto era un `select` directo sobre `organizations` (exigía que
  /// cualquiera pudiera leer todas las organizaciones para validar un código,
  /// filtrando invite_code/cif de todo el mundo) + un `upsert` directo sobre
  /// `profiles` (sin verificación de servidor de qué columnas se tocaban).
  /// Ambos motivos de la auditoría de seguridad de 2026-08.
  Future<Hospital?> joinHospitalWithCode(String inviteCode, {String? displayName}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;

    final rows = await _client.rpc('join_hospital_with_code', params: {
      'p_invite_code': normalizeInviteCode(inviteCode),
      if (displayName != null && displayName.isNotEmpty) 'p_display_name': displayName,
    }) as List<dynamic>;
    if (rows.isEmpty) return null;

    final hospital = Hospital.fromRow(rows.first as Map<String, dynamic>);
    _clearGroupContentCaches();
    _organizationId = hospital.id;
    _organizationName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _ownerId = hospital.ownerId;
    _isAdmin = false;
    _isOwner = false;
    return hospital;
  }

  /// Registra un hospital nuevo (autoservicio) y lo liga como admin al usuario actual.
  ///
  /// Vía RPC (`register_hospital`, ver schema_v31_profile_security_hardening.sql):
  /// antes el `insert`+`upsert` se hacían directamente desde el cliente,
  /// confiando en que la policy de `profiles` no permitiera fijar columnas
  /// arbitrarias -- no era así (auditoría de seguridad 2026-08).
  Future<Hospital> registerHospital({
    required String name,
    String? displayName,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay sesión activa.');

    final rows = await _client.rpc('register_hospital', params: {
      'p_name': name.trim(),
      if (displayName != null && displayName.isNotEmpty) 'p_display_name': displayName,
    }) as List<dynamic>;

    final hospital = Hospital.fromRow(rows.first as Map<String, dynamic>);
    _clearGroupContentCaches();
    _organizationId = hospital.id;
    _organizationName = hospital.name;
    _hospitalCif = hospital.cif;
    _inviteCode = hospital.inviteCode;
    _ownerId = hospital.ownerId;
    _isAdmin = true;
    _isOwner = true;
    return hospital;
  }

  /// Genera un nuevo código de invitación para el hospital actual (solo admin).
  Future<String> regenerateInviteCode() async {
    if (_organizationId == null) throw StateError('No perteneces a ningún hospital.');
    String code = generateInviteCode();
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _client.from('organizations').update({'invite_code': code}).eq('id', _organizationId!);
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
    if (_organizationId == null) return [];
    final rows = await _client
        .from('profiles')
        .select('id, display_name, is_admin')
        .eq('organization_id', _organizationId!);
    return (rows as List<dynamic>)
        .map((r) => HospitalMember.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Expulsa a un miembro del hospital (solo admin, vía función security
  /// definer -- `remove_hospital_member`, ver
  /// schema_v31_profile_security_hardening.sql). Antes era un `update`
  /// directo sobre `profiles`: la UI ocultaba el botón para admins/propietario
  /// pero nada lo impedía en el servidor -- un admin podía expulsar a otro
  /// admin o a la propietaria/el propietario llamando la misma escritura
  /// directamente (auditoría de seguridad 2026-08). El RPC rechaza ambos
  /// casos; el error real (no capturado aquí) lo muestra la pantalla llamante.
  Future<void> removeMember(String userId) async {
    await _client.rpc('remove_hospital_member', params: {'p_user_id': userId});
  }

  /// Transfiere la propiedad del grupo a otro miembro (solo la propietaria/el
  /// propietario actual, vía función security definer).
  Future<void> transferOwnership(String newOwnerUserId) async {
    await _client.rpc('transfer_hospital_ownership', params: {'new_owner_id': newOwnerUserId});
    _isOwner = false;
  }

  /// Promueve o quita el rol de administrador/a de otro miembro del grupo
  /// (solo admin, vía función security definer). El RPC rechaza quitar el
  /// último admin de la organización — el error real (no capturado aquí) lo
  /// muestra la pantalla llamante, igual que con `transferOwnership`.
  Future<void> setHospitalAdmin(String userId, bool isAdmin) async {
    await _client.rpc('set_hospital_admin', params: {'p_user_id': userId, 'p_is_admin': isAdmin});
  }
}
