// ignore_for_file: avoid_print
// One-off tool: inserts `image: InstrumentImage(...)` fields into existing
// Instrument(...) blocks in lib/data/instruments_data.dart, based on a merged
// JSON file of {id: {url, license, attribution, sourceUrl}} produced by the
// image-research agents. Parses the data file as raw text (same approach as
// generate_vademecum.dart) since the model file transitively imports Flutter.
import 'dart:convert';
import 'dart:io';

String dartStringEscape(String s) {
  return s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n');
}

void main(List<String> args) {
  final repoRoot = Directory.current;
  final dataFile = File('${repoRoot.path}/lib/data/instruments_data.dart');
  final mergedFile = File(args.isNotEmpty
      ? args[0]
      : 'tool/images_merged.json');

  final images = jsonDecode(mergedFile.readAsStringSync()) as Map<String, dynamic>;
  var source = dataFile.readAsStringSync();

  const blockMarker = '  Instrument(';
  const closeMarker = '\n  ),';

  var applied = 0;
  var skippedHasImage = 0;
  var skippedNotFoundInFile = 0;

  for (final entry in images.entries) {
    final id = entry.key;
    final img = entry.value as Map<String, dynamic>;

    final idNeedle = "    id: '$id',";
    final idIndex = source.indexOf(idNeedle);
    if (idIndex == -1) {
      skippedNotFoundInFile++;
      stderr.writeln('WARN: id not found in data file: $id');
      continue;
    }

    final blockStart = source.lastIndexOf(blockMarker, idIndex);
    final blockClose = source.indexOf(closeMarker, idIndex);
    if (blockStart == -1 || blockClose == -1) {
      stderr.writeln('WARN: could not find block bounds for: $id');
      continue;
    }

    final block = source.substring(blockStart, blockClose);
    if (block.contains('image: InstrumentImage(')) {
      skippedHasImage++;
      continue;
    }

    final url = dartStringEscape(img['url'] as String);
    final license = dartStringEscape(img['license'] as String);
    final attribution = dartStringEscape(img['attribution'] as String);
    final sourceUrl = dartStringEscape(img['sourceUrl'] as String);

    final imageField = "\n    image: InstrumentImage(\n"
        "      url: '$url',\n"
        "      license: '$license',\n"
        "      attribution: '$attribution',\n"
        "      sourceUrl: '$sourceUrl',\n"
        "    ),";

    source = source.substring(0, blockClose) +
        imageField +
        source.substring(blockClose);
    applied++;
  }

  dataFile.writeAsStringSync(source);

  print('Applied: $applied');
  print('Skipped (already had image): $skippedHasImage');
  print('Skipped (id not found in file): $skippedNotFoundInFile');
}
