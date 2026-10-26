/// DOOR SCREENS concept kit — shared collage language for the five
/// Drop Studio door screens (Background, Start art, Checkout, Themes, Access).
///
/// Rules baked in (Ribon reject 1:25 AM): no light chip with light text, every
/// option shows its real media, no settings-card pages, no chip grids.
/// Text always sits on a dark scrim or on solid gold with dark ink.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../admin/template/editable.dart';
import '../../../widgets/concept/stillwater.dart';
import 'film_dial_kit.dart';

export 'film_dial_kit.dart';

const doorDeep = Color(0xFF060C18);
const doorPaper = Color(0xFFF4EEDF);

/// Home greeting type (NmGreeting, sections_top.dart): the only non-poster
/// styles. 'Good Evening' = greet, 'Healer' = title, subline = sub.
TextStyle doorGreet({Color color = const Color(0xE6FFFFFF)}) =>
    TextStyle(fontFamily: 'DM Sans', fontSize: 19, fontWeight: FontWeight.w300, color: color);
TextStyle doorTitle({Color color = Colors.white}) =>
    TextStyle(fontFamily: 'DM Sans', fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1.1);
TextStyle doorSub({Color color = const Color(0xD9FFFFFF)}) =>
    TextStyle(fontFamily: 'DM Sans', fontSize: 12.5, fontWeight: FontWeight.w400, color: color);

/// Runs a looping 0..1 phase, or holds [debugPhase] for shot tests.
mixin DoorPhase<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController phase =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
  double? get debugPhaseValue;
  void startPhase() {
    if (debugPhaseValue != null) {
      phase.value = debugPhaseValue!;
    } else {
      // Reduced motion holds the phase still; otherwise loop.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !Stillwater.still(context)) phase.repeat();
      });
    }
  }

  @override
  void dispose() {
    phase.dispose();
    super.dispose();
  }
}

/// A real-media tile: a still (poster frame or art) drifting in a slow
/// Ken-Burns pan. [videoBuilder] lets Builder swap in the live clip.
class DoorMedia extends StatelessWidget {
  const DoorMedia({
    super.key,
    required this.asset,
    required this.slot,
    required this.t,
    this.drift = 1,
    this.fit = BoxFit.cover,
    this.child,
  });
  final String? asset;
  final String slot;
  final double t; // 0..1 phase
  final double drift;
  final BoxFit fit;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final a = t * math.pi * 2;
    final s = 1.08 + .04 * math.sin(a) * drift;
    final dx = 10 * math.cos(a) * drift, dy = 6 * math.sin(a) * drift;
    return ClipRect(
      child: Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFF0B0A12)),
        if (asset != null)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(dx, dy, 0, 1)
              ..scaleByDouble(s, s, 1, 1),
            child: child ??
                EditableImage.asset(asset!, slot: slot, fit: fit,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1426))),
          ),
      ]),
    );
  }
}

/// Black marquee strip, gold-on-black type, scrolling with [t].
class DoorTicker extends StatelessWidget {
  const DoorTicker({super.key, required this.items, required this.t});
  final List<String> items;
  final double t;
  @override
  Widget build(BuildContext context) {
    final line = '${items.map((e) => e.toUpperCase()).join('   •   ')}   •   ';
    return Transform.rotate(
      angle: -.012,
      child: Container(
        height: 26,
        color: Colors.black,
        child: ClipRect(
          child: LayoutBuilder(builder: (context, c) {
            return OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-t * 400, 0),
                child: Text(line * 6,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: doorBody(12, color: doorGoldSoft, w: FontWeight.w800, ls: 2)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DoorRoundButton extends StatelessWidget {
  const DoorRoundButton({super.key, required this.icon, this.onTap, required this.semantic, this.size = 44});
  final IconData icon;
  final VoidCallback? onTap;
  final String semantic;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantic,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: .72),
              border: Border.all(color: doorGold, width: 1.4),
            ),
            child: Icon(icon, color: Colors.white, size: size * .5),
          ),
        ),
      );
}

/// Solid gold action with dark ink — the only "filled" control in the set.
class DoorGoldAction extends StatelessWidget {
  const DoorGoldAction({super.key, required this.label, this.onTap, this.icon, this.slot});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? slot;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [doorGoldSoft, doorGold]),
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: doorInk, size: 22), const SizedBox(width: 10)],
            Flexible(
              child: EditableLabel(slot ?? 'concept.Doors.action', label,
                  textAlign: TextAlign.center,
                  style: doorBody(17, color: doorInk, w: FontWeight.w800)),
            ),
          ]),
        ),
      );
}

