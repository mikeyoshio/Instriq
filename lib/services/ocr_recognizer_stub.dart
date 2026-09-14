import 'package:cross_file/cross_file.dart';

/// Implementación de repuesto para cualquier plataforma que no sea
/// Android/iOS (ver `ocr_recognizer_io.dart`) ni Flutter Web (ver
/// `ocr_recognizer_web.dart`) -- en la práctica, desktop (Windows/Linux/
/// macOS), que no es un target de despliegue real de esta app (ver
/// README). Nunca debería llegar a invocarse porque `OcrService.isSupported`
/// ya oculta el botón de escanear ahí, pero conviene que falle con un
/// mensaje claro en vez de un `NoSuchMethodError` si algún día se llama de
/// todos modos.
Future<List<String>> ocrRecognizeLines(XFile file, String languageCode) {
  throw UnsupportedError('OCR no disponible en esta plataforma');
}

Future<void> ocrDispose() async {}
