/// Drop Studio v5 — polished picks from the v4 review.
///   [DoorsPrismV5]  "Make this home yours": a turning 4-face prism, one real
///                   setting per face. Swipe OR tap a tab to turn; haptic on
///                   every face snap; tap the front face to open its hook.
///   [EntryPeelV5]   Fashion-home entry card: this hour's film poster whose
///                   corner is a real drag-to-peel revealing the next hour's
///                   word; release springs back; tap anywhere enters.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../data/content.dart';
import '../../data/day_part.dart';
import '../../data/models.dart';
import '../../data/settings.dart';
import '../../widgets/concept/stillwater.dart';
import 'drop_v4_concepts.dart' show DoorHooks, DoorKind, SettingPreview, doorState, doorTitle, hourWord;
import 'drop_v4_type.dart';
import '../store/store_art.dart' show meaningFlipArt, storeSubjectArt;

const _gold = Color(0xFFC8A96E);
const _violet = Color(0xFF7C4DDB);
const _deep = Color(0xFF060C18);
const _ink = Color(0xFF0B0B10);
const _paper = Color(0xFFF3EADB);

String _poster(String mp4) => mp4.replaceAll('.mp4', '-poster.webp');

// ─── DOORS · prism ──────────────────────────────────────────────────────

class DoorsPrismV5 extends StatefulWidget {
  const DoorsPrismV5({super.key, this.hooks = const DoorHooks(), this.debugFront, this.debugAngle});
  final DoorHooks hooks;
  /// Shots: freeze on this face (0..3).
  final int? debugFront;
  /// Motion frames: freeze at this fractional angle (in faces).
  final double? debugAngle;
  @override
  State<DoorsPrismV5> createState() => _PrismV5State();
}

