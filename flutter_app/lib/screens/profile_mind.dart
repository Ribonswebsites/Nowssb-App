/// Profile > "Your practice mind": the cognitive-cards layout from Ribon's
/// reference, rebuilt in the two Editeaze styles (orange-box cards and the
/// two-photo strip). Every number is the user's own practice record from
/// [PracticeProgress]; nothing is estimated, and nothing here is a brain or
/// medical measurement. With no sessions yet it says so.
///
/// Each time the section is opened it picks a fresh, harmonious palette so
/// the Focus, Rhythm, This week and Practise-now tiles don't share one
/// colour, and never repeats the palette used on the previous open. Each
/// palette carries its own Focus today portrait (one distinct person per
/// palette), so the photo changes together with the colours and crossfades
/// in over the same 600ms easeInOutCubic.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/practice_progress.dart';
import '../widgets/editeaze.dart';

/// NowssB gold (tokens: gold C8A96E, profile accent E3BD7D), deepened so
/// white type reads on it. Kept as a fallback / first-frame colour.
const kMindGold = Color(0xFFB8924F);

/// SharedPreferences key for the last [kMindPalettes] index shown.
const kMindPalettePrefKey = 'nwsb_mind_palette_index';

/// Decode width shared by [Image.asset] and the precache so the cached
/// frame is reused (no flash when the next portrait fades in).
const _kMindPhotoCacheWidth = 800;

ImageProvider mindPhotoProvider(String asset) =>
    ResizeImage(AssetImage(asset), width: _kMindPhotoCacheWidth);

/// One harmonious set of shades for the section. Focus, Rhythm, This week
/// and the photo-strip tile each get a different shade, with a lighter
/// [accent] for the plan-progress ring. All body colours keep white type
/// at least 4.5:1 contrast.
class MindPalette {
  const MindPalette({
    required this.id,
    required this.focus,
    required this.rhythm,
    required this.week,
    required this.tile,
    required this.accent,
    required this.image,
  });

  final String id;
  final Color focus, rhythm, week, tile, accent;

  /// The Focus today portrait paired with this palette. Unique per palette.
  final String image;

