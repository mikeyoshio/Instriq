import '../l10n/app_localizations.dart';
import '../models/wound_closure_material.dart';

/// Etiqueta localizada de una [WoundClosureCategory]. `WoundClosureCategory.label`
/// (en el modelo) es un texto fijo en castellano, solo para depuración o
/// contextos sin [AppLocalizations] a mano — mismo criterio que
/// `drugClassValueLabel` para [DrugClass]: la traducción real vive en la capa
/// de UI, no en el modelo.
String woundClosureCategoryValueLabel(AppLocalizations l10n, WoundClosureCategory category) {
  switch (category) {
    case WoundClosureCategory.hemostaticoAbsorbible:
      return l10n.woundClosureCategoryHemostaticoAbsorbible;
    case WoundClosureCategory.hemostaticoActivo:
      return l10n.woundClosureCategoryHemostaticoActivo;
    case WoundClosureCategory.sellanteTisular:
      return l10n.woundClosureCategorySellanteTisular;
    case WoundClosureCategory.adhesivoCutaneo:
      return l10n.woundClosureCategoryAdhesivoCutaneo;
    case WoundClosureCategory.grapaCutanea:
      return l10n.woundClosureCategoryGrapaCutanea;
    case WoundClosureCategory.tiraAdhesivaCutanea:
      return l10n.woundClosureCategoryTiraAdhesivaCutanea;
    case WoundClosureCategory.ceraOsea:
      return l10n.woundClosureCategoryCeraOsea;
  }
}
