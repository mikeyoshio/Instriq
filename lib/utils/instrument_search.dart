import '../models/instrument.dart';
import 'fuzzy_match.dart';

/// Rànquing únic per a la cerca d'instrumental (Omnihub i Catàleg).
///
/// Ordre: el nom comença per la cerca → una paraula del nom comença per la
/// cerca → el nom la conté → un àlies → la resta del text (descripció, ús,
/// especialitat…). Dins de cada nivell es manté l'ordre del catàleg.
/// Amb diverses paraules, totes han de coincidir.
///
/// Retorna null si l'instrument no coincideix; com més baix, millor.
int? instrumentMatchRank(Instrument instrument, String query, String languageCode, {String extraText = ''}) {
  final q = normalizeForSearch(query.trim());
  if (q.isEmpty) return 0;
  final name = normalizeForSearch(instrument.name.forLanguageCode(languageCode));
  final aliases = instrument.aliases.map(normalizeForSearch).toList();
  if (name.startsWith(q)) return 0;
  if (name.split(RegExp(r'[\s()\-/·,]+')).any((w) => w.startsWith(q))) return 1;
  if (name.contains(q)) return 2;
  if (aliases.any((a) => a.contains(q))) return 3;

  final words = q.split(RegExp(r'\s+'));
  final nameAndAliases = [name, ...aliases].join(' ');
  if (words.length > 1 && words.every(nameAndAliases.contains)) return 4;
  // Errates d'una lletra (fuzzy) al nom o als àlies.
  if (fuzzyContains(instrument.name.forLanguageCode(languageCode), query) ||
      instrument.aliases.any((a) => fuzzyContains(a, query))) {
    return 5;
  }
  if (extraText.isNotEmpty && words.every((w) => fuzzyContains(extraText, w))) return 6;
  return null;
}

/// Filtra i ordena [instruments] segons [instrumentMatchRank].
List<Instrument> rankInstruments(
  Iterable<Instrument> instruments,
  String query,
  String languageCode, {
  String Function(Instrument)? extraText,
}) {
  final scored = <(int, int, Instrument)>[];
  var order = 0;
  for (final i in instruments) {
    final rank = instrumentMatchRank(i, query, languageCode, extraText: extraText?.call(i) ?? '');
    if (rank != null) scored.add((rank, order, i));
    order++;
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
  return [for (final s in scored) s.$3];
}
