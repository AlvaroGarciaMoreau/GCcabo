import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';import 'package:intl/intl.dart';import 'package:gccabo/results_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Mis resultados')),
      body: StreamBuilder<QuerySnapshot>(
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
              final randomizeAcrossTopics = data['randomizeAcrossTopics'] == true;
              final presetQuestionCount = data['presetQuestionCount'];
              final allTopicsJson = (data['allTopicsJson'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList();
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
                      topicJson: '',
                      randomizeAcrossTopics: randomizeAcrossTopics,
                      allTopicsJson: allTopicsJson,
                      presetQuestionCount: presetQuestionCount is int ? presetQuestionCount : null,
                      saveResult: false, // don't save again when viewing
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
