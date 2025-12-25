import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gccabo/results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topic;
  final List<String> topicJsons;
  final int? fixedNumberOfQuestions;

  const QuizScreen({super.key, required this.topic, required this.topicJsons, this.fixedNumberOfQuestions});

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  int? _numberOfQuestions;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  DateTime? _startTime;
  final Map<String, Map<String, dynamic>> _answers = {};

  // Timer for total elapsed time
  int _elapsedSeconds = 0;
  Timer? _timer;

  // New state variables
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    if (widget.fixedNumberOfQuestions != null) {
      _loadQuestions(widget.fixedNumberOfQuestions!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNumberOfQuestionsDialog();
      });
    }
  }

  Future<void> _loadQuestions(int count) async {
    List<Map<String, dynamic>> allQuestions = [];
    for (String jsonPath in widget.topicJsons) {
      final String response = await rootBundle.loadString(jsonPath);
      final data = await json.decode(response);
      List<Map<String, dynamic>> questions;
      if (data[0] is List) {
        // Tema 1 has [[obj]]
        questions = List<Map<String, dynamic>>.from(data[0][0]['preguntas']);
      } else {
        // Other temas have [obj]
        questions = List<Map<String, dynamic>>.from(data[0]['preguntas']);
      }
      allQuestions.addAll(questions);
    }
    allQuestions.shuffle();
    setState(() {
      _questions = allQuestions.take(count).toList();
      _startTime = DateTime.now();
      _elapsedSeconds = 0;
    });
    _startTimer();
  }

  void _showNumberOfQuestionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose
      builder: (ctx) => AlertDialog(
        title: const Text('Número de preguntas'),
        content: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _numberOfQuestions = int.tryParse(value);
          },
          decoration:
              const InputDecoration(hintText: "Ingrese el número de preguntas"),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Iniciar Quiz'),
            onPressed: () {
              if (_numberOfQuestions != null && _numberOfQuestions! > 0) {
                Navigator.of(ctx).pop();
                _loadQuestions(_numberOfQuestions!);
              }
            },
          )
        ],
      ),
    );
  }

  void _answerQuestion(String selectedAnswer) {
    if (_isAnswered) return; // Prevent answering more than once

    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedAnswer;
      final correctAnswer =
          _questions[_currentQuestionIndex]['respuesta_correcta'];
      final questionText = _questions[_currentQuestionIndex]['pregunta'];
      if (selectedAnswer == correctAnswer) {
        _score++;
        _answers[questionText] = {
          'correct': correctAnswer,
          'selected': selectedAnswer,
          'isCorrect': true,
          'cita': _questions[_currentQuestionIndex]['cita']
        };
      } else {
        _answers[questionText] = {
          'correct': correctAnswer,
          'selected': selectedAnswer,
          'isCorrect': false,
          'cita': _questions[_currentQuestionIndex]['cita']
        };
      }
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
    _timer?.cancel();
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
      // Last question, finish the quiz
      _stopTimer();
      final timeTaken = _elapsedSeconds;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            score: _score,
            totalQuestions: _questions.length,
            timeTaken: timeTaken,
            answers: _answers,
            topic: widget.topic,
            topicJsons: widget.topicJsons, // Pass topicJsons
          ),
        ),
      );
    }
  }

  ButtonStyle _getButtonStyle(String answer) {
    // Use MaterialStateProperty so colors apply even when the button is disabled
    final correctAnswer = _questions.isNotEmpty ? _questions[_currentQuestionIndex]['respuesta_correcta'] : null;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (!_isAnswered) return null; // use default
        if (answer == correctAnswer) return Colors.green;
        if (answer == _selectedAnswer) return Colors.red;
        return null;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (!_isAnswered) return null; // use default
        if (answer == correctAnswer || answer == _selectedAnswer) return Colors.white;
        return null;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          if (answer == correctAnswer) return Colors.greenAccent.withAlpha((0.2 * 255).round());
          if (answer == _selectedAnswer) return Colors.redAccent.withAlpha((0.2 * 255).round());
        }
        return null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Precompute current question data to avoid statements inside the widget list
    final currentQuestion = _questions.isEmpty ? null : _questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion != null ? currentQuestion['respuesta_correcta'] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
      ),
      body: _questions.isEmpty
          ? Center(
              child: _numberOfQuestions == null
                  ? const SizedBox.shrink() // Don't show progress indicator before questions are loaded
                  : const CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pregunta ${_currentQuestionIndex + 1}/${_questions.length}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tiempo: ${_formatTime(_elapsedSeconds)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _questions[_currentQuestionIndex]['pregunta'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (_questions[_currentQuestionIndex]['cita'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Cita: ${_questions[_currentQuestionIndex]['cita']}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ...(_questions[_currentQuestionIndex]['opciones'] as List<dynamic>)
                      .map((answer) {
                    return ElevatedButton(
                      onPressed: _isAnswered ? null : () => _answerQuestion(answer),
                      style: _getButtonStyle(answer).copyWith(
                        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
                          if (!_isAnswered) return null;
                          if (answer == correctAnswer) return const BorderSide(color: Colors.green, width: 2.0);
                          if (answer == _selectedAnswer) return const BorderSide(color: Colors.red, width: 2.0);
                          return null;
                        }),
                      ),
                      child: Row(
                        children: [
                          // Left permanent icon to highlight correct/wrong
                          if (_isAnswered && answer == correctAnswer)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.check_circle, color: Colors.green),
                            )
                          else if (_isAnswered && answer == _selectedAnswer)
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.cancel, color: Colors.red),
                            )
                          else
                            const SizedBox(width: 32),

                          Expanded(child: Text(answer)),

                          // Keep right-side indicator for clarity (optional)
                          if (_isAnswered && answer == correctAnswer)
                            const Icon(Icons.check, color: Colors.white)
                          else if (_isAnswered && answer == _selectedAnswer)
                            const Icon(Icons.close, color: Colors.white)
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    );
                  }),

                  // Explanation box shown when answered and explanation exists
                  if (_isAnswered)
                    Builder(builder: (context) {
                      final explanation = _questions[_currentQuestionIndex]['explicacion'] ?? _questions[_currentQuestionIndex]['explicación'] ?? '';
                      if (explanation == null || explanation.toString().trim().isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Explicación', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8.0),
                            Text(explanation.toString()),
                          ],
                        ),
                      );
                    }),

                  const Spacer(), // Pushes the button to the bottom
                  if (_isAnswered)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      child: Text(_currentQuestionIndex < _questions.length - 1
                          ? 'Siguiente'
                          : 'Finalizar'),
                    ),
                ],
              ),
            ),
    );
  }
}
