/// Recent session list for My Progress.
library;

import 'package:flutter/material.dart';

import 'progress_tokens.dart';

class ProgressSessionsCard extends StatelessWidget {
  const ProgressSessionsCard({
    super.key,
    required this.sessions,
    required this.organFor,
  });

  final List<Map<String, dynamic>> sessions;
  final Map<String, String> organFor;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return ProgressGlass(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
        minHeight: 175,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Check(),
            SizedBox(height: 16),
            Text(
              'No sessions recorded yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: MpColors.white),
            ),
            SizedBox(height: 7),
            Text(
              'Complete your first practice session and your real progress will appear here — every rep, every word, every day.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.65, color: MpColors.dim),
            ),
          ],
        ),
      );
    }

    return ProgressGlass(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: MpColors.line),
            _SessionRow(session: sessions[i], organ: organFor['${sessions[i]['word'] ?? ''}'] ?? ''),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x21FFFFFF)),
      ),
      child: const Text('✓', style: TextStyle(fontSize: 20, color: Color(0xFF74797B))),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.organ});
  final Map<String, dynamic> session;
  final String organ;

  @override
  Widget build(BuildContext context) {
    final word = '${session['word'] ?? '—'}';
    final letter = word.isEmpty ? '—' : word.substring(0, 1).toUpperCase();
    final reps = session['repsCompleted'] is num ? (session['repsCompleted'] as num).toInt() : 0;
    final target = session['repTarget'] is num ? (session['repTarget'] as num).toInt() : 7;
    final dateLabel = _fmt(session['completedAt'] ?? session['date']);
    final detail = [
      if (organ.isNotEmpty) organ,
      dateLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: MpColors.line),
            ),
            child: Text(letter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MpColors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: MpColors.white)),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(fontSize: 12, color: MpColors.dim)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$reps', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MpColors.gold)),
              Text('of $target reps', style: const TextStyle(fontSize: 10, color: MpColors.dim)),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(dynamic raw) {
    if (raw == null) return '';
    final s = '$raw';
    try {
      final d = DateTime.parse(s.contains('T') ? s : '${s}T12:00:00');
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return s;
    }
  }
}
