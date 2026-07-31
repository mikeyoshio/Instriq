/// Resultado de `organization_usage_stats` (ver
/// supabase/schema_v23_usage_analytics.sql): uso real de los últimos 30 días,
/// a diferencia de [HospitalContentStats] que mide contenido documentado, no
/// consultado. Visible solo para admin de la organización (misma política de
/// privacidad que audit_log).
class UsageRefCount {
  final String refType;
  final String refId;
  final int viewCount;

  const UsageRefCount({required this.refType, required this.refId, required this.viewCount});

  factory UsageRefCount.fromRow(Map<String, dynamic> row) {
    return UsageRefCount(
      refType: row['ref_type'] as String? ?? '',
      refId: row['ref_id'] as String? ?? '',
      viewCount: (row['view_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class UsageQueryCount {
  final String query;
  final int searchCount;

  const UsageQueryCount({required this.query, required this.searchCount});

  factory UsageQueryCount.fromRow(Map<String, dynamic> row) {
    return UsageQueryCount(
      query: row['query'] as String? ?? '',
      searchCount: (row['search_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class UsagePersonCount {
  final String displayName;
  final int draftCount;

  const UsagePersonCount({required this.displayName, required this.draftCount});

  factory UsagePersonCount.fromRow(Map<String, dynamic> row) {
    return UsagePersonCount(
      displayName: row['display_name'] as String? ?? '',
      draftCount: (row['draft_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Resultado completo de `organization_usage_stats`.
class UsageStats {
  final List<UsageRefCount> topViewed;
  final List<UsageQueryCount> topSearches;
  final List<UsageQueryCount> zeroResultSearches;
  final List<UsagePersonCount> pendingDraftsByPerson;

  const UsageStats({
    required this.topViewed,
    required this.topSearches,
    required this.zeroResultSearches,
    required this.pendingDraftsByPerson,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    final topViewedRaw = json['top_viewed'] as List<dynamic>? ?? [];
    final topSearchesRaw = json['top_searches'] as List<dynamic>? ?? [];
    final zeroResultRaw = json['zero_result_searches'] as List<dynamic>? ?? [];
    final pendingDraftsRaw = json['pending_drafts_by_person'] as List<dynamic>? ?? [];
    return UsageStats(
      topViewed: topViewedRaw.map((e) => UsageRefCount.fromRow(e as Map<String, dynamic>)).toList(),
      topSearches: topSearchesRaw.map((e) => UsageQueryCount.fromRow(e as Map<String, dynamic>)).toList(),
      zeroResultSearches:
          zeroResultRaw.map((e) => UsageQueryCount.fromRow(e as Map<String, dynamic>)).toList(),
      pendingDraftsByPerson:
          pendingDraftsRaw.map((e) => UsagePersonCount.fromRow(e as Map<String, dynamic>)).toList(),
    );
  }
}
