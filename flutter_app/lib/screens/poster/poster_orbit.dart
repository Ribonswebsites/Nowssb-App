/// POSTER · Orbit stage — the loved Fashion "Today's offers" 3D effect
/// (EnterCurveStage), rebuilt deeper for the Trending hero.
///
/// The Cleopatra cut-out stands still at the centre; the hero-curve word
/// posters ride a tilted 3D ellipse around her. Posters with z < 0 paint
/// BEHIND her, z > 0 paint IN FRONT (bigger, sharper) → real occlusion.
/// The backdrop photo, the orbit plane and the figure move at three parallax
/// depths under drag (gyro-feel spring back). Drag horizontally to spin.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import 'poster_kit.dart';

/// One orbiting poster: real hero-curve art.
class OrbitPoster {
  const OrbitPoster(this.asset, this.id);
  final String asset, id;
}

const kOrbitPosters = <OrbitPoster>[
  // text-free stills only (no printed words on the orbiting posters)
  OrbitPoster('assets/hero-curve/tab-forest.webp', 'orbit.forest'),
  OrbitPoster('assets/hero-curve/tab-beach.webp', 'orbit.beach'),
  OrbitPoster('assets/hero-curve/tab-desert.webp', 'orbit.desert'),
  OrbitPoster('assets/hero-curve/tab-rain.webp', 'orbit.rain'),
  OrbitPoster('assets/hero-curve/tab-stool.webp', 'orbit.stool'),
  OrbitPoster('assets/hero-curve/listen.webp', 'orbit.listen'),
];

class PosterOrbitStage extends StatefulWidget {
  const PosterOrbitStage({
    super.key,
    required this.slot,
    required this.word,
    required this.onOpenWord,
    required this.onBuy,
    this.debugAngle,
    this.debugTilt,
  });
  final String slot;

  /// The featured (No. 1 trending) word shown on the stage plate.
  final Word word;
  final VoidCallback onOpenWord, onBuy;
  final double? debugAngle;
  final Offset? debugTilt;

  @override
  State<PosterOrbitStage> createState() => _PosterOrbitStageState();
}

class _PosterOrbitStageState extends State<PosterOrbitStage> with TickerProviderStateMixin {
  /// One full orbit = 28 s, linear (calm).
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(() => setState(() => _tilt = _from * _spring.value));
  Offset _tilt = Offset.zero, _from = Offset.zero;
  double _spin = 0; // extra angle from drag