class _PrismV5State extends State<DoorsPrismV5> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: (widget.debugFront ?? 0).toDouble());
  double get a => widget.debugAngle ?? _c.value;
  static final int _n = DoorKind.values.length;
  final _tabKeys = List.generate(_n, (_) => GlobalKey());

  int get front => (a.round() % _n + _n) % _n;

  @override
  void initState() {
    super.initState();
    DayClock.retain(); // face 1 greeting follows the local hour
  }

  @override
  void dispose() {
    DayClock.release();
    _c.dispose();
    super.dispose();
  }

  /// Turn to the nearest copy of face [i] (shortest way round), snap + haptic.
  void _turnTo(double target) {
    final still = Stillwater.still(context);
    _c
        .animateTo(target, duration: still ? Duration.zero : const Duration(milliseconds: 320), curve: Curves.easeOutCubic)
        .whenComplete(() {
      if (mounted) HapticFeedback.selectionClick();
    });
  }

  void _toFace(int i) {
    final cur = _c.value;
    var d = (i - cur) % _n;
    if (d > _n / 2) d -= _n;
    _turnTo((cur + d).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Make this home yours', style: V4Type.greet()),
          // one line, never an orphaned word: scales down to fit narrow/large text
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Three doors. One tap.', key: const ValueKey('drop-prism-heading'), maxLines: 1, style: V4Type.title())),
          const SizedBox(height: 3),
          Text('Turn the prism. Tap the front to change it.', style: V4Type.sub()),
        ]),
      ),
      LayoutBuilder(builder: (context, c) {
        final w = math.min(c.maxWidth - 96, 250.0);
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Breath(builder: (context, t) {
            // a resting quarter-turn bias so the next side face always peeks
            final step = 2 * math.pi / _n;
            final depth = w / (2 * math.tan(math.pi / _n));
            final faces = [for (var i = 0; i < _n; i++) (i, (i - a - .2) * step)]
              ..sort((x, y) => math.cos(x.$2).compareTo(math.cos(y.$2)));
            final fr = front;
            return Semantics(
              button: true,
              label: 'Change ${doorTitle(DoorKind.values[fr]).toLowerCase()}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => _c.value -= d.delta.dx / w,
                onHorizontalDragEnd: (d) {
                  final v = -(d.primaryVelocity ?? 0) / w;
                  _turnTo((_c.value + v.clamp(-1.0, 1.0) * .35).roundToDouble());
                },
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.hooks.of(DoorKind.values[fr])?.call();
                },
                child: SizedBox(
                  key: const ValueKey('drop-prism'),
                  height: 300,
                  width: double.infinity,
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: RadialGradient(radius: .7, colors: [
                        _violet.withValues(alpha: .30 + .18 * Stillwater.lungs(t)),
                        Colors.transparent
                      ]))),
                    ),
                    for (final f in faces)
                      if (math.cos(f.$2) > .02)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .0018)
                            ..translateByDouble(0, 0, depth, 1)
                            ..rotateY(f.$2)
                            ..translateByDouble(0, 0, -depth, 1),
                          child: _Face(kind: DoorKind.values[f.$1], w: w, t: t, isFront: f.$1 == fr, shade: 1 - math.cos(f.$2)),
                        ),
                  ]),
                ),
              ),
            );
          }),
        );
      }),
      const SizedBox(height: 10),
      AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final fr = front;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // scrollable tab row: icon + label, one text size, never squeezed
              // all four tabs always visible: wrap to a second row when narrow
              Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < _n; i++)
                    Semantics(
                      key: _tabKeys[i],
                      button: true,
                      selected: fr == i,
                      child: GestureDetector(
                        key: ValueKey('drop-prism-tab-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _toFace(i),
                        child: AnimatedContainer(
                          duration: Stillwater.still(context) ? Duration.zero : const Duration(milliseconds: 240),
                          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: fr == i ? Colors.white.withValues(alpha: .10) : Colors.transparent,
                            border: Border.all(color: fr == i ? _gold : Colors.white24),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(doorTitle(DoorKind.values[i]),
                                maxLines: 1,
                                style: V4Type.sub().copyWith(
                                    color: fr == i ? Colors.white : Colors.white70, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                    ),
                ]),
              const SizedBox(height: 6),
              // one-line live caption of the current setting
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Live now: ', style: V4Type.sub()),
                  Text(doorState(DoorKind.values[fr]), maxLines: 1, style: V4Type.sub().copyWith(color: Colors.white)),
                ]),
              ),
            ]),
          );
        },
      ),
    ]);
  }
}


class _Face extends StatelessWidget {
  const _Face({required this.kind, required this.w, required this.t, required this.isFront, required this.shade});
  final DoorKind kind;
  final double w, t, shade;
  final bool isFront;
  @override
  Widget build(BuildContext context) {
    final Widget preview = switch (kind) {
      DoorKind.startArt => const _StillPreview(),
      _ => SettingPreview(kind: kind, t: t),
    };
    return Container(
      width: w,
      height: 280,
      decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5), color: _ink),
      foregroundDecoration: BoxDecoration(color: Colors.black.withValues(alpha: shade.clamp(0.0, 1.0) * .7)),
      // side faces: the big image only. Label lives on the front face.
      child: isFront
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: preview),
              Container(
                color: _paper,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(doorTitle(kind), maxLines: 1, style: V4Type.title(dark: false).copyWith(fontSize: 22))),
                  Text('Change ${doorTitle(kind).toLowerCase()}', maxLines: 1, style: V4Type.action(dark: false)),
                ]),
              ),
            ])
          : preview,
    );
  }
}

/// Start art face: the saved still shown WHOLE (contain), so any word in
/// the artwork reads in full, over a darkened fill of the same still.
class _StillPreview extends StatelessWidget {
  const _StillPreview();
  @override
  Widget build(BuildContext context) {
    final still = Settings.instance.fashionImageAsset ?? Settings.fashionImages.first;
    return Stack(fit: StackFit.expand, children: [
      // ONE still, full-bleed, cropped to the model (bottom-left) so no
      // part of the FASHION lettering is cut.
      ClipRect(
        child: Transform.scale(
          scale: 1.9,
          alignment: Alignment.bottomLeft,
          child: Image.asset(still, fit: BoxFit.cover, alignment: Alignment.bottomLeft),
        ),
      ),
    ]);
  }
}

