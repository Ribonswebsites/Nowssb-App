/// R27 (Ribon 10-27) — shared kit for the Rewards / Gifts / Earn / Coupons
/// sections, their pages, and the video replacements.
///
/// Language: poster word card (giant Anton word), torn tile, Hero poster.
/// Type: Anton ONLY for giant poster words; every other line is one of the
/// three DM Sans greeting styles (19 w300 hello, 26 w800 title, 12.5 sub).
/// Backgrounds are black (no purple). Imagery: text-free hour posters.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../normal/surface.dart';

// ── Colour ────────────────────────────────────────────────────────────────
const r27Black = Color(0xFF000000);
const r27Coal = Color(0xFF0E0E10);
const r27Line = Color(0x29FFFFFF);
const r27Gold = Color(0xFFD9A441);
const r27Paper = Color(0xFFF1E9DA);
const r27PaperInk = Color(0xFF16130F);

// ── Type (DM Sans greeting styles, light-on-dark variants) ───────────────
/// 19 / w300 — "Good Evening" on black (13.6:1).
const dHello = TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: Color(0xD1FFFFFF), height: 1.2);
/// 26 / w800 — "Healer" on black.
const dTitle = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1);
/// 12.5 — subline on black (12.9:1).
const dSub = TextStyle(fontSize: 12.5, color: Color(0xCCFFFFFF), height: 1.35);
/// 12.5 / w700 gold — link line on black (9.1:1).
const dLink = TextStyle(fontSize: 12.5, color: r27Gold, fontWeight: FontWeight.w700, height: 1.35);
/// 12.5 / w800 tag (gold tag label from the torn-tile flow).
const r27Tag = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: r27PaperInk, height: 1.2);
/// Giant poster words only.
const r27Anton = TextStyle(fontFamily: 'Anton', height: .92, color: Colors.white);

// ── Imagery ───────────────────────────────────────────────────────────────
/// The twelve hour words (assets/content/library.json) and their text-free
/// posters, bundled at assets/home/hour-<key>.webp.
const r27Hours = ['ojas', 'surya', 'chandra', 'soma', 'ananda', 'tejas', 'prana', 'shakti', 'vata', 'kapha', 'pitta', 'aarogya'];
String r27Poster(String key) => 'assets/home/hour-$key.webp';

/// Hour poster drawn with its violet cast pulled toward black (order 2:
/// no purple backgrounds). [sat] 1 = original colour.
class R27Img extends StatelessWidget {
  const R27Img(this.hour, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center, this.sat = .42});
  final String hour;
  final BoxFit fit;
  final Alignment alignment;
  final double sat;
  @override
  Widget build(BuildContext context) => ColorFiltered(
        colorFilter: ColorFilter.matrix(_satMatrix(sat)),
        child: Image.asset(r27Poster(hour), fit: fit, alignment: alignment, width: double.infinity, height: double.infinity,
            errorBuilder: (_, __, ___) => const ColoredBox(color: r27Coal)),
      );
}