/// Full-bleed live backdrop: the focused option fills the whole page,
/// under a top/bottom scrim so all type stays readable.
class DoorBackdrop extends StatelessWidget {
  const DoorBackdrop({super.key, required this.asset, required this.slot, required this.t, this.dim = .55});
  final String? asset;
  final String slot;
  final double t, dim;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: KeyedSubtree(
            key: ValueKey(asset),
            child: asset == null
                ? const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment(-.5, -.7), radius: 1.3, colors: [Color(0xFF1A1F33), doorDeep])))
                : DoorMedia(asset: asset, slot: slot, t: t, drift: .6),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
              Colors.black.withValues(alpha: .80),
              Colors.black.withValues(alpha: dim * .5),
              Colors.black.withValues(alpha: dim * .6),
              Colors.black.withValues(alpha: .92),
            ], stops: const [0, .32, .6, 1]),
          ),
        ),
      ]);
}

/// Black label tape with white type — used for option names on media.
class DoorTape extends StatelessWidget {
  const DoorTape(this.text, {super.key, this.angle = -.02, this.gold = false, this.size = 13});
  final String text;
  final double angle, size;
  final bool gold;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: gold ? doorGold : Colors.black,
          child: Text(text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: doorBody(size, color: gold ? doorInk : Colors.white, w: FontWeight.w800, ls: 1.2)),
        ),
      );
}

/// Violet liquid backdrop from Drop Studio, phase-driven.
class DoorLiquid extends StatelessWidget {
  const DoorLiquid({super.key, required this.t});
  final double t;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _LiquidPainter(t), size: Size.infinite);
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter(this.t);
  final double t;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF0A0818));
    final a = 2 * math.pi * t;
    void blob(Offset o, double r, Color col) => c.drawCircle(
        o,
        r,
        Paint()
          ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: r)));
    blob(Offset(s.width * (.15 + .06 * math.sin(a)), s.height * .12), s.width * .9, const Color(0x8A5B2BC4));
    blob(Offset(s.width * (.95 - .05 * math.cos(a)), s.height * .4), s.width * .8, const Color(0x669D4EDD));
    blob(Offset(s.width * .3, s.height * (.8 + .02 * math.sin(a))), s.width * .9, const Color(0x553A1C8C));
  }

  @override
  bool shouldRepaint(_LiquidPainter o) => o.t != t;
}

