/// DOOR SCREENS — Fashion Plus page (WidgetsPage: streak widget, Add to
/// home screen, Hero header = Themes, Jump to, Make it yours) + a new
/// background-film DIM DIAL.
///
/// Every card is a Fashion-home Hero glass pane (GlassWrap: blur 9, 5.5%
/// fill, 13% line, 18 radius) carrying the 2nd Hero card's full-banner art
/// (the rail clip's own poster) edge to edge, with giant serif type on a
/// dark scrim. Animated vector motion (CustomPainter): orbit rings,
/// silk ribbons and a spark field drift over the film.
/// Signature move: THE DIAL — drag a gold knob round a 270° arc; the film
/// behind the page brightens/dims live as you turn it.
/// Writes (via Builder): nwsb_fashplus_bg_dim (0..1), nwsb_hero_style.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/template/editable.dart';
import 'door_kit.dart';
import 'film_dial.dart';

const _slot = 'concept.Doors.FashionPlus';

class DoorHeroStyle {
  const DoorHeroStyle(this.id, this.title, this.sub, this.art);
  final String id, title, sub, art;
  static const all = [
    DoorHeroStyle('tv', 'On the television', 'The set, on the page', 'assets/video/hero-word-store-poster.webp'),
    DoorHeroStyle('full', 'Full screen', 'The photographs, edge to edge', 'assets/fashion/fp-intro.webp'),
    DoorHeroStyle('plain', 'Plain header', 'No pictures, no set', 'assets/video/subscription-b-poster.webp'),
  ];
}

class DoorJump {
  const DoorJump(this.id, this.title, this.sub, this.art, {this.toggle});
  final String id, title, sub, art;
  final bool? toggle; // non-null → this card is a switch
}

class DoorFashionPlusPage extends StatefulWidget {
  const DoorFashionPlusPage({
    super.key,
    required this.backdrop,
    required this.streak,
    required this.wordOfDay,
    required this.wordLine,
    required this.heroStyle,
    required this.dim,
    required this.jumps,
    required this.make,
    this.addingToHome = false,
    this.onBack,
    this.onPractise,
    this.onAddToHome,
    this.onPickStyle,
    this.onDimChanged,
    this.onDimChangeEnd,
    this.onJump,
    this.onMake,
    this.onToggle,
    this.debugPhase,
  });
  final String backdrop; // current film poster (Builder: live clip)
  final int streak;
  final String wordOfDay, wordLine;
  final String heroStyle; // tv | full | plain
  final double dim; // 0 = film hidden … 1 = film full
  final List<DoorJump> jumps, make;
  final bool addingToHome;
  final VoidCallback? onBack, onPractise, onAddToHome;
  final void Function(String id)? onPickStyle;
  final ValueChanged<double>? onDimChanged;
  /// Fires on release; this is when Builder saves nwsb_fashplus_bg_dim.
  final ValueChanged<double>? onDimChangeEnd;
  final void Function(String id)? onJump, onMake;
  final void Function(String id, bool on)? onToggle;
  final double? debugPhase;

  @override
  State<DoorFashionPlusPage> createState() => _S();
}

class _S extends State<DoorFashionPlusPage> with TickerProviderStateMixin, DoorPhase {
  late double _dim = widget.dim;

  @override
  double? get debugPhaseValue => widget.debugPhase;

  @override
  void initState() {
    super.initState();
    startPhase();
  }

  @override
  void didUpdateWidget(DoorFashionPlusPage o) {
    super.didUpdateWidget(o);
    if (o.dim != widget.dim) _dim = widget.dim;
  }

