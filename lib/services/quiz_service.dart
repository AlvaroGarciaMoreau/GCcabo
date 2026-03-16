import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gccabo/models/question.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuizService {
  static Future<List<Question>> loadQuestions(List<String> jsonPaths) async {
    List<Question> allQuestions = [];
    for (String path in jsonPaths) {
      final String response = await rootBundle.loadString(path);
      final dynamic data = json.decode(response);
      
      List<dynamic> questionsJson;
      if (data is List && data.isNotEmpty) {
        if (data[0] is List) {
           // Case [[{"preguntas": [...]}]]
          questionsJson = data[0][0]['preguntas'];
        } else if (data[0] is Map && data[0].containsKey('preguntas')) {
          // Case [{"preguntas": [...]}]
          questionsJson = data[0]['preguntas'];
        } else {
           // Fallback for different structures if they exist
          questionsJson = [];
        }
        allQuestions.addAll(questionsJson.map((q) => Question.fromJson(q)).toList());
      }
    }
    return allQuestions;
  }

  static Future<void> generateAndSharePdf(String title, List<Question> questions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Examen: $title')),
          ...questions.asMap().entries.map((entry) {
            int index = entry.key + 1;
            Question q = entry.value;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$index. ${q.text}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (q.citation != null) 
                  pw.Text('Cita: ${q.citation}', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                ...q.options.map((opt) => pw.Text('  $opt', style: pw.TextStyle(fontSize: 9))),
                pw.SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'examen.pdf');
  }
}
