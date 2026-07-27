/// Cobertura de conocimiento documentado de una especialidad concreta dentro
/// del hospital: cuantas tecnicas/protocolos tienen version aprobada vigente
/// (publicada) y cuantas estan en borrador o revision. Esto mide contenido
/// documentado, no consultas ni uso.
class SpecialtyContentStats {
  final String specialty;
  final int publishedCount;
  final int draftReviewCount;

  const SpecialtyContentStats({
    required this.specialty,
    required this.publishedCount,
    required this.draftReviewCount,
  });

  factory SpecialtyContentStats.fromRow(Map<String, dynamic> row) {
    return SpecialtyContentStats(
      specialty: row['specialty'] as String? ?? 'Sin especialidad',
      publishedCount: (row['published_count'] as num?)?.toInt() ?? 0,
      draftReviewCount: (row['draft_review_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Miembros del hospital agrupados por rol efectivo. "administrator" es a
/// nivel de organizacion; reader/editor/approver son por espacio de trabajo
/// (una misma persona puede contar en varias columnas si tiene roles
/// distintos en espacios distintos).
class MembersByRole {
  final int administrator;
  final int reader;
  final int editor;
  final int approver;

  const MembersByRole({
    this.administrator = 0,
    this.reader = 0,
    this.editor = 0,
    this.approver = 0,
  });

  factory MembersByRole.fromRow(Map<String, dynamic> row) {
    return MembersByRole(
      administrator: (row['administrator'] as num?)?.toInt() ?? 0,
      reader: (row['reader'] as num?)?.toInt() ?? 0,
      editor: (row['editor'] as num?)?.toInt() ?? 0,
      approver: (row['approver'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Resultado de `hospital_content_stats`: foto agregada de cuanto
/// conocimiento tiene documentado el hospital, no de cuanto se usa/consulta
/// (ese dato no existe hoy — el progreso de aprendizaje vive solo local en
/// cada dispositivo, ver lib/services/progress_service.dart).
class HospitalContentStats {
  final List<SpecialtyContentStats> bySpecialty;
  final int workspacesCount;
  final int preferenceCardsCount;
  final MembersByRole membersByRole;

  const HospitalContentStats({
    required this.bySpecialty,
    required this.workspacesCount,
    required this.preferenceCardsCount,
    required this.membersByRole,
  });

  factory HospitalContentStats.fromJson(Map<String, dynamic> json) {
    final bySpecialtyRaw = json['by_specialty'] as List<dynamic>? ?? [];
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final membersRaw = totals['members_by_role'] as Map<String, dynamic>? ?? {};
    return HospitalContentStats(
      bySpecialty: bySpecialtyRaw
          .map((e) => SpecialtyContentStats.fromRow(e as Map<String, dynamic>))
          .toList(),
      workspacesCount: (totals['workspaces_count'] as num?)?.toInt() ?? 0,
      preferenceCardsCount: (totals['preference_cards_count'] as num?)?.toInt() ?? 0,
      membersByRole: MembersByRole.fromRow(membersRaw),
    );
  }
}
