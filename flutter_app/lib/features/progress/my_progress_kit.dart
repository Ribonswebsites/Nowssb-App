/// My progress in the CliniQ layout Ribon sent (Nov 23), worn in NowssB's
/// own dark glass. The reference's white cards are glass panes, its navy
/// highlight is our solid white card, its icons sit in white circles.
///
///  * [MpHero]        the word you practised last: its poster fills a big
///                    rounded card, a level chip, the word as a two-line
///                    title and its sound and meaning as two tiny lines.
///  * [MpActionRow]   a Details pill and three white circles (Listen,
///                    Practice, Share).
///  * [MpStatStrip]   one glass strip: streak, practice time, words learnt.
///  * [MpMonthBar] / [MpDayTiles]  "Your days" with a month switcher and
///                    day tiles, the selected one filled.
///  * [MpHourRuler]   the chosen day's practice across the hours.
///  * [MpStartButton] the full-width Start session pill.
///  * [MpWordCarousel] tall poster cards of the words practised lately.
///  * [MpGoalsHeading] / [MpGoalGrid]  "Today's / goals", 2x2 cards with
///                    one lit (the next goal) and arrow buttons.
///
/// Every value comes from [PracticeProgress] / [ProgressCenter]; a new
/// account sees empty states, never sample numbers.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/app_haptics.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/practice_progress.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import 'progress_center.dart';
import 'progress_sources.dart';

const _muted = Color(0x99FFFFFF);
const _faint = Color(0x66FFFFFF);
const _hair = Color(0x24FFFFFF);
const _glassFill = Color(0x17FFFFFF);
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// Outlined marks for this page (24 box, stroked by [NwsbIcon]).
abstract final class MpMarks {
  static const heart = '<path d="M12 20s-7.5-4.5-7.5-10.2A4.3 4.3 0 0 1 12 7.2a4.3 4.3 0 0 1 7.5 2.6C19.5 15.5 12 20 12 20z"/>';
  static const listen = '<path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6"/><path d="M18.2 6.4a7.6 7.6 0 0 1 0 11.2"/>';
  static const practice = '<path d="M5 9v6"/><path d="M9 6v12"/><path d="M13 9v6"/><path d="M17 4v16"/><path d="M21 10v4"/>';
  static const share = '<path d="M12 3.5v11"/><path d="M8 7.5l4-4 4 4"/><path d="M5.5 12.5v5.5a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2v-5.5"/>';
  static const info = '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5.2"/><path d="M12 7.7v.1"/>';
  static const star = '<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"/>';
  static const left = '<path d="M14.5 6l-6 6 6 6"/>';
  static const right = '<path d="M9.5 6l6 6-6 6"/>';
  static const arrow = '<path d="M7 17L17 7"/><path d="M9 7h8v8"/>';
  static const swap = '<path d="M4 8h13"/><path d="M14 5l3 3-3 3"/><path d="M20 16H7"/><path d="M10 13l-3 3 3 3"/>';
  static const streak = '<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M8 3v4"/><path d="M16 3v4"/><path d="M8.5 13.5l2.4 2.4 4.6-4.8"/>';
  static const time = '<path d="M7 3.5h10"/><path d="M7 20.5h10"/><path d="M8 3.5c0 4 4 5 4 8.5s-4 4.5-4 8.5"/><path d="M16 3.5c0 4-4 5-4 8.5s4 4.5 4 8.5"/>';
  static const words = '<path d="M4 5.5a2 2 0 0 1 2-2h13v14H6a2 2 0 0 0-2 2z"/><path d="M4 19.5a2 2 0 0 0 2 2h13v-4"/><path d="M8.5 8h6.5"/>';
  static const checkin = '<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M8 3v4"/><path d="M16 3v4"/><path d="M8.5 13.5l2.4 2.4 4.6-4.8"/>';
}

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dayTitle(DateTime d, DateTime today) {
  final t = dateOnly(today);
  final x = dateOnly(d);
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

/// "AAROGYA" → "Aarogya".
String wordTitle(String w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase();

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
    for (final l in byDay.values) {
      l.sort((a, b) => (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0)));
    }
  }
  factory PracticeLog.now() => PracticeLog(PracticeProgress.instance.sessionsSnapshot);

  final Map<String, List<DaySession>> byDay = {};

  List<DaySession> on(DateTime d) => byDay[dayKey(d)] ?? const [];

  bool get isEmpty => byDay.isEmpty;

  /// The first month with practice, or null.
  DateTime? get firstDay {
    final k = (byDay.keys.toList()..sort()).firstOrNull;
    return k == null ? null : DateTime.tryParse(k);
  }

  static bool _real(String w) => w.isNotEmpty && w != 'Streak restore';

  /// Words finished most recently first, each once (restores left out).
  List<String> recentWords({int max = 10}) {
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final out = <String>[];
    for (final k in keys) {
      final day = [...byDay[k]!]..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
      for (final s in day) {
        if (!_real(s.word) || out.contains(s.word)) continue;
        out.add(s.word);
        if (out.length >= max) return out;
      }
    }
    return out;
  }

  /// How many times [word] was finished, its time and the last day.
  ({int times, int seconds, String? last}) of(String word) {
    var times = 0, secs = 0;
    String? last;
    for (final e in byDay.entries) {
      for (final s in e.value) {
        if (s.word != word) continue;
        times++;
        secs += s.seconds;
        if (last == null || e.key.compareTo(last) > 0) last = e.key;
      }
    }
    return (times: times, seconds: secs, last: last);
  }
}