  static MindPalette lerp(MindPalette a, MindPalette b, double t) =>
      MindPalette(
        id: t < 0.5 ? a.id : b.id,
        focus: Color.lerp(a.focus, b.focus, t)!,
        rhythm: Color.lerp(a.rhythm, b.rhythm, t)!,
        week: Color.lerp(a.week, b.week, t)!,
        tile: Color.lerp(a.tile, b.tile, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        image: t < 0.5 ? a.image : b.image,
      );
}

/// Curated premium palettes. Order is stable; indices are what we persist.
const kMindPalettes = <MindPalette>[
  MindPalette(
    id: 'sage',
    focus: Color(0xFF3F6A54),
    rhythm: Color(0xFF547A64),
    week: Color(0xFF2F5644),
    tile: Color(0xFF4A7360),
    accent: Color(0xFFB7D4C4),
    image: 'assets/home/ez/ez-med-focus.webp',
  ),
  MindPalette(
    id: 'dustyRose',
    focus: Color(0xFF8A4554),
    rhythm: Color(0xFF9B5866),
    week: Color(0xFF733A47),
    tile: Color(0xFFA05F6C),
    accent: Color(0xFFE4B7BF),
    image: 'assets/home/ez/ez-med-focus-dustyrose.webp',
  ),
  MindPalette(
    id: 'slateBlue',
    focus: Color(0xFF3A5678),
    rhythm: Color(0xFF4A6890),
    week: Color(0xFF2E4664),
    tile: Color(0xFF557398),
    accent: Color(0xFFB7C8DC),
    image: 'assets/home/ez/ez-med-focus-slateblue.webp',
  ),
  MindPalette(
    id: 'terracotta',
    focus: Color(0xFFA04A32),
    rhythm: Color(0xFFB45C42),
    week: Color(0xFF8A3E2A),
    tile: Color(0xFFA8543E),
    accent: Color(0xFFE8C0B0),
    image: 'assets/home/ez/ez-med-focus-terracotta.webp',
  ),
  MindPalette(
    id: 'lavender',
    focus: Color(0xFF5A4A78),
    rhythm: Color(0xFF6C5A8C),
    week: Color(0xFF4A3C66),
    tile: Color(0xFF7A68A0),
    accent: Color(0xFFD0C4E4),
    image: 'assets/home/ez/ez-med-focus-lavender.webp',
  ),
  MindPalette(
    id: 'teal',
    focus: Color(0xFF216666),
    rhythm: Color(0xFF2D7A7A),
    week: Color(0xFF1A5454),
    tile: Color(0xFF2A7474),
    accent: Color(0xFFA8D4D4),
    image: 'assets/home/ez/ez-med-focus-teal.webp',
  ),
  MindPalette(
    id: 'sand',
    focus: Color(0xFF7A5A34),
    rhythm: Color(0xFF8A6A40),
    week: Color(0xFF5A3E24),
    tile: Color(0xFF6A4C2C),
    accent: Color(0xFFE6D2B4),
    image: 'assets/home/ez/ez-med-focus-sand.webp',
  ),
  MindPalette(
    id: 'plum',
    focus: Color(0xFF6A3558),
    rhythm: Color(0xFF7C4468),
    week: Color(0xFF582A48),
    tile: Color(0xFF8A4E74),
    accent: Color(0xFFDDB4C8),
    image: 'assets/home/ez/ez-med-focus-plum.webp',
  ),
  MindPalette(
    id: 'olive',
    focus: Color(0xFF5A6434),
    rhythm: Color(0xFF6C7642),
    week: Color(0xFF4A5428),
    tile: Color(0xFF64703C),
    accent: Color(0xFFD0D8A8),
    image: 'assets/home/ez/ez-med-focus-olive.webp',
  ),
  MindPalette(
    id: 'rust',
    focus: Color(0xFF8A4030),
    rhythm: Color(0xFF9C5240),
    week: Color(0xFF743428),
    tile: Color(0xFFA85A46),
    accent: Color(0xFFE8B8A8),
    image: 'assets/home/ez/ez-med-focus-rust.webp',
  ),
  MindPalette(
    id: 'ocean',
    focus: Color(0xFF2F5568),
    rhythm: Color(0xFF3C6780),
    week: Color(0xFF254656),
    tile: Color(0xFF4A738C),
    accent: Color(0xFFB0D0DC),
    image: 'assets/home/ez/ez-med-focus-ocean.webp',
  ),
  MindPalette(
    id: 'wine',
    focus: Color(0xFF6E2E3A),
    rhythm: Color(0xFF82404C),
    week: Color(0xFF5A242E),
    tile: Color(0xFF8E4A56),
    accent: Color(0xFFE0B4BA),
    image: 'assets/home/ez/ez-med-focus-wine.webp',
  ),
];

const _kMindOpenFrom = MindPalette(
  id: 'open',
  focus: Color(0xFF2C2A28),
  rhythm: Color(0xFF2C2A28),
  week: Color(0xFF2C2A28),
  tile: Color(0xFF2C2A28),
  accent: Color(0xFFE3BD7D),
  image: '',
);

/// Picks a palette index that is never [last] when [last] is in range.
/// [nextInt] is `Random.nextInt` (exclusive upper bound).
int pickMindPaletteIndex({
  required int last,
  required int length,
  required int Function(int maxExclusive) nextInt,
}) {
  if (length <= 1) return 0;
  if (last < 0 || last >= length) return nextInt(length);
  var i = nextInt(length - 1);
  if (i >= last) i++;
  return i;
}

/// Real numbers for the section, computed from session records.
class MindStats {
  MindStats.from(PracticeProgress p)
      : total = p.totalSessions,
        today = p.todaySessions,
        goal = PracticeProgress.dailyPracticeGoal,
        streak = p.streak,
        minutes = p.totalMinutes,
        words = p.uniqueWords,
        byPart = _parts(p.sessionsSnapshot),
        week = _week(p);

  final int total, today, goal, streak, minutes, words;

  /// Sessions started in the morning, afternoon, evening and night.
  final List<int> byPart;

  /// Sessions on each of the last 7 days, oldest first.
  final List<int> week;

  /// Today's sessions against the daily plan, 0..100.
  int get focusPercent =>
      goal <= 0 ? 0 : ((today.clamp(0, goal) / goal) * 100).round();

  static List<int> _parts(List<Map<String, dynamic>> s) {
    final out = [0, 0, 0, 0];
    for (final x in s) {
      final t = DateTime.tryParse('${x['completedAt'] ?? ''}')?.toLocal();
      if (t == null) continue;
      final h = t.hour;
      out[h >= 5 && h < 12
          ? 0
          : h >= 12 && h < 17
              ? 1
              : h >= 17 && h < 21
                  ? 2
                  : 3]++;
    }
    return out;
  }

