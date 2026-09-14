import 'dart:async';
import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:web/web.dart' as web;

/// Implementación Flutter Web: Tesseract.js autoalojado en `web/tesseract/`
/// (nada se pide a un CDN de terceros en tiempo de ejecución -- mismo
/// principio que ML Kit en Android/iOS, ver `OcrService`). Se carga de
/// forma perezosa: ni el script ni el modelo del idioma se piden hasta que
/// alguien pulsa "escanear" por primera vez, para no engordar la carga
/// inicial de la app con un payload de varios MB que la mayoría de sesiones
/// no llega a usar.
///
/// Los tres ficheros JS (`tesseract.min.js`, `worker.min.js`) y el core wasm
/// se descargaron con `Invoke-WebRequest` desde jsDelivr
/// (`tesseract.js@7.0.0` / `tesseract.js-core@7.0.0`) y los `.traineddata.gz`
/// de `@tesseract.js-data` para los tres idiomas de la app (cat/spa/eng).
/// Ver comentarios en `pubspec.yaml` y el propio directorio `web/tesseract/`.
const _scriptUrl = 'tesseract/tesseract.min.js';
const _workerPath = 'tesseract/worker.min.js';
const _corePath = 'tesseract/core';
const _langPath = 'tesseract/lang';

/// Código de idioma de la app (`LocaleService`) -> código de 3 letras que
/// espera Tesseract (ISO 639-2). Si algún día la app soporta un idioma sin
/// `.traineddata.gz` descargado, cae a inglés antes que reventar.
const _tesseractLangByLocale = {
  'ca': 'cat',
  'es': 'spa',
  'en': 'eng',
};

@JS('Tesseract')
external TesseractGlobal get _tesseractGlobal;

extension type TesseractGlobal._(JSObject _) implements JSObject {
  external JSPromise<TesseractWorker> createWorker(String langs, int oem, TesseractWorkerOptions options);
}

extension type TesseractWorkerOptions._(JSObject _) implements JSObject {
  external factory TesseractWorkerOptions({
    String workerPath,
    String corePath,
    String langPath,
  });
}

extension type TesseractWorker._(JSObject _) implements JSObject {
  external JSPromise<TesseractRecognizeResult> recognize(JSAny image);
  external JSPromise<JSAny?> terminate();
}

extension type TesseractRecognizeResult._(JSObject _) implements JSObject {
  external TesseractRecognizeData get data;
}

extension type TesseractRecognizeData._(JSObject _) implements JSObject {
  external String get text;
}

Future<void>? _scriptLoadFuture;
TesseractWorker? _worker;
String? _workerLangCode;

/// Inyecta `<script src="tesseract/tesseract.min.js">` en el `<head>` la
/// primera vez que se necesita, y reutiliza el mismo `Future` en llamadas
/// posteriores (incluidas las concurrentes) para no insertar el script dos
/// veces.
Future<void> _ensureScriptLoaded() {
  return _scriptLoadFuture ??= () async {
    final completer = Completer<void>();
    final script = web.HTMLScriptElement()..src = _scriptUrl;
    script.addEventListener(
      'load',
      (web.Event event) {
        if (!completer.isCompleted) completer.complete();
      }.toJS,
    );
    script.addEventListener(
      'error',
      (web.Event event) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('No se ha podido cargar $_scriptUrl'));
        }
      }.toJS,
    );
    web.document.head!.appendChild(script);
    return completer.future;
  }();
}

Future<TesseractWorker> _ensureWorker(String langCode) async {
  await _ensureScriptLoaded();
  if (_worker != null && _workerLangCode == langCode) return _worker!;
  if (_worker != null) {
    await _worker!.terminate().toDart;
    _worker = null;
    _workerLangCode = null;
  }
  final worker = await _tesseractGlobal
      .createWorker(
        langCode,
        1, // OEM_LSTM_ONLY: único modelo que se ha descargado para el core.
        TesseractWorkerOptions(workerPath: _workerPath, corePath: _corePath, langPath: _langPath),
      )
      .toDart;
  _worker = worker;
  _workerLangCode = langCode;
  return worker;
}

Future<List<String>> ocrRecognizeLines(XFile file, String languageCode) async {
  final tesseractLang = _tesseractLangByLocale[languageCode] ?? 'eng';
  final bytes = await file.readAsBytes();
  final worker = await _ensureWorker(tesseractLang);
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: file.mimeType ?? 'image/jpeg'),
  );
  final result = await worker.recognize(blob).toDart;
  return result.data.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

Future<void> ocrDispose() async {
  final worker = _worker;
  if (worker != null) {
    await worker.terminate().toDart;
    _worker = null;
    _workerLangCode = null;
  }
}
