import 'package:flutter/material.dart';
import 'package:gccabo/quiz_screen.dart';
import 'package:gccabo/pdf_generator.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gccabo/settings_screen.dart';
import 'package:gccabo/results_list_screen.dart';

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
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ...topics.entries.map((entry) {
            return Card(
              color: Colors.green[200],
              child: ListTile(
                title: Text(entry.key),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        topicJson: entry.value,
                        topic: entry.key,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Card(
              color: Colors.blueGrey[50],
              child: ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Examen general'),
                subtitle: const Text('Preguntas aleatorias de todos los temas'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showExamDialog(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Card(
              color: Colors.orange[50],
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Generar PDF'),
                subtitle: const Text('Crear PDF de preguntas y compartir'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPdfDialog(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showExamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examen general'),
        content: const Text('Elige cuántas preguntas quieres responder.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startGeneralExam(context, 50);
            },
            child: const Text('50 preguntas'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startGeneralExam(context, 100);
            },
            child: const Text('100 preguntas'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _startGeneralExam(BuildContext context, int totalQuestions) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          topicJson: '',
          topic: 'Examen general',
          randomizeAcrossTopics: true,
          allTopicsJson: topics.values.toList(),
          presetQuestionCount: totalQuestions,
        ),
      ),
    );
  }

  void _showPdfDialog(BuildContext context) {
    final TextEditingController numberController =
        TextEditingController(text: '50');
    String selectedTopic = topics.keys.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Generar PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Origen de las preguntas:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedTopic,
                isExpanded: true,
                items: [
                  ...topics.keys.map((topic) => DropdownMenuItem(
                        value: topic,
                        child: Text(topic),
                      )),
                  const DropdownMenuItem(
                    value: 'examen',
                    child: Text('Examen general (todos los temas)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedTopic = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text('Número de preguntas:'),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 50',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final count = int.tryParse(numberController.text) ?? 0;
                if (count <= 0) return;
                Navigator.of(ctx).pop();
                await _handleGeneratePdf(context,
                    topicKey: selectedTopic, count: count);
              },
              child: const Text('Generar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGeneratePdf(
    BuildContext context, {
    required String topicKey,
    required int count,
  }) async {
    try {
      List<Map<String, dynamic>> questions = [];
      String title;

      if (topicKey == 'examen') {
        title = 'PDF de preguntas (Examen general)';
        final List<Map<String, dynamic>> combined = [];
        for (final path in topics.values) {
          final String response = await rootBundle.loadString(path);
          final data = await json.decode(response);
          final qs = List<Map<String, dynamic>>.from(data[0]['preguntas']);
          combined.addAll(qs);
        }
        combined.shuffle();
        questions = combined.take(count).toList();
      } else {
        title = 'PDF de preguntas ($topicKey)';
        final topicPath = topics[topicKey];
        if (topicPath == null) {
          throw Exception('Topic not found');
        }
        final String response = await rootBundle.loadString(topicPath);
        final data = await json.decode(response);
        final allQuestions =
            List<Map<String, dynamic>>.from(data[0]['preguntas']);
        allQuestions.shuffle();
        questions = allQuestions.take(count).toList();
      }

      if (questions.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudieron cargar preguntas para el PDF.')),
        );
        return;
      }

      final file = await generateQuizPdf(title: title, questions: questions);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Cuestionario GCcabo',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando PDF: $e')),
      );
    }
  }
}
