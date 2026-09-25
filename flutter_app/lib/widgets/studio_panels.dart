/// Fashion-home practice board, matched to the courses reference.
/// Profile photo and banner, campaign stills, working controls.
library;

import 'package:flutter/material.dart';

import '../data/practice_progress.dart';
import '../screens/notifications_sheet.dart';
import '../screens/practice.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/sound_library.dart';
import '../shell/nav_shell.dart';
import 'glass_wrap.dart';

void openPracticeTab(BuildContext context, int tab) {
  final scope = context.getInheritedWidgetOfExactType<NavScope>();
  if (scope != null) {
    scope.go(tab);
    return;
  }
  final page = switch (tab) {
    1 => const PracticeScreen(),
    2 => const SoundLibraryScreen(),
    _ => const PracticeScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class PracticeStudioSection extends StatelessWidget {
  const PracticeStudioSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PracticeCoursesPanel();
  }
}

class PracticeCoursesPanel extends StatefulWidget {
  const PracticeCoursesPanel({super.key});

  @override
  State<PracticeCoursesPanel> createState() => _PracticeCoursesPanelState();
}

class _PracticeCoursesPanelState extends State<PracticeCoursesPanel> {
  var _progress = false;
  var _chip = 0;

  static const _profile = 'assets/profile_source/img-about.jpeg';

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_on);
    PracticeProgress.instance.start();
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  void _openTab(int tab) => openPracticeTab(context, tab);

  void _openPractice() => _openTab(1);

  void _openProgress() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PracticeProgressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = PracticeProgress.instance;
    final done = p.uniqueWords;
    final title = _progress ? 'Your Progress' : 'Origin Words';
    final art = _progress
        ? 'assets/banners/course-bubble.jpg'
        : 'assets/banners/course-cleo-a.jpg';
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tab('My Practice', !_progress, () => setState(() => _progress = false)),
                        _tab('Progress', _progress, () => setState(() => _progress = true)),
                      ],
                    ),
                  ),
                ),
              ),
                      GestureDetector(
                        onTap: () => showNotificationsSheet(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(
                      height: 248,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFB7E8), Color(0xFFE56BFF), Color(0xFF7A4CFF)],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Image.asset(art, fit: BoxFit.contain, height: 248),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xAA3A1458), Color(0x223A1458), Color(0x003A1458)],
                                stops: [0, 0.46, 0.72],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _faces('+12'),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text('Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    height: 1.02,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(p.timeLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFD15C), size: 16),
                                    const Text(' 4.7', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                                    Text(' $done', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '${_chip == 0 ? 1 : done.clamp(0, 5)} of 5',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _progress ? _openProgress : _openPractice,
                                      child: const Text(
                                        'Continue  ›',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _chipBtn('All Paths', '12', 0),
                      _chipBtn('Completed', '$done', 1),
                      _chipBtn('In practice', '${p.todaySessions}', 2),
                      _chipBtn('Saved', '${p.streak}', 3),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _openPractice,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xF014101C),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              _lower[_chip].$1,
                              width: 112,
                              height: 112,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(alignment: Alignment.centerRight, child: _faces('+2k')),
                                Text(
                                  _lower[_chip].$2,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.02, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(_lower[_chip].$3, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.chevron_right, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  static const _lower = [
    ('assets/banners/course-bubble.jpg', 'From\nSound to\nStillness', '12h 24m    ★ 4.8    12'),
    ('assets/banners/course-cleo-a.jpg', 'Hear\nyourself', 'Completed path'),
    ('assets/banners/course-cleo-b.jpg', 'Let go', 'Still in practice'),
    ('assets/banners/course-cleo-a.jpg', 'Saved\nwords', 'Kept for later'),
  ];

  Widget _tab(String label, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? Colors.white38 : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(color: on ? Colors.white : Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Widget _chipBtn(String label, String count, int i) {
    final on = _chip == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _chip = i),
        child: Column(
          children: [
            Text.rich(
              TextSpan(
                text: label,
                style: TextStyle(color: on ? Colors.white : Colors.white60, fontWeight: FontWeight.w700, fontSize: 11),
                children: [
                  TextSpan(text: ' $count', style: const TextStyle(fontSize: 9, color: Color(0xFFD2C4FF))),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: on ? Colors.white : Colors.transparent),
          ],
        ),
      ),
    );
  }

  Widget _faces(String extra) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(child: Image.asset(_profile, width: 22, height: 22, fit: BoxFit.cover)),
          const SizedBox(width: 4),
          Text(extra, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

class PracticeCourseRail extends StatelessWidget {
  const PracticeCourseRail({super.key});

  static const _items = [
    ('assets/banners/course-cleo-a.jpg', 'Hear yourself', 1),
    ('assets/banners/course-cleo-b.jpg', 'Let go', 2),
    ('assets/banners/course-bubble.jpg', 'Find your sound', 1),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => openPracticeTab(context, item.$3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(item.$1, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC140818), Color(0x00140818)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Text(
                        item.$2,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