Word? libraryWord(String name) {
  final n = name.trim().toLowerCase();
  for (final w in ContentStore.instance.library) {
    if (w.word.toLowerCase() == n || w.key.toLowerCase() == n) return w;
  }
  return null;
}

ImageProvider artImage(String art, {int width = 900}) {
  if (art.startsWith('http')) return ResizeImage(NetworkImage(art), width: width);
  return ResizeImage(AssetImage(art), width: width);
}

void _tap(VoidCallback? f) {
  if (f == null) return;
  AppHaptics.selection();
  f();
}

/// A round button: white disc with a black mark (the reference's white
/// circles), or a glass disc with a white mark.
class MpCircle extends StatelessWidget {
  const MpCircle({super.key, required this.mark, this.onTap, this.size = 46, this.white = true, this.semantics, this.markColor, this.fill});
  final String mark;
  final VoidCallback? onTap;
  final double size;
  final bool white;
  final String? semantics;
  final Color? markColor;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final bg = fill ?? (white ? Colors.white : const Color(0x33FFFFFF));
    final fg = markColor ?? (white ? Colors.black : Colors.white);
    return Semantics(
      button: onTap != null,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => _tap(onTap),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: white ? null : Border.all(color: const Color(0x40FFFFFF)),
            boxShadow: white ? const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))] : null,
          ),
          child: Center(child: NwsbIcon(mark, size: size * 0.42, color: fg, strokeWidth: 1.9)),
        ),
      ),
    );
  }
}

/// A frosted pane (our glass in place of the reference's white cards).
class MpGlass extends StatelessWidget {
  const MpGlass({super.key, required this.child, this.radius = 24, this.padding = EdgeInsets.zero, this.fill = _glassFill, this.blur = true});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color fill;
  final bool blur;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(color: fill, borderRadius: r, border: Border.all(color: _hair)),
      child: child,
    );
    return ClipRRect(
      borderRadius: r,
      child: blur ? BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: box) : box,
    );
  }
}

// ───────────────────────────── hero ─────────────────────────────

class MpHero extends StatelessWidget {
  const MpHero({
    super.key,
    required this.art,
    required this.title,
    required this.second,
    required this.lineA,
    required this.lineB,
    required this.chip,
    required this.liked,
    required this.onLike,
    this.onSwap,
  });

