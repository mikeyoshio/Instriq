// One-off: splits the overloaded InstrumentCategory.especiales bucket (174 of
// 390 entries, ~45% of the catalog) into equipos (existing, now also holding
// powered/capital-equipment items that were inconsistently left out) plus 3
// new categories (consumibles, implantes, accesos), with ~20 genuine one-off
// hand tools folded into the existing corte/diseccion/separacion categories.
// Mapping authored by hand in recategorize.json, id -> new category.
//
// Usage: dart run tool/recategorize_especiales.dart

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final mappingFile = File(args.isNotEmpty ? args[0] : 'tool/recategorize_especiales.json');
  final mapping = jsonDecode(mappingFile.readAsStringSync(encoding: utf8)) as Map<String, dynamic>;

  final dataFile = File('lib/data/instruments_data.dart');
  final lines = dataFile.readAsLinesSync();

  final idPattern = RegExp(r"^\s*id: '([^']+)',");
  final categoryPattern = RegExp(r'^(\s*category: InstrumentCategory\.)especiales,');

  String? currentId;
  var replaced = 0;
  final touchedIds = <String>{};

  for (var i = 0; i < lines.length; i++) {
    final idMatch = idPattern.firstMatch(lines[i]);
    if (idMatch != null) {
      currentId = idMatch.group(1);
      continue;
    }
    final catMatch = categoryPattern.firstMatch(lines[i]);
    if (catMatch == null) continue;

    final newCategory = mapping[currentId];
    if (newCategory == null) {
      throw StateError('No mapping for especiales entry with id=$currentId at line ${i + 1}');
    }
    lines[i] = '${catMatch.group(1)}$newCategory,';
    replaced++;
    touchedIds.add(currentId!);
  }

  if (replaced != mapping.length) {
    throw StateError('Replaced $replaced lines but mapping has ${mapping.length} entries');
  }
  final unused = mapping.keys.toSet().difference(touchedIds);
  if (unused.isNotEmpty) {
    throw StateError('Mapping entries never matched in file: $unused');
  }

  dataFile.writeAsStringSync('${lines.join('\n')}\n', encoding: utf8);
  stdout.writeln('Recategorized $replaced entries.');
}
