import '../l10n/app_localizations.dart';
import '../models/instrument_incident.dart';

/// Etiquetas localizadas de [IncidentSeverity]/[IncidentStatus]. Igual que
/// `sterilizationMethodValueLabel` (ver widgets/sterilization_method_label.dart):
/// `.label` en el modelo es un texto fijo en castellano solo para depuración,
/// la traducción real vive en la capa de UI.
String incidentSeverityValueLabel(AppLocalizations l10n, IncidentSeverity severity) {
  switch (severity) {
    case IncidentSeverity.low:
      return l10n.incidentSeverityValueLow;
    case IncidentSeverity.medium:
      return l10n.incidentSeverityValueMedium;
    case IncidentSeverity.high:
      return l10n.incidentSeverityValueHigh;
  }
}

String incidentStatusValueLabel(AppLocalizations l10n, IncidentStatus status) {
  switch (status) {
    case IncidentStatus.open:
      return l10n.incidentStatusValueOpen;
    case IncidentStatus.resolved:
      return l10n.incidentStatusValueResolved;
  }
}
