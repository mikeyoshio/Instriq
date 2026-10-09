// ignore_for_file: avoid_print
// One-off tool: appends the Andrologia specialty's new Instrument(...)
// blocks to lib/data/instruments_data.dart, from a merged JSON file of
// researched/verified instruments. Plain text append (same approach as
// apply_images.dart) -- the model file transitively imports Flutter, so a
// generator can't import it and run under plain `dart run`.
import 'dart:convert';
import 'dart:io';

String esc(String s) => s.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

String tri(Map<String, dynamic> m, String indent) {
  return "LocalizedText(\n"
      "$indent  ca: '${esc(m['ca'] as String)}',\n"
      "$indent  es: '${esc(m['es'] as String)}',\n"
      "$indent  en: '${esc(m['en'] as String)}',\n"
      "$indent),";
}

void main(List<String> args) {
  final mergedFile = File(args.isNotEmpty ? args[0] : 'tool/andrologia_merged.json');
  final dataFile = File('lib/data/instruments_data.dart');
  final instruments = jsonDecode(mergedFile.readAsStringSync()) as List<dynamic>;

  final buffer = StringBuffer();
  for (final raw in instruments) {
    final i = raw as Map<String, dynamic>;
    final aliases = (i['aliases'] as List<dynamic>).map((a) => "'${esc(a as String)}'").join(', ');
    buffer.writeln('  Instrument(');
    buffer.writeln("    id: '${esc(i['id'] as String)}',");
    buffer.writeln('    name: ${tri(i['name'] as Map<String, dynamic>, '    ')}');
    buffer.writeln('    category: InstrumentCategory.${i['category']},');
    buffer.writeln('    specialty: Specialty.${i['specialty']},');
    buffer.writeln('    aliases: [$aliases],');
    buffer.writeln("    icon: '${esc(i['icon'] as String)}',");
    buffer.writeln('    description: ${tri(i['description'] as Map<String, dynamic>, '    ')}');
    buffer.writeln('    use: ${tri(i['use'] as Map<String, dynamic>, '    ')}');
    if (i['tip'] != null) {
      buffer.writeln('    tip: ${tri(i['tip'] as Map<String, dynamic>, '    ')}');
    }
    buffer.writeln('    isNew: true,');
    buffer.writeln('  ),');
  }

  final source = dataFile.readAsStringSync();
  const closeMarker = '\n];';
  final idx = source.lastIndexOf(closeMarker);
  if (idx == -1) {
    stderr.writeln('ERROR: could not find list close marker');
    exit(1);
  }
  final newSource = '${source.substring(0, idx)}\n${buffer.toString()}$closeMarker${source.substring(idx + closeMarker.length)}';
  dataFile.writeAsStringSync(newSource);
  print('Appended ${instruments.length} instruments.');
}