  final String art;
  final String title;
  final String second;
  final String lineA;
  final String lineB;
  final String chip;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final h = (box.maxWidth * 1.0).clamp(320.0, 430.0);
      return SizedBox(
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFF15151C)),
            Image(
              key: const ValueKey('mp-hero-art'),
              image: artImage(art),
              fit: BoxFit.cover,
              alignment: const Alignment(0.45, 0.2),
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
            // Shade from the left so the title reads, as the reference's
            // soft backdrop does behind its name.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xE6000000), Color(0x99000000), Color(0x00000000)],
                  stops: [0, 0.42, 0.78],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000), Color(0x00000000), Color(0x99000000)],
                  stops: [0, 0.22, 0.7, 1],
                ),
              ),
            ),
            DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), border: Border.all(color: _hair))),
            if (onSwap != null)
              Positioned(
                left: 14,
                top: 14,
                child: MpCircle(key: const ValueKey('mp-hero-swap'), mark: MpMarks.swap, white: false, size: 42, semantics: 'Another word', onTap: onSwap),
              ),
            Positioned(
              right: 14,
              top: 14,
              child: MpCircle(
                key: const ValueKey('mp-hero-like'),
                mark: MpMarks.heart,
                size: 42,
                semantics: liked ? 'Saved' : 'Save word',
                markColor: liked ? Colors.black : Colors.black,
                fill: liked ? NwsbColors.goldLight : Colors.white,
                onTap: onLike,
              ),
            ),
            Positioned(
              left: 20,
              bottom: 24,
              width: math.min(box.maxWidth * 0.6, 260),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                _StarChip(key: const ValueKey('mp-hero-chip'), text: chip),
                const SizedBox(height: 14),
                _Fit(Text(title, key: const ValueKey('mp-hero-title'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500, height: 1.08, letterSpacing: -0.6))),
                if (second.isNotEmpty)
                  _Fit(Text(second, key: const ValueKey('mp-hero-second'), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w500, height: 1.08, letterSpacing: -0.6))),
                const SizedBox(height: 10),
                if (lineA.isNotEmpty) Text(lineA, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35)),
                if (lineB.isNotEmpty) Text(lineB, key: const ValueKey('mp-hero-meaning'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35)),
              ]),
            ),
          ]),
        ),
      );
    });
  }
}

class _Fit extends StatelessWidget {
  const _Fit(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child),
      );
}

class _StarChip extends StatelessWidget {
  const _StarChip({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x40FFFFFF))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const NwsbIcon(MpMarks.star, size: 14, color: NwsbColors.goldLight, strokeWidth: 2),
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

// ───────────────────────────── action row ─────────────────────────────

class MpActionRow extends StatelessWidget {
  const MpActionRow({super.key, required this.onDetails, required this.onListen, required this.onPractice, required this.onShare, this.listening = false});
  final VoidCallback onDetails;
  final VoidCallback onListen;
  final VoidCallback onPractice;
  final VoidCallback onShare;
  final bool listening;

