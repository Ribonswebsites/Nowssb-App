/// Weekly Insight card for My Progress.
library;

import 'package:flutter/material.dart';

import '../../data/practice_progress.dart';
import 'progress_tokens.dart';

class ProgressInsight extends StatelessWidget {
  const ProgressInsight({super.key, required this.progress});
  final PracticeProgress progress;

  @override
  Widget build(BuildContext context) {
    final text = _copy(progress);
    return ProgressGlass(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('■', style: TextStyle(fontSize: 9, color: Color(0xFFBFC5C7))),
              SizedBox(width: 8),
              Text(
                'SHABDAPATHY · AI ANALYSIS',
                style: TextStyle(fontSize: 9, letterSpacing: 2.8, color: Color(0xFFBFC5C7)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            text,
            style: const TextStyle(fontSize: 16, height: 1.75, color: Color(0xFFA8ADAF)),
          ),
        ],
      ),
    );
  }

  static String _copy(PracticeProgress p) {
    if (p.totalSessions == 0) {
      return 'Complete your first practice session and a personal insight will appear here — built from your actual data, not a template.';
    }
    if (p.streak >= 21) {
      return 'A ${p.streak}-day streak with ${p.uniqueWords} words activated across ${p.totalSessions} sessions. Your practice has crossed into deep consistency — keep the same window each day and the body map will keep lighting up.';
    }
    if (p.streak >= 7) {
      return '${p.streak} days in a row, ${p.uniqueWords} unique words, ${p.totalSessions} sessions logged. Momentum is real. Protect today\'s session and the weekly grid stays full.';
    }
    if (p.streak == 0) {
      return 'You have ${p.totalSessions} session${p.totalSessions == 1 ? '' : 's'} in history across ${p.uniqueWords} word${p.uniqueWords == 1 ? '' : 's'}. Practice today to restart the streak — consistency compounds faster than volume.';
    }
    return '${p.streak}-day streak · ${p.totalSessions} sessions · ${p.uniqueWords} words practiced. Small daily reps are building your healing record — stay with the same organ focus for a few days to deepen the map.';
  }
}
