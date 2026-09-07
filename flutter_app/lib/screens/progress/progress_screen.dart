/// My Progress — Glass Orb layout with full-bleed page videos.
///
/// Matches website/WebView: scene-1 as edge-to-edge hero backdrop, scroll
/// clip as full-page bg after the orb, stats inside the ring, HBM body map,
/// and a working back control that pops (or returns home).
library;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../shell/nav_shell.dart';
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
  /// 0 = hero (scene-1) dominant; 1 = scroll bg fully on.
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
    final t = (_scroll.offset / (ProgressOrbHero.height * 0.72)).clamp(0.0, 1.0);
    if ((t - _scrollBg).abs() > 0.02) {
      setState(() => _scrollBg = t);
    }
  }

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    NavScope.goTo(context, 0);
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

  Widget _pad(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      );

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
          ProgressHeroBgVideo(opacity: (1.0 - _scrollBg).clamp(0.0, 1.0)),
          ProgressScrollBgVideo(opacity: 0.15 + 0.85 * _scrollBg),
          const ProgressVideoShade(),
          const ProgressGrain(),
          Column(
            children: [
              ProgressHeader(onBack: _handleBack),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 90),
                  children: [
                    // Full-bleed orb overlay (page video shows through).
                    ProgressOrbHero(
                      sessions: progress.totalSessions,
                      timeLabel: progress.timeLabel,
                      onViewInsights: _scrollToInsight,
                    ),
                    _pad(const ProgressEyebrow('Your Numbers', tightTop: true)),
                    _pad(ProgressStatsRow(progress: progress)),
                    const SizedBox(height: 14),
                    _pad(const ProgressPracticeForward()),
                    _pad(const ProgressEyebrow('This Week')),
                    _pad(ProgressWeekGrid(progress: progress)),
                    if (progress.lastPracticed != null) ...[
                      const SizedBox(height: 10),
                      _pad(ProgressLastPracticed(date: progress.lastPracticed!)),
                    ],
                    _pad(const ProgressEyebrow('Recent Sessions')),
                    _pad(ProgressSessionsCard(
                      sessions: progress.sessionsSnapshot.take(8).toList(),
                      organFor: organFor,
                    )),
                    _pad(const ProgressEyebrow('Body & Mind')),
                    _pad(ProgressBodyMap(progress: progress, words: widget.words)),
                    _pad(const ProgressEyebrow('Milestones')),
                    _pad(ProgressMilestones(progress: progress)),
                    _pad(ProgressEyebrow('Weekly Insight', key: _insightKey)),
                    _pad(ProgressInsight(progress: progress)),
                    _pad(const ProgressEyebrow('Your Feedback')),
                    _pad(const ProgressFeedbackSection()),
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
