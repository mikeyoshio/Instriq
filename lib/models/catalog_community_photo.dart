/// Foto aportada por la comunidad para un instrumento del catálogo global
/// que todavía no tiene foto verificada (ver `Instrument.image` en
/// `lib/models/instrument.dart`). Vive en moderación previa: solo se muestra
/// a cualquier usuario (con o sin sesión) cuando [status] es 'approved'. Ver
/// supabase/schema_v16_community_photos.sql para el modelo completo y RLS.
class CatalogCommunityPhoto {
  final String id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String photoPath;
  final String status;
  final String? submittedBy;
  final String? creditName;
  final bool consentAccepted;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;

  const CatalogCommunityPhoto({
    required this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    required this.photoPath,
    required this.status,
    this.submittedBy,
    this.creditName,
    required this.consentAccepted,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory CatalogCommunityPhoto.fromRow(Map<String, dynamic> row) {
    return CatalogCommunityPhoto(
      id: row['id'] as String,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      photoPath: row['photo_path'] as String,
      status: row['status'] as String? ?? 'pending',
      submittedBy: row['submitted_by'] as String?,
      creditName: row['credit_name'] as String?,
      consentAccepted: row['consent_accepted'] as bool? ?? false,
      reviewedBy: row['reviewed_by'] as String?,
      reviewedAt: row['reviewed_at'] != null ? DateTime.tryParse(row['reviewed_at'] as String) : null,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
