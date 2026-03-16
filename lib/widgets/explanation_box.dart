import 'package:flutter/material.dart';

class ExplanationBox extends StatelessWidget {
  final String explanation;

  const ExplanationBox({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    if (explanation.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green[50]?.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explicación',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8.0),
          Text(explanation),
        ],
      ),
    );
  }
}
