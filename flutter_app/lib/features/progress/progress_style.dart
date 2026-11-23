/// Today's progress in the layout Ribon picked (Nov 23, the CliniQ
/// reference), worn in NowssB's own look: the app film behind, GlassWrap
/// panes, black cards, white / gold accents. Every value is the user's own
/// record ([PracticeProgress], [ProgressCenter]); a new account sees empty
/// states, never sample numbers.
///
///  * [ProgressHero]       tall photo card: practice portrait, name, level
///                         chip, "x of 5 goals done", Details pill and two
///                         rounded-square buttons (check in, Practice tab).
///  * [ProgressStatRow]    three chips: streak, practice time, words.
///  * [ProgressDayStrip]   the last 14 days; the selected one is white.
///  * [ProgressTickScale]  a 24-hour ruler; gold ticks are the hours the
///                         selected day was practised, the handle reads one.
///  * [ProgressStartButton] full-width dark button that opens the player.
///  * [ProgressGoalGrid]   2x2 (4 across on tablets) goal cards, one lit.
///  * [ProgressWordCarousel] the words practised lately, poster cards.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/app_haptics.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../screens/practice_player.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import 'progress_center.dart';
import 'progress_kit.dart';
import 'progress_sources.dart';

const _muted = Color(0x99FFFFFF);
const _hair = Color(0x24FFFFFF);
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String dayTitle(DateTime d, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final x = DateTime(d.year, d.month, d.day);
  if (x == t) return 'Today';
  if (x == DateTime(t.year, t.month, t.day - 1)) return 'Yesterday';
  return '${_weekdays[x.weekday - 1]}, ${x.day} ${_months[x.month - 1]}';
}

String minutesLabel(int seconds) {
  if (seconds <= 0) return '0m';
  final m = math.max(1, (seconds / 60).round());
  if (m < 60) return '${m}m';
  final h = m ~/ 60, r = m % 60;
  return r == 0 ? '${h}h' : '${h}h ${r}m';
}

String hourLabel(int h) {
  final x = h % 24;
  final ap = x < 12 ? 'AM' : 'PM';
  final v = x % 12 == 0 ? 12 : x % 12;
  return '$v $ap';
}

/// One finished word from the practice log.
class DaySession {
  const DaySession({required this.word, required this.at, required this.seconds});
  final String word;
  final DateTime? at;
  final int seconds;
}

/// The practice log grouped by day (real sessions only).
class PracticeLog {
  PracticeLog(List<Map<String, dynamic>> raw) {
    for (final s in raw) {
      final date = '${s['date'] ?? ''}';
      if (date.isEmpty) continue;
      final word = '${s['word'] ?? ''}';
      final d = s['durationSec'];
      final at = DateTime.tryParse('${s['completedAt'] ?? ''}')?.toLocal();
      (byDay[date] ??= []).add(DaySession(word: word, at: at, seconds: d is num && d > 0 ? d.round() : 0));
    }
    // Each day in the order it was played.
    for (final l in byDay.values) {
      l.sort((a, b) => (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0)));
    }
  }
  factory PracticeLog.now() => PracticeLog(PracticeProgress.instance.sessionsSnapshot);

  final Map<String, List<DaySession>> byDay = {};

  List<DaySession> on(DateTime d) => byDay[dayKey(d)] ?? const [];

  /// Words finished most recently first, each once (restores left out).
  List<String> recentWords({int max = 10}) {
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final out = <String>[];
    for (final k in keys) {
      final day = [...byDay[k]!]..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
      for (final s in day) {
        if (s.word.isEmpty || s.word == 'Streak restore' || out.contains(s.word)) continue;
        out.add(s.word);
        if (out.length >= max) return out;
      }
    }
    return out;
  }
}

Word? libraryWord(String name) {
  final n = name.trim().toLowerCase();
  for (final w in ContentStore.instance.library) {
    if (w.word.toLowerCase() == n || w.key.toLowerCase() == n) return w;
  }
  return null;
}

/// A rounded-square glass tile (badges, buttons). Never a circle.
class SquareGlass extends StatelessWidget {
  const SquareGlass({super.key, required this.child, this.size = 44, this.fill = const Color(0x1FFFFFFF), this.radius = 14, this.onTap, this.semantics});
  final Widget child;
  final double size;
  final Color fill;
  final double radius;
  final VoidCallback? onTap;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(radius), border: Border.all(color: const Color(0x33FFFFFF))),
      child: Center(child: child),
    );
    if (onTap == null) return box;
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap!();
        },
        child: box,
      ),
    );
  }
}

