

class QuizResult {
  final int score;
  final int totalQuestions;
  final int timeTaken;
  final String topic;
  final Map<String, AnswerRecord> answers;
  final DateTime date;

  QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.timeTaken,
    required this.topic,
    required this.answers,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  factory QuizResult.fromFirestore(Map<String, dynamic> data) {
    // Assuming structure for conversion if needed from Firebase
    // This is a placeholder for now as the current code uses raw maps
    return QuizResult(
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      timeTaken: data['timeTaken'] ?? 0,
      topic: data['topic'] ?? '',
      answers: {}, // Parsing complex map would go here
    );
  }
}

class AnswerRecord {
  final String correct;
  final String selected;
  final bool isCorrect;
  final String? citation;

  AnswerRecord({
    required this.correct,
    required this.selected,
    required this.isCorrect,
    this.citation,
  });
}