  void _setDim(double v) {
    v = v.clamp(0.0, 1.0);
    if ((v * 20).round() != (_dim * 20).round()) HapticFeedback.selectionClick();
    setState(() => _dim = v);
    widget.onDimChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: phase,
        builder: (context, _) {
          final t = phase.value;
          return Stack(fit: StackFit.expand, children: [
            Opacity(
              opacity: .12 + .88 * _dim,
              child: DoorMedia(asset: widget.backdrop, slot: '$_slot.backdrop', t: t, drift: .6),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x55000000), Color(0xCC000000)]),
              ),
            ),
            IgnorePointer(child: CustomPaint(painter: _VectorStorm(t))),
            SafeArea(
              child: Column(children: [
                DoorTopBar(slot: _slot, sub: 'Fashion Plus', onBack: widget.onBack),
                Expanded(
                  child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
                    DoorTicker(items: const ['Fashion Plus', 'Your film', 'Your header', 'Your doors'], t: t),
                    _streakCard(t),
                    const DoorKicker('$_slot.kDial', 'Film visibility'),
                    FilmDial(value: _dim, onChanged: _setDim, onChangeEnd: widget.onDimChangeEnd, debugPhase: t),
                    const DoorKicker('$_slot.kHero', 'Hero header'),
                    for (var i = 0; i < DoorHeroStyle.all.length; i++) _heroCard(DoorHeroStyle.all[i], i, t),
                    const DoorKicker('$_slot.kJump', 'Jump to'),
                    for (var i = 0; i < widget.jumps.length; i++) _bannerCard(widget.jumps[i], i, t, widget.onJump),
                    const DoorKicker('$_slot.kMake', 'Make it yours'),
                    for (var i = 0; i < widget.make.length; i++) _bannerCard(widget.make[i], i + 3, t, widget.onMake),
                  ]),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _streakCard(double t) => _Glass(
        child: _BannerArt(
          art: 'assets/video/fashion-plus-bg-silver-poster.webp',
          slot: '$_slot.streak',
          t: t,
          height: 210,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${widget.streak}', textScaler: TextScaler.noScaling, style: doorDisplay(96, color: doorGold, ls: -3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(widget.streak == 1 ? 'DAY STREAK' : 'DAYS IN A ROW',
                        style: doorBody(12, color: doorGoldSoft, w: FontWeight.w800, ls: 2)),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              const Spacer(),
              Text(widget.wordOfDay.toUpperCase(), style: doorTitle()),
              const SizedBox(height: 4),
              Text(widget.wordLine, style: doorSub()),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Pill(label: 'Practise', icon: Icons.play_arrow_rounded, onTap: widget.onPractise),
                _Pill(
                    label: widget.addingToHome ? 'Adding…' : 'Add to home screen',
                    icon: Icons.add_to_home_screen_rounded,
                    dark: true,
                    onTap: widget.onAddToHome),
              ]),
            ]),
          ),
        ),
      );

  Widget _heroCard(DoorHeroStyle s, int i, double t) {
    final on = widget.heroStyle == s.id;
    return _Glass(
      gold: on,
      child: _BannerArt(
        art: s.art,
        slot: '$_slot.hero.${s.id}',
        t: (t + i * .3) % 1,
        height: 190,
        preview: _HeroPreview(kind: s.id, art: s.art, t: t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(s.id.toUpperCase(), textScaler: TextScaler.noScaling, style: doorDisplay(64, ls: -2)),
              if (on) const DoorSticker('On your home'),
            ]),
            const Spacer(),
            Text(s.title, style: doorGreet(color: Colors.white)),
            Text(s.sub, style: doorSub()),
            const SizedBox(height: 10),
            _Pill(
              label: on ? 'Applied' : 'Apply now',
              icon: on ? Icons.check_rounded : Icons.arrow_forward_rounded,
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onPickStyle?.call(s.id);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _bannerCard(DoorJump j, int i, double t, void Function(String)? go) => GestureDetector(
        onTap: j.toggle != null ? () => widget.onToggle?.call(j.id, !j.toggle!) : () => go?.call(j.id),
        child: _Glass(
          child: _BannerArt(
            art: j.art,
            slot: '$_slot.card.${j.id}',
            t: (t + i * .17) % 1,
            height: 118,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                    // Words never break mid-word: wrap at spaces, shrink a long single word to fit.
                    for (final w in j.title.split(' '))
                      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(w, style: doorTitle())),
                    const SizedBox(height: 4),
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(j.sub, style: doorSub(color: Colors.white)),
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                if (j.toggle != null)
                  _Lever(on: j.toggle!, onChanged: (v) => widget.onToggle?.call(j.id, v))
                else
                  const DoorRoundButton(icon: Icons.arrow_forward_rounded, semantic: 'Open', size: 40),
              ]),
            ),
          ),
        ),
      );
}

/// Fashion-home Hero glass (GlassWrap values).
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.gold = false});
  final Widget child;
  final bool gold;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: const [BoxShadow(color: Color(0x57000000), offset: Offset(0, 16), blurRadius: 40)],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x0EFFFFFF),
                borderRadius: r,
                border: Border.all(color: gold ? doorGold : const Color(0x21FFFFFF), width: gold ? 1.6 : 1),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The 2nd Hero card's full-banner art: the clip's poster edge to edge
