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
  final List<String> topicJsons;
  final bool saveResult;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.answers,
    required this.topic,
    required this.topicJsons,
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

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    try {
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }

    if (!(user?.emailVerified ?? false)) {
      if (!mounted) return;
      _showVerificationDialog(user);
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

      await FirebaseFirestore.instance.collection('resultados').add(payload);

      if (!mounted) return;
      _showSavedIconTemporarily();
    } catch (e) {
      debugPrint('Error saving results: $e');
      if (!mounted) return;
      _handleSaveError(e);
    }
  }

  void _showVerificationDialog(User? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificación requerida'),
        content: const Text(
            'Debes verificar tu correo para poder guardar los resultados.'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await user?.sendEmailVerification();
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email enviado')));
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al enviar correo: $e')));
              }
            },
            child: const Text('Reenviar correo'),
          ),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _handleSaveError(Object e) {
    if (e.toString().contains('permission-denied')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso denegado'),
          content: const Text(
              'No tienes permiso para guardar. Regla de seguridad o usuario no verificado.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Puntos: ${widget.score} / ${widget.totalQuestions}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tiempo: ${widget.timeTaken} segundos',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_showSavedIcon)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Guardado', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            const Text(
              'Revision:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.answers.length,
                itemBuilder: (context, index) {
                  final entry = widget.answers.entries.elementAt(index);
                  final isCorrect = entry.value['isCorrect'] == true;
                  return Card(
                    color: isCorrect ? Colors.green[50] : Colors.red[50],
                    child: ListTile(
                      leading: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      title: Text(entry.key),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Respuesta: ${entry.value['selected']}',
                              style: TextStyle(
                                  color:
                                      isCorrect ? Colors.green : Colors.red)),
                          if (!isCorrect)
                            Text('Correcta: ${entry.value['correct']}',
                                style: const TextStyle(color: Colors.green)),
                          if (entry.value['cita'] != null)
                            Text('Cita: ${entry.value['cita']}',
                                style: const TextStyle(
                                    fontSize: 10, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    topic: widget.topic,
                    topicJsons: widget.topicJsons,
                  ),
                ),
              ),
              child: const Text('Repetir Quiz'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Volver al Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
