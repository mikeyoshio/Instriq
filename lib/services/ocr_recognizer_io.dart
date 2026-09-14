import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Implementación Android/iOS: envuelve el SDK nativo de ML Kit (modelo de
/// script latino integrado, sin descarga ni llamada de red -- ver
/// `OcrService`). [XFile.path] en estas plataformas ya es una ruta real de
/// disco, así que basta con envolverla en un `dart:io.File` de toda la vida.
TextRecognizer? _recognizer;

TextRecognizer get _instance => _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

/// [languageCode] no se usa aquí (ML Kit ya reconoce el script latino
/// completo con un único modelo): solo lo necesita la implementación web,
/// pero la firma es común a las tres para que el facade no tenga que saber
/// qué plataforma tiene detrás.
Future<List<String>> ocrRecognizeLines(XFile file, String languageCode) async {
  final inputImage = InputImage.fromFile(File(file.path));
  final recognizedText = await _instance.processImage(inputImage);
  return recognizedText.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Future<void> ocrDispose() async {
  await _recognizer?.close();
  _recognizer = null;
}
