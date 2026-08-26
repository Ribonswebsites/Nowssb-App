/// Working native Personal Coach flow paired with the supplied WebView page.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/practice_progress.dart';
import 'practice_player.dart';

class PersonalCoachScreen extends StatefulWidget {
  const PersonalCoachScreen({super.key});

  @override
  State<PersonalCoachScreen> createState() => _PersonalCoachScreenState();
}

class _PersonalCoachScreenState extends State<PersonalCoachScreen> {
  final _messageController = TextEditingController();
  String? _coachReply;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _reply(String message) {
    final text = message.trim();
    if (text.isEmpty) return;
    final sessions = PracticeProgress.instance.totalSessions;
    setState(() {
      _coachReply = sessions == 0
          ? 'Start with one focused practice for “$text”. When it is complete, your coach check-in will reflect that real session.'
          : 'You have $sessions completed sessions. For “$text”, continue with one focused practice and build on your existing momentum.';
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = PracticeProgress.instance.totalSessions;
    final streak = PracticeProgress.instance.streak;
    final words = ContentStore.instance.library.take(6).toList();
    final percent = math.min(100, (sessions * 10)).toInt();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(children: [
              IconButton.filled(style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black), onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded)),
              const SizedBox(width: 12),
              const Expanded(child: Text('Personal Coach', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              const CircleAvatar(backgroundColor: Color(0xFF202024), child: Icon(Icons.person_outline_rounded, color: Colors.white70)),
            ]),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1A20), Color(0xFF050505)]), border: Border.all(color: Colors.white12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Personal\nCoach', style: TextStyle(color: Colors.white, fontSize: 34, height: 1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Your goals. My guidance.\nUnstoppable you.', style: TextStyle(color: Colors.white60, height: 1.5)),
                const SizedBox(height: 22),
                FilledButton.icon(onPressed: words.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticePlayerScreen(words: words, title: 'Personal Coach Session'))), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start focused practice')),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _coachCard('Progress', '$percent%', '$percent% On Track\nKeep showing up.')), const SizedBox(width: 12),
              Expanded(child: Column(children: [_coachCard('Focus', sessions == 0 ? 'Begin' : 'Consistency', '$sessions sessions completed'), const SizedBox(height: 12), _coachCard('Mindset', 'Growth', 'Stay patient. Results compound.')]))
            ]),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF151518), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)), child: const Text('“\nDiscipline today,\nfreedom tomorrow.', style: TextStyle(color: Colors.white, fontSize: 22, height: 1.25, fontWeight: FontWeight.w700))),
            const SizedBox(height: 20),
            const Text('Chat with your coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(controller: _messageController, onSubmitted: _reply, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'How can I help you today?', hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: const Color(0xFF101013), suffixIcon: IconButton(onPressed: () => _reply(_messageController.text), icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: ['Need clarity', 'Plan my day', 'Stay motivated'].map((label) => ActionChip(label: Text(label), onPressed: () => _reply(label))).toList()),
            if (_coachReply != null) ...[const SizedBox(height: 12), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF19191E), borderRadius: BorderRadius.circular(16)), child: Text('Coach: $_coachReply', style: const TextStyle(color: Colors.white70, height: 1.45)))],
            const SizedBox(height: 8),
            TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PracticeProgressScreen(words: ContentStore.instance.library))), icon: const Icon(Icons.insights_outlined), label: Text('Review progress · ${streak > 0 ? '$streak-day streak' : 'start your streak'}')),
          ],
        ),
      ),
    );
  }

  Widget _coachCard(String label, String title, String detail) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF0E0E10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(detail, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35))]),
  );
}
            ),
          ],
        ),
      ),
    );
  }
}
