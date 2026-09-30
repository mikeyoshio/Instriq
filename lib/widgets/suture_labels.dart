import '../l10n/app_localizations.dart';
import '../models/suture.dart';

/// Etiqueta localizada de un [SutureMaterial]. `SutureMaterial.label` (en el
/// modelo) es un texto fijo en castellano, solo para depuración o contextos
/// sin [AppLocalizations] a mano — mismo criterio que
/// `sterilizationMethodValueLabel` para [SterilizationMethod]: la traducción
/// real vive en la capa de UI, no en el modelo.
String sutureMaterialValueLabel(
    AppLocalizations l10n, SutureMaterial material) {
  switch (material) {
    case SutureMaterial.seda:
      return l10n.sutureMaterialValueSeda;
    case SutureMaterial.vicryl:
      return l10n.sutureMaterialValueVicryl;
    case SutureMaterial.monocryl:
      return l10n.sutureMaterialValueMonocryl;
    case SutureMaterial.nylon:
      return l10n.sutureMaterialValueNylon;
    case SutureMaterial.pds:
      return l10n.sutureMaterialValuePds;
    case SutureMaterial.catgut:
      return l10n.sutureMaterialValueCatgut;
    case SutureMaterial.prolene:
      return l10n.sutureMaterialValueProlene;
    case SutureMaterial.dexon:
      return l10n.sutureMaterialValueDexon;
    case SutureMaterial.altres:
      return l10n.sutureMaterialValueAltres;
  }
}

/// Mismo criterio que [sutureMaterialValueLabel], para [NeedleType].
String needleTypeValueLabel(AppLocalizations l10n, NeedleType needleType) {
  switch (needleType) {
    case NeedleType.cortante:
      return l10n.needleTypeValueCortante;
    case NeedleType.redonda:
      return l10n.needleTypeValueRedonda;
    case NeedleType.cortanteInversa:
      return l10n.needleTypeValueCortanteInversa;
    case NeedleType.tapercut:
      return l10n.needleTypeValueTapercut;
  }
}
