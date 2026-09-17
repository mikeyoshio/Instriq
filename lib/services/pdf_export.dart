import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart';
import '../models/preference_card.dart';
import '../models/tray.dart';

/// Genera el PDF del checklist de una bandeja publicada y lo manda al
/// diálogo nativo de imprimir/guardar de la plataforma (incluido el diálogo
/// de impresión del navegador en Flutter Web) -- pensado como respaldo en
/// papel puntual para el caso concreto del día, no como sustituto de la app.
Future<void> exportTrayChecklistPdf({
  required TrayVersion published,
  required List<CustomInstrument> customInstruments,
  required String? specialtyLabel,
  required AppLocalizations l10n,
}) async {
  final hasPositions = published.items.any((i) => (i.position ?? '').trim().isNotEmpty);

  final table = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: hasPositions
        ? {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(4), 2: const pw.FlexColumnWidth(1)}
        : {0: const pw.FlexColumnWidth(5), 1: const pw.FlexColumnWidth(1)},
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          if (hasPositions) _cell(l10n.pdfPositionColumn, bold: true),
          _cell(l10n.pdfInstrumentColumn, bold: true),
          _cell(l10n.pdfQuantityColumn, bold: true, alignment: pw.Alignment.centerRight),
        ],
      ),
      for (final item in published.items)
        pw.TableRow(
          children: [
            if (hasPositions) _cell(item.position ?? ''),
            _cell(item.resolveName(customInstruments)),
            _cell('${item.expectedQty}', alignment: pw.Alignment.centerRight),
          ],
        ),
    ],
  );

  await _layoutAndPrint(
    title: published.name,
    specialtyLabel: specialtyLabel,
    l10n: l10n,
    body: table,
    observations: published.observations,
  );
}

/// Igual que [exportTrayChecklistPdf] pero para una técnica/protocolo: la
/// tabla de arriba (instrumental con cantidad) no tiene sentido aquí, así
/// que el cuerpo es la lista de pasos (agrupados por categoría si los hay,
/// al estilo checklist de seguridad quirúrgica de la OMS que ya usa
/// [ProtocolStep.category]) más el material fungible si se registró alguno.
Future<void> exportGroupDocumentPdf({
  required GroupDocumentVersion published,
  required String? specialtyLabel,
  required AppLocalizations l10n,
}) async {
  final stepsByCategory = <String, List<ProtocolStep>>{};
  for (final step in published.steps) {
    stepsByCategory.putIfAbsent(step.category ?? '', () => []).add(step);
  }

  final body = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final entry in stepsByCategory.entries) ...[
        if (entry.key.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(entry.key, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
        ],
        for (var i = 0; i < entry.value.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 18,
                  height: 18,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(width: 0.75)),
                  child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(entry.value[i].text, style: const pw.TextStyle(fontSize: 10))),
              ],
            ),
          ),
      ],
      if (published.consumables.isNotEmpty) ...[
        pw.SizedBox(height: 14),
        pw.Text(l10n.pdfConsumablesLabel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        for (final c in published.consumables)
          pw.Text(
            '•  ${c.name}${(c.quantity ?? '').trim().isNotEmpty ? ' (${c.quantity})' : ''}',
            style: const pw.TextStyle(fontSize: 10),
          ),
      ],
    ],
  );

  await _layoutAndPrint(
    title: published.title,
    specialtyLabel: specialtyLabel,
    l10n: l10n,
    body: body,
    observations: null,
  );
}

/// Igual que [exportTrayChecklistPdf], para una tarjeta de preferencia: el
/// título es cirujano + procedimiento (no hay "nombre" propio de la tarjeta)
/// y cada ítem lleva una nota libre en vez de cantidad.
Future<void> exportPreferenceCardPdf({
  required PreferenceCardVersion published,
  required String surgeonName,
  required AppLocalizations l10n,
}) async {
  final hasNotes = published.items.any((i) => (i.note ?? '').trim().isNotEmpty);

  final table = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: hasNotes
        ? {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(3)}
        : {0: const pw.FlexColumnWidth(1)},
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell(l10n.pdfInstrumentColumn, bold: true),
          if (hasNotes) _cell(l10n.pdfObservationsLabel, bold: true),
        ],
      ),
      for (final item in published.items)
        pw.TableRow(
          children: [
            _cell(item.customName),
            if (hasNotes) _cell(item.note ?? ''),
          ],
        ),
    ],
  );

  final title = surgeonName.trim().isEmpty ? published.procedureName : '$surgeonName — ${published.procedureName}';

  await _layoutAndPrint(
    title: title,
    specialtyLabel: null,
    l10n: l10n,
    body: table,
    observations: published.generalNotes,
  );
}

Future<void> _layoutAndPrint({
  required String title,
  required String? specialtyLabel,
  required AppLocalizations l10n,
  required pw.Widget body,
  required String? observations,
}) async {
  final doc = pw.Document();
  final generatedOn = DateTime.now();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        if (specialtyLabel != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(specialtyLabel, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
        pw.SizedBox(height: 2),
        pw.Text(
          l10n.pdfGeneratedOn(_formatDate(generatedOn)),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),
        body,
        if ((observations ?? '').trim().isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(l10n.pdfObservationsLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(observations!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => doc.save());
}

pw.Widget _cell(String text, {bool bold = false, pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
