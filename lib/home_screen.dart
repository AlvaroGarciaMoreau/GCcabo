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
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final Map<String, String> topics = {
    'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL':
        'assets/Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL/ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL.json',
    'Tema 2 RÉGIMEN INTERIOR':
        'assets/Tema 2 RÉGIMEN INTERIOR/Regimen interior.json',
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

  Future<List<Map<String, dynamic>>> _loadFailedQuestions() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get all failed questions from Firestore
      final resultados = await FirebaseFirestore.instance
          .collection('resultados')
          .where('userId', isEqualTo: user.uid)
          .get();

      Set<String> failedQuestionTexts = {};
      for (var doc in resultados.docs) {
        List<dynamic> failed = doc['failedQuestions'] ?? [];
        failedQuestionTexts.addAll(failed.cast<String>());
      }

      if (failedQuestionTexts.isEmpty) {
        throw Exception('No hay preguntas incorrectas');
      }

      // Load all questions from JSON files and filter by failed questions
      List<Map<String, dynamic>> allQuestions = [];
      for (String jsonPath in topics.values) {
        String jsonString = await rootBundle.loadString(jsonPath);
        dynamic data = json.decode(jsonString);

        if (data is List && data.isNotEmpty) {
          dynamic firstElement = data[0];

          if (firstElement is List) {
            for (var item in firstElement) {
              if (item is Map && item.containsKey('preguntas')) {
                List<dynamic> questions = item['preguntas'] as List<dynamic>;
                allQuestions.addAll(List<Map<String, dynamic>>.from(questions));
              }
            }
          } else if (firstElement is Map && firstElement.containsKey('preguntas')) {
            List<dynamic> questions = firstElement['preguntas'] as List<dynamic>;
            allQuestions.addAll(List<Map<String, dynamic>>.from(questions));
          }
        }
      }

      // Filter questions that are in failedQuestionTexts
      List<Map<String, dynamic>> failedQuestions = allQuestions
          .where((q) => failedQuestionTexts.contains(q['pregunta']))
          .toList();

      if (failedQuestions.isEmpty) {
        throw Exception('No se encontraron preguntas fallidas');
      }

      return failedQuestions;
    } catch (e) {
      debugPrint('Error loading failed questions: $e');
      rethrow;
    }
  }

  IconData _getThemeIcon(String topic) {
    final iconMap = {
      'Tema 1 ESTATUTO DEL PERSONAL DE LA GUARDIA CIVIL': Icons.gavel,
      'Tema 2 RÉGIMEN INTERIOR': Icons.rule,
      'Tema 3 DEONTOLOGÍA PROFESIONAL': Icons.psychology,
      'Tema 4 DERECHOS HUMANOS': Icons.volunteer_activism,
      'Tema 5 DERECHO ADMINISTRATIVO': Icons.description,
      'Tema 6 PROTECCIÓN DE LA SEGURIDAD CIUDADANA': Icons.security,
      'Tema 7 DERECHO FISCAL': Icons.attach_money,
      'Tema 8 ARMAS, EXPLOSIVOS, ARTÍCULOS PIROTÉCNICOS Y CARTUCHERÍA': Icons.precision_manufacturing,
      'Tema 9 PATRIMONIO NATURAL Y BIODIVERSIDAD': Icons.nature,
      'Tema 10 PROTECCIÓN INTEGRAL CONTRA LA VIOLENCIA DE GÉNERO Y ACTUACIÓN CON MENORES': Icons.child_care,
      'Tema 11 DERECHO PENAL': Icons.warning,
      'Tema 12 PODER JUDICIAL': Icons.balance,
      'Tema 13 LEY DE ENJUICIAMIENTO CRIMINAL': Icons.gavel_sharp,
      'Tema 14 IGUALDAD EFECTIVA DE MUJERES Y HOMBRES': Icons.diversity_2,
      'Tema 15 PROTECCION CIVIL': Icons.emergency,
      'Tema 16 TECNOLOGIAS DE LA INFORMACION Y LA COMUNICACION': Icons.computer,
      'TEMA 17 TOPOGRAFIA': Icons.terrain,
    };
    return iconMap[topic] ?? Icons.book;
  }

  void _startFailedQuestionsQuiz(BuildContext context) async {
    try {
      final failedQuestions = await _loadFailedQuestions();

      if (!context.mounted) return;

      // Show dialog to ask for number of questions
      int? requestedQuestions;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Examen de Errores Cometidos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tienes ${failedQuestions.length} pregunta${failedQuestions.length != 1 ? 's' : ''} incorrecta${failedQuestions.length != 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  requestedQuestions = int.tryParse(value);
                },
                decoration: InputDecoration(
                  hintText: 'Ingresa número de preguntas',
                  border: OutlineInputBorder(),
                  suffixText: '/ ${failedQuestions.length}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (requestedQuestions == null || requestedQuestions! <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un número válido')),
                  );
                  return;
                }

                int questionsToUse = requestedQuestions!;
                String warningMessage = '';

                if (questionsToUse > failedQuestions.length) {
                  warningMessage =
                      'Solo hay ${failedQuestions.length} preguntas incorrectas, pero solicitaste $questionsToUse. Se usarán todas las disponibles.';
                  questionsToUse = failedQuestions.length;
                }

                Navigator.of(ctx).pop();

                // Show warning if necessary
                if (warningMessage.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (wCtx) => AlertDialog(
                      title: const Text('Aviso'),
                      content: Text(warningMessage),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(wCtx).pop();
                            _navigateToFailedQuizzes(
                              context,
                              failedQuestions,
                              questionsToUse,
                            );
                          },
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  _navigateToFailedQuizzes(
                    context,
                    failedQuestions,
                    questionsToUse,
                  );
                }
              },
              child: const Text('Comenzar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToFailedQuizzes(
    BuildContext context,
    List<Map<String, dynamic>> failedQuestions,
    int numberOfQuestions,
  ) {
    List<Map<String, dynamic>> selectedQuestions = failedQuestions
        .toList()
        ..shuffle()
        ..length;

    final quizQuestions = selectedQuestions.take(numberOfQuestions).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreenWithQuestions(
          questions: quizQuestions,
          topic:
              'Examen de Errores Cometidos ($numberOfQuestions pregunta${numberOfQuestions != 1 ? 's' : ''})',
        ),
      ),
    );
  }

  Future<void> _generatePdf(String selectedTopic, int numQuestions) async {
    try {
      List<String> jsonPaths = selectedTopic == 'Examen Aleatorio' ? topics.values.toList() : [topics[selectedTopic]!];

      List<Map<String, dynamic>> allQuestions = [];
      for (String path in jsonPaths) {
        String jsonString = await rootBundle.loadString(path);
        dynamic data = json.decode(jsonString);
        
        // data es [[{...}]], así que data[0] es [{...}]
        if (data is List && data.isNotEmpty) {
          dynamic firstElement = data[0];
          
          if (firstElement is List) {
            // Si es una lista de diccionarios
            for (var item in firstElement) {
              if (item is Map && item.containsKey('preguntas')) {
                List<dynamic> questions = item['preguntas'] as List<dynamic>;
                allQuestions.addAll(List<Map<String, dynamic>>.from(questions));
              }
            }
          } else if (firstElement is Map && firstElement.containsKey('preguntas')) {
            // Si es directamente un diccionario con preguntas
            List<dynamic> questions = firstElement['preguntas'] as List<dynamic>;
            allQuestions.addAll(List<Map<String, dynamic>>.from(questions));
          }
        }
      }
      
      if (allQuestions.isEmpty) {
        throw Exception('No se encontraron preguntas');
      }
      
      allQuestions.shuffle();
      List<Map<String, dynamic>> selectedQuestions = allQuestions.take(numQuestions).toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text('Examen: $selectedTopic')),
            ...selectedQuestions.asMap().entries.map((entry) {
              int index = entry.key + 1;
              Map<String, dynamic> q = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$index. ${q['pregunta']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (q['cita'] != null) pw.Text('Cita: ${q['cita']}', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  ...List<String>.from(q['opciones'] as List).map((opt) => pw.Text('  $opt', style: pw.TextStyle(fontSize: 9))),
                  pw.SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'examen.pdf');
    } catch (e) {
      debugPrint('Error generando PDF: $e');
      rethrow;
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Sección de opciones rápidas
            Row(
              children: [
                Expanded(
                  child: _buildQuickOptionCard(
                    context,
                    title: 'Examen Aleatorio',
                    icon: Icons.shuffle,
                    color: Colors.blue,
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickOptionCard(
                    context,
                    title: 'Errores Cometidos',
                    icon: Icons.error_outline,
                    color: Colors.orange,
                    onTap: () => _startFailedQuestionsQuiz(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickOptionCard(
              context,
              title: 'Generar PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              onTap: () => _showPdfDialog(context),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Temas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            // Grid de temas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                String topic = topics.keys.elementAt(index);
                return _buildThemeCard(
                  context,
                  topic: topic,
                  icon: _getThemeIcon(topic),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required String topic,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[700]!, Colors.green[600]!],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                topic,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
