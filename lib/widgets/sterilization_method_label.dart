import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart';

/// Etiqueta localizada de un [SterilizationMethod]. `SterilizationMethod.label`
/// (en el modelo) es un texto fijo en castellano, solo para depuración o
/// contextos sin [AppLocalizations] a mano — mismo criterio que
/// `WorkModePicker.labelFor` para [WorkMode]: la traducción real vive en la
/// capa de UI, no en el modelo.
String sterilizationMethodValueLabel(AppLocalizations l10n, SterilizationMethod method) {
  switch (method) {
    case SterilizationMethod.vapor:
      return l10n.sterilizationMethodValueVapor;
    case SterilizationMethod.plasma:
      return l10n.sterilizationMethodValuePlasma;
    case SterilizationMethod.oxidoEtileno:
      return l10n.sterilizationMethodValueOxidoEtileno;
    case SterilizationMethod.bajaTemperatura:
      return l10n.sterilizationMethodValueBajaTemperatura;
    case SterilizationMethod.desechable:
      return l10n.sterilizationMethodValueDesechable;
    case SterilizationMethod.noEsterilizable:
      return l10n.sterilizationMethodValueNoEsterilizable;
  }
}
