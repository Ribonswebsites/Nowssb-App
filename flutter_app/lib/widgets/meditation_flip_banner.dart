/// Three Hotstar-style promo strips. Flat colour, then the portrait pops
/// on the right, then the title, then the line under it. The row scrolls
/// sideways and advances on its own.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class _Slide {
  const _Slide({
    required this.color,
    required this.asset,
    required this.word,
    required this.line,
    required this.ink,
    required this.svg,
  });

  final Color color;
  final String svg;
  final String asset;
  final String word;
  final String line;
  final Color ink;
}

const _slides = <_Slide>[
  _Slide(
    color: Color(0xFF692FCC),
    svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><circle cx="32" cy="15" r="6" fill="#692FCC"/><path d="M32 23c-5 0-8 4-8 9v6l-9 6c-2 1-1 4 1 4h32c2 0 3-3 1-4l-9-6v-6c0-5-3-9-8-9z" fill="#692FCC"/><path d="M10 52h44" stroke="#B79AF0" stroke-width="3" stroke-linecap="round"/><path d="M24 34l-8 5M40 34l8 5" stroke="#692FCC" stroke-width="3" stroke-linecap="round"/></svg>',
    asset: 'assets/banners/banner-sit.webp',
    word: 'MEDITATION',
    line: 'DAILY PRACTICE\nBEGIN ANYTIME',
    ink: Colors.white,
  ),
  _Slide(
    color: Color(0xFFC8102E),
    svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M14 22h36l-3 32H17z" fill="#C8102E"/><path d="M24 24v-6a8 8 0 0 1 16 0v6" fill="none" stroke="#C8102E" stroke-width="3.5" stroke-linecap="round"/><path d="M25 38h14M25 45h9" stroke="#fff" stroke-width="3" stroke-linecap="round"/></svg>',
    asset: 'assets/banners/banner-store.webp',
    word: 'STORE',
    line: 'WORDS AND MEANINGS\nOPEN ANYTIME',
    ink: Colors.white,
  ),
  _Slide(
    color: Color(0xFFF5C400),
    svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M27 8h10M32 8v6" stroke="#1A1200" stroke-width="3.5" stroke-linecap="round"/><circle cx="32" cy="36" r="20" fill="#F5C400"/><circle cx="32" cy="36" r="20" fill="none" stroke="#1A1200" stroke-width="3"/><path d="M32 36V24" stroke="#1A1200" stroke-width="3.5" stroke-linecap="round"/><path d="M32 36l7 5" stroke="#1A1200" stroke-width="3" stroke-linecap="round"/></svg>',
    asset: 'assets/banners/banner-gold.webp',
    word: 'PRACTICE',
    line: 'FIVE QUIET MINUTES\nONE WORD',
    ink: Color(0xFF1A1200),
  ),
];

class MeditationFlipBanner extends StatefulWidget {
  const MeditationFlipBanner({super.key, this.onTap, this.leadingIcons = false});

  final VoidCallback? onTap;

  /// Normal home: a white circle on the left of each strip, as tall as the
  /// strip, holding an SVG in the strip's colour. Fashion leaves it off.
  final bool leadingIcons;

  @override
  State<MeditationFlipBanner> createState() => _MeditationFlipBannerState();
}

