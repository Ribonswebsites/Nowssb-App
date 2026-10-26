/// DOOR SCREENS — Start art still picker (FashionPlusScreen mode startArt).
/// Signature move: THE PIN WALL — the stills are torn prints pinned in a
/// tilted, overlapping collage; tapping one lifts it to the front, swings
/// it on its pin and floods the page behind with it. "BLACK" is the
/// no-image option (id = '-1', the normal NowssB black).
/// Writes (via Builder): nwsb_fashplus_image (index, -1 = none).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/day_part.dart';
import 'door_kit.dart';

const _slot = 'concept.Doors.StartArt';

class DoorStill {
  const DoorStill({required this.id, required this.name, this.asset});
  final String id; // Settings.fashionImages index as string; '-1' = none
  final String name;
  final String? asset;
}

class DoorStartArtPicker extends StatefulWidget {
  const DoorStartArtPicker({
    super.key,
    required this.stills,
    required this.selectedId,
    this.onPickImage,
    this.onBack,
    this.debugPhase,
    this.debugFocus,
  });
  final List<DoorStill> stills; // include DoorStill(id:'-1', name:'Black') first
  final String selectedId;
  final void Function(String id)? onPickImage;
  final VoidCallback? onBack;
  final double? debugPhase;
  final String? debugFocus;

  @override
  State<DoorStartArtPicker> createState() => _S();
}

class _S extends State<DoorStartArtPicker> with TickerProviderStateMixin, DoorPhase {
  late String _focus = widget.debugFocus ?? widget.selectedId;
  late final AnimationController _swing =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900), value: 1);

  @override
  double? get debugPhaseValue => widget.debugPhase;

  @override
  void initState() {
    super.initState();
    startPhase();
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  DoorStill get _f => widget.stills.firstWhere((s) => s.id == _focus, orElse: () => widget.stills.first);

  void _tap(DoorStill s) {
    HapticFeedback.selectionClick();
    if (s.id == _focus) {
      HapticFeedback.mediumImpact();
      widget.onPickImage?.call(s.id);
      return;
    }
    setState(() => _focus = s.id);
    _swing.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doorDeep,
      body: AnimatedBuilder(
        animation: Listenable.merge([phase, _swing]),
        builder: (context, _) {
          final t = phase.value;
          final f = _f;
          final chosen = widget.selectedId == f.id;
          return Stack(fit: StackFit.expand, children: [
            DoorBackdrop(asset: f.asset, slot: '$_slot.backdrop', t: t, dim: .55),
            SafeArea(
              child: Column(children: [
                DoorTopBar(slot: _slot, sub: 'Start art', onBack: widget.onBack),
                Expanded(
                  child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
                    () {
                      final h = widget.stills.firstWhere((x) => x.id == _focus, orElse: () => widget.stills.first);
                      return DoorFilmHero(
                        slot: '$_slot.hero',
                        asset: h.asset,
                        t: t,
                        title: h.name,
                        sub: h.id == widget.selectedId ? 'Behind your start while motion rests' : 'Previewing this still',
                        badge: h.id == widget.selectedId ? 'Pinned' : null,
                        child: h.asset == null ? const _BlackPlate(big: true) : null,
                      );
                    }(),
                    const DoorKicker('$_slot.k', 'Pin one to the wall'),
                    LayoutBuilder(builder: (context, c) => _wall(c.maxWidth, t)),
                  ]),
                ),
                DoorDock(
                  slot: _slot,
                  kicker: chosen ? 'On the start now' : 'Previewing',
                  line: f.name,
                  action: chosen ? 'Pinned' : 'Pin it',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onPickImage?.call(f.id);
                  },
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _wall(double w, double t) {
    final tileW = (w - 28) * .49; // no horizontal overlap: words stay whole
    final tileH = tileW * 1.05;
    final step = tileH * .62;
    final n = widget.stills.length;
    final h = step * (n - 1) + tileH + 20;
    final order = [
      for (final s in widget.stills)
        if (s.id != _focus) s,
      for (final s in widget.stills)
        if (s.id == _focus) s,
    ];
    return SizedBox(
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        for (final s in order) _pinned(s, widget.stills.indexOf(s), w, tileW, tileH, step, t),
      ]),
    );
  }

  Widget _pinned(DoorStill s, int i, double w, double tw, double th, double step, double t) {
    final left = i.isEven ? 14.0 : w - 14 - tw;
    final top = i * step;
    final focused = s.id == _focus;
    final picked = s.id == widget.selectedId;
    final base = (i.isEven ? -1 : 1) * (.05 + (i % 3) * .02);
    final swing = focused ? math.sin(_swing.value * math.pi * 3) * (1 - _swing.value) * .18 : 0.0;
    final breathe = math.sin((t + i * .13) * math.pi * 2) * .012;
    final words = s.name.split(' ');
    return Positioned(
      left: left,
      top: top,
      width: tw,
      height: th,
      child: Semantics(
        button: true,
        selected: picked,
        label: s.name,
        child: GestureDetector(
          onTap: () => _tap(s),
          child: Transform.rotate(
            angle: (focused ? 0 : base) + swing + breathe,
            alignment: Alignment.topCenter,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: focused ? 1.06 : 1,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(4, 12))]),
                    child: DoorTornTile(
                      slot: '$_slot.tile.${s.id}',
                      asset: s.asset,
                      seed: 40 + i,
                      t: focused ? t : 0,
                      selected: focused,
                      sticker: picked && tw > 170 ? 'On the start' : null, // narrow tiles: gold frame only, word stays clear
                      word: words.length > 1 ? '${words.first}\n${words.skip(1).join(' ')}' : s.name,
                      wordSize: 34,
                      wordTop: true,
                      child: s.asset == null ? const _BlackPlate() : null,
                    ),
                  ),
                ),
                // the pin
                Positioned(
                  top: -6,
                  left: tw / 2 - 9,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [doorGoldSoft, doorGold, Color(0xFF6E5A30)]),
                      boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 2))],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Real preview of the black start: pure black, the NowssB. mark, the
/// greeting and the gold play ring exactly where the start screen puts them.
class _BlackPlate extends StatelessWidget {
  const _BlackPlate({this.big = false});
  final bool big;
  @override
  Widget build(BuildContext context) {
    // Hero: preview sits top-right, clear of the title. Tile: bottom, clear of the word.
    return ColoredBox(
      color: Colors.black,
      child: Align(
        alignment: big ? const Alignment(.92, -.8) : const Alignment(0, .9),
        child: FractionallySizedBox(
          widthFactor: big ? .42 : .7,
          heightFactor: .5,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 240,
              height: 260,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('NowssB.', textScaler: TextScaler.noScaling, style: doorBody(30, w: FontWeight.w800)),
                const SizedBox(height: 14),
                Text(dayPartFor(DayClock.now()).greeting, textScaler: TextScaler.noScaling, style: doorGreet(color: const Color(0xFFB9B9C3))),
                Text('Healer', textScaler: TextScaler.noScaling, style: doorTitle()),
                const SizedBox(height: 16),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: doorGold, width: 2)),
                  child: const Icon(Icons.play_arrow_rounded, color: doorGold, size: 30),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
