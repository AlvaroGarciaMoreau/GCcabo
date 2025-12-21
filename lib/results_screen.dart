import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gccabo/quiz_screen.dart';

class ResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int timeTaken;
  final Map<String, Map<String, dynamic>> answers;
  final String topic;
  final String topicJson; // Added topicJson
  final bool saveResult;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.answers,
    required this.topic,
    required this.topicJson, // Added topicJson
    this.saveResult = true,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _showSavedIcon = false;

  void _showSavedIconTemporarily() {
    if (!mounted) return;
    setState(() => _showSavedIcon = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSavedIcon = false);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.saveResult) {
      _saveResults();
    }
  }

  Future<void> _saveResults() async {
    var user = FirebaseAuth.instance.currentUser;

    // Debug info
    debugPrint('Attempting to save results. user.uid=${user?.uid}, emailVerified=${user?.emailVerified}');
    debugPrint('Result payload: score=${widget.score}, totalQuestions=${widget.totalQuestions}, timeTaken=${widget.timeTaken}, answersCount=${widget.answers.length}');

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No se pudo guardar el resultado: Usuario no autenticado.')),
      );
      return;
    }

    // Ensure we have the latest emailVerified state
    try {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }

    if (!(user?.emailVerified ?? false)) {
      if (!mounted) return;
      // Prompt the user to verify email and offer to resend
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verificación requerida'),
          content: const Text('Debes verificar tu correo para poder guardar los resultados.'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await user?.sendEmailVerification();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de verificación reenviado')));
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo reenviar el correo: $e')));
                }
              },
              child: const Text('Reenviar correo'),
            ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ],
        ),
      );
      return;
    }

    try {
      final failedQuestions = widget.answers.entries
          .where((e) => e.value['isCorrect'] == false)
          .map((e) => e.key)
          .toList();

      final payload = {
        'userId': user!.uid,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'timeTaken': widget.timeTaken,
        'date': Timestamp.now(),
        'answers': widget.answers,
        'failedQuestions': failedQuestions,
        'topic': widget.topic,
      };

      debugPrint('Saving payload: $payload');

      await FirebaseFirestore.instance.collection('resultados').add(payload);

      if (!mounted) return;
      _showSavedIconTemporarily();

    } catch (e) {
      debugPrint('Error saving results to Firestore: $e');
      if (!mounted) return;

      // If permission denied, show a helpful dialog with next steps
      final errMsg = e.toString();
      if (errMsg.contains('permission-denied')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permiso denegado'),
            content: const Text('No tienes permiso para guardar en Firestore. Revisa las reglas de seguridad o comprueba que tu usuario está verificado.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar resultados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Resultados'),
        automaticallyImplyLeading: false, // Removes back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tus puntos: ${widget.score} / ${widget.totalQuestions}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Tiempo tomado: ${widget.timeTaken} segundos',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(
              'Respuestas:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _showSavedIcon
                  ? Center(
                      key: const ValueKey('saved'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Guardado', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty')),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.answers.length,
                itemBuilder: (context, index) {
                  final entry = widget.answers.entries.elementAt(index);
                  final question = entry.key;
                  final data = entry.value;
                  final selected = data['selected'] ?? '';
                  final correct = data['correct'] ?? '';
                  final isCorrect = data['isCorrect'] == true;

                  return Card(
                    color: isCorrect ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      title: Text(question),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu respuesta: $selected',
                            style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Respuesta correcta: $correct',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      topic: widget.topic,
                      topicJson: widget.topicJson,
                    ),
                  ),
                );
              },
              child: const Text('Repetir Quiz'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Volver a la pantalla principal'),
            ),
          ],
        ),
      ),
    );
  }
}