  @override
  Widget build(BuildContext context) => Row(children: [
        Semantics(
          button: true,
          child: GestureDetector(
            key: const ValueKey('today-details'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tap(onDetails),
            child: const MpGlass(
              radius: 24,
              padding: EdgeInsets.fromLTRB(14, 0, 18, 0),
              child: SizedBox(
                height: 46,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  NwsbIcon(MpMarks.info, size: 18, strokeWidth: 1.9),
                  SizedBox(width: 8),
                  Text('Details', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ),
        const Spacer(),
        MpCircle(key: const ValueKey('mp-listen'), mark: MpMarks.listen, semantics: 'Listen', fill: listening ? NwsbColors.goldLight : null, onTap: onListen),
        const SizedBox(width: 10),
        MpCircle(key: const ValueKey('mp-practice'), mark: MpMarks.practice, semantics: 'Practice', onTap: onPractice),
        const SizedBox(width: 10),
        MpCircle(key: const ValueKey('mp-share'), mark: MpMarks.share, semantics: 'Share', onTap: onShare),
      ]);
}

// ───────────────────────────── stats ─────────────────────────────

class MpStatStrip extends StatelessWidget {
  const MpStatStrip({super.key, required this.streak, required this.time, required this.words});
  final int streak;
  final String time;
  final int words;

  @override
  Widget build(BuildContext context) {
    Widget cell(String key, String mark, String value, String l1, String l2) => Expanded(
          child: Row(key: ValueKey(key), children: [
            NwsbIcon(mark, size: 24, color: Colors.white, strokeWidth: 1.5),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                _Fit(Text(value, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1))),
                const SizedBox(height: 2),
                Text(l1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.2)),
                Text(l2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 10.5, height: 1.2)),
              ]),
            ),
          ]),
        );
    Widget rule() => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 8), color: _hair);
    return MpGlass(
      key: const ValueKey('mp-stats'),
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(children: [
        cell('today-stat-streak', MpMarks.streak, '$streak', streak == 1 ? 'Day' : 'Days', 'Streak'),
        rule(),
        cell('today-stat-time', MpMarks.time, time, 'Practice', 'Time'),
        rule(),
        cell('today-stat-words', MpMarks.words, '$words', words == 1 ? 'Word' : 'Words', 'Learnt'),
      ]),
    );
  }
}

// ───────────────────────────── days ─────────────────────────────

/// "Your days" on the left, "< November >" on the right.
class MpMonthBar extends StatelessWidget {
  const MpMonthBar({super.key, required this.title, required this.month, this.onPrev, this.onNext});
  final String title;
  final DateTime month;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  static String label(DateTime d, DateTime now) => d.year == now.year ? _monthsLong[d.month - 1] : '${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    Widget chev(String key, String mark, VoidCallback? f) => Semantics(
          button: true,
          child: GestureDetector(
            key: ValueKey(key),
            behavior: HitTestBehavior.opaque,
            onTap: f == null ? null : () => _tap(f),
            child: SizedBox(width: 30, height: 30, child: Center(child: NwsbIcon(mark, size: 16, color: f == null ? const Color(0x40FFFFFF) : Colors.white, strokeWidth: 2.2))),
          ),
        );
    return Row(children: [
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
      chev('mp-month-prev', MpMarks.left, onPrev),
      Text(label(month, DateTime.now()), key: const ValueKey('mp-month-label'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      chev('mp-month-next', MpMarks.right, onNext),
    ]);
  }
}

/// The days of one month, four across; the selected one is filled white.
class MpDayTiles extends StatefulWidget {
  const MpDayTiles({super.key, required this.month, required this.today, required this.selected, required this.practised, required this.onPick});
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final bool Function(DateTime d) practised;
  final ValueChanged<DateTime> onPick;

  @override
  State<MpDayTiles> createState() => _MpDayTilesState();
}

class _MpDayTilesState extends State<MpDayTiles> {
  static const _gap = 10.0;
  ScrollController? _ctrl;
  double _tileW = 80;

  int get _last {
    final t = dateOnly(widget.today), m = widget.month;
    return m.year == t.year && m.month == t.month ? t.day : DateTime(m.year, m.month + 1, 0).day;
  }

  /// Offset that keeps the selected day in view (latest day at the right).
  double _offsetFor(double tileW) {
    final i = _last - widget.selected.day;
    return math.max(0, i - 3) * (tileW + _gap);
  }