/// Small label over a section: grey eyebrow + bold title, optional trailing.
class ProgressLabel extends StatelessWidget {
  const ProgressLabel({super.key, required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(trailing!, style: const TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
}

// ───────────────────────────── hero ─────────────────────────────

class ProgressHero extends StatelessWidget {
  const ProgressHero({
    super.key,
    required this.name,
    required this.photo,
    required this.level,
    required this.done,
    required this.total,
    required this.today,
    required this.checkedIn,
    required this.onDetails,
    required this.onCheckIn,
    required this.onPractice,
    required this.since,
    this.busy = false,
  });

  /// "Practising since 12 Nov" / "New to NowssB".
  final String since;

  final String name;
  final ImageProvider photo;
  final int level;
  final int done;
  final int total;
  final DateTime today;
  final bool checkedIn;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onCheckIn;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = (box.maxWidth * 1.08).clamp(360.0, 460.0);
      return SizedBox(
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFF15151C)),
            Image(image: photo, fit: BoxFit.cover, alignment: const Alignment(0, -0.35), errorBuilder: (_, __, ___) => const SizedBox()),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x00000000), Color(0xB3000000), Color(0xF2000000)],
                  stops: [0, 0.38, 0.72, 1],
                ),
              ),
            ),
            DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: _hair))),
            Positioned(
              left: 14,
              top: 14,
              child: _HeroChip(key: const ValueKey('today-level-chip'), mark: GoalMarks.practice, text: 'Level $level'),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: _HeroChip(mark: GoalMarks.checkin, text: '${_weekdays[today.weekday - 1]}, ${today.day} ${_months[today.month - 1]}'),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(name,
                        key: const ValueKey('today-hero-name'),
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.1)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(since,
                    key: const ValueKey('today-hero-since'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('$done of $total goals done',
                    key: const ValueKey('today-goals-done'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NwsbColors.goldLight, fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        key: const ValueKey('today-details'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          AppHaptics.selection();
                          onDetails();
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Text('Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Opacity(
                    opacity: busy ? 0.5 : 1,
                    child: SquareGlass(
                      key: const ValueKey('today-action-checkin'),
                      size: 50,
                      radius: 16,
                      semantics: checkedIn ? 'Checked in' : 'Check in',
                      fill: checkedIn ? NwsbColors.goldLight : const Color(0x33FFFFFF),
                      onTap: checkedIn || busy ? null : onCheckIn,
                      child: NwsbIcon(GoalMarks.checkin, size: 22, color: checkedIn ? Colors.black : Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SquareGlass(
                    key: const ValueKey('today-hero-practice'),
                    size: 50,
                    radius: 16,
                    semantics: 'Practice',
                    fill: const Color(0x33FFFFFF),
                    onTap: onPractice,
                    child: const NwsbIcon(GoalMarks.practice, size: 22),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({super.key, required this.mark, required this.text});
  final String mark;
  final String text;
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x33FFFFFF))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        NwsbIcon(mark, size: 15, color: NwsbColors.goldLight),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ───────────────────────────── stats ─────────────────────────────

class ProgressStatRow extends StatelessWidget {
  const ProgressStatRow({super.key, required this.streak, required this.time, required this.words});
  final int streak;
  final String time;
  final int words;

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String mark, String value, String label) => Expanded(
          child: Container(
            key: ValueKey(key),
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: _hair)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              SquareGlass(size: 30, radius: 10, child: NwsbIcon(mark, size: 15)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
                ),
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11.5, height: 1.2)),
            ]),
          ),
        );
    return Row(children: [
      chip('today-stat-streak', NwsbMarks.trending, '$streak', streak == 1 ? 'Day streak' : 'Days streak'),
      const SizedBox(width: 8),
      chip('today-stat-time', NwsbMarks.hourglass, time, 'Practice time'),
      const SizedBox(width: 8),
      chip('today-stat-words', NwsbMarks.word, '$words', words == 1 ? 'Word learnt' : 'Words learnt'),
    ]);
  }
}

// ───────────────────────────── day strip ─────────────────────────────

class ProgressDayStrip extends StatelessWidget {
  const ProgressDayStrip({super.key, required this.today, required this.selected, required this.practised, required this.onPick, this.days = 14});
  final DateTime today;
  final DateTime selected;
  final bool Function(DateTime d) practised;
  final ValueChanged<DateTime> onPick;
  final int days;

  static String monthLabel(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final t = DateTime(today.year, today.month, today.day);
    return SizedBox(
      height: 80,
      child: ListView.separated(
        key: const ValueKey('today-day-strip'),
        scrollDirection: Axis.horizontal,
        reverse: true, // today sits at the right edge, earlier days scroll in
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = DateTime(t.year, t.month, t.day - i);
          final on = dayKey(d) == dayKey(selected);
          final did = practised(d);
          return GestureDetector(
            key: ValueKey('today-day-${dayKey(d)}'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              onPick(d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              decoration: BoxDecoration(
                color: on ? Colors.white : const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: on ? Colors.white : _hair),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(i == 0 ? 'Today' : _weekdays[d.weekday - 1],
                    style: TextStyle(color: on ? const Color(0x99000000) : _muted, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${d.day}', style: TextStyle(color: on ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 6),
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: did ? (on ? NwsbColors.gold : NwsbColors.goldLight) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────────── tick scale ─────────────────────────────

/// A 24-hour ruler: a tick every half hour, labels every 6 hours, gold ticks
/// for the hours that day was practised. Tap or drag to read an hour.
class ProgressTickScale extends StatelessWidget {
  const ProgressTickScale({super.key, required this.sessions, required this.hour, required this.onHour});
  final List<DaySession> sessions;
  final int hour;
  final ValueChanged<int> onHour;

  Map<int, int> get _perHour {
    final m = <int, int>{};
    for (final s in sessions) {
      if (s.at == null) continue;
      m[s.at!.hour] = (m[s.at!.hour] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final per = _perHour;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      int at(double dx) => ((dx / w) * 24).floor().clamp(0, 23);
      return GestureDetector(
        key: const ValueKey('today-tick-scale'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          AppHaptics.selection();
          onHour(at(d.localPosition.dx));
        },
        onHorizontalDragUpdate: (d) {
          final h = at(d.localPosition.dx);
          if (h != hour) onHour(h);
        },
        child: SizedBox(
          height: 74,
          width: w,
          child: CustomPaint(painter: _TickPainter(per: per, hour: hour, font: DefaultTextStyle.of(context).style.fontFamily)),
        ),
      );
    });
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.per, required this.hour, this.font});
  final Map<int, int> per;
  final int hour;
  final String? font;

  @override
  void paint(Canvas canvas, Size size) {
    const base = 46.0;
    final step = size.width / 48;
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 48; i++) {
      final x = (i * step).clamp(1.0, size.width - 1);
      final h = i ~/ 2;
      final hit = i < 48 && (per[h] ?? 0) > 0;
      final major = i % 12 == 0;
      final len = hit ? 18.0 + math.min(3, per[h]!) * 6 : (major ? 18.0 : (i.isEven ? 11.0 : 7.0));
      p
        ..color = hit ? NwsbColors.goldLight : (major ? const Color(0x99FFFFFF) : const Color(0x4DFFFFFF))
        ..strokeWidth = hit ? 3 : 1.4;
      canvas.drawLine(Offset(x, base - len), Offset(x, base), p);
      if (major) {
        final tp = TextPainter(
          text: TextSpan(text: i == 48 ? '12a' : ['12a', '6a', '12p', '6p'][i ~/ 12], style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600, fontFamily: font)),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(lx, base + 8));
      }
    }
    // The handle: a rounded bar over the read hour (centre of its hour).
    final hx = ((hour + 0.5) / 24) * size.width;
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hx, base - 16), width: 8, height: 40), const Radius.circular(4));
    canvas.drawRRect(r, Paint()..color = Colors.white);
    canvas.drawRRect(r, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.hour != hour || old.per.length != per.length || old.per.toString() != per.toString();
}

// ───────────────────────────── start button ─────────────────────────────

class ProgressStartButton extends StatelessWidget {
  const ProgressStartButton({super.key, required this.label, required this.sub, required this.onTap});
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          key: const ValueKey('today-start-session'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x3DFFFFFF)),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10))],
            ),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11.5)),
                ]),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: NwsbColors.goldLight, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: NwsbIcon(NwsbMarks.play24, size: 20, color: Colors.black)),
              ),
            ]),
          ),
        ),
      );
}

