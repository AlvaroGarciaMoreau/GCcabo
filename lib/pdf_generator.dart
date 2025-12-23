import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<File> generateQuizPdf({
  required String title,
  required List<Map<String, dynamic>> questions,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            final pregunta = q['pregunta']?.toString() ?? '';
            final opciones = (q['opciones'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${index + 1}. $pregunta',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...opciones.asMap().entries.map((optEntry) {
                  final optIndex = optEntry.key;
                  final optText = optEntry.value;
                  final label = String.fromCharCode(65 + optIndex); // A, B, C...
                  return pw.Text(
                    '  $label) $optText',
                    style: const pw.TextStyle(fontSize: 11),
                  );
                }),
                pw.SizedBox(height: 12),
              ],
            );
          }),
        ];
      },
    ),
  );

  // Hoja de respuestas
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Hoja de Respuestas',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 10,
              children: questions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;
                final correcta = q['correcta'];
                final label =
                    correcta is int ? String.fromCharCode(65 + correcta) : '-';

                return pw.Text(
                  '${index + 1}. $label',
                  style: const pw.TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        );
      },
    ),
  );

  final dir = await getTemporaryDirectory();
  final file =
      File('${dir.path}/quiz_${DateTime.now().millisecondsSinceEpoch}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}


