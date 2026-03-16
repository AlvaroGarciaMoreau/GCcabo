class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String? citation;
  final String? explanation;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.citation,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['pregunta'] as String,
      options: List<String>.from(json['opciones'] as List),
      correctAnswer: json['respuesta_correcta'] as String,
      citation: json['cita'] as String?,
      explanation: (json['explicacion'] ?? json['explicación']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pregunta': text,
      'opciones': options,
      'respuesta_correcta': correctAnswer,
      'cita': citation,
      'explicacion': explanation,
    };
  }
}
