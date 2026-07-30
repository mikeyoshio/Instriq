/// Fila cruda de `favorites`/`recent_views` (ver
/// supabase/schema_v18_work_mode_favorites_recent.sql): solo la referencia,
/// nunca el título humano — resolverlo requiere consultar el servicio dueño
/// de ese tipo de contenido (ver lib/utils/ref_resolver.dart), así que estos
/// modelos se quedan deliberadamente "tontos".
class FavoriteEntry {
  final String refType;
  final String refId;

  const FavoriteEntry({required this.refType, required this.refId});

  factory FavoriteEntry.fromRow(Map<String, dynamic> row) => FavoriteEntry(
        refType: row['ref_type'] as String,
        refId: row['ref_id'] as String,
      );
}

class RecentViewEntry {
  final String refType;
  final String refId;
  final DateTime viewedAt;

  const RecentViewEntry({required this.refType, required this.refId, required this.viewedAt});

  factory RecentViewEntry.fromRow(Map<String, dynamic> row) => RecentViewEntry(
        refType: row['ref_type'] as String,
        refId: row['ref_id'] as String,
        viewedAt: DateTime.parse(row['viewed_at'] as String),
      );
}
