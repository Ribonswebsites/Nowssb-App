/// Zen Plus entry (Ribon 11-12 rebuild): a black card on the white home, built
/// around an auto-rotating reel of five generated people (assets/video/zp-*.mp4),
/// each a slow orbit with a pulsing golden node mesh on the neck, jaw and ear.
///
/// Layers, bottom to top: the reel (PageView, 5 s per person, a finger pauses
/// it and it carries on 5 s after the finger lifts, 600 ms easeInOutCubic);
/// a vignette; viewfinder corner brackets; mesh callouts with live node counts;
/// the title pill and a page counter; a thumbnail rail; a big title that slides
/// with each person; then a glass panel (GlassWrap) with feature cells, a pulse
/// meter, a page indicator that fills over the 5 s, the gold CTA with the glint
/// sweep, and a ticker. The whole card opens Zen Plus.
///
/// Motion is only what the app already had (fades, slides, the glint sweep,
/// the home ticker, the open-zoom on tap, the 5 s auto-cycle pattern). The
/// golden dots live only inside the videos. Under reduced motion the reel
/// shows posters and holds still.
///
/// [bgDim] is kept for call-site compatibility (the Zen home's dim setting).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../media/nwsb_video.dart';
import '../../glass_wrap.dart';
import '../../home_parts.dart' show GentleMarqueeText;
import 'surface.dart';

const _gold = Color(0xFFE0B04C);
const _goldDeep = Color(0xFFB8821C);
const _ink = Color(0xFF050505);

class _Person {
  const _Person(this.key, this.session, this.focus, this.nodes, this.ear, this.jaw, this.neck);
  final String key, session, focus;
  final int nodes;
  final Offset ear, jaw, neck;
  String get clip => 'assets/video/zp-$key.mp4';
  String get poster => 'assets/video/zp-$key-poster.webp';
  String get thumb => 'assets/home/hx/zpt-$key.webp';
}

const _people = [
  _Person('man-black', 'Stillness', 'Jaw release', 9842, Offset(.34, .47), Offset(.56, .50), Offset(.50, .63)),
  _Person('woman-indian', 'Depth', 'Neck soften', 10318, Offset(.40, .48), Offset(.58, .50), Offset(.54, .62)),
  _Person('man-asian', 'Breath', 'Throat open', 9120, Offset(.38, .47), Offset(.56, .51), Offset(.50, .62)),
  _Person('woman-silver', 'Silence', 'Ear and jaw', 10976, Offset(.37, .49), Offset(.58, .53), Offset(.50, .64)),
  _Person('man-latino', 'Light', 'Crown ease', 9654, Offset(.36, .49), Offset(.56, .52), Offset(.50, .65)),
];

class NFashionPlusEntry extends StatefulWidget {
  const NFashionPlusEntry({super.key, required this.onEnter, this.bgDim, this.startAt = 0});
  final VoidCallback onEnter;
  final double? bgDim;

  /// First person shown (tests and renders).
  final int startAt;

  /// Renders only: paint this image instead of the clip (its poster by default).
  static ImageProvider Function(String clip)? debugFrame;

  @override
  State<NFashionPlusEntry> createState() => _NFashionPlusEntryState();
}

class _NFashionPlusEntryState extends State<NFashionPlusEntry> with TickerProviderStateMixin {
  static const _every = Duration(seconds: 5);
  static const _glide = Duration(milliseconds: 600);
  static const _base = 1000;

  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
  late final AnimationController _clock = AnimationController(vsync: this, duration: _every);
  late final PageController _page = PageController(initialPage: _base * _people.length + widget.startAt);
  late int _ix = _base * _people.length + widget.startAt;
  bool _opening = false;
  bool _touching = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  bool get _still => _reduced || NormalLoop.debugT != null;
  int get _who => _ix % _people.length;

