// Auditoría de calidad del catálogo global (tool/, solo lectura): detecta
// duplicados de nombre, colisiones de sinónimo, traducciones vacías y fichas
// sin imagen sobre lib/data/instruments_data.dart. Reutiliza el parser de
// generate_vademecum.dart (mismo motivo de ese archivo: el modelo
// Instrument/LocalizedText real importa Flutter via app_localizations.dart
// para las extensiones .label(l10n), que `dart run` no puede cargar) en vez
// de duplicar la lógica de parseo.
//
// No toca `knowledge_links`/datos de fabricante de Supabase (viven en el
// proyecto real, no en este repo) -- eso queda para una ronda futura con
// acceso a la base de datos.
//
// Uso: dart run tool/audit_catalog_quality.dart
import 'dart:io';

import 'generate_vademecum.dart' show Instr, Tri, parseInstruments;

void main() async {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent;
  final dataFile = File('${repoRoot.path}/lib/data/instruments_data.dart');
  final source = await dataFile.readAsString();
  final instruments = parseInstruments(source);

  final issues = <String>[];
  _checkDuplicateIds(instruments, issues);
  _checkNearDuplicateNames(instruments, issues);
  _checkAliasCollisions(instruments, issues);
  _checkEmptyTranslations(instruments, issues);
  _checkMissingImages(instruments, issues);

  stdout.writeln('Auditoría de calidad del catálogo — ${instruments.length} instrumentos\n');
  if (issues.isEmpty) {
    stdout.writeln('Sin hallazgos.');
    return;
  }
  for (final issue in issues) {
    stdout.writeln('- $issue');
  }
  stdout.writeln('\n${issues.length} hallazgo(s).');
}

void _checkDuplicateIds(List<Instr> instruments, List<String> issues) {
  final seen = <String>{};
  for (final i in instruments) {
    if (!seen.add(i.id)) issues.add('[id duplicado] "${i.id}" aparece más de una vez');
  }
}

void _checkNearDuplicateNames(List<Instr> instruments, List<String> issues) {
  for (var a = 0; a < instruments.length; a++) {
    for (var b = a + 1; b < instruments.length; b++) {
      final nameA = instruments[a].name.es;
      final nameB = instruments[b].name.es;
      if (nameA == nameB) {
        issues.add('[nombre idéntico] "$nameA" en ${instruments[a].id} y ${instruments[b].id}');
        continue;
      }
      final normA = _normalize(nameA);
      final normB = _normalize(nameB);
      if (normA.length <= 4 || normB.length <= 4) continue;
      if ((normA.length - normB.length).abs() > 2) continue;
      final distance = _levenshtein(normA, normB);
      if (distance <= 2) {
        issues.add(
          '[posible duplicado] "$nameA" (${instruments[a].id}) ~ "$nameB" (${instruments[b].id}), distancia $distance',
        );
      }
    }
  }
}

void _checkAliasCollisions(List<Instr> instruments, List<String> issues) {
  final ownerOf = <String, String>{}; // nombre normalizado -> id dueño
  for (final i in instruments) {
    ownerOf.putIfAbsent(_normalize(i.name.es), () => i.id);
  }
  for (final i in instruments) {
    for (final alias in i.aliases) {
      final key = _normalize(alias);
      final owner = ownerOf[key];
      if (owner != null && owner != i.id) {
        issues.add('[alias en conflicto] "$alias" en ${i.id} coincide con el nombre de $owner');
      } else {
        ownerOf.putIfAbsent(key, () => i.id);
      }
    }
  }
}

void _checkEmptyTranslations(List<Instr> instruments, List<String> issues) {
  for (final i in instruments) {
    final fields = <String, Tri>{'name': i.name, 'description': i.description, 'use': i.use};
    fields.forEach((label, text) {
      if (text.ca.trim().isEmpty) issues.add('[traducción vacía] ${i.id}.$label.ca');
      if (text.es.trim().isEmpty) issues.add('[traducción vacía] ${i.id}.$label.es');
      if (text.en.trim().isEmpty) issues.add('[traducción vacía] ${i.id}.$label.en');
    });
  }
}

void _checkMissingImages(List<Instr> instruments, List<String> issues) {
  final withoutImage = instruments.where((i) => i.image == null).toList();
  if (withoutImage.isEmpty) return;
  issues.add(
    '[sin imagen] ${withoutImage.length}/${instruments.length} instrumentos sin foto: '
    '${withoutImage.map((i) => i.id).join(', ')}',
  );
}

String _normalize(String value) => value.toLowerCase().trim();

int _levenshtein(String a, String b) {
  final lenA = a.length;
  final lenB = b.length;
  var previousRow = List<int>.generate(lenB + 1, (j) => j);
  for (var i = 1; i <= lenA; i++) {
    final currentRow = List<int>.filled(lenB + 1, 0);
    currentRow[0] = i;
    for (var j = 1; j <= lenB; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      currentRow[j] = [
        currentRow[j - 1] + 1,
        previousRow[j] + 1,
        previousRow[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previousRow = currentRow;
  }
  return previousRow[lenB];
}