  @override
  void didUpdateWidget(MpDayTiles old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) {
      _ctrl?.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = dateOnly(widget.today);
    final month = widget.month;
    final last = _last;
    return LayoutBuilder(builder: (context, box) {
      _tileW = (box.maxWidth - _gap * 3) / 4;
      final w = _tileW;
      _ctrl ??= ScrollController(initialScrollOffset: _offsetFor(w));
      return SizedBox(
        height: 78,
        child: ListView.separated(
          key: ValueKey('today-day-strip-${month.year}-${month.month}'),
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          reverse: true, // the latest day sits at the right; earlier days scroll in
          itemCount: last,
          separatorBuilder: (_, __) => const SizedBox(width: _gap),
          itemBuilder: (context, i) {
            final d = DateTime(month.year, month.month, last - i);
            final on = dayKey(d) == dayKey(widget.selected);
            final did = widget.practised(d);
            return GestureDetector(
              key: ValueKey('today-day-${dayKey(d)}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(() => widget.onPick(d)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w,
                decoration: BoxDecoration(
                  color: on ? Colors.white : _glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? Colors.white : _hair),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${d.day}', style: TextStyle(color: on ? Colors.black : Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _FitC(Text(dayKey(d) == dayKey(t) ? 'Today' : _weekdaysLong[d.weekday - 1],
                        style: TextStyle(color: on ? const Color(0x99000000) : _muted, fontSize: 11, fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(color: did ? (on ? NwsbColors.gold : NwsbColors.goldLight) : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                  ),
                ]),
              ),
            );
          },
        ),
      );
    });
  }
}

class _FitC extends StatelessWidget {
  const _FitC(this.child);
  final Widget child;
  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, child: child);
}

// ───────────────────────────── hour ruler ─────────────────────────────

/// Thin ticks every 15 minutes across the day, gold where words were
/// finished, a white bar over the hour being read. Tap or drag to read.
class MpHourRuler extends StatelessWidget {
  const MpHourRuler({super.key, required this.sessions, required this.hour, required this.onHour});
  final List<DaySession> sessions;
  final int hour;
  final ValueChanged<int> onHour;

  @override
  Widget build(BuildContext context) {
    final quarters = <int>{for (final s in sessions) if (s.at != null) s.at!.hour * 4 + s.at!.minute ~/ 15};
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      int at(double dx) => ((dx / w) * 24).floor().clamp(0, 23);
      return GestureDetector(
        key: const ValueKey('today-tick-scale'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _tap(() => onHour(at(d.localPosition.dx))),
        onHorizontalDragUpdate: (d) {
          final h = at(d.localPosition.dx);
          if (h != hour) onHour(h);
        },
        child: SizedBox(
          height: 66,
          width: w,
          child: CustomPaint(painter: _RulerPainter(quarters: quarters, hour: hour, font: DefaultTextStyle.of(context).style.fontFamily)),
        ),
      );
    });
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.quarters, required this.hour, this.font});
  final Set<int> quarters;
  final int hour;
  final String? font;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 14.0, base = 42.0;
    final step = size.width / 96;
    final p = Paint()..strokeCap = StrokeCap.round;
    // The read hour: a short bar above the ticks (the reference's teal mark).
    final x0 = hour * 4 * step, x1 = (hour + 1) * 4 * step;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x0 + 1, 2, x1 - 1, 8), const Radius.circular(3)), Paint()..color = Colors.white);
    for (var i = 0; i <= 96; i++) {
      final x = (i * step + step / 2).clamp(1.0, size.width - 1);
      if (i == 96) break;
      final hit = quarters.contains(i);
      final inHour = i ~/ 4 == hour;
      final major = i % 24 == 0;
      p
        ..color = hit ? NwsbColors.goldLight : (inHour ? Colors.white : (major ? const Color(0x99FFFFFF) : const Color(0x47FFFFFF)))
        ..strokeWidth = hit ? 2.4 : 1.2;
      canvas.drawLine(Offset(x, hit ? top - 2 : (major ? top : top + 6)), Offset(x, base), p);
    }
    const labels = ['12 AM', '6 AM', '12 PM', '6 PM', '12 AM'];
    for (var k = 0; k < labels.length; k++) {
      final x = k * 24 * step;
      final tp = TextPainter(
        text: TextSpan(text: labels[k], style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600, fontFamily: font)),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(lx, base + 8));
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.hour != hour || old.quarters.length != quarters.length || !old.quarters.containsAll(quarters);
}