  @override
  void dispose() {
    _orbit.dispose();
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final W = box.maxWidth;
      final H = W * 1.12;
      final id = 'word:${widget.word.word.toLowerCase()}';
      final p = priceOrNull(id, wordPrice(widget.word.word));
      // The plate lives in its OWN band under the scene, so at any width the
      // word, tag and pills never sit on a poster or on the figure.
      final plate = Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF120A1F),
          border: Border(top: BorderSide(color: kPGold, width: 2)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const GoldTag("Today's drop"),
          const SizedBox(height: 8),
          SizedBox(height: 64, child: GiantWord(widget.word.word.toUpperCase(), style: anton(72, color: kPPaper))),
          if (widget.word.meaning.isNotEmpty) ...[const SizedBox(height: 6), InkTag(widget.word.meaning)],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            p == null ? GoldPill(label: ownedLabel(id), onTap: widget.onOpenWord) : GoldPill(label: 'Own · $p', onTap: widget.onBuy),
            GoldPill(label: 'Hear it', onTap: widget.onOpenWord, dark: true, arrow: true),
          ]),
        ]),
      );
      return Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onPanStart: (_) => _spring.stop(),
          onPanUpdate: (d) => setState(() {
            _spin += d.delta.dx / W * math.pi;
            _tilt = Offset((_tilt.dx + d.delta.dx / (W / 2)).clamp(-1.0, 1.0), (_tilt.dy + d.delta.dy / 160).clamp(-1.0, 1.0));
          }),
          onPanEnd: (_) {
            HapticFeedback.lightImpact();
            _from = _tilt;
            _spring.value = 1;
            _spring.animateWith(SpringSimulation(const SpringDescription(mass: 1, stiffness: 110, damping: 10), 1, 0, 0));
          },
          onTap: widget.onOpenWord,
          child: AnimatedBuilder(
            animation: _orbit,
            builder: (context, _) {
              final t = widget.debugTilt ?? _tilt;
              final a = widget.debugAngle ?? (_orbit.value * math.pi * 2 + _spin);
              return SizedBox(width: W, height: H, child: _scene(W, H, a, t));
            },
          ),
        ),
        plate
      ]);
    });
  }

  Widget _scene(double W, double H, double a, Offset t) {
    final n = kOrbitPosters.length;
    final items = <(double z, Widget w)>[];
    for (var i = 0; i < n; i++) {
      final th = a + i * 2 * math.pi / n;
      final x = math.cos(th), z = math.sin(th);
      final s = .62 + .38 * (z + 1) / 2; // depth scale
      final pw = W * .40 * s;
      final cx = W / 2 + x * W * .38 + t.dx * 22 * (z + 1);
      // ellipse plane tilted 14°: near posters ride lower
      final cy = H * .48 + z * H * .08 + t.dy * 14 * (z + 1);
      items.add((
        z,
        Positioned(
          left: cx - pw / 2,
          top: cy - pw * .56 / 2,
          width: pw,
          height: pw * .5625,
          child: Opacity(
            opacity: (.45 + .55 * (z + 1) / 2).clamp(0, 1),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateY(-x * .75)
                ..rotateZ(x * .05),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 18 * s, offset: Offset(0, 10 * s))],
                ),
                child: Photo(kOrbitPosters[i].asset, slot: widget.slot, id: kOrbitPosters[i].id),
              ),
            ),
          ),
        ),
      ));
    }
    items.sort((p, q) => p.$1.compareTo(q.$1));
    final behind = [
      for (final e in items)
        if (e.$1 <= .15) e.$2
    ];
    final front = [
      for (final e in items)
        if (e.$1 > .15) e.$2
    ];
    final word = widget.word.word.toUpperCase();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        // depth 0: the cosmos photo, slow & opposite
        Positioned(
          left: -30 - t.dx * 16,
          right: -30 + t.dx * 16,
          top: -30 - t.dy * 10,
          bottom: -30 + t.dy * 10,
          child: Opacity(opacity: .55, child: Photo('assets/hero-curve/tab-window.webp', slot: widget.slot, id: 'orbit.backdrop', align: Alignment.topCenter)),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment(0, -.1), radius: .9, colors: [Color(0x553A1F63), Color(0xF0060C18)]),
            ),
          ),
        ),
        // depth .15: giant ghost word behind the orbit
        Positioned(
          left: 8 + t.dx * 6,
          right: 8 - t.dx * 6,
          top: H * .06,
          height: H * .24,
          child: GiantWord(word, align: Alignment.center, style: anton(H * .24, w: FontWeight.w800, ls: -3), outline: kPGold.withValues(alpha: .55)),
        ),
        // the orbit ring (thin gold ellipse) for the "track"
        Positioned.fill(child: CustomPaint(painter: _Ring(t))),
        ...behind,
        // depth .7: the cut-out, front and centre
        Positioned(
          left: W * .16 + t.dx * 34,
          width: W * .68,
          top: H * .02 + t.dy * 10,
          bottom: -H * .02,
          child: Cutout(PosterAssets.cleopatra, slot: widget.slot, id: 'orbit.cutout', fadeBottom: .12),
        ),
        ...front,
      ]),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.t);
  final Offset t;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromCenter(center: Offset(s.width / 2 + t.dx * 22, s.height * .48 + t.dy * 14), width: s.width * .86, height: s.height * .22);
    c.drawOval(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = kPGold.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(_Ring o) => o.t != t;
}