/// Drop Studio torn-paper edge.
class DoorTornClipper extends CustomClipper<Path> {
  const DoorTornClipper(this.seed);
  final int seed;
  @override
  Path getClip(Size s) {
    final r = math.Random(seed);
    final p = Path()..moveTo(0, 0);
    for (var x = 0.0; x < s.width; x += 14) {
      p.lineTo(x, r.nextDouble() * 6);
    }
    p.lineTo(s.width, 0);
    for (var y = 0.0; y < s.height; y += 16) {
      p.lineTo(s.width - r.nextDouble() * 5, y);
    }
    p.lineTo(s.width, s.height);
    for (var x = s.width; x > 0; x -= 12) {
      p.lineTo(x, s.height - r.nextDouble() * 9);
    }
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(DoorTornClipper o) => o.seed != seed;
}

/// "NowssB. / DROP STUDIO"-style top bar with back + a trailing round icon.
class DoorTopBar extends StatelessWidget {
  const DoorTopBar({super.key, required this.slot, required this.sub, this.onBack, this.trailing});
  final String slot, sub;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Row(children: [
          DoorRoundButton(icon: Icons.arrow_back_rounded, onTap: onBack, semantic: 'Back'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              EditableLabel('$slot.brand', 'NowssB.',
                  maxLines: 1, style: doorBody(19, w: FontWeight.w800, ls: -.4).copyWith(height: 1)),
              const SizedBox(height: 3),
              EditableLabel('$slot.sub', sub.toUpperCase(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: doorBody(10, color: doorGoldSoft, w: FontWeight.w700, ls: 2.6)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// The page's animated word-poster banner: a cream poster with a giant
/// serif word, a model cut-out that breathes/sways, a black meaning tag.
/// [layout] varies it per page so no two doors are copies.
class DoorPosterBanner extends StatelessWidget {
  const DoorPosterBanner({
    super.key,
    required this.slot,
    required this.word,
    required this.tag,
    required this.figure,
    required this.t,
    this.paper = doorPaper,
    this.ink = doorInk,
    this.figureLeft = false,
    this.tilt = -.025,
    this.height = 230,
    this.photo,
  });
  final String slot, word, tag, figure;
  final String? photo; // optional photo layer behind the word
  final double t, tilt, height;
  final Color paper, ink;
  final bool figureLeft;

  @override
  Widget build(BuildContext context) {
    final a = t * math.pi * 2;
    final sway = math.sin(a) * .025;
    final lift = math.sin(a) * 5;
    final lines = word.length > 5 ? [word.substring(0, (word.length / 2).ceil()), word.substring((word.length / 2).ceil())] : [word];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Transform.rotate(
        angle: tilt + math.sin(a) * .006,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 14))],
          ),
          padding: const EdgeInsets.all(5),
          child: ClipRect(
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: paper),
              if (photo != null)
                Opacity(opacity: .9, child: DoorMedia(asset: photo, slot: '$slot.photo', t: t, drift: .5)),
              Positioned(
                left: 10,
                right: 10,
                top: 6,
                bottom: 40,
                child: Align(
                 alignment: figureLeft ? Alignment.topRight : Alignment.topLeft,
                 child: FractionallySizedBox(
                 widthFactor: .6,
                 child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: figureLeft ? Alignment.topRight : Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: figureLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      for (final l in lines)
                        Text(l.toUpperCase(),
                            textScaler: TextScaler.noScaling,
                            style: doorDisplay(110, color: photo != null ? Colors.white : ink, ls: -4)),
                    ],
                  ),
                ),
                 ),
                ),
              ),
              Positioned(
                right: figureLeft ? null : -6,
                left: figureLeft ? -6 : null,
                bottom: -8 + lift,
                top: 6,
                child: Transform.rotate(
                  angle: sway,
                  alignment: Alignment.bottomCenter,
                  child: EditableImage.asset(figure,
                      slot: '$slot.figure', fit: BoxFit.contain, alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ),
              Positioned(
                left: figureLeft ? null : 8,
                right: figureLeft ? 8 : null,
                bottom: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 210),
                  child: Transform.translate(
                    offset: Offset(math.sin(a + 1) * 3, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      color: const Color(0xF0181818),
                      child: EditableLabel('$slot.tag', tag,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: doorBody(13, w: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Gold sticker tape (dark ink on gold).
class DoorSticker extends StatelessWidget {
  const DoorSticker(this.text, {super.key, this.angle = .04, this.size = 10});
  final String text;
  final double angle, size;
  @override
  Widget build(BuildContext context) => DoorTape(text, angle: angle, gold: true, size: size);
}

/// A torn photo tile with a huge white serif word over the photo — the
/// PICK/HEAR/OWN tile, generalised. [selected] adds a gold frame + sticker.
class DoorTornTile extends StatelessWidget {
  const DoorTornTile({
    super.key,
    required this.slot,
    required this.asset,
    required this.word,
    required this.seed,
    required this.t,
    this.sticker,
    this.selected = false,
    this.wordSize = 64,
    this.child,
    this.wordTop = false,
  });
  final bool wordTop;
  final String slot, word;
  final String? asset, sticker;
  final int seed;
  final double t, wordSize;
  final bool selected;
  final Widget? child;
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: DoorTornClipper(seed),
        child: Container(
          color: selected ? doorGold : const Color(0xFFF1E8D6),
          padding: EdgeInsets.all(selected ? 7 : 5),
          child: Stack(fit: StackFit.expand, children: [
            child ?? DoorMedia(asset: asset, slot: slot, t: t),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x33000000), Color(0xDD000000)]),
              ),
            ),
            if (wordTop)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment(0, -.1), colors: [Color(0xCC000000), Color(0x00000000)]),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              top: wordTop ? 18 : null,
              bottom: wordTop ? null : 10,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: wordTop ? Alignment.topLeft : Alignment.bottomLeft,
                child: Text(word,
                    textScaler: TextScaler.noScaling,
                    style: doorDisplay(wordSize, ls: -2.5)
                        .copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 12)])),
              ),
            ),
            if (sticker != null) Positioned(right: 8, top: wordTop ? null : 10, bottom: wordTop ? 14 : null, child: DoorSticker(sticker!)),
          ]),
        ),
      );
}

