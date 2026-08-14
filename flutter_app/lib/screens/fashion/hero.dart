/// The Fashion home's hero — index.html:1690-1752.
///
/// Not a glass pane: it sits above `.home-body` and fills the top of the
/// page. `hero-bg.mp4` behind everything, the wordmark and the search button
/// across the top, and at the foot the strapline, the card rail, the big
/// rotating word and the two pills.
///
/// The rotations are the website's own, timings included — HERO_WORDS and
/// TAG_WORDS from app/js/part012.js:1379 and :1429, the card every 4s and
/// the tagline every 2.5s. Both pause when the page is not being looked at,
/// which is what `if (document.hidden) return` does there and what
/// TickerMode does here.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';

/// HERO_IMGS — app/js/part012.js:1372. Five, cycled with the word.
const _heroImgs = [
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776753853585_luk2yh.jpg',
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776754047350_m02pef.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778662189/image-84_bqpkid.jpg',
  'https://res.cloudinary.com/dkzxw33ln/image/upload/q_auto/f_auto,w_900/v1776800798/grok_image_1776754188034_snzcgu.jpg',
  'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto,w_900/v1778662207/image-202_yktk8y.jpg',
];

const _heroWords = ['VIBRATION', 'FREQUENCIES', 'MIND', 'NEURONS', 'RESONANCE'];
const _tagWords = [
  'VIBRATION',
  'FREQUENCY',
  'RESONANCE',
  'AWAKENING',
  'SOUND BIRTH',
];

class FashionHero extends StatefulWidget {
  const FashionHero({super.key, this.onExplore, this.onGuide, this.onSearch});

  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;

  @override
  State<FashionHero> createState() => _FashionHeroState();
}

class _FashionHeroState extends State<FashionHero> {
  Timer? _cards;
  Timer? _tag;
  int _card = 0;
  int _tagIdx = 0;

  @override
  void initState() {
    super.initState();
    _cards = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _card = (_card + 1) % _heroImgs.length);
    });
    _tag = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _tagIdx = (_tagIdx + 1) % _tagWords.length);
    });
  }

  @override
  void dispose() {
    _cards?.cancel();
    _tag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const NwsbVideo(
            asset: 'assets/video/hero-bg.mp4',
            priority: ClipPriority.feature,
          ),
          // The film is bright in places and every word on this hero is
          // white, so the type sits on its own gradient rather than trusting
          // the frame underneath it.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x73000000),
                  Color(0x26000000),
                  Color(0xCC000000),
                  Color(0xF2060C18),
                ],
                stops: [0, 0.3, 0.75, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _Wordmark(),
                          const Spacer(),
                          _SearchButton(onTap: widget.onSearch),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // One word, swapped on a fade — the same 250ms the
                      // website uses on the tagline.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _tagWords[_tagIdx],
                          key: ValueKey(_tagIdx),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 20),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xD9FFFFFF),
                        shadows: [
                          Shadow(color: Color(0xCC000000), blurRadius: 12,
                              offset: Offset(0, 1)),
                        ],
                      ),
                      children: [
                        TextSpan(text: 'Natural Origin of '),
                        TextSpan(
                          text: 'Word Science',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                _CardRail(active: _card),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _heroWords[_card],
                      key: ValueKey(_card),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Row(
                    children: [
                      _HeroPill(
                        label: 'Explore',
                        primary: true,
                        onTap: widget.onExplore,
                      ),
                      const SizedBox(width: 10),
                      _HeroPill(label: 'App Guide', onTap: widget.onGuide),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `Nowss` heavy, `B` light — the mark reads as one word with a break in the
/// weight rather than as two words.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.09;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: size.clamp(32.0, 52.0),
          color: Colors.white,
          height: 1.05,
        ),
        children: const [
          TextSpan(text: 'Nowss', style: TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: 'B', style: TextStyle(fontWeight: FontWeight.w200)),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Image.asset(
          'assets/icons/search.webp',
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.search, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// `.hero-cards` — five stills, the active one wide and the rest narrow.
class _CardRail extends StatelessWidget {
  const _CardRail({required this.active});
  final int active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _heroImgs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: i == active ? 118 : 62,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            border: Border.all(
              color: i == active
                  ? const Color(0x8CFFFFFF)
                  : const Color(0x1FFFFFFF),
            ),
          ),
          child: NwsbImage(
            url: _heroImgs[i],
            // Until the download runs these are the hero clip's own frame,
            // which is the picture the rail is sitting on anyway.
            fallback: Image.asset(
              'assets/video/hero-bg-poster.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0A0F1C)),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, this.primary = false, this.onTap});
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? Colors.white : const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primary ? Colors.white : const Color(0x59FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: primary ? NwsbColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}
