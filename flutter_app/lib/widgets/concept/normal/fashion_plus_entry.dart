/// Zen Plus entry (Ribon 11-02): a white neumorphic card holding a brand-new
/// Flutter animation — a dark video window (golden_breath.dart), Ribon 11-03.
/// Tapping eases the clip forward,
/// then calls [onEnter].
///
/// [bgDim] is kept for call-site compatibility (the Zen home's dim setting)
/// and only deepens the lotus tint slightly, so the card previews it.
library;

import 'package:flutter/material.dart';
import '../../../media/golden_breath.dart';
import 'surface.dart';

class NFashionPlusEntry extends StatefulWidget {
  const NFashionPlusEntry({super.key, required this.onEnter, this.bgDim});
  final VoidCallback onEnter;
  final double? bgDim;
  @override
  State<NFashionPlusEntry> createState() => _NFashionPlusEntryState();
}

class _NFashionPlusEntryState extends State<NFashionPlusEntry> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(milliseconds: 6000);
  bool _opening = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _enter() async {
    if (_opening) return;
    setState(() => _opening = true);
    if (!_reduced) await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    widget.onEnter();
    if (!_reduced) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Enter Zen Plus', onTap: _enter, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step into', style: nHello),
            Text('Zen Plus', style: nTitle),
            SizedBox(height: 4),
            Text('A calmer, deeper home for your practice. Tap anywhere to open it.', style: nSub),
          ])),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('zen-plus-well'),
            height: 236,
            decoration: neu(r: 22, pressed: true),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _opening ? 1 : 0), duration: _reduced ? Duration.zero : const Duration(milliseconds: 480), curve: Curves.easeOutCubic,
              builder: (_, open, __) => ClipRRect(
                key: const ValueKey('zen-plus-lotus'),
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  Transform.scale(scale: 1 + .06 * open, child: const GoldenBreathClip(slot: 'fashion_plus_entry.NFashionPlusEntry',
                      asset: kGoldenBreathClip, poster: kGoldenBreathPoster, alignment: Alignment(.3, -.1))),
                  // a lavender breath at the foot ties the dark window to the white card
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x00000000), Color(0x447B61D9)], stops: [0, .6, 1]))),
                  DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: .5), width: 1.4))),
                ]),
              ),
            ),
          ),
        ]),
      )));
}
