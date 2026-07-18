import 'dart:math';

/// Alfabeto sin caracteres ambiguos (sin 0/O, 1/I) para códigos legibles a mano.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateInviteCode({int length = 8}) {
  final random = Random.secure();
  return List.generate(length, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
}

/// Normaliza un código introducido a mano: mayúsculas, sin espacios ni guiones.
String normalizeInviteCode(String raw) {
  return raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
}
