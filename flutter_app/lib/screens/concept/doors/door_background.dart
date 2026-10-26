/// DOOR SCREENS — Background film picker (FashionPlusScreen mode background).
/// Signature move: THE REEL — a fanned poster deck you flip through; the
/// focused film fills the whole page behind everything, live.
/// Writes (via Builder): nwsb_fashplus_video (index) and Fashion Plus motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'door_kit.dart';

const _slot = 'concept.Doors.Background';

class DoorVideo {
  const DoorVideo({required this.id, required this.name, required this.poster, this.asset});
  final String id; // Builder: Settings.fashionVideos index as string
  final String name;
  final String poster; // the clip's own -poster.webp frame
  final String? asset; // the .mp4, for Builder's live preview
}

class DoorBackgroundPicker extends StatefulWidget {
  const DoorBackgroundPicker({
    super.key,
    required this.videos,
    required this.selectedId,
    required this.motionOn,
    this.onPickVideo,
    this.onToggleMotion,
    this.onBack,
    this.debugPhase,
    this.debugFocus,
  });
  final List<DoorVideo> videos;
  final String selectedId;
  final bool motionOn;
  final void Function(String id)? onPickVideo;
  final void Function(bool on)? onToggleMotion;
  final VoidCallback? onBack;
  final double? debugPhase;
  final int? debugFocus;

  @override
  State<DoorBackgroundPicker> createState() => _S();
}

class _S extends State<DoorBackgroundPicker> with TickerProviderStateMixin, DoorPhase {
  late int _focus = widget.debugFocus ??
      math.max(0, widget.videos.indexWhere((v) => v.id == widget.selectedId));
  late final PageController _deck = PageController(viewportFraction: .64, initialPage: _focus);

  @override
  double? get debugPhaseValue => widget.debugPhase;

  @override
  void initState() {
    super.initState();
    startPhase();
  }

  @override
  void dispose() {
    _deck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.videos[_focus];
    final on = widget.motionOn;
    return Scaffold(
      backgroundColor: doorDeep,
      body: AnimatedBuilder(
        animation: phase,
        builder: (context, _) {
          final t = phase.value;
          return Stack(fit: StackFit.expand, children: [
            DoorBackdrop(asset: v.poster, slot: '$_slot.backdrop', t: on ? t : 0, dim: .6),
            SafeArea(
              child: Column(children: [
                DoorTopBar(slot: _slot, sub: 'Background film', onBack: widget.onBack),
                Expanded(
                  // Bottom padding = dock height, so the last reel tile scrolls fully clear.
                  child: ListView(padding: EdgeInsets.only(bottom: MediaQuery.textScalerOf(context).scale(doorDockHeight)), children: [
                    DoorFilmHero(
                      slot: '$_slot.hero',
                      asset: v.poster,
                      t: on ? t : 0,
                      title: v.name,
                      sub: on ? 'Plays behind every page' : 'Held still · motion is off',
                      badge: v.id == widget.selectedId ? 'Playing' : 'Preview',
                    ),
                    const DoorKicker('$_slot.k1', 'Motion'),
                    _MotionSwitch(on: on, t: t, poster: v.poster, onChanged: (b) {
                      HapticFeedback.mediumImpact();
                      widget.onToggleMotion?.call(b);
                    }),
                    const DoorKicker('$_slot.k2', 'Flip the reel'),
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        controller: _deck,
                        itemCount: widget.videos.length,
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _focus = i);
                        },
                        itemBuilder: (context, i) => AnimatedBuilder(
                          animation: _deck,
                          builder: (context, child) {
                            final p = _deck.hasClients && _deck.position.haveDimensions
                                ? (_deck.page ?? _focus.toDouble())
                                : _focus.toDouble();
                            final d = (i - p).clamp(-1.5, 1.5);
                            return Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, .0012)
                                ..rotateZ(d * .09)
                                ..translateByDouble(0, d.abs() * 26, 0, 1)
                                ..scaleByDouble(1 - d.abs() * .12, 1 - d.abs() * .12, 1, 1),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (i != _focus) {
                                _deck.animateToPage(i, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
                              } else {
                                HapticFeedback.mediumImpact();
                                widget.onPickVideo?.call(widget.videos[i].id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: _ReelCard(
                                v: widget.videos[i],
                                t: on ? (t + i * .25) % 1 : 0,
                                seed: 11 + i,
                                playing: widget.videos[i].id == widget.selectedId,
                                focused: i == _focus,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Dots(n: widget.videos.length, i: _focus),
                  ]),
                ),
                DoorDock(
                  slot: _slot,
                  kicker: widget.selectedId == v.id ? 'Playing behind every page' : 'Preview',
                  line: v.name,
                  action: widget.selectedId == v.id ? 'Playing' : 'Set film',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onPickVideo?.call(v.id);
                  },
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.v, required this.t, required this.seed, required this.playing, required this.focused});
  final DoorVideo v;
  final double t;
  final int seed;
  final bool playing, focused;
  @override
  Widget build(BuildContext context) {
    final words = v.name.split(' ');
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black87, blurRadius: 22, offset: Offset(0, 12))]),
      child: DoorTornTile(
        slot: '$_slot.reel.${v.id}',
        asset: v.poster,
        seed: seed,
        t: t,
        selected: playing,
        sticker: playing ? 'Playing' : (focused ? 'Tap to set' : null),
        word: words.join('\n'),
        wordSize: 58,
      ),
    );
  }
}

/// PLAY / HOLD — two torn halves of the current film; the live half is
/// gold-framed and the held half is desaturated.
class _MotionSwitch extends StatelessWidget {
  const _MotionSwitch({required this.on, required this.t, required this.poster, required this.onChanged});
  final bool on;
  final double t;
  final String poster;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    Widget half(bool value, String word, String sub, int seed, double angle) {
      final active = on == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: '$word: $sub',
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Transform.rotate(
              angle: angle,
              child: AnimatedScale(
                scale: active ? 1 : .92,
                duration: const Duration(milliseconds: 260),
                child: SizedBox(
                  height: 130,
                  child: ColorFiltered(
                    colorFilter: active
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([
                            .33, .33, .33, 0, 0, .33, .33, .33, 0, 0, .33, .33, .33, 0, 0, 0, 0, 0, 1, 0,
                          ]),
                    child: DoorTornTile(
                      slot: '$_slot.motion.$word',
                      asset: poster,
                      seed: seed,
                      t: value && on ? t : 0,
                      selected: active,
                      sticker: active ? sub : null,
                      word: word,
                      wordSize: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        half(true, 'PLAY', 'Moving', 3, -.035),
        const SizedBox(width: 10),
        half(false, 'HOLD', 'Still', 7, .03),
      ]),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.n, required this.i});
  final int n, i;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < n; k++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: k == i ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(color: k == i ? doorGold : Colors.white38, borderRadius: BorderRadius.circular(4)),
          ),
      ]);
}
