import 'package:flutter/material.dart';
import 'package:gccabo/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gccabo/auth/login_screen.dart';
import 'package:gccabo/settings_screen.dart';
import 'package:gccabo/results_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gccabo/constants/topics.dart';
import 'package:gccabo/services/quiz_service.dart';
import 'package:gccabo/widgets/quick_option_card.dart';
import 'package:gccabo/models/question.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showPdfDialog(BuildContext context) {
    String selectedTopic = Topics.items.keys.first;
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
                    ...Topics.items.keys.map((topic) => DropdownMenuItem(
                        value: topic,
                        child: Text(topic, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(
                        value: 'Examen Aleatorio',
                        child: Text('Examen Aleatorio')),
                  ],
                  onChanged: (value) => setState(() => selectedTopic = value!),
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Número de preguntas'),
                  onChanged: (value) => questionsText = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                int? num = int.tryParse(questionsText);
                if (num != null && num > 0) {
                  Navigator.of(ctx).pop();
                  await _generatePdf(context, selectedTopic, num);
                }
              },
              child: const Text('Generar PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(
      BuildContext context, String selectedTopic, int numQuestions) async {
    try {
      List<String> jsonPaths = selectedTopic == 'Examen Aleatorio'
          ? Topics.items.values.toList()
          : [Topics.items[selectedTopic]!];

      List<Question> allQuestions = await QuizService.loadQuestions(jsonPaths);
      allQuestions.shuffle();
      List<Question> selectedQuestions =
          allQuestions.take(numQuestions).toList();

      await QuizService.generateAndSharePdf(selectedTopic, selectedQuestions);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generando PDF: $e')),
      );
    }
  }

  Future<List<Question>> _loadFailedQuestions() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

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

      List<Question> allQuestions =
          await QuizService.loadQuestions(Topics.items.values.toList());
      return allQuestions
          .where((q) => failedQuestionTexts.contains(q.text))
          .toList();
    } catch (e) {
      debugPrint('Error loading failed questions: $e');
      rethrow;
    }
  }

  void _startFailedQuestionsQuiz(BuildContext context) async {
    try {
      final failedQuestions = await _loadFailedQuestions();

      if (!context.mounted) return;

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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) => requestedQuestions = int.tryParse(value),
                decoration: InputDecoration(
                  hintText: 'Ingresa número de preguntas',
                  border: const OutlineInputBorder(),
                  suffixText: '/ ${failedQuestions.length}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar')),
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
                      'Solo hay ${failedQuestions.length} preguntas incorrectas. Se usarán todas las disponibles.';
                  questionsToUse = failedQuestions.length;
                }

                Navigator.of(ctx).pop();

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
                            _navigateToQuiz(
                                context, failedQuestions, questionsToUse);
                          },
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  );
                } else {
                  _navigateToQuiz(context, failedQuestions, questionsToUse);
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

  void _navigateToQuiz(
      BuildContext context, List<Question> questions, int count) {
    List<Question> selected = List.from(questions)..shuffle();
    final quizQuestions = selected.take(count).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          questions: quizQuestions,
          topic: 'Examen de Errores Cometidos ($count preguntas)',
        ),
      ),
    );
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ResultsListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
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
            Row(
              children: [
                Expanded(
                  child: QuickOptionCard(
                    title: 'Examen Aleatorio',
                    icon: Icons.shuffle,
                    color: Colors.blue,
                    onTap: () => _showRandomQuizDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickOptionCard(
                    title: 'Errores Cometidos',
                    icon: Icons.error_outline,
                    color: Colors.orange,
                    onTap: () => _startFailedQuestionsQuiz(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            QuickOptionCard(
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: Topics.items.length,
              itemBuilder: (context, index) {
                String topic = Topics.items.keys.elementAt(index);
                return _buildThemeCard(context, topic);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRandomQuizDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seleccionar número de preguntas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(context, ctx, 50),
            const SizedBox(height: 10),
            _buildDialogButton(context, ctx, 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(
      BuildContext context, BuildContext dialogCtx, int count) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(dialogCtx).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              topicJsons: Topics.items.values.toList(),
              topic: 'Examen Aleatorio ($count preguntas)',
              fixedNumberOfQuestions: count,
            ),
          ),
        );
      },
      child: Text('$count preguntas'),
    );
  }

  Widget _buildThemeCard(BuildContext context, String topic) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              topicJsons: [Topics.items[topic]!],
              topic: topic,
            ),
          ),
        ),
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
            children: [
              Icon(Topics.getIcon(topic), size: 18, color: Colors.white),
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
