import 'package:flutter/material.dart';

class QuizOptionButton extends StatelessWidget {
  final String text;
  final bool isAnswered;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback? onPressed;

  const QuizOptionButton({
    super.key,
    required this.text,
    required this.isAnswered,
    required this.isCorrect,
    required this.isSelected,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? foregroundColor;
    BorderSide? side;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        side = const BorderSide(color: Colors.green, width: 2.0);
      } else if (isSelected) {
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        side = const BorderSide(color: Colors.red, width: 2.0);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton(
        onPressed: isAnswered ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: side,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          children: [
            if (isAnswered && isCorrect)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green),
              )
            else if (isAnswered && isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.cancel, color: Colors.red),
              )
            else
              const SizedBox(width: 32),
            Expanded(child: Text(text)),
            if (isAnswered && isCorrect)
              const Icon(Icons.check, color: Colors.white)
            else if (isAnswered && isSelected)
              const Icon(Icons.close, color: Colors.white)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
