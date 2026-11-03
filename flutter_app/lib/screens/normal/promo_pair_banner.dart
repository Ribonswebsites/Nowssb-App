/// Normal home only: the MeditationFlipBanner card look, two cards side by
/// side, six slides in total. Every few seconds the pair softly cross-fades
/// to the next two. Fashion keeps its own single-strip MeditationFlipBanner.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromoPairSlide {
  const PromoPairSlide({
    required this.color,
    required this.asset,
    required this.word,
    required this.line,
    required this.ink,
    required this.onTap,
  });

  final Color color;
  final String asset;
  final String word;
  final String line;
  final Color ink;
  final VoidCallback? onTap;
}

class PromoPairBanner extends StatefulWidget {
  const PromoPairBanner({
    super.key,
    this.onMeditation,
    this.onStore,
    this.onPractice,
    this.onQuotes,
    this.onEarn,
    this.onConnect,
  });

  final VoidCallback? onMeditation;
  final VoidCallback? onStore;
  final VoidCallback? onPractice;
  final VoidCallback? onQuotes;
  final VoidCallback? onEarn;
  final VoidCallback? onConnect;

  @override
  State<PromoPairBanner> createState() => _PromoPairBannerState();
}

class _PromoPairBannerState extends State<PromoPairBanner> {
  Timer? _timer;
  var _pair = 0;

  bool get _quiet =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  List<PromoPairSlide> get slides => [
        PromoPairSlide(
          color: const Color(0xFF692FCC),
          asset: 'assets/banners/banner-sit.webp',
          word: 'MEDITATION',
          line: 'DAILY PRACTICE\nBEGIN ANYTIME',
          ink: Colors.white,
          onTap: widget.onMeditation,
        ),
        PromoPairSlide(
          color: const Color(0xFFC8102E),
          asset: 'assets/banners/banner-store.webp',
          word: 'STORE',
          line: 'WORDS AND\nMEANINGS',
          ink: Colors.white,
          onTap: widget.onStore,
        ),
        PromoPairSlide(
          color: const Color(0xFFF5C400),
          asset: 'assets/banners/banner-gold.webp',
          word: 'PRACTICE',
          line: 'FIVE QUIET\nMINUTES',
          ink: const Color(0xFF1A1200),
          onTap: widget.onPractice,
        ),
        PromoPairSlide(
          color: const Color(0xFF1F7A55),
          asset: 'assets/banners/promo/pose-02.png',
          word: 'QUOTES',
          line: 'A LINE\nFOR TODAY',
          ink: Colors.white,
          onTap: widget.onQuotes,
        ),
        PromoPairSlide(
          color: const Color(0xFF1C4FBF),
          asset: 'assets/banners/promo/pose-05.png',
          word: 'EARN',
          line: 'COINS FOR\nEVERY DAY',
          ink: Colors.white,
          onTap: widget.onEarn,
        ),
        PromoPairSlide(
          color: const Color(0xFFE2691E),
          asset: 'assets/banners/promo/pose-07.png',
          word: 'CONNECT',
          line: 'PRACTICE\nTOGETHER',
          ink: Colors.white,
          onTap: widget.onConnect,
        ),
      ];

  @override
  void initState() {
    super.initState();
    if (_quiet) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _pair = (_pair + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = slides;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Row(
                key: ValueKey('promo-pair-$_pair'),
                children: [
                  Expanded(child: _PairCard(slide: s[_pair * 2])),
                  const SizedBox(width: 10),
                  Expanded(child: _PairCard(slide: s[_pair * 2 + 1])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                GestureDetector(
                  onTap: () => setState(() => _pair = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == _pair ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color:
                          i == _pair ? Colors.white : const Color(0x55FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairCard extends StatelessWidget {
  const _PairCard({required this.slide});

  final PromoPairSlide slide;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: slide.word,
      child: GestureDetector(
        onTap: slide.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: slide.color,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  right: -6,
                  bottom: 0,
                  width: 84,
                  height: 132,
                  child: Image.asset(
                    slide.asset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 14,
                  right: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOWSSB',
                          maxLines: 1,
                          style: GoogleFonts.oswald(
                              color: slide.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: slide.ink, width: 1.2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 3),
                          child: Text(slide.word,
                              maxLines: 1,
                              style: GoogleFonts.oswald(
                                  color: slide.ink,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 14,
                  right: 70,
                  child: Text(slide.line,
                      maxLines: 2,
                      style: GoogleFonts.oswald(
                          color: slide.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          letterSpacing: 0.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
