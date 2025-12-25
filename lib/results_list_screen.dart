import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gccabo/results_screen.dart';

class ResultsListScreen extends StatelessWidget {
  const ResultsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados')),
        body: const Center(child: Text('Debe iniciar sesión para ver resultados.')),
      );
    }

    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('resultados')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis resultados'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Estadísticas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Historial
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No hay resultados guardados.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final score = data['score'] ?? 0;
                    final total = data['totalQuestions'] ?? 0;
                    final timeTaken = data['timeTaken'] ?? 0;
                    final topic = data['topic'] ?? '';
                    final date = data['date'] != null && data['date'] is Timestamp
                        ? (data['date'] as Timestamp).toDate()
                        : null;

                    // Format date to DD/MM/YYYY HH:MM using intl
                    String dateText = '';
                    if (date != null) {
                      dateText = ' - ${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())}';
                    }

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(topic.isNotEmpty ? topic : 'Resultado $index'),
                      subtitle: Text('$score / $total - ${timeTaken}s$dateText'),
                      onTap: () {
                        // Recreate answers map into the expected typed structure
                        final rawAnswers = data['answers'] as Map<String, dynamic>?;
                        final Map<String, Map<String, dynamic>> answers = {};
                        if (rawAnswers != null) {
                          rawAnswers.forEach((k, v) {
                            if (v is Map) {
                              answers[k] = Map<String, dynamic>.from(v.cast<String, dynamic>());
                            }
                          });
                        }

                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ResultsScreen(
                            score: score,
                            totalQuestions: total,
                            timeTaken: timeTaken,
                            answers: answers,
                            topic: topic ?? '',
                            topicJsons: [],
                            saveResult: false, // don't save again when viewing
                          ),
                        ));
                      },
                    );
                  },
                );
              },
            ),
            // Estadísticas
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No hay resultados para estadísticas.'));
                }

                // Calcular estadísticas
                int totalQuizzes = docs.length;
                double totalScore = 0;
                double totalQuestions = 0;
                double totalTime = 0;
                int maxScorePercent = 0;
                int minScorePercent = 100;
                Map<String, int> topicCounts = {};
                List<Map<String, double>> progressSpots = [];

                for (int i = 0; i < docs.length; i++) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  int score = data['score'] ?? 0;
                  int total = data['totalQuestions'] ?? 0;
                  int time = data['timeTaken'] ?? 0;
                  String topic = data['topic'] ?? '';

                  totalScore += score;
                  totalQuestions += total;
                  totalTime += time;
                  topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;

                  int percent = total > 0 ? (score * 100 ~/ total) : 0;
                  if (percent > maxScorePercent) maxScorePercent = percent;
                  if (percent < minScorePercent) minScorePercent = percent;
                }

                double averageScore = totalQuestions > 0 ? (totalScore / totalQuestions * 100) : 0;
                double averageTime = totalQuizzes > 0 ? totalTime / totalQuizzes : 0;
                int totalCorrect = totalScore.toInt();
                int totalFailed = (totalQuestions - totalScore).toInt();

                int numProgress = docs.length < 10 ? docs.length : 10;
                for (int i = docs.length - numProgress; i < docs.length; i++) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  int score = data['score'] ?? 0;
                  int total = data['totalQuestions'] ?? 0;

                  // Para lista de progreso (últimos 10)
                  double x = (i - (docs.length - numProgress)).toDouble();
                  progressSpots.add({'x': x, 'y': score / total * 100});
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('Total de Quizzes: $totalQuizzes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Puntuación Promedio: ${averageScore.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Total Preguntas Respondidas: ${totalQuestions.toInt()}', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Total Correctas: $totalCorrect', style: const TextStyle(fontSize: 16, color: Colors.green)),
                            const SizedBox(height: 8),
                            Text('Total Fallidas: $totalFailed', style: const TextStyle(fontSize: 16, color: Colors.red)),
                            const SizedBox(height: 8),
                            Text('Tiempo Medio por Examen: ${averageTime.toStringAsFixed(0)} segundos', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Mejor Puntuación: $maxScorePercent%', style: const TextStyle(fontSize: 16, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Text('Peor Puntuación: $minScorePercent%', style: const TextStyle(fontSize: 16, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Progreso Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...progressSpots.reversed.map((spot) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text('${spot['y']!.toStringAsFixed(1)}%'),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Quizzes por Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...topicCounts.entries.map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key.isEmpty ? 'Sin tema' : entry.key),
                                  Text('${entry.value}'),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