// ─── ENTRY · peeling poster ─────────────────────────────────────────────

String _hh(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h ${d.hour < 12 ? 'AM' : 'PM'}';
}

class EntryPeelV5 extends StatefulWidget {
  const EntryPeelV5({super.key, this.onOpenDrop, this.now, this.debugPeel, this.wordFor});
  final VoidCallback? onOpenDrop;
  /// Clock override (tests). Null = the shared [DayClock] (local time,
  /// refreshes on the hour and on resume).
  final DateTime Function()? now;
  /// This hour's drop word (the same list the Drop Studio dock uses).
  final Word? Function(DateTime at)? wordFor;
  /// Shots/motion: freeze the peel (0 = resting, 1 = fully dragged).
  final double? debugPeel;
  @override
  State<EntryPeelV5> createState() => _EntryPeelV5State();
}

class _EntryPeelV5State extends State<EntryPeelV5> with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController.unbounded(vsync: this, value: 0);
  double get peel => (widget.debugPeel ?? _p.value).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    DayClock.retain();
  }

  @override
  void dispose() {
    DayClock.release();
    _p.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.lightImpact();
    widget.onOpenDrop?.call();
  }

  void _release(double v) {
    if (Stillwater.still(context)) {
      _p.value = 0;
      return;
    }
    _p.animateWith(SpringSimulation(const SpringDescription(mass: 1, stiffness: 260, damping: 18), _p.value, 0, v));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ContentStore.instance, DayClock.tick]),
      builder: (context, _) {
        final at = widget.now?.call() ?? DayClock.now();
        final part = dayPartFor(at);
        final pick = widget.wordFor ?? hourWord;
        final w = pick(at);
        final next = pick(at.add(const Duration(hours: 1)));
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: LayoutBuilder(builder: (context, c) {
            final width = c.maxWidth;
            // the peel lives in the bottom band ONLY, below the word row
            // full peel lifts ~60% of the card so the next word clearly shows;
            // the layout band stays at the resting size.
            final rest = 104.0, maxD = math.max(rest, math.min(230.0, width * .6));
            final band = math.max(rest, math.min(124.0, width * .4));
            return AnimatedBuilder(
              animation: _p,
              builder: (context, _) => Breath(builder: (context, t) {
                final d = rest + 6 * Stillwater.lungs(t) * (1 - peel) + (maxD - rest) * peel;
                return Semantics(
                  button: true,
                  label: 'Open Drop Studio. This hour: ${w?.word ?? 'NowssB'}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _open,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(children: [
                        // underneath: the next hour, revealed by the peel
                        Positioned.fill(child: _Under(next: next, at: at, d: d)),
                        // shadow the curl casts along the fold, onto the art
                        Positioned(right: 0, bottom: 0, width: d, height: d, child: CustomPaint(painter: _FoldShadow())),
                        ClipPath(
                          clipper: _CornerCut(d),
                          child: _Face2(word: w, at: at, part: part, band: band),
                        ),
                        // the curled-back flap
                        Positioned(right: 0, bottom: 0, width: d, height: d, child: CustomPaint(painter: _FlapPainter(part))),
                        // corner drag handle (bigger than the flap, ≥ 64px)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          width: math.max(d + 24, 72),
                          height: math.max(d + 24, 72),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (_) => HapticFeedback.selectionClick(),
                            onPanUpdate: (g) =>
                                _p.value = (_p.value - (g.delta.dx + g.delta.dy) / (2 * (maxD - rest))).clamp(0.0, 1.0),
                            onPanEnd: (g) => _release(-(g.velocity.pixelsPerSecond.dx + g.velocity.pixelsPerSecond.dy) / (2 * (maxD - rest))),
                            onTap: _open,
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }
}

/// Strip under the word = resting peel (104 + 6 breath) + 8px clearance.
const double _strip = 118;

class _Face2 extends StatelessWidget {
  const _Face2({required this.word, required this.at, required this.part, required this.band});
  final Word? word;
  final DateTime at;
  final DayPart part;
  final double band;
  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    final night = part == DayPart.night;
    final tint = switch (part) {
      DayPart.night => const Color(0xE6040814),
      DayPart.morning => const Color(0x8C2A1E10),
      DayPart.afternoon => const Color(0x991A1030),
      DayPart.evening => const Color(0xA62A0E3A),
    };
    final when = switch (part) {
      DayPart.night => 'Tonight, ${_hh(at)}',
      DayPart.morning => 'This morning, ${_hh(at)}',
      DayPart.afternoon => 'This afternoon, ${_hh(at)}',
      DayPart.evening => 'This evening, ${_hh(at)}',
    };
    return Stack(children: [
      Positioned.fill(
          child: Image.asset(_poster(Settings.fashionVideos[s.fashionVideoIndex]),
              fit: BoxFit.cover, color: night ? const Color(0xFF8E9BD6) : null, colorBlendMode: night ? BlendMode.multiply : null)),
      Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tint.withValues(alpha: tint.a * .7), tint])))),
      if (night) ...[
        // Ritual night haze + a real glowing moon
        const Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: RadialGradient(
                        center: Alignment(.9, -.95),
                        radius: 1.1,
                        colors: [Color(0x553A4C8C), Color(0x00000000)])))),
        Positioned(right: -6, top: -6, width: 96, height: 96, child: CustomPaint(painter: _MoonPainter())),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          // one line, never a lone 'AM': shrinks to fit at narrow / large text
          FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(when, key: const ValueKey('drop-entry-when'), maxLines: 1, softWrap: false, style: V4Type.greet())),
          Text('Drop Studio', style: V4Type.title()),
          const SizedBox(height: 14),
          // giant word: Anton poster sans, always whole
          // the word grows to the full width; its right edge is kept clear of
          // the peel's reach above the strip.
          Padding(
           padding: EdgeInsets.only(right: math.max(0.0, band + 8 - _strip)),
           child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: Text((word?.word ?? 'NowssB').toUpperCase(),
                key: const ValueKey('drop-studio-entry-word'),
                maxLines: 1,
                softWrap: false,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 104,
                    height: 1.05,
                    letterSpacing: 1,
                    color: night ? const Color(0xFFEDE6D3) : Colors.white)),
          )),
          // bottom band: the only place the peel can reach. Meaning + link sit
          // left of the peel, so there is no dead gap under the word.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _strip),
            child: Padding(
              padding: EdgeInsets.only(right: band - 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (word != null)
                  Text(word!.meaning, style: V4Type.sub().copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text('Peel into the studio', maxLines: 1, style: V4Type.action()))),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _Under extends StatelessWidget {
  const _Under({required this.next, required this.at, required this.d});
  final Word? next;
  final DateTime at;
  final double d;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        // the next hour's real art from the app's word pictures
        // the art's own backdrop fills the whole reveal (no seam)
        Positioned.fill(child: Image.asset(_nextArt(next), fit: BoxFit.cover, alignment: Alignment.topLeft, scale: .2)),
        // framed to the peel so the subject (Surya → the sun) shows in the corner
        Positioned(
            // subject centre lands ~30% in from the corner, inside the reveal
            right: -.42 * d,
            bottom: -.62 * d,
            width: d * 1.8,
            height: d * 1.8,
            child: Image.asset(_nextArt(next), fit: BoxFit.cover)),
        // caption scrim: ~70-85% black towards the caption so white text holds 4.5:1+
        const Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment(0, -.4),
                        end: Alignment.bottomRight,
                        stops: [0, .5, 1],
                        colors: [Color(0x00000000), Color(0xB3000000), Color(0xD9000000)])))),
        // caption lives in the revealed (dark) triangle only: its box is
        // .50d x .28d from the corner, so its far corner sits at .78d + 12
        // < d along the fold diagonal for every d in the curl range.
        Positioned(
          right: 6,
          bottom: 6,
          width: d * .5,
          height: d * .28,
          child: FittedBox(
            key: const ValueKey('drop-entry-next'),
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text('Next, ${_hh(at.add(const Duration(hours: 1)))}',
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1.1, shadows: [Shadow(blurRadius: 4)])),
              Text((next?.word ?? '').toUpperCase(),
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(fontFamily: 'Anton', fontSize: 18, color: Colors.white, height: 1.15, shadows: [Shadow(blurRadius: 4)])),
            ]),
          ),
        ),
      ]);
}