  static List<int> _week(PracticeProgress p) {
    final now = DateTime.now();
    String day(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final counts = <String, int>{};
    for (final x in p.sessionsSnapshot) {
      final d = '${x['date'] ?? ''}';
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return [
      for (var i = 6; i >= 0; i--)
        counts[day(DateTime(now.year, now.month, now.day - i))] ?? 0,
    ];
  }
}

class ProfileMind extends StatefulWidget {
  const ProfileMind({
    super.key,
    this.onPractice,
    this.onProgress,
    this.paletteIndex,
    this.random,
  });
  final VoidCallback? onPractice;
  final VoidCallback? onProgress;

  /// When set, skip the random pick and use this [kMindPalettes] index
  /// (tests and screenshots). The colour animation is skipped.
  final int? paletteIndex;

  /// Injected for tests; production uses [math.Random].
  final math.Random? random;

  @override
  State<ProfileMind> createState() => _ProfileMindState();
}

class _ProfileMindState extends State<ProfileMind>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _t;
  MindPalette _from = _kMindOpenFrom;
  MindPalette _to = kMindPalettes.first;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _t = CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);
    final forced = widget.paletteIndex;
    if (forced != null) {
      _to = kMindPalettes[forced.clamp(0, kMindPalettes.length - 1)];
      _from = _to;
      _anim.value = 1;
    } else {
      _load();
    }
  }

  /// The palette for the next open, picked (and its portrait decoded) while
  /// this one is on screen, so the next person is already in the image
  /// cache when the section opens again and fades in without a flash. Only
  /// used with the production random source; tests inject their own.
  static int? _queued;

