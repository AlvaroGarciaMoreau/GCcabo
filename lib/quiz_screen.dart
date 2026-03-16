import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gccabo/services/quiz_service.dart';
import 'package:gccabo/results_screen.dart';
import 'package:gccabo/models/question.dart';
import 'package:gccabo/widgets/quiz_option_button.dart';
import 'package:gccabo/widgets/explanation_box.dart';

class QuizScreen extends StatefulWidget {
  final String topic;
  final List<String>? topicJsons;
  final List<Question>? questions;
  final int? fixedNumberOfQuestions;

  const QuizScreen({
    super.key,
    required this.topic,
    this.topicJsons,
    this.questions,
    this.fixedNumberOfQuestions,
  });

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  DateTime? _startTime;
  final Map<String, Map<String, dynamic>> _answers = {};
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    if (widget.questions != null) {
      _initWorkout(widget.questions!);
    } else if (widget.fixedNumberOfQuestions != null) {
      _loadQuestions(widget.fixedNumberOfQuestions!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNumberOfQuestionsDialog();
      });
    }
  }

  void _initWorkout(List<Question> questions) {
    setState(() {
      _questions = List.from(questions)..shuffle();
      _startTime = DateTime.now();
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  Future<void> _loadQuestions(int count) async {
    if (widget.topicJsons == null) return;
    try {
      final questions = await QuizService.loadQuestions(widget.topicJsons!);
      setState(() {
        _questions = questions..shuffle();
        if (count < _questions.length) {
          _questions = _questions.take(count).toList();
        }
        _startTime = DateTime.now();
        _elapsedSeconds = 0;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando preguntas: $e')),
      );
    }
  }

  void _showNumberOfQuestionsDialog() {
    int? count;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Número de preguntas'),
        content: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) => count = int.tryParse(value),
          decoration:
              const InputDecoration(hintText: "Ingrese el número de preguntas"),
        ),
        actions: [
          TextButton(
            child: const Text('Iniciar Quiz'),
            onPressed: () {
              if (count != null && count! > 0) {
                Navigator.of(ctx).pop();
                _loadQuestions(count!);
              }
            },
          )
        ],
      ),
    );
  }

  void _answerQuestion(String selected) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = selected;
      final q = _questions[_currentQuestionIndex];
      final isCorrect = selected == q.correctAnswer;
      if (isCorrect) _score++;

      _answers[q.text] = {
        'correct': q.correctAnswer,
        'selected': selected,
        'isCorrect': isCorrect,
        'cita': q.citation,
      };
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime == null) return;
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _stopTimer();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          score: _score,
          totalQuestions: _questions.length,
          timeTaken: _elapsedSeconds,
          answers: _answers,
          topic: widget.topic,
          topicJsons: widget.topicJsons ?? [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final q = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic)),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pregunta ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    q.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (q.citation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cita: ${q.citation}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ...q.options.map((opt) => QuizOptionButton(
                        text: opt,
                        isAnswered: _isAnswered,
                        isCorrect: opt == q.correctAnswer,
                        isSelected: opt == _selectedAnswer,
                        onPressed: () => _answerQuestion(opt),
                      )),
                  if (_isAnswered && q.explanation != null)
                    ExplanationBox(explanation: q.explanation!),
                ],
              ),
            ),
          ),
          if (_isAnswered)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_currentQuestionIndex < _questions.length - 1
                    ? 'Siguiente'
                    : 'Finalizar'),
              ),
            ),
        ],
      ),
    );
  }
}
