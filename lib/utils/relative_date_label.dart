/// Etiqueta "Hoy"/"Mañana"/fecha corta para agrupar listas por día (agenda
/// quirúrgica). `todayLabel`/`tomorrowLabel` vienen de AppLocalizations para
/// que esté traducido -- esta función no conoce l10n directamente.
///
/// Sin `package:intl` a propósito (mismo motivo que `content_trust_dialog.dart`/
/// `pdf_export.dart`: no es una dependencia directa del pubspec, solo
/// transitiva vía `flutter_localizations` -- importarla aquí dispara el lint
/// `depend_on_referenced_packages`). `dd/MM/yyyy` sin nombres de mes/día
/// localizados, mismo criterio que `_formatShortDate` en
/// `instrument_detail_screen.dart`.
String relativeDateLabel(
  DateTime date, {
  required String todayLabel,
  required String tomorrowLabel,
  String? locale,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return todayLabel;
  if (diff == 1) return tomorrowLabel;
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
