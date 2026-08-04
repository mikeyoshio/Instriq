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

/// Las ~50 filas de `supabase/seed_v1_catalog_sterilization_defaults.sql`
/// (catálogo global) repiten literalmente una de 4 frases fijas en
/// castellano -- no hay ninguna columna por idioma en `observations`
/// (consistente con el resto del esquema: `group_documents.content`,
/// notas de safates, etc. tampoco la tienen, es texto libre de una sola
/// vez). Si el texto guardado coincide exactamente con una de esas 4
/// plantillas, se traduce vía l10n; si no (texto propio de un hospital,
/// escrito por su equipo), se muestra tal cual -- mismo criterio que el
/// resto de contenido de autor libre en la app.
String sterilizationObservationsText(AppLocalizations l10n, String observations) {
  switch (observations) {
    case 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.':
      return l10n.sterilizationObsGenericReusable;
    case 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.':
      return l10n.sterilizationObsGenericDisposable;
    case "Corresponde al mango reutilizable del bisturi. La hoja es un componente de un solo uso independiente: ver la otra fila de este mismo instrumento (method = 'desechable'). Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.":
      return l10n.sterilizationObsScalpelHandle;
    case 'Corresponde a la hoja de bisturi, de un solo uso: no reesterilizar. El mango (reutilizable) se esteriliza aparte por vapor: ver la otra fila de este mismo instrumento. Verifica las instrucciones del fabricante.':
      return l10n.sterilizationObsScalpelBlade;
    default:
      return observations;
  }
}
