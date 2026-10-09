// Generates the public, SEO-indexable "Vademecum" instrument reference site
// under landing/vademecum/, parsing lib/data/instruments_data.dart as raw
// text (not importing it -- the model file transitively pulls in Flutter's
// dart:ui via app_localizations.dart, which plain `dart run` cannot load).
//
// Usage: dart run tool/generate_vademecum.dart
//
// Re-run this (and `npx wrangler deploy` from landing/) any time the catalog
// changes, so the Vademecum and the app can never drift out of sync -- both
// are generated from the same single source of truth.

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Data model (records -- no need for full classes for a throwaway tool)
// ---------------------------------------------------------------------------

typedef Tri = ({String ca, String es, String en});
typedef ImgInfo = ({String url, String license, String attribution, String sourceUrl});
typedef Instr = ({
  String id,
  Tri name,
  String category,
  String specialty,
  List<String> aliases,
  Tri description,
  Tri use,
  Tri? tip,
  ImgInfo? image,
  bool isNew,
});
typedef HistoryInfo = ({String addedOn, String addedSha, String lastTouchedOn, String lastTouchedSha});

const languages = ['ca', 'es', 'en'];
const specialtyOrder = [
  'general',
  'laparoscopiaEnergia',
  'roboticaAsistida',
  'ortopediaTrauma',
  'neurocirugia',
  'cardiovascular',
  'ginecologiaObstetricia',
  'urologia',
  'otorrino',
  'vascular',
  'maxilofacial',
  'pediatrica',
  'plastica',
  'toracica',
  'dermatologia',
  'oftalmologia',
  'anestesiologiaReanimacio',
  'andrologia',
];
const categoryOrder = ['corte', 'diseccion', 'sutura', 'separacion', 'succion', 'especiales', 'equipos'];

String unescapeDartString(String s) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '\\' && i + 1 < s.length) {
      buf.write(s[i + 1]);
      i++;
    } else {
      buf.write(s[i]);
    }
  }
  return buf.toString();
}

