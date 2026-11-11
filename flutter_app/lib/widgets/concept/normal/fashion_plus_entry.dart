/// Zen Plus entry (Ribon 11-11 rebuild): a white neumorphic card with a new
/// still photo (assets/home/hx/zenplus-terrace.webp, self-generated) in a
/// pressed well, layered with a black pill + gold tag, a feature ticker
/// ([GentleMarqueeText]) and the existing glint sweep ([NormalLoop]); below it
/// feature tiles, "inside" chips and a black CTA. The only motion is what the
/// app already had: the card's open-zoom on tap, the [NormalLoop] glint, the
/// premium Lottie and the home marquee. Tapping eases the photo forward, then
/// calls [onEnter].
///
/// [bgDim] is kept for call-site compatibility (the Zen home's dim setting).
library;

import 'package:flutter/material.dart';
import '../../home_parts.dart' show GentleMarqueeText;
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

  static const _gold = Color(0xFFE0B04C);

  Widget _tile(IconData icon, String big, String label) => Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: neu(r: 16, pressed: true),
        child: Column(children: [
          Icon(icon, size: 19, color: nAccent),
          const SizedBox(height: 5),
          Text(big, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: nInk, height: 1.15)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: nSoft, height: 1.2)),
        ]),
      ));

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: nBase, borderRadius: BorderRadius.circular(30), boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 7),
          BoxShadow(color: Color(0x2E8E97B5), offset: Offset(3, 4), blurRadius: 9),
        ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: const Color(0xFFB8821C)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nInk, height: 1.1)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Enter Zen Plus', onTap: _enter, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step into', style: nHello),
              Text('Zen Plus', style: nTitle),
              SizedBox(height: 4),
              Text('A calmer, deeper home for your practice.', style: nSub),
            ])),
            const SizedBox(width: 10),
            Container(width: 54, height: 54, decoration: neu(r: 18, pressed: true),
                child: const Center(child: NLottie('assets/home/nm-anim-premium.json', size: 40))),
          ])),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('zen-plus-well'),
            height: 262,
            padding: const EdgeInsets.all(5),
            decoration: neu(r: 24, pressed: true),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _opening ? 1 : 0), duration: _reduced ? Duration.zero : const Duration(milliseconds: 480), curve: Curves.easeOutCubic,
              builder: (_, open, __) => ClipRRect(
                key: const ValueKey('zen-plus-lotus'),
                borderRadius: BorderRadius.circular(19),
                child: Stack(fit: StackFit.expand, children: [
                  Transform.scale(scale: 1 + .06 * open, child: const Image(
                      image: AssetImage('assets/home/hx/zenplus-terrace.webp'), fit: BoxFit.cover, alignment: Alignment(-.35, 0))),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: [0, .35, .72, 1], colors: [Color(0x55000000), Color(0x00000000), Color(0x22000000), Color(0xEB000000)]))),
                  // the existing glint sweep, slowed to this card's own loop
                  AnimatedBuilder(animation: loop, builder: (_, __) => DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment(-2 + 4 * loop.value, -1), end: Alignment(-1 + 4 * loop.value, 1),
                    colors: const [Color(0x00FFFFFF), Color(0x26FFFFFF), Color(0x00FFFFFF)])))),
                  Positioned(left: 10, top: 10, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('ZEN HOME', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
                      SizedBox(width: 7),
                      Text('PLUS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: _gold)),
                    ]),
                  )),
                  Positioned(left: 14, right: 14, bottom: 46, child: const Text('Dawn over the quiet ridge.',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2,
                          shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)]))),
                  Positioned(left: 0, right: 0, bottom: 0, child: Container(
                    height: 34, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.centerLeft,
                    color: const Color(0x99000000),
                    child: const GentleMarqueeText('Live video  ·  Golden Breath  ·  Drop Studio  ·  Poster pages  ·  Dimmable look  ·  Glass sections  ·  ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                  )),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _tile(Icons.videocam_outlined, 'Live video', 'moving home'),
            const SizedBox(width: 10),
            _tile(Icons.tune_rounded, 'Dimmable', 'your own look'),
            const SizedBox(width: 10),
            _tile(Icons.layers_outlined, 'Glass', 'every section'),
          ])),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(Icons.air_rounded, 'Golden Breath'),
            _chip(Icons.palette_outlined, 'Drop Studio'),
            _chip(Icons.photo_library_outlined, 'Poster pages'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: Text('Tap anywhere to open it.', style: nSub)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(40),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 5), blurRadius: 10)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Enter now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 16, color: _gold),
              ]),
            ),
          ]),
        ]),
      )));
}