/// Small gold-rule kicker: "— HOW THE DROP FLOWS".
class DoorKicker extends StatelessWidget {
  const DoorKicker(this.slot, this.text, {super.key});
  final String slot, text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Row(children: [
          Container(width: 22, height: 1.4, color: doorGold),
          const SizedBox(width: 10),
          Flexible(
            child: EditableLabel(slot, text.toUpperCase(),
                style: doorBody(11, color: doorGoldSoft, w: FontWeight.w700, ls: 2.4)),
          ),
        ]),
      );
}

/// Bottom dock like Drop Studio's BuyDock: dark glass bar, serif line, gold pill.
/// Rendered height of [DoorDock] at 1× text (margin + pill). Scale with the text scaler.
const double doorDockHeight = 100; // kicker row above the line + pill

class DoorDock extends StatelessWidget {
  const DoorDock({super.key, required this.slot, required this.kicker, required this.line, required this.action, this.onTap, this.extra});
  final String slot, kicker, line, action;
  final String? extra;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xF2120C22),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: doorGold.withValues(alpha: .55)),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20)],
        ),
        // The kicker spans the whole dock (one line where it fits); below it
        // the line + gold pill row.
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          EditableLabel('$slot.dockKicker', kicker.toUpperCase(),
              maxLines: 3, // full label, wraps on narrow phones
              style: doorBody(9.5, color: doorGoldSoft, w: FontWeight.w700, ls: 1.2)),
          const SizedBox(height: 3),
          Row(children: [
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final text = Text.rich(
                TextSpan(children: [
                  TextSpan(text: line, style: doorGreet(color: Colors.white)),
                  if (extra != null) TextSpan(text: '  $extra', style: doorBody(13, color: doorGoldSoft, w: FontWeight.w800)),
                ]),
                // Full size, never cut: a long name or price wraps between words.
                softWrap: true,
              );
              // A word is never broken ('Includ/ed'): when the longest word is
              // wider than the room, the line scales down to keep it whole.
              final scaler = MediaQuery.textScalerOf(context);
              final style = DefaultTextStyle.of(context).style.merge(doorGreet(color: Colors.white));
              var widest = 0.0;
              for (final w in line.split(RegExp(r'\s+'))) {
                final tp = TextPainter(
                    text: TextSpan(text: w, style: style),
                    textDirection: TextDirection.ltr,
                    textScaler: scaler)
                  ..layout();
                if (tp.width > widest) widest = tp.width;
                tp.dispose();
              }
              if (widest <= c.maxWidth) return text;
              return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(width: widest.ceilToDouble() + 2, child: text));
            }),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(color: doorGold, borderRadius: BorderRadius.circular(30)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action, style: doorBody(14.5, color: doorInk, w: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, color: doorInk, size: 18),
              ]),
            ),
          ),
          ]),
        ]),
      );
}


/// A screen's own hero: its real media full-bleed (or a custom [child]),
/// with an Anton title + greeting-style subline laid over a bottom scrim.
class DoorFilmHero extends StatelessWidget {
  const DoorFilmHero({
    super.key,
    required this.slot,
    required this.title,
    required this.sub,
    required this.t,
    this.asset,
    this.child,
    this.badge,
    this.height = 240,
  });
  final String slot, title, sub;
  final String? asset, badge;
  final double t, height;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final k = MediaQuery.textScalerOf(context).scale(10) / 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height * (1 + (k - 1) * .6)),
          child: Stack(children: [
            Positioned.fill(child: child ?? DoorMedia(asset: asset, slot: '$slot.media', t: t, drift: 1)),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .45, 1],
                      colors: [Color(0x33000000), Color(0x11000000), Color(0xF0000000)]),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: doorGold.withValues(alpha: .5)),
                ),
              ),
            ),
            if (badge != null) Positioned(right: 12, top: 12, child: DoorSticker(badge!)),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: height * (1 + (k - 1) * .6)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title.toUpperCase(),
                      style: doorDisplay(40, ls: 0).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 14)])),
                  const SizedBox(height: 4),
                  Text(sub, style: doorSub(color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
