// The Player's sound picker: what plays softly under the teacher's voice.
// Black and white glass cards; tapping one plays it right away and keeps it.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class MusicBed {
  const MusicBed(this.id, this.name, this.line);
  final String id;
  final String name;
  final String line;
}

const kMusicBeds = <MusicBed>[
  MusicBed('drone', 'Drone', 'A deep, steady hum'),
  MusicBed('pad', 'Warm pad', 'A soft chord that breathes'),
  MusicBed('bowl', 'Singing bowl', 'A gentle bell, now and then'),
  MusicBed('bansuri', 'Bansuri', 'A soft bamboo flute'),
  MusicBed('tanpura', 'Tanpura', 'Strings that hum in a circle'),
  MusicBed('voice', 'Voice only', 'Just your teacher'),
];

/// Opens the sheet. [onPick] plays the stage with that sound and keeps it;
/// [previewSeconds] is how long that preview runs.
Future<void> showMusicPicker(
  BuildContext context, {
  required String current,
  required Future<void> Function(String id) onPick,
  double previewSeconds = 9,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x8C000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => Align(
      alignment: Alignment.bottomCenter,
      child: MusicPickerSheet(current: current, onPick: onPick, previewSeconds: previewSeconds),
    ),
    transitionBuilder: (ctx, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(position: Tween(begin: const Offset(0, .18), end: Offset.zero).animate(c), child: child),
      );
    },
  );
}

class MusicPickerSheet extends StatefulWidget {
  const MusicPickerSheet({super.key, required this.current, required this.onPick, this.previewSeconds = 9});
  final String current;
  final Future<void> Function(String id) onPick;
  final double previewSeconds;

  @override
  State<MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> with SingleTickerProviderStateMixin {
  late String _sel = widget.current;
  String? _playing;
  late final AnimationController _eq =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Timer? _stopEq;

  @override
  void dispose() {
    _stopEq?.cancel();
    _eq.dispose();
    super.dispose();
  }

  Future<void> _tap(String id) async {
    _stopEq?.cancel();
    setState(() {
      _sel = id;
      _playing = id;
    });
    _eq.repeat();
    _stopEq = Timer(Duration(milliseconds: (widget.previewSeconds * 1000).round()), () {
      if (!mounted) return;
      _eq.stop();
      setState(() => _playing = null);
    });
    await widget.onPick(id);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 10 + bottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              key: const ValueKey('music-sheet'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD91C1C1F), Color(0xF2050506)],
                ),
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0x4DFFFFFF), borderRadius: BorderRadius.circular(9))),
                ),
                const SizedBox(height: 16),
                const Text('Sound',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.3)),
                const SizedBox(height: 2),
                const Text('Plays softly under your teacher’s voice',
                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.02,
                  children: [
                    for (final b in kMusicBeds)
                      _BedCard(
                        bed: b,
                        selected: _sel == b.id,
                        playing: _playing == b.id,
                        eq: _eq,
                        onTap: () => _tap(b.id),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  key: const ValueKey('music-done'),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: const Text('Done',
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
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

class _BedCard extends StatelessWidget {
  const _BedCard({required this.bed, required this.selected, required this.playing, required this.eq, required this.onTap});
  final MusicBed bed;
  final bool selected;
  final bool playing;
  final Animation<double> eq;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('music-opt-${bed.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? const Color(0x24FFFFFF) : const Color(0x0DFFFFFF),
          border: Border.all(color: selected ? Colors.white : const Color(0x1FFFFFFF), width: selected ? 1.4 : 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(fit: StackFit.expand, children: [
                    AnimatedScale(
                      scale: playing ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(selected ? _kSoftMono : _kMono),
                        child: Image.asset(
                          'assets/images/sound_beds/${bed.id}.webp',
                          key: ValueKey('music-photo-${bed.id}'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0x14FFFFFF)),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x8C000000)],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 15, color: Colors.black),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: playing
                    ? AnimatedBuilder(animation: eq, builder: (_, __) => _Eq(t: eq.value))
                    : Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(bed.name,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -.1)),
          const SizedBox(height: 2),
          Text(bed.line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
        ]),
      ),
    );
  }
}

/// Four bars that bounce while a sound previews.
class _Eq extends StatelessWidget {
  const _Eq({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('music-eq'),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: 5 + 11 * (.5 + .5 * math.sin(t * math.pi * 2 * (i.isEven ? 1 : 2) + i * 1.3)).abs(),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
          ),
      ]),
    );
  }
}

/// Photos sit in the black-and-white look: mostly grey until picked, then
/// in their own colour.
List<double> _sat(double v) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  return [
    r + (1 - r) * v, g - g * v, b - b * v, 0, 0,
    r - r * v, g + (1 - g) * v, b - b * v, 0, 0,
    r - r * v, g - g * v, b + (1 - b) * v, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

final _kMono = _sat(0.25);
final _kSoftMono = _sat(1.0);