String htmlEscape(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String attrEscape(String s) => htmlEscape(s).replaceAll('"', '&quot;');

/// camelCase enum name -> kebab-case slug (anestesiologiaReanimacio -> anestesiologia-reanimacio)
String kebab(String enumName) {
  final buf = StringBuffer();
  for (var i = 0; i < enumName.length; i++) {
    final c = enumName[i];
    if (c.toUpperCase() == c && c.toLowerCase() != c && i > 0) {
      buf.write('-');
      buf.write(c.toLowerCase());
    } else {
      buf.write(c);
    }
  }
  return buf.toString();
}

// ---------------------------------------------------------------------------
// Parsing lib/data/instruments_data.dart
// ---------------------------------------------------------------------------

/// Matches a quoted Dart string's content, handling \' and \\ escapes.
const _qp = r"'((?:[^'\\]|\\.)*)'";

Tri _parseTri(String block, String fieldName) {
  final re = RegExp('$fieldName:\\s*LocalizedText\\(\\s*ca:\\s*$_qp,\\s*es:\\s*$_qp,\\s*en:\\s*$_qp,?\\s*\\)', dotAll: true);
  final m = re.firstMatch(block);
  if (m == null) {
    throw StateError('Could not parse $fieldName in block starting: ${block.substring(0, block.length > 60 ? 60 : block.length)}');
  }
  return (
    ca: unescapeDartString(m.group(1)!),
    es: unescapeDartString(m.group(2)!),
    en: unescapeDartString(m.group(3)!),
  );
}

Tri? _parseTriOptional(String block, String fieldName) {
  final re = RegExp('$fieldName:\\s*LocalizedText\\(\\s*ca:\\s*$_qp,\\s*es:\\s*$_qp,\\s*en:\\s*$_qp,?\\s*\\)', dotAll: true);
  final m = re.firstMatch(block);
  if (m == null) return null;
  return (
    ca: unescapeDartString(m.group(1)!),
    es: unescapeDartString(m.group(2)!),
    en: unescapeDartString(m.group(3)!),
  );
}

ImgInfo? _parseImage(String block) {
  final re = RegExp(
    'image:\\s*InstrumentImage\\(\\s*url:\\s*$_qp,\\s*license:\\s*$_qp,\\s*attribution:\\s*$_qp,\\s*sourceUrl:\\s*$_qp,?\\s*\\)',
    dotAll: true,
  );
  final m = re.firstMatch(block);
  if (m == null) return null;
  final url = unescapeDartString(m.group(1)!);
  if (url.isEmpty) return null;
  return (
    url: url,
    license: unescapeDartString(m.group(2)!),
    attribution: unescapeDartString(m.group(3)!),
    sourceUrl: unescapeDartString(m.group(4)!),
  );
}

List<String> _parseAliases(String block) {
  final re = RegExp(r'aliases:\s*\[(.*?)\],', dotAll: true);
  final m = re.firstMatch(block);
  if (m == null) return [];
  final inner = m.group(1)!;
  final itemRe = RegExp(_qp);
  return itemRe.allMatches(inner).map((mm) => unescapeDartString(mm.group(1)!)).toList();
}

Instr _parseInstrument(String block) {
  final idMatch = RegExp("id:\\s*$_qp").firstMatch(block);
  if (idMatch == null) throw StateError('No id found in block');
  final id = unescapeDartString(idMatch.group(1)!);

  final catMatch = RegExp(r'category:\s*InstrumentCategory\.(\w+)').firstMatch(block);
  final category = catMatch?.group(1) ?? 'especiales';

  final specMatch = RegExp(r'specialty:\s*Specialty\.(\w+)').firstMatch(block);
  final specialty = specMatch?.group(1) ?? 'general';

  final isNew = RegExp(r'isNew:\s*true').hasMatch(block);

  return (
    id: id,
    name: _parseTri(block, 'name'),
    category: category,
    specialty: specialty,
    aliases: _parseAliases(block),
    description: _parseTri(block, 'description'),
    use: _parseTri(block, 'use'),
    tip: _parseTriOptional(block, 'tip'),
    image: _parseImage(block),
    isNew: isNew,
  );
}

/// Splits the raw source of instruments_data.dart into one text block per
/// Instrument(...) entry. Blocks are delimited by the literal "  Instrument("
/// marker and close at the first 2-space-indented "  ),\n" (nested closes
/// inside LocalizedText(...)/InstrumentImage(...) are always 4+ spaces).
List<Instr> parseInstruments(String source) {
  final results = <Instr>[];
  const marker = '  Instrument(';
  var searchFrom = 0;
  while (true) {
    final start = source.indexOf(marker, searchFrom);
    if (start == -1) break;
    final bodyStart = start + marker.length;
    final end = source.indexOf('\n  ),', bodyStart);
    if (end == -1) throw StateError('Unterminated Instrument( block at offset $start');
    final block = source.substring(bodyStart, end);
    results.add(_parseInstrument(block));
    searchFrom = end + 5;
  }
  return results;
}

// ---------------------------------------------------------------------------
// ARB label loading
// ---------------------------------------------------------------------------

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

Future<Map<String, Map<String, String>>> loadLabels(Directory repoRoot, String prefix, List<String> enumNames) async {
  // Returns: lang -> enumName -> label
  final result = <String, Map<String, String>>{};
  for (final lang in languages) {
    final arbFile = File('${repoRoot.path}/lib/l10n/app_$lang.arb');
    final json = jsonDecode(await arbFile.readAsString(encoding: utf8)) as Map<String, dynamic>;
    final labels = <String, String>{};
    for (final name in enumNames) {
      final key = '$prefix${_capitalize(name)}';
      final value = json[key];
      if (value == null) throw StateError('Missing ARB key $key in app_$lang.arb');
      labels[name] = value as String;
    }
    result[lang] = labels;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Git-derived history (single whole-file pass, no per-id shelling)
// ---------------------------------------------------------------------------

Map<String, HistoryInfo> computeHistory(Directory repoRoot, String relPath) {
  final logResult = Process.runSync(
    'git',
    ['log', '--reverse', '--format=%H|%ad', '--date=short', '--', relPath],
    workingDirectory: repoRoot.path,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  if (logResult.exitCode != 0) {
    throw StateError('git log failed: ${logResult.stderr}');
  }
  final lines = (logResult.stdout as String).trim().split('\n').where((l) => l.isNotEmpty);
  final commits = lines.map((l) {
    final parts = l.split('|');
    return (sha: parts[0], date: parts[1]);
  }).toList();

  final addedOn = <String, String>{};
  final addedSha = <String, String>{};
  final lastTouchedOn = <String, String>{};
  final lastTouchedSha = <String, String>{};
  final lastSignature = <String, String>{};

  for (final commit in commits) {
    final showResult = Process.runSync(
      'git',
      ['show', '${commit.sha}:$relPath'],
      workingDirectory: repoRoot.path,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (showResult.exitCode != 0) continue; // file may not have existed yet in a weird edge case
    final snapshotSource = showResult.stdout as String;
    List<Instr> snapshot;
    try {
      snapshot = parseInstruments(snapshotSource);
    } catch (_) {
      continue; // an older/malformed snapshot shouldn't crash generation
    }
    for (final instr in snapshot) {
      final sig = _blockSignature(instr);
      if (!addedOn.containsKey(instr.id)) {
        addedOn[instr.id] = commit.date;
        addedSha[instr.id] = commit.sha;
      }
      final prevSig = lastSignature[instr.id];
      if (prevSig != sig) {
        lastTouchedOn[instr.id] = commit.date;
        lastTouchedSha[instr.id] = commit.sha;
      }
      lastSignature[instr.id] = sig;
    }
  }

  final result = <String, HistoryInfo>{};
  for (final id in addedOn.keys) {
    result[id] = (
      addedOn: addedOn[id]!,
      addedSha: addedSha[id]!,
      lastTouchedOn: lastTouchedOn[id] ?? addedOn[id]!,
      lastTouchedSha: lastTouchedSha[id] ?? addedSha[id]!,
    );
  }
  return result;
}

String _blockSignature(Instr i) {
  // Whitespace-insensitive content signature so a pure reformat doesn't
  // register as a change; order-independent across all fields.
  final parts = [
    i.name.ca, i.name.es, i.name.en,
    i.category, i.specialty,
    i.aliases.join('|'),
    i.description.ca, i.description.es, i.description.en,
    i.use.ca, i.use.es, i.use.en,
    i.tip?.ca ?? '', i.tip?.es ?? '', i.tip?.en ?? '',
    i.image?.url ?? '', i.image?.license ?? '', i.image?.attribution ?? '', i.image?.sourceUrl ?? '',
    i.isNew.toString(),
  ];
  return parts.join('\u0000');
}

// ---------------------------------------------------------------------------
// Image vendoring
// ---------------------------------------------------------------------------

String _extensionFor(String url) {
  final path = Uri.parse(url).path;
  final dot = path.lastIndexOf('.');
  if (dot == -1) return 'jpg';
  final ext = path.substring(dot + 1).toLowerCase();
  if (ext.length <= 4 && RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return ext;
  return 'jpg';
}

Future<Map<String, String>> vendorImages(List<Instr> instruments, Directory imagesDir) async {
  // Returns: id -> local relative filename (e.g. "pinza-kocher.jpg")
  if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
  final result = <String, String>{};
  final client = HttpClient();
  client.userAgent = 'Instriq-Vademecum-Generator/1.0 (https://instriq.org)';
  client.connectionTimeout = const Duration(seconds: 15);
  var downloaded = 0;
  var skipped = 0;
  for (final instr in instruments) {
    final image = instr.image;
    if (image == null) continue;
    final ext = _extensionFor(image.url);
    final filename = '${instr.id}.$ext';
    final file = File('${imagesDir.path}/$filename');
    result[instr.id] = filename;
    if (file.existsSync() && file.lengthSync() > 0) {
      skipped++;
      continue;
    }
    // Pace requests -- Wikimedia returns 429 if hit with a burst of
    // sequential requests with no delay between them.
    await Future.delayed(const Duration(milliseconds: 1000));
    var ok = false;
    for (var attempt = 1; attempt <= 5 && !ok; attempt++) {
      try {
        final req = await client.getUrl(Uri.parse(image.url)).timeout(const Duration(seconds: 20));
        // Force a fresh connection per request -- avoids stale keep-alive
        // connection issues across many sequential downloads to one host.
        req.headers.set(HttpHeaders.connectionHeader, 'close');
        final resp = await req.close().timeout(const Duration(seconds: 30));
        if (resp.statusCode == 429) {
          final retryAfter = resp.headers.value('retry-after');
          final waitSeconds = retryAfter != null ? (int.tryParse(retryAfter) ?? 5) : 5 * attempt;
          stderr.writeln('WARN (attempt $attempt): ${instr.id} rate-limited (429), waiting ${waitSeconds}s...');
          await resp.drain<void>();
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        if (resp.statusCode != 200) {
          stderr.writeln('WARN (attempt $attempt): ${image.url} for ${instr.id}: HTTP ${resp.statusCode}');
          await resp.drain<void>();
          continue;
        }
        final bytes = await resp.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk)).timeout(const Duration(seconds: 30));
        await file.writeAsBytes(bytes);
        downloaded++;
        ok = true;
      } catch (e) {
        stderr.writeln('WARN (attempt $attempt): ${image.url} for ${instr.id}: $e');
      }
    }
    if (!ok) {
      stderr.writeln('FAILED: ${image.url} for ${instr.id}');
      result.remove(instr.id);
    }
  }
  client.close(force: true);
  stdout.writeln('Images: $downloaded downloaded, $skipped already present, ${result.length} total available.');
  return result;
}

// ---------------------------------------------------------------------------
// Chrome translations (UI strings that are NOT instrument content)
// ---------------------------------------------------------------------------

const chrome = <String, Tri>{
  'siteTitle': (ca: 'Vademècum Instriq', es: 'Vademécum Instriq', en: 'Instriq Vademecum'),
  'tagline': (
    ca: 'Catàleg obert d\'instrumental quirúrgic',
    es: 'Catálogo abierto de instrumental quirúrgico',
    en: 'Open catalog of surgical instruments',
  ),
  'home': (ca: 'Inici', es: 'Inicio', en: 'Home'),
  'allSpecialties': (ca: 'Totes les especialitats', es: 'Todas las especialidades', en: 'All specialties'),
  'specialty': (ca: 'Especialitat', es: 'Especialidad', en: 'Specialty'),
  'category': (ca: 'Categoria', es: 'Categoría', en: 'Category'),
  'aliases': (ca: 'També conegut com', es: 'También conocido como', en: 'Also known as'),
  'use': (ca: 'Com s\'utilitza', es: 'Cómo se utiliza', en: 'How it is used'),
  'tip': (ca: 'Consell clínic', es: 'Consejo clínico', en: 'Clinical tip'),
  'sources': (ca: 'Fonts', es: 'Fuentes', en: 'Sources'),
  'history': (ca: 'Historial', es: 'Historial', en: 'History'),
  'related': (ca: 'Instruments relacionats', es: 'Instrumentos relacionados', en: 'Related instruments'),
  'links': (ca: 'Enllaços d\'interès', es: 'Enlaces de interés', en: 'Links of interest'),
  'newBadge': (ca: 'Nou', es: 'Nuevo', en: 'New'),
  'instrumentsCount': (ca: 'instruments', es: 'instrumentos', en: 'instruments'),
  'openInApp': (ca: 'Obre el catàleg a l\'app', es: 'Abre el catálogo en la app', en: 'Open the catalog in the app'),
  'viewSource': (ca: 'Veure la font original', es: 'Ver la fuente original', en: 'View original source'),
  'backToSpecialty': (ca: 'Torna a', es: 'Volver a', en: 'Back to'),
  'methodologyLinkText': (ca: 'Com es redacta aquest catàleg', es: 'Cómo se redacta este catálogo', en: 'How this catalog is written'),
  'methodologyStatement': (
    ca: 'Aquesta fitxa forma part del catàleg d\'Instriq, investigat i redactat per especialitat a partir de cerca web real -- mai generat o inventat sense verificació --, i revisat de forma escèptica i independent abans de publicar-se.',
    es: 'Esta ficha forma parte del catálogo de Instriq, investigado y redactado por especialidad a partir de búsqueda web real -- nunca generado o inventado sin verificación --, y revisado de forma escéptica e independiente antes de publicarse.',
    en: 'This entry is part of the Instriq catalog, researched and written per specialty from real web research -- never generated or invented without verification -- and reviewed skeptically and independently before publication.',
  ),
  'imageCredit': (ca: 'Imatge', es: 'Imagen', en: 'Image'),
  'license': (ca: 'Llicència', es: 'Licencia', en: 'License'),
  'source': (ca: 'Font', es: 'Fuente', en: 'Source'),
  'addedOn': (ca: 'Afegit al catàleg el', es: 'Añadido al catálogo el', en: 'Added to the catalog on'),
  'lastUpdated': (ca: 'Última actualització de contingut', es: 'Última actualización de contenido', en: 'Content last updated'),
  'historyDisclaimer': (
    ca: 'Dates derivades de l\'historial públic de control de versions del projecte a GitHub, no d\'un registre d\'edicions col·laboratiu en viu.',
    es: 'Fechas derivadas del historial público de control de versiones del proyecto en GitHub, no de un registro de ediciones colaborativo en vivo.',
    en: 'Dates derived from the project\'s public version-control history on GitHub, not a live collaborative edit log.',
  ),
  'methodologyTitle': (ca: 'Com es redacta aquest catàleg', es: 'Cómo se redacta este catálogo', en: 'How this catalog is written'),
  'homeIntro': (
    ca: 'Un catàleg de referència obert, amb fitxa pròpia per a cada instrument i material quirúrgic, en català, castellà i anglès.',
    es: 'Un catálogo de referencia abierto, con ficha propia para cada instrumento y material quirúrgico, en catalán, castellano e inglés.',
    en: 'An open reference catalog, with its own entry for every surgical instrument and material, in Catalan, Spanish and English.',
  ),
  'specialtyIntro': (
    ca: 'Instruments i materials catalogats dins d\'aquesta especialitat.',
    es: 'Instrumentos y materiales catalogados dentro de esta especialidad.',
    en: 'Instruments and materials cataloged within this specialty.',
  ),
  'viewMethodology': (ca: 'Metodologia', es: 'Metodología', en: 'Methodology'),
  'footerNote': (
    ca: 'Part del projecte de codi obert Instriq.',
    es: 'Parte del proyecto de código abierto Instriq.',
    en: 'Part of the open-source Instriq project.',
  ),
};

String t(String key, String lang) {
  final tri = chrome[key];
  if (tri == null) throw StateError('Missing chrome key: $key');
  return switch (lang) {
    'ca' => tri.ca,
    'es' => tri.es,
    _ => tri.en,
  };
}

String triFor(Tri tri, String lang) => switch (lang) { 'ca' => tri.ca, 'es' => tri.es, _ => tri.en };

const _htmlLangBase = 'https://instriq.org';

// ---------------------------------------------------------------------------
// Shared CSS -- reuses the existing site's design tokens verbatim
// ---------------------------------------------------------------------------

const _sharedCss = r'''
:root {
  --paper: #f6f4f0; --paper-alt: #edeae2; --surface: #ffffff;
  --ink: #201c17; --ink-muted: #6e6459; --rule: #e2ddd3;
  --accent: #a34e1c; --accent-soft: #f1e3d7;
  --display: ui-monospace, "SF Mono", "Cascadia Code", "Roboto Mono", Consolas, "Liberation Mono", monospace;
  --body: "Iowan Old Style", "Palatino Linotype", "URW Palladio L", Georgia, "Times New Roman", serif;
}
@media (prefers-color-scheme: dark) {
  :root { --paper: #16191a; --paper-alt: #1d2122; --surface: #202425; --ink: #f1ede6; --ink-muted: #a8a094; --rule: #2c3234; --accent: #e2915c; --accent-soft: #3a2a1f; }
}
:root[data-theme="dark"] { --paper: #16191a; --paper-alt: #1d2122; --surface: #202425; --ink: #f1ede6; --ink-muted: #a8a094; --rule: #2c3234; --accent: #e2915c; --accent-soft: #3a2a1f; }
:root[data-theme="light"] { --paper: #f6f4f0; --paper-alt: #edeae2; --surface: #ffffff; --ink: #201c17; --ink-muted: #6e6459; --rule: #e2ddd3; --accent: #a34e1c; --accent-soft: #f1e3d7; }
* { box-sizing: border-box; }
body { background: var(--paper); color: var(--ink); font-family: var(--body); font-size: 18px; line-height: 1.7; margin: 0; -webkit-font-smoothing: antialiased; }
a { color: var(--accent); }
a:not(.btn):not(.chip) { text-decoration-color: color-mix(in srgb, var(--accent) 50%, transparent); }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; }
.wrap { max-width: 1040px; margin: 0 auto; padding: 0 20px; }
header.site { border-bottom: 1px solid var(--rule); background: var(--paper); }
header.site .bar { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 16px 0; flex-wrap: wrap; }
.brand { display: flex; align-items: baseline; gap: 10px; text-decoration: none; color: var(--ink); }
.brand b { font-family: var(--display); font-weight: 700; font-size: 1.05rem; }
.brand span { font-size: 0.82rem; color: var(--ink-muted); }
.lang-switch { display: flex; gap: 4px; font-family: var(--display); font-size: 0.78rem; }
.lang-switch a { padding: 4px 8px; border-radius: 4px; text-decoration: none; color: var(--ink-muted); }
.lang-switch a.active { color: var(--ink); font-weight: 700; background: var(--paper-alt); }
.crumbs { font-family: var(--display); font-size: 0.78rem; color: var(--ink-muted); padding: 18px 0 0; }
.crumbs a { color: var(--ink-muted); text-decoration: none; }
.crumbs a:hover { color: var(--accent); }
main { padding-bottom: 60px; }
h1 { font-family: var(--display); font-size: 1.8rem; font-weight: 700; letter-spacing: -0.01em; margin: 10px 0 6px; text-wrap: balance; }
h2 { font-family: var(--display); font-size: 1.05rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; color: var(--ink-muted); margin: 36px 0 12px; border-bottom: 1px solid var(--rule); padding-bottom: 6px; }
p { margin: 0 0 14px; }
.badges { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 20px; }
.chip { display: inline-flex; align-items: center; font-family: var(--display); font-size: 0.72rem; font-weight: 700; letter-spacing: 0.02em; color: var(--accent); background: var(--accent-soft); border-radius: 999px; padding: 4px 11px; text-decoration: none; }
.chip.is-muted { color: var(--ink-muted); background: var(--paper-alt); }
.layout { display: grid; grid-template-columns: 1fr 280px; gap: 40px; align-items: start; }
@media (max-width: 760px) { .layout { grid-template-columns: 1fr; } }
.infobox { background: var(--surface); border: 1px solid var(--rule); border-radius: 10px; padding: 18px; font-size: 0.9rem; }
.infobox img { width: 100%; border-radius: 6px; display: block; background: var(--paper-alt); }
.infobox figcaption { font-size: 0.74rem; color: var(--ink-muted); margin-top: 6px; line-height: 1.4; }
.infobox dl { margin: 14px 0 0; }
.infobox dt { font-family: var(--display); font-size: 0.68rem; text-transform: uppercase; letter-spacing: 0.04em; color: var(--ink-muted); margin-top: 12px; }
.infobox dt:first-child { margin-top: 0; }
.infobox dd { margin: 3px 0 0; color: var(--ink); }
.list-plain { list-style: none; margin: 0; padding: 0; }
.list-plain li { padding: 10px 0; border-bottom: 1px dashed var(--rule); }
.list-plain li:last-child { border-bottom: none; }
.list-plain a { text-decoration: none; color: var(--ink); font-weight: 600; }
.list-plain a:hover { color: var(--accent); }
.list-plain .meta { display: block; font-size: 0.8rem; color: var(--ink-muted); font-weight: 400; margin-top: 2px; }
.spec-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 14px; margin-top: 10px; }
.spec-card { border: 1px solid var(--rule); border-radius: 10px; padding: 16px; text-decoration: none; display: block; background: var(--surface); }
.spec-card b { font-family: var(--display); font-size: 0.95rem; color: var(--ink); display: block; margin-bottom: 4px; }
.spec-card span { font-size: 0.8rem; color: var(--ink-muted); }
.related-grid { display: flex; flex-wrap: wrap; gap: 8px; }
footer.site { border-top: 1px solid var(--rule); padding: 24px 0; font-size: 0.82rem; color: var(--ink-muted); }
footer.site a { color: var(--ink-muted); }
.disclaimer { font-size: 0.8rem; color: var(--ink-muted); font-style: italic; }
.source-line { font-size: 0.86rem; }
''';

// ---------------------------------------------------------------------------
// Shared page shell
// ---------------------------------------------------------------------------

String _pageShell({
  required String lang,
  required String title,
  required String description,
  required String canonicalPath, // e.g. "/vademecum/ca/pinza-kocher/"
  required Map<String, String> hreflangPaths, // lang -> path (including the current one)
  required String crumbsHtml,
  required String bodyHtml,
  String? jsonLd,
}) {
  final canonical = '$_htmlLangBase$canonicalPath';
  final hreflangTags = StringBuffer();
  for (final l in languages) {
    final p = hreflangPaths[l];
    if (p != null) {
      hreflangTags.writeln('<link rel="alternate" hreflang="$l" href="$_htmlLangBase$p">');
    }
  }
  final xDefault = hreflangPaths['ca'];
  if (xDefault != null) {
    hreflangTags.writeln('<link rel="alternate" hreflang="x-default" href="$_htmlLangBase$xDefault">');
  }

  final langSwitch = StringBuffer();
  for (final l in languages) {
    final p = hreflangPaths[l];
    if (p == null) continue;
    final cls = l == lang ? ' class="active"' : '';
    langSwitch.writeln('<a href="$_htmlLangBase$p"$cls>${l.toUpperCase()}</a>');
  }

  return '''<!doctype html>
<html lang="$lang">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#f6f4f0" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#16191a" media="(prefers-color-scheme: dark)">
<title>${htmlEscape(title)}</title>
<meta name="description" content="${attrEscape(description)}">
<link rel="canonical" href="$canonical">
$hreflangTags<link rel="icon" type="image/png" href="$_htmlLangBase/favicon.png">
<meta property="og:type" content="website">
<meta property="og:url" content="$canonical">
<meta property="og:site_name" content="${htmlEscape(t('siteTitle', lang))}">
<meta property="og:title" content="${attrEscape(title)}">
<meta property="og:description" content="${attrEscape(description)}">
${jsonLd != null ? '<script type="application/ld+json">\n$jsonLd\n</script>\n' : ''}<link rel="stylesheet" href="$_htmlLangBase/vademecum/assets/vademecum.css">
</head>
<body>
<header class="site">
  <div class="wrap bar">
    <a href="$_htmlLangBase/vademecum/$lang/" class="brand"><b>${htmlEscape(t('siteTitle', lang))}</b><span>${htmlEscape(t('tagline', lang))}</span></a>
    <nav class="lang-switch">$langSwitch</nav>
  </div>
</header>
<div class="wrap crumbs">$crumbsHtml</div>
<main class="wrap">
$bodyHtml
</main>
<footer class="site">
  <div class="wrap">
    <p>${htmlEscape(t('footerNote', lang))} &middot; <a href="$_htmlLangBase/">instriq.org</a> &middot; <a href="https://app.instriq.org">app.instriq.org</a> &middot; <a href="https://github.com/mikeyoshio/Instriq">GitHub</a> &middot; <a href="$_htmlLangBase/vademecum/$lang/metodologia/">${htmlEscape(t('viewMethodology', lang))}</a></p>
  </div>
</footer>
</body>
</html>
''';
}

// ---------------------------------------------------------------------------
// Instrument page
// ---------------------------------------------------------------------------

String _renderInstrumentPage({
  required Instr instr,
  required String lang,
  required Map<String, Map<String, String>> categoryLabels,
  required Map<String, Map<String, String>> specialtyLabels,
  required HistoryInfo? history,
  required Map<String, String> vendoredImages,
  required List<Instr> related,
}) {
  final name = triFor(instr.name, lang);
  final desc = triFor(instr.description, lang);
  final use = triFor(instr.use, lang);
  final tip = instr.tip != null ? triFor(instr.tip!, lang) : null;
  final specialtySlug = kebab(instr.specialty);
  final specialtyLabel = specialtyLabels[lang]![instr.specialty]!;
  final categoryLabel = categoryLabels[lang]![instr.category]!;

  final hreflangPaths = {for (final l in languages) l: '/vademecum/$l/${instr.id}/'};

  final crumbs =
      '<a href="$_htmlLangBase/vademecum/$lang/">${htmlEscape(t('siteTitle', lang))}</a> &rsaquo; '
      '<a href="$_htmlLangBase/vademecum/$lang/$specialtySlug/">${htmlEscape(specialtyLabel)}</a> &rsaquo; '
      '${htmlEscape(name)}';

  final badges = StringBuffer();
  badges.write('<a class="chip" href="$_htmlLangBase/vademecum/$lang/$specialtySlug/">${htmlEscape(specialtyLabel)}</a>');
  badges.write('<span class="chip is-muted">${htmlEscape(categoryLabel)}</span>');
  if (instr.isNew) badges.write('<span class="chip">${htmlEscape(t('newBadge', lang))}</span>');

  final imageFile = vendoredImages[instr.id];
  final infoboxImage = instr.image != null && imageFile != null
      ? '<img src="$_htmlLangBase/vademecum/assets/images/$imageFile" alt="${attrEscape(name)}">'
          '<figcaption>${htmlEscape(t('imageCredit', lang))}: ${htmlEscape(instr.image!.attribution)} &middot; ${htmlEscape(instr.image!.license)}</figcaption>'
      : '';

  final aliasesHtml = instr.aliases.isNotEmpty
      ? '<dt>${htmlEscape(t('aliases', lang))}</dt><dd>${instr.aliases.map(htmlEscape).join(', ')}</dd>'
      : '';

  final infobox = '''
<aside class="infobox">
  $infoboxImage
  <dl>
    <dt>${htmlEscape(t('category', lang))}</dt><dd>${htmlEscape(categoryLabel)}</dd>
    <dt>${htmlEscape(t('specialty', lang))}</dt><dd>${htmlEscape(specialtyLabel)}</dd>
    $aliasesHtml
  </dl>
</aside>''';

  final tipHtml = tip != null ? '<h2>${htmlEscape(t('tip', lang))}</h2><p>${htmlEscape(tip)}</p>' : '';

  final sourcesHtml = StringBuffer();
  sourcesHtml.write('<p class="disclaimer">${htmlEscape(t('methodologyStatement', lang))} '
      '<a href="$_htmlLangBase/vademecum/$lang/metodologia/">${htmlEscape(t('methodologyLinkText', lang))}</a>.</p>');
  if (instr.image != null) {
    sourcesHtml.write('<p class="source-line">${htmlEscape(t('imageCredit', lang))}: ${htmlEscape(instr.image!.attribution)}. '
        '${htmlEscape(t('license', lang))} ${htmlEscape(instr.image!.license)}. '
        '<a href="${attrEscape(instr.image!.sourceUrl)}">${htmlEscape(t('viewSource', lang))}</a>.</p>');
  }

  final historyHtml = StringBuffer();
  if (history != null) {
    historyHtml.write('<p>${htmlEscape(t('addedOn', lang))} '
        '<a href="https://github.com/mikeyoshio/Instriq/commit/${history.addedSha}">${history.addedOn}</a>');
    if (history.lastTouchedOn != history.addedOn) {
      historyHtml.write('. ${htmlEscape(t('lastUpdated', lang))}: '
          '<a href="https://github.com/mikeyoshio/Instriq/commit/${history.lastTouchedSha}">${history.lastTouchedOn}</a>');
    }
    historyHtml.write('.</p><p class="disclaimer">${htmlEscape(t('historyDisclaimer', lang))}</p>');
  }

  final relatedHtml = StringBuffer();
  if (related.isNotEmpty) {
    relatedHtml.write('<div class="related-grid">');
    for (final r in related) {
      relatedHtml.write('<a class="chip is-muted" href="$_htmlLangBase/vademecum/$lang/${r.id}/">${htmlEscape(triFor(r.name, lang))}</a>');
    }
    relatedHtml.write('</div>');
  }

  final linksHtml = '''
<ul class="list-plain">
  <li><a href="https://app.instriq.org">${htmlEscape(t('openInApp', lang))}</a></li>
  ${instr.image != null ? '<li><a href="${attrEscape(instr.image!.sourceUrl)}">${htmlEscape(t('viewSource', lang))}</a></li>' : ''}
  <li><a href="$_htmlLangBase/vademecum/$lang/$specialtySlug/">${htmlEscape(t('backToSpecialty', lang))} ${htmlEscape(specialtyLabel)}</a></li>
</ul>''';

  final body = '''
<div class="layout">
  <div>
    <div class="badges">$badges</div>
    <h1>${htmlEscape(name)}</h1>
    <p>${htmlEscape(desc)}</p>
    <h2>${htmlEscape(t('use', lang))}</h2>
    <p>${htmlEscape(use)}</p>
    $tipHtml
    <h2>${htmlEscape(t('sources', lang))}</h2>
    $sourcesHtml
    <h2>${htmlEscape(t('history', lang))}</h2>
    $historyHtml
    ${related.isNotEmpty ? '<h2>${htmlEscape(t('related', lang))}</h2>$relatedHtml' : ''}
    <h2>${htmlEscape(t('links', lang))}</h2>
    $linksHtml
  </div>
  $infobox
</div>
''';

  final jsonLd = jsonEncode({
    '@context': 'https://schema.org',
    '@graph': [
      {
        '@type': 'WebPage',
        'inLanguage': lang,
        'name': name,
        'url': '$_htmlLangBase/vademecum/$lang/${instr.id}/',
        if (history != null) 'datePublished': history.addedOn,
        if (history != null) 'dateModified': history.lastTouchedOn,
        'mainEntity': {
          '@type': 'DefinedTerm',
          'name': name,
          if (instr.aliases.isNotEmpty) 'alternateName': instr.aliases,
          'description': desc,
          'inDefinedTermSet': '$_htmlLangBase/vademecum/$lang/',
          'url': '$_htmlLangBase/vademecum/$lang/${instr.id}/',
        },
        if (instr.image != null)
          'image': {
            '@type': 'ImageObject',
            'contentUrl': '$_htmlLangBase/vademecum/assets/images/${vendoredImages[instr.id]}',
            'license': instr.image!.license,
            'creditText': instr.image!.attribution,
            'acquireLicensePage': instr.image!.sourceUrl,
          },
      },
      {
        '@type': 'BreadcrumbList',
        'itemListElement': [
          {'@type': 'ListItem', 'position': 1, 'name': t('siteTitle', lang), 'item': '$_htmlLangBase/vademecum/$lang/'},
          {'@type': 'ListItem', 'position': 2, 'name': specialtyLabel, 'item': '$_htmlLangBase/vademecum/$lang/$specialtySlug/'},
          {'@type': 'ListItem', 'position': 3, 'name': name, 'item': '$_htmlLangBase/vademecum/$lang/${instr.id}/'},
        ],
      },
    ],
  });

  return _pageShell(
    lang: lang,
    title: '$name · ${t('siteTitle', lang)}',
    description: desc,
    canonicalPath: '/vademecum/$lang/${instr.id}/',
    hreflangPaths: hreflangPaths,
    crumbsHtml: crumbs,
    bodyHtml: body,
    jsonLd: jsonLd,
  );
}

// ---------------------------------------------------------------------------
// Specialty index page
// ---------------------------------------------------------------------------

String _renderSpecialtyPage({
  required String specialty,
  required String lang,
  required Map<String, Map<String, String>> specialtyLabels,
  required List<Instr> instruments,
}) {
  final label = specialtyLabels[lang]![specialty]!;
  final hreflangPaths = {for (final l in languages) l: '/vademecum/$l/${kebab(specialty)}/'};
  final crumbs = '<a href="$_htmlLangBase/vademecum/$lang/">${htmlEscape(t('siteTitle', lang))}</a> &rsaquo; ${htmlEscape(label)}';

  final items = StringBuffer();
  final sorted = [...instruments]..sort((a, b) => triFor(a.name, lang).compareTo(triFor(b.name, lang)));
  for (final i in sorted) {
    items.write('<li><a href="$_htmlLangBase/vademecum/$lang/${i.id}/">${htmlEscape(triFor(i.name, lang))}</a></li>');
  }

  final body = '''
<h1>${htmlEscape(label)}</h1>
<p>${htmlEscape(t('specialtyIntro', lang))} (${instruments.length} ${htmlEscape(t('instrumentsCount', lang))})</p>
<ul class="list-plain">$items</ul>
''';

  final jsonLd = jsonEncode({
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    'inLanguage': lang,
    'name': label,
    'url': '$_htmlLangBase/vademecum/$lang/${kebab(specialty)}/',
    'mainEntity': {
      '@type': 'ItemList',
      'itemListElement': [
        for (var idx = 0; idx < sorted.length; idx++)
          {
            '@type': 'ListItem',
            'position': idx + 1,
            'name': triFor(sorted[idx].name, lang),
            'url': '$_htmlLangBase/vademecum/$lang/${sorted[idx].id}/',
          },
      ],
    },
  });

  return _pageShell(
    lang: lang,
    title: '$label · ${t('siteTitle', lang)}',
    description: '${t('specialtyIntro', lang)} $label.',
    canonicalPath: '/vademecum/$lang/${kebab(specialty)}/',
    hreflangPaths: hreflangPaths,
    crumbsHtml: crumbs,
    bodyHtml: body,
    jsonLd: jsonLd,
  );
}

// ---------------------------------------------------------------------------
// Home page
// ---------------------------------------------------------------------------

String _renderHomePage({
  required String lang,
  required Map<String, Map<String, String>> specialtyLabels,
  required Map<String, int> countsBySpecialty,
}) {
  final hreflangPaths = {for (final l in languages) l: '/vademecum/$l/'};
  final crumbs = htmlEscape(t('siteTitle', lang));

  final cards = StringBuffer();
  for (final spec in specialtyOrder) {
    final label = specialtyLabels[lang]![spec]!;
    final count = countsBySpecialty[spec] ?? 0;
    cards.write('<a class="spec-card" href="$_htmlLangBase/vademecum/$lang/${kebab(spec)}/"><b>${htmlEscape(label)}</b>'
        '<span>$count ${htmlEscape(t('instrumentsCount', lang))}</span></a>');
  }

  final totalCount = countsBySpecialty.values.fold<int>(0, (a, b) => a + b);

  final body = '''
<h1>${htmlEscape(t('siteTitle', lang))}</h1>
<p>${htmlEscape(t('homeIntro', lang))}</p>
<p><a href="$_htmlLangBase/vademecum/$lang/metodologia/">${htmlEscape(t('methodologyLinkText', lang))}</a></p>
<h2>${htmlEscape(t('allSpecialties', lang))} ($totalCount ${htmlEscape(t('instrumentsCount', lang))})</h2>
<div class="spec-grid">$cards</div>
''';

  final jsonLd = jsonEncode({
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    'inLanguage': lang,
    'name': t('siteTitle', lang),
    'url': '$_htmlLangBase/vademecum/$lang/',
    'description': t('homeIntro', lang),
  });

  return _pageShell(
    lang: lang,
    title: t('siteTitle', lang),
    description: t('homeIntro', lang),
    canonicalPath: '/vademecum/$lang/',
    hreflangPaths: hreflangPaths,
    crumbsHtml: crumbs,
    bodyHtml: body,
    jsonLd: jsonLd,
  );
}

// ---------------------------------------------------------------------------
// Methodology page
// ---------------------------------------------------------------------------

const _methodologyBody = <String, String>{
  'ca': '''
<h1>Com es redacta aquest catàleg</h1>
<p>Cada fitxa del Vademècum prové del catàleg d'instrumental d'Instriq, un projecte de codi obert. El contingut es redacta seguint un procés en dues fases:</p>
<p><b>1. Investigació.</b> Per a cada especialitat o lot d'instruments, es redacta una proposta a partir de coneixement mèdic/quirúrgic i cerca web real sobre fonts estàndard (manuals de cirurgia, literatura d'infermeria perioperatòria, documentació de fabricants) -- mai generada o inventada sense contrastar-se.</p>
<p><b>2. Verificació escèptica i independent.</b> Una segona revisió, feta per separat de la redacció inicial, comprova cada proposta per exactitud mèdica, duplicitat amb instruments ja existents al catàleg i consistència entre els 3 idiomes, per defecte descartant qualsevol cosa dubtosa.</p>
<p>L'historial complet d'ampliacions del catàleg, incloent-hi propostes rebutjades durant la verificació, és públic a <a href="https://github.com/mikeyoshio/Instriq/blob/main/docs/CHANGELOG.md">docs/CHANGELOG.md</a> al repositori de GitHub.</p>
''',
  'es': '''
<h1>Cómo se redacta este catálogo</h1>
<p>Cada ficha del Vademécum proviene del catálogo de instrumental de Instriq, un proyecto de código abierto. El contenido se redacta siguiendo un proceso en dos fases:</p>
<p><b>1. Investigación.</b> Para cada especialidad o lote de instrumentos, se redacta una propuesta a partir de conocimiento médico/quirúrgico y búsqueda web real sobre fuentes estándar (manuales de cirugía, literatura de enfermería perioperatoria, documentación de fabricantes) -- nunca generada o inventada sin contrastarse.</p>
<p><b>2. Verificación escéptica e independiente.</b> Una segunda revisión, hecha por separado de la redacción inicial, comprueba cada propuesta por exactitud médica, duplicidad con instrumentos ya existentes en el catálogo y consistencia entre los 3 idiomas, descartando por defecto cualquier cosa dudosa.</p>
<p>El historial completo de ampliaciones del catálogo, incluyendo propuestas rechazadas durante la verificación, es público en <a href="https://github.com/mikeyoshio/Instriq/blob/main/docs/CHANGELOG.md">docs/CHANGELOG.md</a> en el repositorio de GitHub.</p>
''',
  'en': '''
<h1>How this catalog is written</h1>
<p>Every Vademecum entry comes from the Instriq instrument catalog, an open-source project. Content is written following a two-stage process:</p>
<p><b>1. Research.</b> For each specialty or batch of instruments, a draft is written from medical/surgical knowledge and real web research against standard sources (surgical textbooks, perioperative nursing literature, manufacturer documentation) -- never generated or invented without being checked.</p>
<p><b>2. Skeptical, independent verification.</b> A second review, done separately from the initial draft, checks each proposal for medical accuracy, duplication with instruments already in the catalog, and consistency across the 3 languages, defaulting to rejecting anything doubtful.</p>
<p>The full history of catalog expansions, including proposals rejected during verification, is public in <a href="https://github.com/mikeyoshio/Instriq/blob/main/docs/CHANGELOG.md">docs/CHANGELOG.md</a> in the GitHub repository.</p>
''',
};

String _renderMethodologyPage(String lang) {
  final hreflangPaths = {for (final l in languages) l: '/vademecum/$l/metodologia/'};
  final crumbs = '<a href="$_htmlLangBase/vademecum/$lang/">${htmlEscape(t('siteTitle', lang))}</a> &rsaquo; ${htmlEscape(t('methodologyTitle', lang))}';
  return _pageShell(
    lang: lang,
    title: '${t('methodologyTitle', lang)} · ${t('siteTitle', lang)}',
    description: t('methodologyTitle', lang),
    canonicalPath: '/vademecum/$lang/metodologia/',
    hreflangPaths: hreflangPaths,
    crumbsHtml: crumbs,
    bodyHtml: _methodologyBody[lang]!,
  );
}

// ---------------------------------------------------------------------------
// Sitemap
// ---------------------------------------------------------------------------

String _renderSitemap(List<String> paths) {
  final buf = StringBuffer();
  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">');
  // paths are grouped in triplets (ca/es/en) of the same logical page, in that order
  for (var i = 0; i < paths.length; i += 3) {
    final group = paths.sublist(i, i + 3);
    for (final p in group) {
      buf.writeln('  <url>');
      buf.writeln('    <loc>$_htmlLangBase$p</loc>');
      for (var j = 0; j < group.length; j++) {
        buf.writeln('    <xhtml:link rel="alternate" hreflang="${languages[j]}" href="$_htmlLangBase${group[j]}" />');
      }
      buf.writeln('    <xhtml:link rel="alternate" hreflang="x-default" href="$_htmlLangBase${group[0]}" />');
      buf.writeln('  </url>');
    }
  }
  buf.writeln('</urlset>');
  return buf.toString();
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent;
  final landingDir = Directory('${repoRoot.path}/landing');
  final vademecumDir = Directory('${landingDir.path}/vademecum');
  final assetsDir = Directory('${vademecumDir.path}/assets');
  final imagesDir = Directory('${assetsDir.path}/images');

  stdout.writeln('Reading instruments_data.dart...');
  final dataFile = File('${repoRoot.path}/lib/data/instruments_data.dart');
  final source = await dataFile.readAsString(encoding: utf8);
  final instruments = parseInstruments(source);
  stdout.writeln('Parsed ${instruments.length} instruments.');

  stdout.writeln('Loading labels...');
  final categoryLabels = await loadLabels(repoRoot, 'catalogCategory', categoryOrder);
  final specialtyLabels = await loadLabels(repoRoot, 'catalogSpecialty', specialtyOrder);

  stdout.writeln('Computing git history...');
  final history = computeHistory(repoRoot, 'lib/data/instruments_data.dart');

  stdout.writeln('Vendoring images...');
  final vendoredImages = await vendorImages(instruments, imagesDir);

  stdout.writeln('Writing shared CSS...');
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);
  await File('${assetsDir.path}/vademecum.css').writeAsString(_sharedCss, encoding: utf8);

  final byId = {for (final i in instruments) i.id: i};
  final bySpecialty = <String, List<Instr>>{};
  for (final i in instruments) {
    bySpecialty.putIfAbsent(i.specialty, () => []).add(i);
  }

  final sitemapPaths = <String>[];
  var pageCount = 0;

  stdout.writeln('Generating instrument pages...');
  for (final instr in instruments) {
    final siblings = (bySpecialty[instr.specialty] ?? [])
        .where((i) => i.id != instr.id)
        .take(6)
        .toList();
    for (final lang in languages) {
      final html = _renderInstrumentPage(
        instr: instr,
        lang: lang,
        categoryLabels: categoryLabels,
        specialtyLabels: specialtyLabels,
        history: history[instr.id],
        vendoredImages: vendoredImages,
        related: siblings,
      );
      final dir = Directory('${vademecumDir.path}/$lang/${instr.id}');
      dir.createSync(recursive: true);
      await File('${dir.path}/index.html').writeAsString(html, encoding: utf8);
      pageCount++;
    }
    sitemapPaths.addAll([for (final l in languages) '/vademecum/$l/${instr.id}/']);
  }

  stdout.writeln('Generating specialty index pages...');
  for (final spec in specialtyOrder) {
    final list = bySpecialty[spec] ?? [];
    for (final lang in languages) {
      final html = _renderSpecialtyPage(specialty: spec, lang: lang, specialtyLabels: specialtyLabels, instruments: list);
      final dir = Directory('${vademecumDir.path}/$lang/${kebab(spec)}');
      dir.createSync(recursive: true);
      await File('${dir.path}/index.html').writeAsString(html, encoding: utf8);
      pageCount++;
    }
    sitemapPaths.addAll([for (final l in languages) '/vademecum/$l/${kebab(spec)}/']);
  }

  stdout.writeln('Generating home pages...');
  final countsBySpecialty = {for (final spec in specialtyOrder) spec: (bySpecialty[spec] ?? []).length};
  for (final lang in languages) {
    final html = _renderHomePage(lang: lang, specialtyLabels: specialtyLabels, countsBySpecialty: countsBySpecialty);
    final dir = Directory('${vademecumDir.path}/$lang');
    dir.createSync(recursive: true);
    await File('${dir.path}/index.html').writeAsString(html, encoding: utf8);
    pageCount++;
  }
  sitemapPaths.addAll([for (final l in languages) '/vademecum/$l/']);

  stdout.writeln('Generating methodology pages...');
  for (final lang in languages) {
    final html = _renderMethodologyPage(lang);
    final dir = Directory('${vademecumDir.path}/$lang/metodologia');
    dir.createSync(recursive: true);
    await File('${dir.path}/index.html').writeAsString(html, encoding: utf8);
    pageCount++;
  }
  sitemapPaths.addAll([for (final l in languages) '/vademecum/$l/metodologia/']);

  stdout.writeln('Writing sitemap-vademecum.xml...');
  final sitemap = _renderSitemap(sitemapPaths);
  await File('${landingDir.path}/sitemap-vademecum.xml').writeAsString(sitemap, encoding: utf8);

  stdout.writeln('');
  stdout.writeln('Done. $pageCount pages written, ${sitemapPaths.length} URLs in sitemap-vademecum.xml.');
  stdout.writeln('Instrument lookup sanity: ${byId.length} unique ids.');
  exit(0);
}