  @override
  void initState() {
    super.initState();
    _clock.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted && _page.hasClients && !_touching) {
        _page.animateToPage(_ix + 1, duration: _glide, curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _loop.stop();
      _clock.stop();
      _loop.value = NormalLoop.debugT ?? .35;
      _clock.value = NormalLoop.debugT ?? .35;
    } else if (!_touching) {
      if (!_loop.isAnimating) _loop.repeat();
      if (!_clock.isAnimating) _clock.forward(from: _clock.value >= 1 ? 0 : _clock.value);
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _clock.dispose();
    _page.dispose();
    super.dispose();
  }

  void _hold() {
    _touching = true;
    _clock.stop();
  }

  void _release() {
    _touching = false;
    if (!_still) _clock.forward(from: 0); // a whole 5 s from now
  }

  void _goto(int who) {
    final cur = _who;
    if (who == cur) return;
    _page.animateToPage(_ix + (who - cur), duration: _glide, curve: Curves.easeInOutCubic);
  }

  Future<void> _enter() async {
    if (_opening) return;
    setState(() => _opening = true);
    if (!_reduced) await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    widget.onEnter();
    if (!_reduced) setState(() => _opening = false);
  }

  // ───────────────────────── pieces ─────────────────────────

  Widget _video(_Person p) {
    final dbg = NFashionPlusEntry.debugFrame;
    if (dbg != null) {
      return Image(image: dbg(p.clip), fit: BoxFit.cover, alignment: const Alignment(0, -.25), gaplessPlayback: true);
    }
    if (_reduced) {
      return Image.asset(p.poster, fit: BoxFit.cover, alignment: const Alignment(0, -.25), gaplessPlayback: true);
    }
    return NwsbVideo(asset: p.clip, poster: p.poster, alignment: const Alignment(0, -.25));
  }

  Widget _tag(String a, String b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x66E0B04C), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(a, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: Colors.white)),
          const SizedBox(width: 7),
          Text(b, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: _gold)),
        ]),
      );

  /// One mesh callout: a square marker on the mesh, an elbow leader down to a
  /// readout chip on the black collar. [slot] 0..2 is the chip's column.
  Widget _callout(BoxConstraints k, String label, int count, Offset anchor, int slot, double t) {
    final w = k.maxWidth, h = k.maxHeight;
    final live = count + (math.sin(t * 2 * math.pi * 2 + label.length) * 14).round();
    final cw = (w - 28 - 16) / 3;
    final left = 14 + slot * (cw + 8);
    final top = h * _chipY;
    return Positioned.fill(
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _LeaderPainter(from: Offset(anchor.dx * w, anchor.dy * h), to: Offset(left + cw / 2, top)))),
        Positioned(
          left: left,
          top: top,
          width: cw,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xCC000000),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0x66E0B04C), width: 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: Color(0xCCFFFFFF), height: 1.1)),
              Text(_fmt(live), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _gold, height: 1.15)),
            ]),
          ),
        ),
      ]),
    );
  }

  static const _chipY = .655;

  static String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  Widget _thumbs() => Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < _people.length; i++)
          GestureDetector(
            key: ValueKey('zen-thumb-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _goto(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 7),
              width: 34,
              height: i == _who ? 46 : 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: i == _who ? _gold : const Color(0x33FFFFFF), width: i == _who ? 1.6 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Opacity(
                  opacity: i == _who ? 1 : .55,
                  child: Image.asset(_people[i].thumb, fit: BoxFit.cover, alignment: const Alignment(.1, -.1)),
                ),
              ),
            ),
          ),
      ]);

  Widget _cell(IconData icon, String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x33E0B04C), width: 1),
          ),
          child: Column(children: [
            Icon(icon, size: 18, color: _gold),
            const SizedBox(height: 5),
            Text(big, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15)),
            Text(small, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xB3FFFFFF), height: 1.2)),
          ]),
        ),
      );

  /// Pulse meter: 16 thin bars rising and falling out of phase.
  Widget _meter(double t) => SizedBox(
        height: 22,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 16; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 4,
              height: 5 + 17 * (.5 + .5 * math.sin(t * 2 * math.pi + i * .7)).abs(),
              decoration: BoxDecoration(color: i.isEven ? _gold : _goldDeep, borderRadius: BorderRadius.circular(1.5)),
            ),
          ],
        ]),
      );

  Widget _indicator(double clock) => Row(children: [
        for (var i = 0; i < _people.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            flex: i == _who ? 3 : 1,
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.centerLeft,
              child: i == _who
                  ? FractionallySizedBox(widthFactor: clock.clamp(0.0, 1.0), child: Container(decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))))
                  : null,
            ),
          ),
        ],
      ]);

  @override
  Widget build(BuildContext context) {
    final p = _people[_who];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(
        label: 'Enter Zen Plus',
        onTap: _enter,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _clock]),
          builder: (context, _) {
            final t = _loop.value;
            return Container(
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), offset: Offset(8, 10), blurRadius: 22),
                  BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 14),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // ── the reel ──
                  SizedBox(
                    key: const ValueKey('zen-plus-well'),
                    height: 460,
                    child: LayoutBuilder(builder: (context, k) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(end: _opening ? 1 : 0),
                        duration: _reduced ? Duration.zero : const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        builder: (_, open, __) => Stack(fit: StackFit.expand, key: const ValueKey('zen-plus-reel'), children: [
                          Transform.scale(
                            scale: 1 + .06 * open,
                            child: Listener(
                              onPointerDown: (_) => _hold(),
                              onPointerUp: (_) => _release(),
                              onPointerCancel: (_) => _release(),
                              child: PageView.builder(
                                controller: _page,
                                onPageChanged: (i) {
                                  setState(() => _ix = i);
                                  if (!_touching && !_still) _clock.forward(from: 0);
                                },
                                itemBuilder: (_, i) => ColoredBox(color: Colors.black, child: _video(_people[i % _people.length])),
                              ),
                            ),
                          ),
                          // vignette: lifts the type, keeps the void black
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0, .22, .6, 1],
                                  colors: [Color(0xB3000000), Color(0x00000000), Color(0x00000000), Color(0xF2050505)],
                                ),
                              ),
                            ),
                          ),
                          // the glint sweep
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(-2 + 4 * t, -1),
                                  end: Alignment(-1 + 4 * t, 1),
                                  colors: const [Color(0x00FFFFFF), Color(0x18FFFFFF), Color(0x00FFFFFF)],
                                ),
                              ),
                            ),
                          ),
                          // viewfinder brackets
                          const IgnorePointer(child: CustomPaint(painter: _BracketPainter())),
                          // mesh callouts
                          IgnorePointer(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: KeyedSubtree(
                                key: ValueKey('callouts-$_who'),
                                child: LayoutBuilder(builder: (_, kk) => Stack(children: [
                                  _callout(kk, 'EAR', (p.nodes * .07).round(), p.ear, 0, t),
                                  _callout(kk, 'NECK', (p.nodes * .50).round(), p.neck, 1, t),
                                  _callout(kk, 'JAW', (p.nodes * .22).round(), p.jaw, 2, t),
                                ])),
                              ),
                            ),
                          ),
                          // top row
                          Positioned(
                            left: 14,
                            right: 14,
                            top: 14,
                            child: Row(children: [
                              _tag('ZEN PLUS', 'NEW'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0x33FFFFFF))),
                                child: Text('0${_who + 1} / 0${_people.length}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
                              ),
                            ]),
                          ),
                          // thumbnail rail
                          Positioned(left: 14, top: 64, child: _thumbs()),
                          // title block
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 14,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Step into', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xCCFFFFFF), height: 1.1)),
                              const Text('Zen Plus', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.05, letterSpacing: -.8)),
                              const SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 420),
                                transitionBuilder: (c, a) => FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(position: Tween(begin: const Offset(0, .35), end: Offset.zero).animate(a), child: c),
                                ),
                                child: Row(key: ValueKey('cap-$_who'), mainAxisSize: MainAxisSize.min, children: [
                                  Text(p.session.toUpperCase(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: _gold)),
                                  const SizedBox(width: 8),
                                  Container(width: 14, height: 1.5, color: _gold),
                                  const SizedBox(width: 8),
                                  Text(p.focus, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                ]),
                              ),
                            ]),
                          ),
                        ]),
                      );
                    }),
                  ),
                  // ── the glass panel ──
                  GlassWrap(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    radius: 22,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          _cell(Icons.videocam_outlined, 'Live video', 'moving home'),
                          const SizedBox(width: 8),
                          _cell(Icons.tune_rounded, 'Dimmable', 'your own look'),
                          const SizedBox(width: 8),
                          _cell(Icons.layers_outlined, 'Glass', 'every section'),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('MESH PULSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xB3FFFFFF))),
                            const SizedBox(height: 6),
                            _meter(t),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('NODES LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xB3FFFFFF))),
                          Text(_fmt(p.nodes + (math.sin(t * 2 * math.pi * 3) * 22).round()),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _gold, height: 1.15)),
                        ]),
                      ]),
                      const SizedBox(height: 12),
                      _indicator(_clock.value),
                      const SizedBox(height: 14),
                      Row(children: [
                        const Expanded(
                          child: Text('Golden Breath, Drop Studio and poster pages, in one dark home.',
                              style: TextStyle(fontSize: 12.5, color: Color(0xCCFFFFFF), height: 1.3)),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                              color: _gold,
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Enter now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 17, color: Colors.black),
                              ]),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(-2 + 4 * t, -1),
                                      end: Alignment(-1 + 4 * t, 1),
                                      colors: const [Color(0x00FFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ]),
                  ),
                  // ── ticker ──
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x26E0B04C)))),
                    child: const GentleMarqueeText(
                      'LIVE MESH  ·  5 SESSIONS  ·  GOLDEN BREATH  ·  DROP STUDIO  ·  POSTER PAGES  ·  DIMMABLE LOOK  ·  ',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _gold, height: 1.2),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A square marker on the mesh and an elbow leader out to the readout.