/// Soft shadow the curled flap casts on the art, hugging the fold line.
class _FoldShadow extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.clipPath(Path()..moveTo(s.width, 0)..lineTo(s.width, s.height)..lineTo(0, s.height)..close());
    final band = Path()
      ..moveTo(0, s.height)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, 14)
      ..lineTo(14, s.height)
      ..close();
    c.drawPath(band, Paint()..color = const Color(0x99000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    c.restore();
  }

  @override
  bool shouldRepaint(_FoldShadow o) => false;
}

class _CornerCut extends CustomClipper<Path> {
  _CornerCut(this.d);
  final double d;
  @override
  Path getClip(Size s) => Path()
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height - d)
    ..lineTo(s.width - d, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_CornerCut o) => o.d != d;
}

/// The back of the poster, curled over the cut.
class _FlapPainter extends CustomPainter {
  _FlapPainter(this.part);
  final DayPart part;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // the back of the paper: fold along the diagonal, tip curling over
    final p = Path()
      ..moveTo(0, h)
      ..lineTo(w, 0)
      ..lineTo(w * .30, 0)
      ..quadraticBezierTo(w * .02, h * .02, 0, h * .30)
      ..close();
    c.drawShadow(p, Colors.black, 8, false);
    final night = part == DayPart.night;
    c.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.center,
            end: Alignment.topLeft,
            colors: night
                ? const [Color(0xFF8E8778), Color(0xFFF3EDDD), Color(0xFFD8D0BD), Color(0xFFA59D8B)]
                : const [Color(0xFFA89E89), Color(0xFFFFFBF2), _paper, Color(0xFFBFB49F)],
            stops: const [0, .35, .7, 1],
          ).createShader(Offset.zero & s));
    // specular highlight running parallel to the fold
    c.drawLine(Offset(w * .12, h * .62), Offset(w * .62, h * .12),
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    // crisp crease on the fold line
    c.drawLine(Offset(0, h), Offset(w, 0), Paint()..color = Colors.black.withValues(alpha: .25)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_FlapPainter o) => o.part != part;
}

