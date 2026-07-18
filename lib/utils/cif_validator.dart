/// Valida el formato y dígito/letra de control de un CIF español
/// (letra + 7 dígitos + dígito o letra de control). Solo valida formato,
/// no confirma que el CIF esté registrado realmente en Hacienda.
bool isValidCif(String rawCif) {
  final cif = rawCif.trim().toUpperCase();
  final match = RegExp(r'^([A-HJNPQRSUVW])(\d{7})([0-9A-J])$').firstMatch(cif);
  if (match == null) return false;

  final letter = match.group(1)!;
  final digits = match.group(2)!;
  final control = match.group(3)!;

  var sumEven = 0;
  var sumOdd = 0;
  for (var i = 0; i < digits.length; i++) {
    final d = int.parse(digits[i]);
    if (i.isEven) {
      final doubled = d * 2;
      sumOdd += doubled > 9 ? doubled - 9 : doubled;
    } else {
      sumEven += d;
    }
  }
  final controlDigit = (10 - ((sumEven + sumOdd) % 10)) % 10;
  const controlLetters = 'JABCDEFGHI';
  const numericControlLetters = 'ABEH';
  const letterControlLetters = 'KNPQRSW';

  if (numericControlLetters.contains(letter)) {
    return control == controlDigit.toString();
  }
  if (letterControlLetters.contains(letter)) {
    return control == controlLetters[controlDigit];
  }
  return control == controlDigit.toString() || control == controlLetters[controlDigit];
}
