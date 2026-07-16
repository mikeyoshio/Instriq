class PreferenceCardItem {
  final String? instrumentId;
  final String customName;
  final String? note;

  const PreferenceCardItem({
    this.instrumentId,
    required this.customName,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'instrumentId': instrumentId,
        'customName': customName,
        'note': note,
      };

  factory PreferenceCardItem.fromJson(Map<String, dynamic> json) {
    return PreferenceCardItem(
      instrumentId: json['instrumentId'] as String?,
      customName: json['customName'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

class PreferenceCard {
  final String id;
  final String surgeonName;
  final String procedureName;
  final List<PreferenceCardItem> items;
  final String? generalNotes;

  const PreferenceCard({
    required this.id,
    required this.surgeonName,
    required this.procedureName,
    required this.items,
    this.generalNotes,
  });

  PreferenceCard copyWith({
    String? surgeonName,
    String? procedureName,
    List<PreferenceCardItem>? items,
    String? generalNotes,
  }) {
    return PreferenceCard(
      id: id,
      surgeonName: surgeonName ?? this.surgeonName,
      procedureName: procedureName ?? this.procedureName,
      items: items ?? this.items,
      generalNotes: generalNotes ?? this.generalNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surgeonName': surgeonName,
        'procedureName': procedureName,
        'items': items.map((i) => i.toJson()).toList(),
        'generalNotes': generalNotes,
      };

  factory PreferenceCard.fromJson(Map<String, dynamic> json) {
    return PreferenceCard(
      id: json['id'] as String,
      surgeonName: json['surgeonName'] as String? ?? '',
      procedureName: json['procedureName'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PreferenceCardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalNotes: json['generalNotes'] as String?,
    );
  }
}