/// A glowing waxing moon: soft halo, lit disc, maria, terminator shadow.
class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    const r = 15.0;
    c.drawCircle(o, s.width / 2,
        Paint()..shader = const RadialGradient(colors: [Color(0x66E8E2FF), Color(0x228C9CFF), Color(0x00000000)], stops: [.18, .45, 1]).createShader(Rect.fromCircle(center: o, radius: s.width / 2)));
    final disc = Rect.fromCircle(center: o, radius: r);
    c.saveLayer(disc.inflate(2), Paint());
    c.drawCircle(o, r, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFFFFFBEF), Color(0xFFD9D2C0)]).createShader(disc));
    final m = Paint()..color = const Color(0x22404060);
    c.drawCircle(o + const Offset(-5, -3), 4, m);
    c.drawCircle(o + const Offset(3, 5), 3, m);
    c.drawCircle(o + const Offset(5, -6), 2, m);
    c.drawCircle(o + const Offset(9, -2), r, Paint()..color = const Color(0xCC0A0F24)..blendMode = BlendMode.srcATop..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    c.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter o) => false;
}

/// The next word's own picture: its meaning art (e.g. Surya → sun), else
/// the store's picture of the word.
String _nextArt(Word? w) {
  if (w == null) return 'assets/hero-curve/cleopatra.webp';
  for (final tok in w.meaning.toLowerCase().split(RegExp(r'[^a-z]+'))) {
    if (tok.isEmpty) continue;
    final a = meaningFlipArt(tok);
    if (a == 'assets/rails/mean-$tok.jpg') return a;
  }
  return storeSubjectArt(w.word);
}

