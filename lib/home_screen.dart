import 'package:flutter/material.dart';
import 'package:gccabo/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gccabo/auth/login_screen.dart';
import 'package:gccabo/settings_screen.dart';
import 'package:gccabo/results_list_screen.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final Map<String, String> topics = {
    'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL':
        'assets/Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL/ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL.json',
    'Tema 2 RÉGIMEN INTERIOR':
        'assets/Tema 2 RÉGIMEN INTERIOR/Regimen anterior.json',
    'Tema 3 DEONTOLOGÍA PROFESIONAL':
        'assets/Tema 3 DEONTOLOGÍA PROFESIONAL/Deontologia profesional.json',
    'Tema 4 DERECHOS HUMANOS':
        'assets/Tema 4 DERECHOS HUMANOS/Derechos Humanos.json',
    'Tema 5 DERECHO ADMINISTRATIVO':
        'assets/Tema 5 DERECHO ADMINISTRATIVO/Derecho administrativo.json',
    'Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA':
        'assets/Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA/Seguridad ciudadana.json',
    'Tema 7 DERECHO FISCAL': 'assets/Tema 7 DERECHO FISCAL/Derecho fiscal.json',
    'Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA':
        'assets/Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA/reglamento de armas.json',
    'Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD':
        'assets/Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD/Patrimonio natural.json',
    'Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES':
        'assets/Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES/Genero y menores.json',
    'Tema 11 DERECHO PENAL':
        'assets/Tema 11 DERECHO PENAL/derecho penal.json',
    'Tema 12 PODER JUDICIAL':
        'assets/Tema 12 PODER JUDICIAL/poder judicial.json',
    'Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL':
        'assets/Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL/Ley enjuiciamiento criminal.json',
    'Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES':
        'assets/Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES/igualdad.json',
    'Tema 15 PROTECCION CIVIL':
        'assets/Tema 15 PROTECCION CIVIL/Proteccion Civil.json',
    'Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION':
        'assets/Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION/Tecnologias.json',
    'TEMA 17 TOPOGRAFIA': 'assets/TEMA 17 TOPOGRAFIA/Topografia.json',
  };

  void _showPdfDialog(BuildContext context) {
    String selectedTopic = topics.keys.first;
    String questionsText = '50';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Generar PDF'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedTopic,
                  isExpanded: true,
                  items: [
                    ...topics.keys.map((topic) => DropdownMenuItem(value: topic, child: Text(topic, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(value: 'Examen Aleatorio', child: Text('Examen Aleatorio')),
                  ],
                  onChanged: (value) => setState(() => selectedTopic = value!),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número de preguntas'),
                  controller: TextEditingController(text: questionsText),
                  onChanged: (value) => questionsText = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                int? num = int.tryParse(questionsText);
                if (num != null && num > 0) {
                  Navigator.of(ctx).pop();
                  await _generatePdf(selectedTopic, num);
                }
              },
              child: const Text('Generar PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(String selectedTopic, int numQuestions) async {
    List<String> jsonPaths = selectedTopic == 'Examen Aleatorio' ? topics.values.toList() : [topics[selectedTopic]!];

    List<Map<String, dynamic>> allQuestions = [];
    for (String path in jsonPaths) {
      String jsonString = await rootBundle.loadString(path);
      List<dynamic> data = json.decode(jsonString);
      allQuestions.addAll(List<Map<String, dynamic>>.from(data[0]['preguntas']));
    }
    allQuestions.shuffle();
    List<Map<String, dynamic>> selectedQuestions = allQuestions.take(numQuestions).toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('Examen: $selectedTopic')),
          ...selectedQuestions.map((q) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(q['pregunta']),
              if (q['cita'] != null) pw.Text('Cita: ${q['cita']}', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ...List<String>.from(q['opciones']).map((opt) => pw.Text('  $opt')),
              pw.SizedBox(height: 10),
            ],
          )),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'examen.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temario Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Consultar resultados',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ResultsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: topics.length + 2,
        itemBuilder: (context, index) {
          if (index < topics.length) {
            String topic = topics.keys.elementAt(index);
            return Card(
              color: Colors.green[200],
              child: ListTile(
                title: Text(topic),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        topicJsons: [topics[topic]!],
                        topic: topic,
                      ),
                    ),
                  );
                },
              ),
            );
          } else if (index == topics.length) {
            return Card(
              color: Colors.blue[200],
              child: ListTile(
                title: const Text('Examen Aleatorio'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Seleccionar número de preguntas'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(
                                    topicJsons: topics.values.toList(),
                                    topic: 'Examen Aleatorio (50 preguntas)',
                                    fixedNumberOfQuestions: 50,
                                  ),
                                ),
                              );
                            },
                            child: const Text('50 preguntas'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(
                                    topicJsons: topics.values.toList(),
                                    topic: 'Examen Aleatorio (100 preguntas)',
                                    fixedNumberOfQuestions: 100,
                                  ),
                                ),
                              );
                            },
                            child: const Text('100 preguntas'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return Card(
              color: Colors.red[200],
              child: ListTile(
                title: const Text('Generar PDF'),
                onTap: () => _showPdfDialog(context),
              ),
            );
          }
        },
      ),
    );
  }
}
