/// My Progress — `#sub-my-progress` Glass Orb layout.
///
/// Matches the live website shell in `index.html` (hero video + orb, stats,
/// week grid, sessions, body map, insight, feedback) and fills numbers from
/// [PracticeProgress] the same way `app/js/part006.js` does for real data.
library;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/practice_progress.dart';
import 'progress_body_map.dart';
import 'progress_feedback.dart';
import 'progress_hero.dart';
import 'progress_insight.dart';
import 'progress_sessions.dart';
import 'progress_stats.dart';
import 'progress_tokens.dart';

class PracticeProgressScreen extends StatefulWidget {
  const PracticeProgressScreen({super.key, this.words = const []});

  final List<Word> words;

  @override
  State<PracticeProgressScreen> createState() => _PracticeProgressScreenState();
}

class _PracticeProgressScreenState extends State<PracticeProgressScreen> {
  final _scroll = ScrollController();
  final _insightKey = GlobalKey();
  /// 0 = hero (scene-1) dominant; 1 = scroll bg (player-bg-loop) fully on.
  double _scrollBg = 0;

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_onProgress);
    PracticeProgress.instance.start();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_onProgress);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // Crossfade page backdrop once the user scrolls past most of the hero.
    final t = (_scroll.offset / (ProgressOrbHero.height * 0.72)).clamp(0.0, 1.0);
    if ((t - _scrollBg).abs() > 0.02) {
      setState(() => _scrollBg = t);
    }
  }

  void _scrollToInsight() {
    final ctx = _insightKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = PracticeProgress.instance;
    final organFor = <String, String>{
      for (final w in widget.words)
        if (w.word.isNotEmpty && w.organ.isNotEmpty) w.word: w.organ,
    };

    return Scaffold(
      backgroundColor: MpColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Scroll clip always under the hero; fades in as hero leaves.
          ProgressScrollBgVideo(opacity: 0.35 + 0.65 * _scrollBg),
          const ProgressVideoShade(),
          const ProgressGrain(),
          Column(
            children: [
              ProgressHeader(onBack: () => Navigator.of(context).maybePop()),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                  children: [
                    ProgressOrbHero(
                      sessions: progress.totalSessions,
                      timeLabel: progress.timeLabel,
                      onViewInsights: _scrollToInsight,
                    ),
                    // Pull Your Numbers tight under VIEW INSIGHTS.
                    const ProgressEyebrow('Your Numbers', tightTop: true),
                    ProgressStatsRow(progress: progress),
                    const SizedBox(height: 18),
                    const ProgressSceneTwo(),
                    const ProgressEyebrow('This Week'),
                    ProgressWeekGrid(progress: progress),
                    if (progress.lastPracticed != null) ...[
                      const SizedBox(height: 10),
                      ProgressLastPracticed(date: progress.lastPracticed!),
                    ],
                    const ProgressEyebrow('Recent Sessions'),
                    ProgressSessionsCard(
                      sessions: progress.sessionsSnapshot.take(8).toList(),
                      organFor: organFor,
                    ),
                    const ProgressEyebrow('Body & Mind'),
                    ProgressBodyMap(progress: progress, words: widget.words),
                    const ProgressEyebrow('Milestones'),
                    ProgressMilestones(progress: progress),
                    ProgressEyebrow('Weekly Insight', key: _insightKey),
                    ProgressInsight(progress: progress),
                    const ProgressEyebrow('Your Feedback'),
                    const ProgressFeedbackSection(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
