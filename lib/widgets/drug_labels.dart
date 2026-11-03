import '../l10n/app_localizations.dart';
import '../models/drug.dart';

/// Etiqueta localizada de una [DrugClass]. `DrugClass.label` (en el modelo)
/// es un texto fijo en catalán, solo para depuración o contextos sin
/// [AppLocalizations] a mano — mismo criterio que `sutureMaterialValueLabel`
/// para [SutureMaterial]: la traducción real vive en la capa de UI, no en
/// el modelo.
String drugClassValueLabel(AppLocalizations l10n, DrugClass drugClass) {
  switch (drugClass) {
    case DrugClass.inductor:
      return l10n.drugClassInductor;
    case DrugClass.relajanteNeuromuscular:
      return l10n.drugClassRelajanteNeuromuscular;
    case DrugClass.opioide:
      return l10n.drugClassOpioide;
    case DrugClass.anestesicoLocal:
      return l10n.drugClassAnestesicoLocal;
    case DrugClass.agenteReversion:
      return l10n.drugClassAgenteReversion;
    case DrugClass.vasopresor:
      return l10n.drugClassVasopresor;
    case DrugClass.antiemetico:
      return l10n.drugClassAntiemetico;
    case DrugClass.sedante:
      return l10n.drugClassSedante;
  }
}
