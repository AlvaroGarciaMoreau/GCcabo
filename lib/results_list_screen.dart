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

    final query = FirebaseFirestore.instance
        .collection('resultados')
        .where('userId', isEqualTo: user.uid)
        .orderBy('date', descending: true);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis resultados'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Usuarios'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Historial
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
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
              stream: query.snapshots(),
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
                Map<String, Map<String, int>> topicStats = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  int score = data['score'] ?? 0;
                  int total = data['totalQuestions'] ?? 0;
                  int time = data['timeTaken'] ?? 0;
                  String topic = data['topic'] ?? 'Sin tema';
                  if (topic.isEmpty) topic = 'Sin tema';

                  totalScore += score;
                  totalQuestions += total;
                  totalTime += time;

                  if (!topicStats.containsKey(topic)) {
                    topicStats[topic] = {'score': 0, 'totalQuestions': 0, 'count': 0};
                  }
                  topicStats[topic]!['score'] = (topicStats[topic]!['score'] ?? 0) + score;
                  topicStats[topic]!['totalQuestions'] = (topicStats[topic]!['totalQuestions'] ?? 0) + total;
                  topicStats[topic]!['count'] = (topicStats[topic]!['count'] ?? 0) + 1;

                  int percent = total > 0 ? (score * 100 ~/ total) : 0;
                  if (percent > maxScorePercent) maxScorePercent = percent;
                  if (percent < minScorePercent) minScorePercent = percent;
                }

                double averageScore = totalQuestions > 0 ? (totalScore / totalQuestions * 100) : 0;
                double averageTime = totalQuizzes > 0 ? totalTime / totalQuizzes : 0;
                int totalCorrect = totalScore.toInt();
                int totalFailed = (totalQuestions - totalScore).toInt();

                // Datos para el gráfico (últimos 10, orden cronológico)
                List<double> chartData = [];
                final recentDocs = docs.take(10).toList().reversed;
                for (var doc in recentDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  int s = data['score'] ?? 0;
                  int t = data['totalQuestions'] ?? 0;
                  double pct = t > 0 ? (s / t * 100) : 0.0;
                  chartData.add(pct);
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Progreso Reciente (Últimos 10)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 150,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: chartData.map((pct) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('${pct.toInt()}', style: const TextStyle(fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 15,
                                        height: (pct / 100) * 120,
                                        decoration: BoxDecoration(
                                          color: pct >= 50 ? Colors.green : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rendimiento por Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...topicStats.entries.map((entry) {
                              final stats = entry.value;
                              double avg = stats['totalQuestions']! > 0 ? (stats['score']! / stats['totalQuestions']! * 100) : 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Text('${avg.toStringAsFixed(1)}% (${stats['count']} tests)'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: avg / 100,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(avg >= 50 ? Colors.green : Colors.red),
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Mejores Usuarios
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('resultados').snapshots(),
              builder: (context, resultsSnapshot) {
                if (resultsSnapshot.hasError) {
                  return Center(child: Text('Error: ${resultsSnapshot.error}'));
                }
                if (!resultsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = resultsSnapshot.data!.docs;
                
                // Agrupar resultados por usuario
                Map<String, List<Map<String, dynamic>>> userResults = {};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  String userId = data['userId'] ?? '';
                  if (userId.isEmpty) continue;

                  if (!userResults.containsKey(userId)) {
                    userResults[userId] = [];
                  }
                  userResults[userId]!.add(data);
                }

                // Calcular estadísticas por usuario
                List<Map<String, dynamic>> userStats = [];
                for (var entry in userResults.entries) {
                  String userId = entry.key;
                  List<Map<String, dynamic>> results = entry.value;

                  int totalQuizzes = results.length;
                  double totalScore = 0;
                  double totalQuestions = 0;
                  int maxScore = 0;
                  int minScore = 100;
                  int totalCorrect = 0;
                  int totalIncorrect = 0;

                  for (var result in results) {
                    int score = result['score'] ?? 0;
                    int total = result['totalQuestions'] ?? 0;

                    totalScore += score;
                    totalQuestions += total;
                    totalCorrect += score;
                    totalIncorrect += (total - score);

                    int percent = total > 0 ? (score * 100 ~/ total) : 0;
                    if (percent > maxScore) maxScore = percent;
                    if (percent < minScore) minScore = percent;
                  }

                  double average = totalQuestions > 0 ? (totalScore / totalQuestions * 100) : 0;

                  userStats.add({
                    'userId': userId,
                    'totalQuizzes': totalQuizzes,
                    'average': average,
                    'totalAnswered': totalQuestions.toInt(),
                    'totalCorrect': totalCorrect,
                    'totalIncorrect': totalIncorrect,
                    'maxScore': maxScore,
                    'minScore': minScore,
                  });
                }

                // Ordenar por promedio descendente
                userStats.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));

                // Tomar los 10 mejores
                List<Map<String, dynamic>> topUsers = userStats.take(10).toList();

                if (topUsers.isEmpty) {
                  return const Center(child: Text('No hay usuarios con resultados.'));
                }

                // Cargar nombres de todos los usuarios usando StreamBuilder
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, usersSnapshot) {
                    Map<String, String> userNames = {};
                    
                    if (usersSnapshot.hasData) {
                      for (var doc in usersSnapshot.data!.docs) {
                        final userData = doc.data() as Map<String, dynamic>;
                        String uid = doc.id;
                        String defaultName = uid.length >= 6 ? uid.substring(uid.length - 6) : uid;
                        
                        // Intentar obtener displayName
                        String displayName = defaultName;
                        if (userData.containsKey('displayName')) {
                          final name = userData['displayName'];
                          if (name != null && name.toString().trim().isNotEmpty) {
                            displayName = name.toString().trim();
                          }
                        }
                        userNames[uid] = displayName;
                        debugPrint('User $uid: displayName=$displayName');
                      }
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: topUsers.length,
                      separatorBuilder: (context, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final userStat = topUsers[index];
                        final userId = userStat['userId'] as String;
                        final rank = index + 1;
                        final average = userStat['average'] as double;
                        final totalQuizzes = userStat['totalQuizzes'] as int;
                        final totalAnswered = userStat['totalAnswered'] as int;
                        final totalCorrect = userStat['totalCorrect'] as int;
                        final totalIncorrect = userStat['totalIncorrect'] as int;
                        final maxScore = userStat['maxScore'] as int;
                        final minScore = userStat['minScore'] as int;
                        
                        // Obtener nombre del usuario
                        String username = userNames[userId] ?? (userId.length >= 6 ? userId.substring(userId.length - 6) : userId);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: rank == 1
                                            ? Colors.amber
                                            : rank == 2
                                                ? Colors.grey[400]
                                                : rank == 3
                                                    ? Colors.orange[700]
                                                    : Colors.blue,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#$rank',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Promedio: ${average.toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _StatItem('Quizzes', '$totalQuizzes'),
                                          _StatItem('Respondidas', '$totalAnswered'),
                                          _StatItem('Correctas', '$totalCorrect', Colors.green),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _StatItem('Incorrectas', '$totalIncorrect', Colors.red),
                                          _StatItem('Mejor', '$maxScore%', Colors.blue),
                                          _StatItem('Peor', '$minScore%', Colors.orange),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem(this.label, this.value, [this.color]);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? Colors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
