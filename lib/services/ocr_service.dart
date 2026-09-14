import 'dart:io' show Platform;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'locale_service.dart';
import 'ocr_recognizer_stub.dart' if (dart.library.js_interop) 'ocr_recognizer_web.dart' if (dart.library.io) 'ocr_recognizer_io.dart' as impl;

/// Reconocimiento de texto en el propio dispositivo/navegador, para
/// fotografiar un procedimiento ya impreso en papel y volcarlo como
/// borrador editable en vez de tener que re-escribirlo a mano (ver
/// `GroupDocumentFormScreen._scanDocument`).
///
/// La implementación real varía por plataforma (import condicional, ver
/// `ocr_recognizer_io.dart` / `ocr_recognizer_web.dart` /
/// `ocr_recognizer_stub.dart`), pero ninguna depende de conexión ni envía
/// contenido clínico a un tercero en tiempo de ejecución:
/// - Android/iOS: ML Kit, modelo de script latino integrado en el SDK.
/// - Web: Tesseract.js autoalojado en `web/tesseract/` (nada se pide a un
///   CDN de terceros).
/// - Cualquier otra plataforma (desktop, no es un target real de esta app):
///   no soportado, ver [isSupported].
///
/// Recibe un [XFile] (de `package:cross_file`, lo que devuelve
/// `image_picker`) en vez de un `dart:io.File`: en Flutter Web,
/// `XFile.path` es una blob: URL, no una ruta de disco real, así que un
/// `dart:io.File` construido a partir de ella no sirve de nada (ver también
/// el mismo patrón -- sin usar todavía -- en `TrayFormScreen`/
/// `CustomInstrumentFormScreen`, que sí siguen limitados a Android/iOS/
/// desktop por otros motivos). Cada implementación convierte el [XFile] del
/// modo que le haga falta: `File(xfile.path)` en Android/iOS,
/// `await xfile.readAsBytes()` en web.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  /// `dart:io`.`Platform.isAndroid`/`isIOS` no se evalúan en web gracias al
  /// cortocircuito de `||` (si `kIsWeb` es `true`, el resto ni se mira) --
  /// mismo patrón ya usado en el resto de la app para no tocar `Platform.*`
  /// sin comprobar antes `kIsWeb` (ver `main.dart`, `push_notification_
  /// service.dart`).
  static bool get isSupported => kIsWeb || Platform.isAndroid || Platform.isIOS;

  /// Reconoce el texto de [imageFile] y lo devuelve como lista de líneas no
  /// vacías: una línea del papel = una entrada de la lista. La decisión de
  /// qué hacer con cada línea (título, paso nuevo...) la toma quien llama,
  /// no este servicio.
  Future<List<String>> recognizeLines(XFile imageFile) {
    final languageCode = LocaleService.instance.locale.value.languageCode;
    return impl.ocrRecognizeLines(imageFile, languageCode);
  }

  /// Libera el reconocedor/worker. No es obligatorio llamarlo entre usos
  /// (se reutiliza la misma instancia mientras la app esté viva) -- solo
  /// hace falta si algún día se necesita soltar el recurso explícitamente.
  Future<void> dispose() => impl.ocrDispose();
}
