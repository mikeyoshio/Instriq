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
    case DrugClass.analgesicoAntiinflamatorio:
      return l10n.drugClassAnalgesicoAntiinflamatorio;
    case DrugClass.antihistaminico:
      return l10n.drugClassAntihistaminico;
    case DrugClass.antibiotico:
      return l10n.drugClassAntibiotico;
    case DrugClass.antiparasitario:
      return l10n.drugClassAntiparasitario;
    case DrugClass.digestivo:
      return l10n.drugClassDigestivo;
    case DrugClass.broncodilatadorRespiratorio:
      return l10n.drugClassBroncodilatadorRespiratorio;
    case DrugClass.vitaminaSuplemento:
      return l10n.drugClassVitaminaSuplemento;
    case DrugClass.corticoide:
      return l10n.drugClassCorticoide;
    case DrugClass.electrolitoFluido:
      return l10n.drugClassElectrolitoFluido;
    case DrugClass.antihipertensivoCardiovascular:
      return l10n.drugClassAntihipertensivoCardiovascular;
    case DrugClass.anticolinergico:
      return l10n.drugClassAnticolinergico;
    case DrugClass.diuretico:
      return l10n.drugClassDiuretico;
    case DrugClass.antipsicotico:
      return l10n.drugClassAntipsicotico;
    case DrugClass.anticonvulsivo:
      return l10n.drugClassAnticonvulsivo;
    case DrugClass.anticoagulanteHemostatico:
      return l10n.drugClassAnticoagulanteHemostatico;
    case DrugClass.antidiabetico:
      return l10n.drugClassAntidiabetico;
  }
}
