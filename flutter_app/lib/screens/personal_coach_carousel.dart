/// Personal Coach rotating horizontal section.
///
/// Black [RoutineStyleBlackBanner] sits OUTSIDE the glass/device wrappers —
/// same pattern as My Routine / Health Journey. Cards auto-scroll inside
/// tablet-style frames. First slide is the AAROGYA Personal Coach artwork.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../widgets/black_glass_banner.dart';

class PersonalCoachCarousel extends StatefulWidget {
  const PersonalCoachCarousel({super.key, this.onTap, this.fashion = false});

  final VoidCallback? onTap;
  final bool fashion;

  @override
  State<PersonalCoachCarousel> createState() => _PersonalCoachCarouselState();
}

class _PersonalCoachCarouselState extends State<PersonalCoachCarousel> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;

  static const _slides = <_CoachSlide>[
    _CoachSlide(
      asset: 'assets/coach/aarogya-personal-coach.png',
      title: 'AAROGYA',
      subtitle: 'Immune System · Personal Coach',
    ),
    _CoachSlide(
      asset: 'assets/coach/personal_coach_hero.jpg',
      title: 'Personal Coach',
      subtitle: 'Guided word practice, for you',
    ),
    _CoachSlide(
      asset: 'assets/coach/coach-orb.png',
      title: 'Daily Ritual',
      subtitle: 'Continue your healing path',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      final next = (_index + 1) % _slides.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleColor =
        widget.fashion ? Colors.white : const Color(0xFF2B2D33);
    final metaColor =
        widget.fashion ? Colors.white70 : const Color(0xFF8A8F9A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header outside wrappers — matches My Routine title row.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Personal Coach',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                Text(
                  '${_slides.length} cards',
                  style: TextStyle(fontSize: 12, color: metaColor),
                ),
              ],
            ),
          ),
          // Black banner OUTSIDE the glass/device card wrappers.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: RoutineStyleBlackBanner(
              title: 'Personal Coach',
              subtitle: 'Customise your practice',
              onTap: widget.onTap,
            ),
          ),
          SizedBox(
            height: 248,
            child: PageView.builder(
              controller: _page,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final slide = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _CoachTabletCard(slide: slide, onTap: widget.onTap),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final on = i == _index;
              return Container(
                width: on ? 16 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: on
                      ? (widget.fashion
                          ? Colors.white
                          : const Color(0xFF2B2D33))
                      : (widget.fashion
                          ? Colors.white.withValues(alpha: 0.35)
                          : const Color(0x552B2D33)),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CoachSlide {
  const _CoachSlide({
    required this.asset,
    required this.title,
    required this.subtitle,
  });
  final String asset;
  final String title;
  final String subtitle;
}

/// Glass-wrapped tablet-style frame around still coach artwork.
class _CoachTabletCard extends StatelessWidget {
  const _CoachTabletCard({required this.slide, this.onTap});
  final _CoachSlide slide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x0EFFFFFF),
              borderRadius: radius,
              border: Border.all(color: const Color(0x55FFFFFF), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x57000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide.asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00000000),
                                Color(0x99000000),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slide.subtitle,
                                style: const TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Thin tablet chin / bezel bar.
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x66FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
