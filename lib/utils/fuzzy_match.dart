/// Comparación de búsqueda tolerante a erratas de una letra (dos si la
/// palabra buscada es larga). Pensada para sustituir `haystack.contains(needle)`
/// en los filtros de búsqueda del catálogo y del resto de listados: la
/// coincidencia exacta se comprueba primero y siempre gana sin coste extra,
/// así que esto nunca hace una búsqueda "peor" que antes, solo más permisiva
/// cuando la subcadena exacta no aparece (p. ej. "tigera" encuentra "tijera",
/// "bisturi" encuentra "bisturí").
///
/// Deliberadamente NO es búsqueda difusa de frases completas: compara la
/// palabra buscada contra cada palabra por separado del texto donde se
/// busca. Cubre el caso real (una errata dentro de una palabra), no
/// reordenar ni fusionar varias palabras.
bool fuzzyContains(String haystack, String needle) {
  final normalizedNeedle = _normalize(needle);
  if (normalizedNeedle.isEmpty) return true;

  final normalizedHaystack = _normalize(haystack);
  if (normalizedHaystack.contains(normalizedNeedle)) return true;

  final maxDistance = normalizedNeedle.length <= 4 ? 1 : 2;
  for (final word in normalizedHaystack.split(RegExp(r'\s+'))) {
    if ((word.length - normalizedNeedle.length).abs() > maxDistance) continue;
    if (_withinEditDistance(word, normalizedNeedle, maxDistance)) return true;
  }
  return false;
}

String _normalize(String value) {
  final lower = value.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    buffer.writeCharCode(_stripAccent(rune));
  }
  return buffer.toString();
}

const _accented = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
const _plain = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';
final _accentedRunes = _accented.runes.toList();

int _stripAccent(int rune) {
  final index = _accentedRunes.indexOf(rune);
  if (index == -1) return rune;
  return _plain.codeUnitAt(index);
}

/// Distancia de Levenshtein acotada: en cuanto se demuestra que el mínimo
/// posible ya supera [maxDistance], deja de tener sentido completar la fila
/// -- pero por simplicidad (las palabras del catálogo son cortas, unas
/// pocas decenas de caracteres como mucho) se calcula la DP completa y solo
/// se compara el resultado final contra el límite; no hace falta la variante
/// con corte anticipado para que esto sea barato a este tamaño.
bool _withinEditDistance(String a, String b, int maxDistance) {
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
      ].reduce((a, b) => a < b ? a : b);
    }
    previousRow = currentRow;
  }
  return previousRow[lenB] <= maxDistance;
}