List<double> _satMatrix(double s) {
  const r = .2126, g = .7152, b = .0722;
  final i = 1 - s;
  return [
    i * r + s, i * g, i * b, 0, 0,
    i * r, i * g + s, i * b, 0, 0,
    i * r, i * g, i * b + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

// ── Motion ────────────────────────────────────────────────────────────────
bool r27Still(BuildContext c) => NormalLoop.debugT != null || (MediaQuery.maybeDisableAnimationsOf(c) ?? false);

/// Repeating 0→1 phase; freezes at [NormalLoop.debugT] (tests) or .35
/// under reduced motion.
class R27Anim extends StatefulWidget {
  const R27Anim({super.key, required this.period, required this.builder});
  final Duration period;
  final Widget Function(BuildContext, double t) builder;
  @override
  State<R27Anim> createState() => _R27AnimState();
}

class _R27AnimState extends State<R27Anim> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (r27Still(context)) {
      _c.stop();
      _c.value = NormalLoop.debugT ?? .35;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (c, _) => widget.builder(c, _c.value));
}

/// Auto-rotating horizontal card row. Advances every [every]; a touch
/// pauses it for 6 s. [builder] gets the card's signed distance from the
/// centre page (0 = centred) so each section can stage its own transition.
class R27AutoRow extends StatefulWidget {
  const R27AutoRow({super.key, required this.count, required this.height, required this.builder,
      this.fraction = .62, this.every = const Duration(milliseconds: 3600), this.initial = 0, this.padEnds = true});
  final int count;
  final double height;
  final double fraction;
  final Duration every;
  final int initial;
  final bool padEnds;
  final Widget Function(BuildContext, int index, double offset) builder;
  @override
  State<R27AutoRow> createState() => _R27AutoRowState();
}

class _R27AutoRowState extends State<R27AutoRow> {
  static const _loops = 40;
  late final PageController _pc = PageController(viewportFraction: widget.fraction, initialPage: _start);
  Timer? _timer;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int get _start => widget.count <= 1 ? 0 : widget.count * (_loops ~/ 2) + widget.initial;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    final inTest = !kIsWeb && const bool.fromEnvironment('FLUTTER_TEST');
    if (widget.count > 1 && !r27Still(context) && !inTest) {
      _timer = Timer.periodic(widget.every, (_) {
        if (!mounted || !_pc.hasClients || DateTime.now().isBefore(_pausedUntil)) return;
        _pc.nextPage(duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: Listener(
          onPointerDown: (_) => _pausedUntil = DateTime.now().add(const Duration(seconds: 6)),
          child: PageView.builder(
            controller: _pc,
            padEnds: widget.padEnds,
            clipBehavior: Clip.none,
            itemCount: widget.count <= 1 ? widget.count : widget.count * _loops,
            itemBuilder: (c, i) => AnimatedBuilder(
              animation: _pc,
              builder: (c, _) {
                final page = _pc.hasClients && _pc.position.haveDimensions ? (_pc.page ?? _start.toDouble()) : _start.toDouble();
                return widget.builder(c, i % widget.count, i - page);
              },
            ),
          ),
        ),
      );
}

/// Height for a row whose cards carry DM Sans lines: grows with text scale
/// so nothing clips at 320 @1.3x.
double r27H(BuildContext c, double base, double textPart) => base + textPart * MediaQuery.textScalerOf(c).scale(1);

// ── Shapes ────────────────────────────────────────────────────────────────
/// Torn paper edge on top and bottom (deterministic per [seed]).
class R27Torn extends CustomClipper<Path> {
  const R27Torn({this.seed = 1, this.depth = 7, this.top = true, this.bottom = true});
  final int seed;
  final double depth;
  final bool top, bottom;
  @override
  Path getClip(Size s) {
    final r = math.Random(seed);
    final p = Path();
    const step = 9.0;
    p.moveTo(0, top ? depth * r.nextDouble() : 0);
    if (top) {
      for (var x = step; x < s.width; x += step) {
        p.lineTo(x, depth * r.nextDouble());
      }
    }
    p.lineTo(s.width, top ? depth * r.nextDouble() : 0);
    p.lineTo(s.width, bottom ? s.height - depth * r.nextDouble() : s.height);
    if (bottom) {
      for (var x = s.width - step; x > 0; x -= step) {
        p.lineTo(x, s.height - depth * r.nextDouble());
      }
    }
    p.lineTo(0, bottom ? s.height - depth * r.nextDouble() : s.height);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(R27Torn o) => o.seed != seed || o.depth != depth;
}

/// Ticket with two side notches and perforation at [stubAt] (0–1 of width).
class R27Ticket extends CustomClipper<Path> {
  const R27Ticket({this.stubAt = .38, this.notch = 11, this.r = 16});
  final double stubAt, notch, r;
  @override
  Path getClip(Size s) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)));
    final x = s.width * stubAt;
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: notch));
    return Path.combine(PathOperation.difference, body, holes);
  }
  @override
  bool shouldReclip(R27Ticket o) => o.stubAt != stubAt;
}