  Future<void> _load() async {
    var last = -1;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      last = prefs.getInt(kMindPalettePrefKey) ?? -1;
    } catch (_) {}
    final rng = widget.random ?? math.Random();
    final q = widget.random == null ? _queued : null;
    final idx = (q != null && q >= 0 && q < kMindPalettes.length && q != last)
        ? q
        : pickMindPaletteIndex(
            last: last,
            length: kMindPalettes.length,
            nextInt: rng.nextInt,
          );
    try {
      await prefs?.setInt(kMindPalettePrefKey, idx);
    } catch (_) {}
    if (!mounted) return;
    // Start decoding this open's portrait now (a no-op when it was queued
    // and precached on the previous open).
    _precache(kMindPalettes[idx].image);
    setState(() {
      _from = (last >= 0 && last < kMindPalettes.length)
          ? kMindPalettes[last]
          : _kMindOpenFrom;
      _to = kMindPalettes[idx];
    });
    _anim.forward(from: 0);
    // Queue and precache the next open's person (never this one).
    if (widget.random == null) {
      final next = pickMindPaletteIndex(
        last: idx,
        length: kMindPalettes.length,
        nextInt: rng.nextInt,
      );
      _queued = next;
      _precache(kMindPalettes[next].image);
    }
  }

  void _precache(String asset) {
    if (!mounted) return;
    precacheImage(
      mindPhotoProvider(asset),
      context,
      onError: (_, __) {},
    ).catchError((_) {});
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PracticeProgress.instance,
        builder: (context, _) {
          final m = MindStats.from(PracticeProgress.instance);
          return AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              final pal = MindPalette.lerp(_from, _to, _t.value);
              return Column(
                key: const ValueKey('profile-mind'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      'Your practice mind',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (m.total == 0) _empty(pal) else ..._cards(m, pal),
                ],
              );
            },
          );
        },
      );

  /// The portrait, crossfading from the previous palette's person to this
  /// one's on the same eased 600ms timeline as the colours.
  Widget _photo(Alignment alignment) {
    final t = _t.value;
    Widget img(String a, double o, String k) => Opacity(
          key: ValueKey('mind-photo-$k'),
          opacity: o.clamp(0.0, 1.0),
          child: Image(
            image: mindPhotoProvider(a),
            fit: BoxFit.cover,
            alignment: alignment,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
    final showFrom =
        _from.image.isNotEmpty && _from.image != _to.image && t < 1;
    // The incoming portrait sits underneath at full strength and the
    // outgoing one fades off on top, so there is no dip to the card colour
    // mid-way. On the very first open there is no previous person, so the
    // portrait simply fades in.
    return Stack(
      fit: StackFit.expand,
      children: [
        img(_to.image, _from.image.isEmpty ? t : 1, 'to'),
        if (showFrom) img(_from.image, 1 - t, 'from'),
      ],
    );
  }

  Widget _empty(MindPalette pal) => EzOrangeCard(
        key: const ValueKey('mind-empty'),
        color: pal.focus,
        headerFade: false,
        title: 'Practice once to see this',
        subtitle: 'Your rhythm, focus and streak appear after a session',
        image: _to.image,
        alignment: const Alignment(0, -.2),
        height: 220,
        icons: [
          EzIcon(
            Icons.play_arrow_rounded,
            label: 'Practise now',
            onTap: widget.onPractice,
          ),
        ],
        onTap: widget.onPractice,
        child: _photo(const Alignment(0, -.2)),
      );

  List<Widget> _cards(MindStats m, MindPalette pal) {
    const parts = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final best = m.byPart.reduce(math.max);
    final bestPart = best == 0 ? null : parts[m.byPart.indexOf(best)];
    return [
      // Focus: today's sessions against the daily plan.
      EzOrangeCard(
        key: const ValueKey('mind-focus'),
        color: pal.focus,
        headerFade: false,
        title: 'Focus today',
        // Pill sits level with the % gauge, under the portrait's face.
        commentBottom: .06,
        subtitle: '${m.today} of ${m.goal} planned sessions',
        height: 230,
        icons: [
          EzIcon(
            Icons.insights_rounded,
            label: 'See progress',
            onTap: widget.onProgress,
          ),
        ],
        comment: EzComment(
          name: '${m.streak} day streak',
          text: '${m.minutes} min · ${m.words} words practised',
          icon: Icons.local_fire_department_rounded,
        ),
        onTap: widget.onProgress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _photo(const Alignment(0, -.25)),
            Positioned(
              right: 14,
              bottom: 14,
              child: _Ring(percent: m.focusPercent, accent: pal.accent),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // Rhythm + load, the reference's curve and wave cards.
      Row(
        children: [
          Expanded(
            child: EzOrangeCard(
              key: const ValueKey('mind-rhythm'),
              color: pal.rhythm,
              headerFade: false,
              title: 'Rhythm',
              subtitle:
                  bestPart == null ? 'No times recorded' : 'Mostly $bestPart',
              height: 150,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: _Graph(
                  values: m.byPart,
                  labels: const ['AM', 'PM', 'Eve', 'Night'],
                  curve: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: EzOrangeCard(
              key: const ValueKey('mind-week'),
              color: pal.week,
              headerFade: false,
              title: 'This week',
              subtitle:
                  '${m.week.fold<int>(0, (a, b) => a + b)} sessions in 7 days',
              height: 150,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: _Graph(
                  values: m.week,
                  labels: const ['', '', '', '', '', '', 'Today'],
                  curve: false,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      // Two-photo strip: morning vs evening practice, counted.
      EzSplitStrip(
        key: const ValueKey('mind-strip'),
        tileColor: pal.tile,
        left: EzTile(
          image: 'assets/home/ez/ez-med-beach.webp',
          label: 'Morning · ${m.byPart[0]}',
          alignment: const Alignment(0, .2),
          onTap: widget.onProgress,
        ),
        right: EzTile(
          image: 'assets/home/ez/ez-med-candle.webp',
          label: 'Evening · ${m.byPart[2] + m.byPart[3]}',
          onTap: widget.onProgress,
        ),
        addLabel: 'Practise now',
        addIcon: Icons.play_arrow_rounded,
        onAdd: widget.onPractice,
      ),
    ];
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.percent, required this.accent});
  final int percent;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(color: kEzPill, shape: BoxShape.circle),
        child: CustomPaint(
          painter: _RingPainter(percent / 100, accent),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'of plan',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f, this.accent);
  final double f;
  final Color accent;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawArc(
      r.deflate(7),
      0,
      math.pi * 2,
      false,
      p..color = const Color(0x26FFFFFF),
    );
    if (f > 0) {
      c.drawArc(
        r.deflate(7),
        -math.pi / 2,
        math.pi * 2 * f.clamp(0, 1),
        false,
        p..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.f != f || o.accent != accent;
}

class _Graph extends StatelessWidget {
  const _Graph({
    required this.values,
    required this.labels,
    required this.curve,
  });
  final List<int> values;
  final List<String> labels;
  final bool curve;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _GraphPainter(values, curve),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in labels)
                Text(
                  l,
                  style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 9),
                ),
            ],
          ),
        ],
      );
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.v, this.curve);
  final List<int> v;
  final bool curve;
  @override
  void paint(Canvas c, Size s) {
    if (v.isEmpty) return;
    final top = math.max(1, v.reduce(math.max));
    final pts = [
      for (var i = 0; i < v.length; i++)
        Offset(
          v.length == 1 ? s.width / 2 : s.width * i / (v.length - 1),
          s.height - 4 - (s.height - 10) * v[i] / top,
        ),
    ];
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (curve) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        final mx = (a.dx + b.dx) / 2;
        path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
      }
      c.drawPath(path, line);
      for (final p in pts) {
        c.drawCircle(p, 3, Paint()..color = Colors.white);
      }
    } else {
      final w = math.min(10.0, s.width / v.length * .5);
      for (final p in pts) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(p.dx - w / 2, p.dy, p.dx + w / 2, s.height),
            const Radius.circular(4),
          ),
          Paint()
            ..color =
                p.dy >= s.height - 4.5 ? const Color(0x40FFFFFF) : Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GraphPainter o) =>
      o.v.toString() != v.toString() || o.curve != curve;
}