/// inside the glass, scrimmed for type. Height grows with text scale.
class _BannerArt extends StatelessWidget {
  const _BannerArt({required this.art, required this.slot, required this.t, required this.height, required this.child, this.preview});
  final String art, slot;
  final double t, height;
  final Widget child;
  final Widget? preview;
  @override
  Widget build(BuildContext context) {
    final k = MediaQuery.textScalerOf(context).scale(10) / 10;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height * (1 + (k - 1) * .8)),
        child: Stack(children: [
          Positioned.fill(child: preview ?? DoorMedia(asset: art, slot: slot, t: t, drift: .8)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x22000000), Color(0xE6000000)]),
              ),
            ),
          ),
          ConstrainedBox(constraints: BoxConstraints(minHeight: height * (1 + (k - 1) * .8)), child: IntrinsicHeight(child: child)),
        ]),
      ),
    );
  }
}

/// Live mini-preview of each hero look, drawn inside its own card.
class _HeroPreview extends StatelessWidget {
  const _HeroPreview({required this.kind, required this.art, required this.t});
  final String kind, art;
  final double t;
  @override
  Widget build(BuildContext context) {
    if (kind == 'full') return DoorMedia(asset: art, slot: '$_slot.hero.full', t: t);
    if (kind == 'plain') {
      return CustomPaint(painter: _VectorStorm(t, dense: false), child: const ColoredBox(color: Color(0x99100A1E)));
    }
    // tv: the set — a bezel with the clip glowing in it
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF0B0F1E)),
      Align(
        alignment: const Alignment(.92, -.85),
        child: FractionallySizedBox(
          widthFactor: .5,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white38),
                boxShadow: [BoxShadow(color: doorViolet.withValues(alpha: .5 + .3 * math.sin(t * math.pi * 2)), blurRadius: 28)],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(5), child: DoorMedia(asset: art, slot: '$_slot.hero.tv', t: t)),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon, this.onTap, this.dark = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: dark ? Colors.black : doorGold,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: dark ? doorGold : doorGoldSoft),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: dark ? doorGoldSoft : doorInk), const SizedBox(width: 6)],
              Flexible(child: Text(label, style: doorBody(14.5, color: dark ? Colors.white : doorInk, w: FontWeight.w800))),
            ]),
          ),
        ),
      );
}

/// Gold-on-black lever switch (no white-on-white).
class _Lever extends StatelessWidget {
  const _Lever({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onChanged(!on);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 66,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: on ? doorGold : Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: doorGold, width: 1.4),
            ),
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, color: on ? doorInk : doorGoldSoft),
              child: Center(child: Text(on ? 'ON' : 'OFF',
                  textScaler: TextScaler.noScaling,
                  style: doorBody(7.5, color: on ? doorGoldSoft : doorInk, w: FontWeight.w900))),
            ),
          ),
        ),
      );
}

/// THE DIAL — 270° arc, gold knob, serif percentage, film ticks.
/// Wild vector motion: orbit rings, two silk ribbons and a spark field.
class _VectorStorm extends CustomPainter {
  _VectorStorm(this.t, {this.dense = true});
  final double t;
  final bool dense;
  @override
  void paint(Canvas c, Size s) {
    final a = t * math.pi * 2;
    // orbit rings
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (var i = 0; i < (dense ? 4 : 2); i++) {
      final o = Offset(s.width * (.8 + .05 * math.sin(a + i)), s.height * (.18 + i * .22));
      ring.color = (i.isEven ? doorGold : doorViolet).withValues(alpha: .28);
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(a * (i.isEven ? 1 : -1) + i);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: s.width * .7, height: s.width * .22), ring);
      c.restore();
    }
    // silk ribbons
    for (var k = 0; k < 2; k++) {
      final p = Path();
      for (var x = 0.0; x <= s.width; x += 8) {
        final y = s.height * (.35 + k * .3) + math.sin(x / s.width * math.pi * 2 + a + k * 2) * 40 + math.sin(x / 37 + a * 2) * 6;
        x == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = LinearGradient(colors: [Colors.transparent, (k == 0 ? doorGoldSoft : const Color(0xFFB98CFF)).withValues(alpha: .55), Colors.transparent])
            .createShader(Offset.zero & s));
    }
    // sparks
    final r = math.Random(7);
    for (var i = 0; i < (dense ? 46 : 18); i++) {
      final x = r.nextDouble() * s.width;
      final y = (r.nextDouble() * s.height - t * s.height * (.2 + r.nextDouble() * .3)) % s.height;
      final tw = (math.sin(a * 2 + i) + 1) / 2;
      c.drawCircle(Offset(x, y), .8 + tw * 1.6, Paint()..color = Colors.white.withValues(alpha: .15 + .45 * tw));
    }
  }

  @override
  bool shouldRepaint(_VectorStorm o) => o.t != t;
}