// ───────────────────────────── start ─────────────────────────────

class MpStartButton extends StatelessWidget {
  const MpStartButton({super.key, required this.onTap, this.label = 'Start session'});
  final VoidCallback onTap;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          key: const ValueKey('today-start-session'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(onTap),
          child: Container(
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(29),
              boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 22, offset: Offset(0, 10))],
            ),
            child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.1)),
          ),
        ),
      );
}

// ───────────────────────────── words carousel ─────────────────────────────

class MpWordCarousel extends StatelessWidget {
  const MpWordCarousel({super.key, required this.words, required this.artFor, required this.lineFor, required this.chipFor, required this.onOpen});
  final List<Word> words;
  final String Function(Word w, int i) artFor;
  final String Function(Word w) lineFor;
  final String Function(Word w) chipFor;
  final ValueChanged<Word> onOpen;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: MpGlass(
          key: ValueKey('today-words-empty'),
          radius: 24,
          padding: EdgeInsets.all(16),
          child: Row(children: [
            MpCircle(mark: MpMarks.words, size: 42),
            SizedBox(width: 12),
            Expanded(
              child: Text('Words you finish in the player show up here, newest first.', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.35)),
            ),
          ]),
        ),
      );
    }
    return LayoutBuilder(builder: (context, box) {
      final cw = math.min(250.0, box.maxWidth * 0.62);
      final ch = (cw * 1.32).roundToDouble();
      return SizedBox(
        height: ch,
        child: ListView.separated(
          key: const ValueKey('today-words'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final w = words[i];
            return GestureDetector(
              key: ValueKey('today-word-${w.key}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(() => onOpen(w)),
              child: SizedBox(
                width: cw,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(fit: StackFit.expand, children: [
                    const ColoredBox(color: Color(0xFF15151C)),
                    Image(image: artImage(artFor(w, i), width: 600), fit: BoxFit.cover, alignment: const Alignment(0.2, 0.3), errorBuilder: (_, __, ___) => const SizedBox()),
                    DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: _hair))),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _SmallChip(text: chipFor(w)),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                            decoration: BoxDecoration(color: const Color(0x52000000), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x33FFFFFF))),
                            child: Row(children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                  _Fit(Text(wordTitle(w.word), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
                                  const SizedBox(height: 2),
                                  Text(lineFor(w), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5)),
                                ]),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                                child: const Center(child: NwsbIcon(MpMarks.arrow, size: 16, strokeWidth: 2)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
      decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x33FFFFFF))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const NwsbIcon(MpMarks.practice, size: 12, color: NwsbColors.goldLight, strokeWidth: 2),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ───────────────────────────── goals ─────────────────────────────

/// "Today's / goals" with the Details and Check-in circles at the right.
class MpGoalsHeading extends StatelessWidget {
  const MpGoalsHeading({super.key, required this.done, required this.total, required this.checkedIn, required this.onInfo, required this.onCheckIn, this.busy = false});
  final int done;
  final int total;
  final bool checkedIn;
  final bool busy;
  final VoidCallback onInfo;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const _Fit(Text('Today\u2019s', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500, height: 1.08, letterSpacing: -0.6))),
            const _Fit(Text('goals', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w500, height: 1.08, letterSpacing: -0.6))),
            const SizedBox(height: 6),
            Text('$done of $total goals done', key: const ValueKey('today-goals-done'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        MpCircle(key: const ValueKey('today-goals-info'), mark: MpMarks.info, semantics: 'Progress details', onTap: onInfo),
        const SizedBox(width: 10),
        Opacity(
          opacity: busy ? 0.5 : 1,
          child: MpCircle(
            key: const ValueKey('today-action-checkin'),
            mark: MpMarks.checkin,
            semantics: checkedIn ? 'Checked in' : 'Check in',
            fill: checkedIn ? NwsbColors.goldLight : Colors.white,
            onTap: checkedIn || busy ? null : onCheckIn,
          ),
        ),
      ]);
}

class MpGoalGrid extends StatelessWidget {
  const MpGoalGrid({super.key, required this.items, required this.lit, required this.onOpen, required this.markFor});
  final List<ProgressItem> items;
  final ProgressKind? lit;
  final void Function(ProgressKind k) onOpen;
  final String Function(ProgressKind k) markFor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth >= 600 ? 4 : 2;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final it in items)
            SizedBox(width: w, height: 168, child: _GoalCard(item: it, lit: it.kind == lit, mark: markFor(it.kind), onOpen: () => onOpen(it.kind))),
        ]);
      });
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({required this.item, required this.lit, required this.mark, required this.onOpen});
  final ProgressItem item;
  final bool lit;
  final String mark;
  final VoidCallback onOpen;
  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  var _down = false;
  @override
  Widget build(BuildContext context) {
    final it = widget.item, lit = widget.lit;
    final fg = lit ? Colors.black : Colors.white;
    final sub = lit ? const Color(0x99000000) : _muted;
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w600, height: 1.15)),
        const SizedBox(height: 6),
        Text(ProgressSources.nextStep(it), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: sub, fontSize: 11, height: 1.3)),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${it.done.clamp(0, it.total)}/${it.total}', style: TextStyle(color: it.complete && !lit ? NwsbColors.goldLight : fg, fontSize: 18, fontWeight: FontWeight.w800)),
                TextSpan(text: it.complete ? '  done' : '  today', style: TextStyle(color: sub, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              key: ValueKey('today-count-${it.kind.name}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            button: true,
            label: 'Open ${it.title}',
            child: GestureDetector(
              key: ValueKey('today-arrow-${it.kind.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(widget.onOpen),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: lit ? Colors.black : Colors.white, shape: BoxShape.circle),
                child: Center(child: NwsbIcon(MpMarks.arrow, size: 16, color: lit ? Colors.white : Colors.black, strokeWidth: 2)),
              ),
            ),
          ),
        ]),
      ]),
    );
    return GestureDetector(
      key: ValueKey('today-goal-${it.kind.name}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => _tap(widget.onOpen),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: lit
            ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)), child: body)
            : MpGlass(radius: 26, child: body),
      ),
    );
  }
}

// ───────────────────────────── sheet ─────────────────────────────

/// A glass bottom sheet of label / value rows. Closes on an outside tap, a
/// swipe down or back (it is a plain modal bottom sheet).
class MpSheet extends StatelessWidget {
  const MpSheet({super.key, required this.title, required this.rows, this.note});
  final String title;
  final List<(String, String)> rows;
  final String? note;

  static Future<void> show(BuildContext context, {required String title, required List<(String, String)> rows, String? note}) => showModalBottomSheet<void>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x99000000),
        builder: (_) => MpSheet(title: title, rows: rows, note: note),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRRect(
      key: const ValueKey('mp-sheet'),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
          decoration: const BoxDecoration(
            color: Color(0xD90E0E14),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _faint, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              if (note != null && note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(note!, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
              ],
              const SizedBox(height: 12),
              for (final r in rows)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _hair))),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 120, child: Text(r.$1, style: const TextStyle(color: _muted, fontSize: 13))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.$2, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.35))),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Section label used between blocks ("Your days", "Words you practised").
class MpLabel extends StatelessWidget {
  const MpLabel(this.text, {super.key, this.trailing});
  final String text;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(trailing!, key: const ValueKey('today-hour-readout'), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ]);
}