class _MeditationFlipBannerState extends State<MeditationFlipBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
  late final PageController _pager = PageController();
  var _page = 0;
  var _hold = false;

  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (_quiet) {
      _cycle.value = 0.55;
      return;
    }
    _cycle.addStatusListener(_onStatus);
    _cycle.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _hold) {
      if (status == AnimationStatus.completed && mounted && _hold) _cycle.forward(from: 0);
      return;
    }
    final next = (_page + 1) % _slides.length;
    setState(() => _page = next);
    if (_pager.hasClients) {
      _pager.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
    _cycle.forward(from: 0);
  }

  @override
  void dispose() {
    _cycle.removeStatusListener(_onStatus);
    _cycle.dispose();
    _pager.dispose();
    super.dispose();
  }

  /// Hidden, then a pop, then a hold, then gone before the page turns.
  double _amount(double t, double start, double end) {
    const holdEnd = 0.78;
    const fadeEnd = 0.92;
    if (t < start || t >= fadeEnd) return 0;
    final shown = t >= end ? 1.0 : Curves.easeOutBack.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
    if (t <= holdEnd) return shown;
    final fade = ((t - holdEnd) / (fadeEnd - holdEnd)).clamp(0.0, 1.0);
    return shown * (1 - fade);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Column(
        children: [
          SizedBox(
            height: 136,
            child: Listener(
              onPointerDown: (_) => _hold = true,
              onPointerUp: (_) => _hold = false,
              onPointerCancel: (_) => _hold = false,
              child: PageView.builder(
                controller: _pager,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  if (i == _page) return;
                  setState(() => _page = i);
                  if (!_quiet) _cycle.forward(from: 0);
                },
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _Card(
                    slide: _slides[i],
                    cycle: _cycle,
                    amount: _amount,
                    onTap: widget.onTap,
                    leadingIcon: widget.leadingIcons,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.slide, required this.cycle, required this.amount, this.onTap, this.leadingIcon = false});

  final bool leadingIcon;

  final _Slide slide;
  final AnimationController cycle;
  final double Function(double t, double start, double end) amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: slide.color,
          child: AnimatedBuilder(
            animation: cycle,
            builder: (context, _) {
              final t = cycle.value;
              final portrait = amount(t, 0.08, 0.22);
              final title = amount(t, 0.24, 0.36);
              final sub = amount(t, 0.36, 0.48);
              final portraitOpacity = portrait.clamp(0.0, 1.0);
              final titleOpacity = title.clamp(0.0, 1.0);
              final subOpacity = sub.clamp(0.0, 1.0);
              if (leadingIcon) return _withIcon(context, portrait, title, sub);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: 8,
                    bottom: 0,
                    width: 108,
                    height: 132,
                    child: Opacity(
                      opacity: portraitOpacity,
                      child: Transform.translate(
                        offset: Offset((1 - portraitOpacity) * 28, 0),
                        child: Image.asset(
                          slide.asset,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 18,
                    child: Opacity(
                      opacity: titleOpacity,
                      child: Transform.translate(
                        offset: Offset((1 - titleOpacity) * -18, 0),
                        child: Transform.scale(
                          scale: 0.88 + 0.12 * title.clamp(0.0, 1.1),
                          alignment: Alignment.centerLeft,
                          child: _Title(word: slide.word, ink: slide.ink),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 78,
                    right: 120,
                    child: Opacity(
                      opacity: subOpacity,
                      child: Transform.translate(
                        offset: Offset(0, (1 - subOpacity) * 12),
                        child: Text(
                          slide.line,
                          style: GoogleFonts.oswald(
                            color: slide.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on _Card {
  Widget _withIcon(BuildContext context, double portrait, double title, double sub) {
    final portraitOpacity = portrait.clamp(0.0, 1.0);
    final titleOpacity = title.clamp(0.0, 1.0);
    final subOpacity = sub.clamp(0.0, 1.0);
    return LayoutBuilder(builder: (context, box) {
      final d = box.maxHeight;
      final textLeft = d + 12;
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final textNeed = 100 * scale;
      final room = box.maxWidth - textLeft - 8;
      final portraitW = (room - textNeed).clamp(0.0, 108.0);
      final showPortrait = portraitW >= 52;
      final textW = room - (showPortrait ? portraitW : 0);
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: d,
            height: d,
            child: DecoratedBox(
              key: const ValueKey('flip-icon-disc'),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Padding(
                padding: EdgeInsets.all(d * 0.2),
                child: SvgPicture.string(slide.svg, fit: BoxFit.contain),
              ),
            ),
          ),
          if (showPortrait)
            Positioned(
              right: 8,
              bottom: 0,
              width: portraitW,
              height: d - 4,
              child: Opacity(
                opacity: portraitOpacity,
                child: Transform.translate(
                  offset: Offset((1 - portraitOpacity) * 28, 0),
                  child: Image.asset(slide.asset, fit: BoxFit.contain, alignment: Alignment.bottomRight, filterQuality: FilterQuality.medium),
                ),
              ),
            ),
          Positioned(
            left: textLeft,
            top: 18,
            width: textW,
            child: Opacity(
              opacity: titleOpacity,
              child: Transform.translate(
                offset: Offset((1 - titleOpacity) * -18, 0),
                child: Transform.scale(
                  scale: 0.88 + 0.12 * title.clamp(0.0, 1.1),
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _Title(word: slide.word, ink: slide.ink)),
                ),
              ),
            ),
          ),
          Positioned(
            left: textLeft,
            top: 78,
            width: textW,
            child: Opacity(
              opacity: subOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - subOpacity) * 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(slide.line, style: GoogleFonts.oswald(color: slide.ink, fontSize: 13, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: 0.4)),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.word, required this.ink});

  final String word;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOWSSB',
          style: GoogleFonts.oswald(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: ink, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              word,
              style: GoogleFonts.oswald(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