/// The Drop Studio entry card's corner peel, reusable on any card: the
/// bottom-right corner curls back (same cut, fold shadow and paper flap as
/// [EntryPeelV5]) over [under]. With [auto] it peels a little and settles on
/// a loop; a tap peels it fully, then calls [onOpen].
class CornerPeel extends StatefulWidget {
  const CornerPeel({super.key, required this.child, this.under, this.onOpen, this.auto = true,
      this.rest = 26, this.loop = const Duration(milliseconds: 3200), this.debugPeel, this.label});
  final Widget child;
  final Widget? under;
  final VoidCallback? onOpen;
  final bool auto;
  /// Corner size while resting (px).
  final double rest;
  final Duration loop;
  /// Shots: freeze the peel (0 = resting, 1 = fully peeled).
  final double? debugPeel;
  final String? label;
  /// Tests: let the loop run although Stillwater holds motion still in tests.
  static bool debugLoopInTests = false;
  @override
  State<CornerPeel> createState() => CornerPeelState();
}

class CornerPeelState extends State<CornerPeel> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: widget.loop);
  late final AnimationController _full = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  bool _opening = false;

  @override
  void initState() {
    super.initState();
  }

  bool get _still => !CornerPeel.debugLoopInTests ? Stillwater.still(context) : (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still || !widget.auto || widget.debugPeel != null) {
      _loop.stop();
    } else if (!_loop.isAnimating && !_opening) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _full.dispose();
    super.dispose();
  }

  /// Auto peel: lift to ~45% and settle, in the first half of each loop.
  double get _autoPeel {
    final t = _loop.value;
    if (t > .5) return 0;
    return .45 * math.sin(t / .5 * math.pi);
  }

  double get peel => (widget.debugPeel ?? math.max(_autoPeel, Curves.easeInOutCubic.transform(_full.value))).clamp(0.0, 1.0);

  Future<void> open() async {
    if (_opening) return;
    _opening = true;
    HapticFeedback.lightImpact();
    _loop.stop();
    await _full.forward(from: 0);
    if (!mounted) return;
    widget.onOpen?.call();
    _full.value = 0;
    _opening = false;
    if (widget.auto && mounted && !_still) _loop.repeat();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: LayoutBuilder(builder: (context, c) {
            final maxD = math.max(c.maxWidth, c.maxHeight) * 1.05;
            return AnimatedBuilder(
              animation: Listenable.merge([_loop, _full]),
              builder: (context, _) {
                final p = peel;
                // ease the corner from rest to past the far corner
                final d = widget.rest + (maxD * 2 - widget.rest) * p * p * .5 + (maxD * .5) * p;
                final flap = math.min(d, maxD * 2);
                return Stack(fit: StackFit.expand, children: [
                  widget.under ?? const ColoredBox(color: Color(0xFF0B0B0D)),
                  Positioned(right: 0, bottom: 0, width: flap, height: flap, child: CustomPaint(painter: _FoldShadow())),
                  ClipPath(clipper: _CornerCut(d), child: widget.child),
                  Positioned(right: 0, bottom: 0, width: flap, height: flap,
                      child: IgnorePointer(child: CustomPaint(key: const ValueKey('corner-peel-flap'), painter: _FlapPainter(DayPart.morning)))),
                ]);
              },
            );
          }),
        ),
      );
}
