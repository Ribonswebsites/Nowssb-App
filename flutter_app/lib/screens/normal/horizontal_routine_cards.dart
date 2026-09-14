/// Six horizontal Get Started / My Routine cards.
///
/// The card language follows the supplied Essentials reference: a wide image,
/// compact metadata, a strong title, a centered Store mark that overlaps the
/// lower edge, and a black action banner underneath. Normal mode uses white
/// neumorphism; Normal Glass mode uses white glassmorphism. Fashion My Routine
/// uses Notifications / GlassWrap dark glass (semi-transparent + blur), not
/// opaque white glass.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'glassmorphism_theme.dart';
import 'essentials_process_line.dart';

class NmHorizontalRoutineCards extends StatefulWidget {
  const NmHorizontalRoutineCards({super.key, this.fashion = false});

  final bool fashion;

  @override
  State<NmHorizontalRoutineCards> createState() =>
      _NmHorizontalRoutineCardsState();
}

class _NmHorizontalRoutineCardsState extends State<NmHorizontalRoutineCards> {
  late final ScrollController _cardsController;
  var _activeCard = 0;

  @override
  void initState() {
    super.initState();
    _cardsController = ScrollController()..addListener(_onCardsScroll);
  }

  @override
  void dispose() {
    _cardsController
      ..removeListener(_onCardsScroll)
      ..dispose();
    super.dispose();
  }

  void _onCardsScroll() {
    final next = (_cardsController.offset / 344).round().clamp(0, 5);
    if (next != _activeCard && mounted) setState(() => _activeCard = next);
  }

  static const _cards = <_EssentialCardData>[
    _EssentialCardData(
        'Get Started',
        'Trusting the Breath',
        'Mindfulness · 4 min',
        'Listen to your first meditation',
        'assets/routine/trusting-the-breath.png',
        Color(0xFFE9C1A5)),
    _EssentialCardData(
        'Life Coaching',
        'Positive Self-Talk & Power',
        'Life Coaching · 4 mins',
        'Open life coaching',
        'assets/routine/positive-self-talk.png',
        Color(0xFFB9D5E8)),
    _EssentialCardData(
        'Story',
        'What Your Body Knows',
        'Story · 8 min',
        'Listen to the story',
        'assets/routine/your-body-knows.png',
        Color(0xFFCBBBE8)),
    _EssentialCardData(
        'Breathwork',
        'Return to Stillness',
        'Breathwork · 6 min',
        'Begin breathwork',
        'assets/routine/stillness.png',
        Color(0xFFBFE2D1)),
    _EssentialCardData(
        'Sounds',
        'A Softer Inner Voice',
        'Sounds · 5 min',
        'Play healing sounds',
        'assets/routine/softer-voice.png',
        Color(0xFFF0D39B)),
    _EssentialCardData(
        'Meditation',
        'A Quiet Place Within',
        'Meditation · 10 min',
        'Start meditation',
        'assets/routine/quiet-within.png',
        Color(0xFFD4C5E8)),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    final title = widget.fashion ? 'My Routine' : 'Get Started';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 14),
            child: Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: glass || widget.fashion
                                ? Colors.white
                                : const Color(0xFF2B2D33)))),
                Text('6 cards',
                    style: TextStyle(
                        fontSize: 12,
                        color: glass || widget.fashion
                            ? Colors.white70
                            : const Color(0xFF8A8F9A))),
              ],
            ),
          ),
          if (widget.fashion) const _FashionRoutineBanner(),
          Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 16, top: 4),
            child: NmEssentialsProcessLine(
                glass: glass || widget.fashion, active: _activeCard),
          ),
          SizedBox(
            height: 340,
            child: ListView.separated(
              controller: _cardsController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20, bottom: 4),
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _EssentialCard(
                  card: _cards[index], glass: glass, fashion: widget.fashion),
            ),
          ),
        ],
      ),
    );
  }
}

class _FashionRoutineBanner extends StatelessWidget {
  const _FashionRoutineBanner();

  @override
  Widget build(BuildContext context) => Container(
        height: 96,
        margin: const EdgeInsets.fromLTRB(0, 0, 20, 12),
        padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x29FFFFFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Routine\nCustomize your practice',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.3)),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward,
                  color: Color(0xFF060C18), size: 22),
            ),
          ],
        ),
      );
}

class _EssentialCardData {
  const _EssentialCardData(this.category, this.title, this.meta, this.action,
      this.image, this.circleColor);
  final String category;
  final String title;
  final String meta;
  final String action;
  final String image;
  final Color circleColor;
}

class _EssentialCard extends StatelessWidget {
  const _EssentialCard(
      {required this.card, required this.glass, required this.fashion});
  final _EssentialCardData card;
  final bool glass;
  final bool fashion;

  /// Fashion My Routine — GlassWrap / Notifications dark glass, not white.
  static const _darkGlassFill = Color(0x0EFFFFFF); // rgba(255,255,255,0.055)
  static const _darkGlassLine = Color(0x21FFFFFF); // rgba(255,255,255,0.13)
  static const _darkGlassBlur = 9.0; // CSS blur(18px) → sigma 9

  @override
  Widget build(BuildContext context) {
    final darkGlass = fashion;
    final foreground =
        darkGlass ? Colors.white : const Color(0xFF263142);
    final surface = darkGlass
        ? _darkGlassFill
        : (glass ? const Color(0xD9FFFFFF) : const Color(0xFFECEEF2));
    final border = darkGlass
        ? _darkGlassLine
        : (glass ? const Color(0xFFFFFFFF) : Colors.transparent);
    final radius = BorderRadius.circular(24);

    Widget face = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.category,
                style: TextStyle(
                    color: foreground.withValues(alpha: darkGlass ? .78 : .72),
                    fontSize: 12)),
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(card.image,
                    height: 104,
                    width: double.infinity,
                    fit: BoxFit.cover)),
            const SizedBox(height: 12),
            Text(card.meta,
                style: TextStyle(
                    color: foreground.withValues(alpha: darkGlass ? .75 : .7),
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text(card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15)),
          ]),
    );

    Widget cardPane;
    if (darkGlass) {
      cardPane = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
                color: Color(0x57000000),
                blurRadius: 40,
                offset: Offset(0, 16)),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _darkGlassBlur, sigmaY: _darkGlassBlur),
            child: Container(
              height: 249,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: radius,
                border: Border.all(color: border),
              ),
              child: face,
            ),
          ),
        ),
      );
    } else {
      cardPane = Container(
        height: 249,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          border: Border.all(color: border, width: glass ? 1.2 : 0),
          boxShadow: glass
              ? const [
                  BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 18,
                      offset: Offset(0, 9))
                ]
              : NwsbShadows.raised,
        ),
        child: ClipRRect(borderRadius: radius, child: face),
      );
    }

    return SizedBox(
      width: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              cardPane,
              const SizedBox(height: 38),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Expanded(
                      child: Text(card.action,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600))),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18)
                ]),
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .82),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 12,
                      offset: Offset(0, 5)),
                ],
              ),
              child: Image.asset('assets/banners/promo/store.png',
                  fit: BoxFit.contain),
            ),
          ),
          Positioned(
            left: 135,
            top: 221,
            child: Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: card.circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 12,
                        offset: Offset(0, 5))
                  ]),
              child: Image.asset('assets/banners/promo/store.png',
                  fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional white-glass wrapper for callers that want the section framed.
class EssentialsGlassFrame extends StatelessWidget {
  const EssentialsGlassFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(28)),
            child: child,
          ),
        ),
      );
}