/// Dashed vertical perforation line.
class R27Perf extends CustomPainter {
  const R27Perf(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = 1.4;
    for (var y = 14.0; y < s.height - 14; y += 8) {
      c.drawLine(Offset(s.width / 2, y), Offset(s.width / 2, y + 4), p);
    }
  }
  @override
  bool shouldRepaint(R27Perf o) => o.color != color;
}

// ── Pieces ────────────────────────────────────────────────────────────────
/// Giant poster word that always fits its box (never truncates).
class R27Word extends StatelessWidget {
  const R27Word(this.text, {super.key, this.color = Colors.white, this.align = Alignment.centerLeft, this.outline = false, this.shadow = true});
  final String text;
  final Color color;
  final Alignment align;
  final bool outline;
  final bool shadow;
  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.contain,
        alignment: align,
        child: Text(text,
            textScaler: TextScaler.noScaling,
            textAlign: align.x < 0 ? TextAlign.left : (align.x > 0 ? TextAlign.right : TextAlign.center),
            style: r27Anton.copyWith(
              fontSize: 120,
              color: outline ? null : color,
              foreground: outline ? (Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..color = color) : null,
              shadows: shadow && !outline ? const [Shadow(color: Color(0x99000000), blurRadius: 18)] : null,
            )),
      );
}

/// Gold tag label (torn-tile flow).
class R27TagLabel extends StatelessWidget {
  const R27TagLabel(this.text, {super.key, this.color = r27Gold});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        // never break a tag mid-word; shrink slightly instead
        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(text.toUpperCase(), style: r27Tag, softWrap: false, maxLines: 1)),
      );
}

/// Pill action (text only — no icon+title+button rows).
class R27Pill extends StatelessWidget {
  const R27Pill(this.text, {super.key, required this.onTap, this.light = false, this.filled = true});
  final String text;
  final VoidCallback onTap;
  final bool light;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final bg = filled ? (light ? r27PaperInk : r27Gold) : Colors.transparent;
    final fg = filled ? (light ? Colors.white : r27PaperInk) : (light ? r27PaperInk : r27Gold);
    return NPress(
      onTap: onTap,
      label: text,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40),
            border: filled ? null : Border.all(color: fg, width: 1.3)),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg, height: 1.3)),
      ),
    );
  }
}

/// Greeting-type heading. [dark] picks the black-page variant.
class R27Head extends StatelessWidget {
  const R27Head({super.key, required this.hello, required this.title, this.sub, this.dark = false});
  final String hello, title;
  final String? sub;
  final bool dark;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(hello, style: dark ? dHello : nHello),
        const SizedBox(height: 2),
        Text(title, style: dark ? dTitle : nTitle),
        if (sub != null) ...[const SizedBox(height: 6), Text(sub!, style: dark ? dSub : nSub)],
      ]);
}

/// Text link in greeting type, tappable.
class R27Link extends StatelessWidget {
  const R27Link(this.text, {super.key, required this.onTap, this.dark = false});
  final String text;
  final VoidCallback onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => NPress(
        onTap: onTap,
        label: text,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('$text  →', style: dark ? dLink : nLinkStyle)),
      );
}

/// White neumorphic frame used on the NORMAL home.
class R27NeuFrame extends StatelessWidget {
  const R27NeuFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(decoration: neu(r: 28), padding: const EdgeInsets.fromLTRB(18, 20, 0, 8), child: child),
      );
}

/// Bottom-up black scrim for legible text on posters.
const r27Scrim = BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0x1A000000), Color(0x66000000), Color(0xF2000000)], stops: [0, .45, 1]));