class _LeaderPainter extends CustomPainter {
  _LeaderPainter({required this.from, required this.to});
  final Offset from, to;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xAAE0B04C)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final y = to.dy - 9;
    canvas.drawPath(Path()..moveTo(from.dx, from.dy)..lineTo(from.dx, y)..lineTo(to.dx, y)..lineTo(to.dx, to.dy), line);
    final box = Paint()..color = _gold;
    canvas.drawRect(Rect.fromCenter(center: from, width: 6, height: 6), box);
    canvas.drawRect(Rect.fromCenter(center: from, width: 14, height: 14), line);
  }

  @override
  bool shouldRepaint(_LeaderPainter o) => o.from != from || o.to != to;
}

/// Four gold corner brackets, like a viewfinder.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x99E0B04C)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const m = 12.0, l = 16.0, top = 58.0;
    final r = Rect.fromLTRB(m + 50, top, s.width - m, s.height * .655 - 22);
    for (final c in [
      [r.topLeft, const Offset(l, 0), const Offset(0, l)],
      [r.topRight, const Offset(-l, 0), const Offset(0, l)],
      [r.bottomLeft, const Offset(l, 0), const Offset(0, -l)],
      [r.bottomRight, const Offset(-l, 0), const Offset(0, -l)],
    ]) {
      final o = c[0];
      canvas.drawPath(Path()..moveTo(o.dx + c[1].dx, o.dy + c[1].dy)..lineTo(o.dx, o.dy)..lineTo(o.dx + c[2].dx, o.dy + c[2].dy), p);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter o) => false;
}
