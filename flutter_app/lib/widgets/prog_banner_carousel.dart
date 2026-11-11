/// The Programmes banner: four black, gold-lit slides that rotate on their
/// own. Each slide layers a glossy render over soft light, with a bold
/// headline, a line of copy and one button to a real page.
///
/// Motion is small and slow: the render floats and turns a few degrees, a
/// band of light passes over it, and the picture drifts a little against the
/// swipe (parallax). It rotates every 5 s, holds while a finger is on it and
/// resumes 5 s after the finger lifts. Reduced motion: no rotation, no float.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/coins/coins_screen.dart';
import '../features/programs/program_router.dart';
import '../screens/subscription.dart';
import '../theme/tokens.dart';
import 'home_text.dart';

bool get _kTest => WidgetsBinding.instance.runtimeType.toString().contains('Test');

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.line,
    required this.cta,
    required this.art,
    required this.open,
    this.coin = false,
  });
  final String eyebrow;
  final String title;
  final String line;
  final String cta;
  final String art;
  final bool coin;
  final void Function(BuildContext) open;
}

final _slides = <_Slide>[
  _Slide(
    eyebrow: 'NOWSSB EARN',
    title: 'Calm that\npays you back',
    line: 'Every quiet minute adds coins.',
    cta: 'Start earning',
    art: 'assets/icons/nwsb-coin.webp',
    coin: true,
    open: (c) => Programmes.open(c, Programme.earn),
  ),
  _Slide(
    eyebrow: 'REFERENCE',
    title: 'Share a word,\ngrow together',
    line: 'Your links pay as friends begin.',
    cta: 'Open my links',
    art: 'assets/banners/promo/drift-seal.webp',
    open: (c) => Programmes.open(c, Programme.reference),
  ),
  _Slide(
    eyebrow: 'EARNINGS',
    title: 'Every coin,\nwritten down',
    line: 'See what you earned and when.',
    cta: 'See earnings',
    art: 'assets/banners/promo/drift-book.webp',
    open: (c) => Programmes.open(c, Programme.earnings),
  ),
  _Slide(
    eyebrow: 'ZEN PLUS',
    title: 'Go deeper,\nwith the full library',
    line: 'Every word, sound and session.',
    cta: 'See plans',
    art: 'assets/banners/promo/drift-ear.webp',
    open: (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
  ),
];

/// Where "Coins" opens, shared with the cards below the banner.
void openCoinsPage(BuildContext c) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const CoinsScreen()));

class ProgBannerCarousel extends StatefulWidget {
  const ProgBannerCarousel({super.key, this.onOpen});

  /// Tests / shots: freeze the motion at this point (0..1) and the page.
  static double? debugT;
  static int? debugPage;

  /// Tests: let the timers and the loop run.
  static bool debugLive = false;

  /// Replaces what the buttons do (index of the slide).
  final void Function(int index)? onOpen;

  static const height = 222.0;
  static const rotate = Duration(seconds: 5);

  @override
  State<ProgBannerCarousel> createState() => _ProgBannerCarouselState();
}

class _ProgBannerCarouselState extends State<ProgBannerCarousel> with SingleTickerProviderStateMixin {
  static final _base = 1000 * _slides.length;
  late final PageController _pager = PageController(initialPage: _base + (ProgBannerCarousel.debugPage ?? 0));
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  Timer? _timer;
  double _page = 0;
  int _index = 0;
  bool _still = false;

  bool get _frozen => (_kTest && !ProgBannerCarousel.debugLive) || ProgBannerCarousel.debugT != null;