// ───────────────────────────── goal grid ─────────────────────────────

class ProgressGoalGrid extends StatelessWidget {
  const ProgressGoalGrid({super.key, required this.items, required this.lit, required this.onOpen, required this.markFor});
  final List<ProgressItem> items;
  final ProgressKind? lit;
  final void Function(ProgressKind k) onOpen;
  final String Function(ProgressKind k) markFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth >= 600 ? 4 : 2;
      const gap = 10.0;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final it in items) SizedBox(width: w, height: 176, child: _GoalTile(item: it, lit: it.kind == lit, mark: markFor(it.kind), onOpen: () => onOpen(it.kind))),
      ]);
    });
  }
}

class _GoalTile extends StatefulWidget {
  const _GoalTile({required this.item, required this.lit, required this.mark, required this.onOpen});
  final ProgressItem item;
  final bool lit;
  final String mark;
  final VoidCallback onOpen;
  @override
  State<_GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends State<_GoalTile> {
  var _down = false;
  @override
  Widget build(BuildContext context) {
    final it = widget.item, lit = widget.lit;
    final fg = lit ? Colors.black : Colors.white;
    final sub = lit ? const Color(0x99000000) : _muted;
    return GestureDetector(
      key: ValueKey('today-goal-${it.kind.name}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        AppHaptics.selection();
        widget.onOpen();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: lit ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: lit ? Colors.white : _hair),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              SquareGlass(
                size: 38,
                radius: 12,
                fill: lit ? const Color(0x14000000) : const Color(0x1FFFFFFF),
                child: NwsbIcon(widget.mark, size: 18, color: fg),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Open ${it.title}',
                child: GestureDetector(
                  key: ValueKey('today-arrow-${it.kind.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptics.selection();
                    widget.onOpen();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: lit ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Transform.rotate(
                        angle: -math.pi / 4,
                        child: NwsbIcon(NwsbMarks.arrow, size: 16, color: lit ? Colors.white : Colors.black, strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const Spacer(),
            Text(it.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(ProgressSources.nextStep(it), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11, height: 1.3)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${it.done.clamp(0, it.total)}/${it.total}',
                  key: ValueKey('today-count-${it.kind.name}'),
                  style: TextStyle(color: it.complete && !lit ? NwsbColors.goldLight : fg, fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: it.value,
                      minHeight: 5,
                      color: lit ? NwsbColors.gold : NwsbColors.goldLight,
                      backgroundColor: lit ? const Color(0x1F000000) : const Color(0x33FFFFFF),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────────── word carousel ─────────────────────────────

class ProgressWordCarousel extends StatelessWidget {
  const ProgressWordCarousel({super.key, required this.words, required this.lastDay, required this.onOpen});
  final List<Word> words;
  final String Function(Word w) lastDay;
  final ValueChanged<Word> onOpen;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          key: const ValueKey('today-words-empty'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: _hair)),
          child: const Row(children: [
            SquareGlass(size: 40, radius: 12, child: NwsbIcon(NwsbMarks.word, size: 19)),
            SizedBox(width: 12),
            Expanded(
              child: Text('Words you finish in the player show up here.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.35)),
            ),
          ]),
        ),
      );
    }
    return SizedBox(
      height: 214,
      child: ListView.separated(
        key: const ValueKey('today-words'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final w = words[i];
          final art = playerCoverArtFor(w, i);
          final img = art.startsWith('http') ? NetworkImage(art) as ImageProvider : AssetImage(art);
          return GestureDetector(
            key: ValueKey('today-word-${w.key}'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              onOpen(w);
            },
            child: SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF15151C)),
                  Image(image: ResizeImage(img, width: 400), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => const SizedBox()),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xE6000000)], stops: [0.45, 1]),
                    ),
                  ),
                  DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: _hair))),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(w.word, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(lastDay(w), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Picks the hero photo: the account's own photo when it has one, else the
/// practice portrait the Profile's "Your practice mind" shows.
ImageProvider heroPhoto({String? path, String? url, required String practice}) {
  if (path != null && path.isNotEmpty && File(path).existsSync()) return ResizeImage(FileImage(File(path)), width: 900);
  if (url != null && url.startsWith('http')) return NetworkImage(url);
  return ResizeImage(AssetImage(practice), width: 900);
}

/// The pane the selected day's numbers sit in.
class ProgressDayPane extends StatelessWidget {
  const ProgressDayPane({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => GlassWrap(margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), radius: 22, child: child);
}

/// "Next up" pane: what to do now and the button that does it.
class ProgressNextUp extends StatelessWidget {
  const ProgressNextUp({super.key, required this.title, required this.line, this.action});
  final String title;
  final String line;
  final Widget? action;
  @override
  Widget build(BuildContext context) => GlassWrap(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        radius: 22,
        child: Row(children: [
          const SquareGlass(size: 44, radius: 14, child: NwsbIcon(GoalMarks.next, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Next up · $title', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35)),
            ]),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ]),
      );
}