  @override
  void initState() {
    super.initState();
    _index = ProgBannerCarousel.debugPage ?? 0;
    _page = (_base + _index).toDouble();
    _pager.addListener(() {
      final p = _pager.hasClients ? (_pager.page ?? _index.toDouble()) : _index.toDouble();
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still || _frozen) {
      _loop.stop();
      _loop.value = ProgBannerCarousel.debugT ?? .3;
      _timer?.cancel();
    } else {
      if (!_loop.isAnimating) _loop.repeat();
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted || _still || _frozen) return;
    _timer = Timer(ProgBannerCarousel.rotate, _advance);
  }

  Future<void> _advance() async {
    if (!mounted || !_pager.hasClients) return;
    // The pager is endless, so the last slide glides on to the first.
    await _pager.animateToPage((_pager.page ?? _page).round() + 1,
        duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    _schedule();
  }

  void _hold() => _timer?.cancel();

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        height: ProgBannerCarousel.height,
        // A finger anywhere on the banner pauses it; five seconds after it
        // lifts the rotation carries on.
        child: Listener(
          onPointerDown: (_) => _hold(),
          onPointerUp: (_) => _schedule(),
          onPointerCancel: (_) => _schedule(),
          child: PageView.builder(
            key: const ValueKey('prog-banner-pager'),
            controller: _pager,
            onPageChanged: (i) => setState(() => _index = i % _slides.length),
            itemBuilder: (context, abs) {
              final i = abs % _slides.length;
              return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => _SlideView(
                  slide: _slides[i],
                  t: _loop.value,
                  shift: (_page - abs).clamp(-1.0, 1.0),
                  still: _still,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onOpen != null) {
                      widget.onOpen!(i);
                    } else {
                      _slides[i].open(context);
                    }
                  },
                ),
              ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < _slides.length; i++)
          AnimatedContainer(
            key: ValueKey('prog-dot-$i'),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == _index ? NwsbColors.goldLight : const Color(0x4DFFFFFF),
            ),
          ),
      ]),
    ]);
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.t, required this.shift, required this.still, required this.onTap});
  final _Slide slide;
  final double t;

  /// -1..1: how far this slide is from the centre of the pager.
  final double shift;
  final bool still;
  final VoidCallback onTap;

  static const _tau = math.pi * 2;

  @override
  Widget build(BuildContext context) {
    final float = still ? 0.0 : math.sin(_tau * t * 2);
    final turn = still ? 0.0 : math.sin(_tau * t) * .22;
    // The sheen takes the loop's first half; the rest it rests off screen.
    final sweep = (t * 1.0) % 1;
    final sx = -1.6 + 3.8 * Curves.easeInOut.transform((sweep * 1.4).clamp(0.0, 1.0));
    final parallax = shift * -46.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${slide.title.replaceAll('\n', ' ')}. ${slide.line} ${slide.cta}.',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x2EFFFFFF)),
            ),
            child: Stack(fit: StackFit.expand, children: [
              // Layer 1: the room. A deep warm glow low and to the right.
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(parallax * .35, 0),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(.72, .15),
                        radius: .95,
                        colors: [Color(0x66B8893A), Color(0x1F6B4A12), Color(0x00000000)],
                        stops: [0, .5, 1],
                      ),
                    ),
                  ),
                ),
              ),
              // Layer 2: the render.
              Positioned(
                right: -22,
                top: 0,
                bottom: 0,
                width: 220,
                child: Transform.translate(
                  offset: Offset(parallax, 0),
                  child: slide.coin ? _Coin(art: slide.art, float: float, turn: turn, sweep: sx) : _Still(art: slide.art, float: float, t: t),
                ),
              ),
              // Layer 3: a slow band of light over everything.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(sx - .5, -1),
                      end: Alignment(sx + .5, 1),
                      colors: const [Color(0x00FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              // Layer 4: keeps the words readable.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xF2000000), Color(0xCC000000), Color(0x00000000)],
                      stops: [0, .46, .78],
                    ),
                  ),
                ),
              ),
              // Layer 5: the words, drifting a touch faster than the picture.
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 14, 16),
                child: Transform.translate(
                  offset: Offset(parallax * .5, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: .64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slide.eyebrow,
                              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(slide.title, style: HomeText.heading.copyWith(fontSize: 25, height: 1.1)),
                          ),
                          const SizedBox(height: 6),
                          Text(slide.line, maxLines: 2, overflow: TextOverflow.ellipsis, style: HomeText.subline.copyWith(color: const Color(0xB3FFFFFF), fontSize: 13)),
                          const SizedBox(height: 14),
                          _Cta(label: slide.cta),
                        ],
                      ),
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

/// The gold NowssB coin: a floating render that turns a few degrees, with a
/// band of light crossing its face.
class _Coin extends StatelessWidget {
  const _Coin({required this.art, required this.float, required this.turn, required this.sweep});
  final String art;
  final double float;
  final double turn;
  final double sweep;

  @override
  Widget build(BuildContext context) {
    const d = 156.0;
    return Stack(alignment: Alignment.center, children: [
      Transform.translate(
        offset: Offset(0, -6 + float * 5),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateY(turn)
            ..rotateX(-.06),
          child: Container(
            width: d,
            height: d,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Color(0x66E8B84A), blurRadius: 46, spreadRadius: -4),
                BoxShadow(color: Color(0x1FFFE6A0), blurRadius: 90, spreadRadius: 2),
              ],
            ),
            child: ClipOval(
              child: Stack(fit: StackFit.expand, children: [
                Transform.scale(scale: 1.13, child: Image.asset(art, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFC8A96E)))),
                // Specular band across the face.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(sweep - .6, -1),
                      end: Alignment(sweep + .6, 1),
                      colors: const [Color(0x00FFFFFF), Color(0x59FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
                // Rim shade so the disc reads as round.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: .62,
                      colors: [Color(0x00000000), Color(0x00000000), Color(0x66000000)],
                      stops: [0, .8, 1],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// A black-ground render (seal, book, box): it fades into the card on its
/// left edge, floats and breathes a little.
class _Still extends StatelessWidget {
  const _Still({required this.art, required this.float, required this.t});
  final String art;
  final double float;
  final double t;

  @override
  Widget build(BuildContext context) {
    final zoom = 1.06 + .035 * math.sin(math.pi * 2 * t);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
        stops: [0, .34, 1],
      ).createShader(r),
      child: Transform.translate(
        offset: Offset(0, float * 4),
        child: Transform.scale(
          scale: zoom,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(art, fit: BoxFit.cover, alignment: Alignment.center),
            // The picture's own edges melt into the card's black.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF000000), Color(0x00000000), Color(0x00000000), Color(0xFF000000)],
                  stops: [0, .22, .78, 1],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 16, right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(colors: [NwsbColors.goldLight, NwsbColors.gold]),
        boxShadow: const [BoxShadow(color: Color(0x40C8A96E), blurRadius: 16, spreadRadius: -3)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(color: Color(0xFF14110A), fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: Color(0xFF14110A), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_forward_rounded, color: NwsbColors.goldLight, size: 16),
        ),
      ]),
    );
  }
}
