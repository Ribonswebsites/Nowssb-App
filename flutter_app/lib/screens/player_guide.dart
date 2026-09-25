/// Player Guide — native counterpart of website `renderPwGuide()`
/// (`app/js/part054.js` + `.pwg-screen` in `nowssb-nm.css`).
///
/// Eight full-bleed setup slides shown BEFORE the practice intro the first
/// time the player opens. Same photography, chrome, copy, dots, and
/// Begin pill as the website walkthrough.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../media/nwsb_image.dart';

const kPlayerGuideSeenKey = 'nwsb_player_guide_seen';

class PlayerGuideSlide {
  const PlayerGuideSlide({
    required this.title,
    required this.icon,
    required this.img,
    required this.heading,
    required this.desc,
    this.isFinal = false,
  });

  final String title;
  final String icon;
  final String img;
  final String heading;
  final String desc;
  final bool isFinal;
}

/// Local copies of the walkthrough stills. Remote URLs made every slide
/// wait on the network — these are in the bundle so the guide is instant.
const _kBrand = 'assets/player/guide/brand.png';
const _kListenIcon = 'assets/player/guide/listen.png';
const _kPracticeIcon = 'assets/player/guide/practice.png';
const _kLibraryIcon = 'assets/player/guide/library.png';
const _kSettingsIcon = 'assets/player/guide/settings.png';
const _kStoreIcon = 'assets/player/guide/store.png';
const _kReadyIcon = 'assets/player/guide/ready.png';

const kPlayerGuideSlides = <PlayerGuideSlide>[
  PlayerGuideSlide(
    title: 'NowssB Player Guide',
    icon: _kBrand,
    img: 'assets/player/guide/01.png',
    heading: 'Welcome to Your Practice Player',
    desc:
        'This is where you listen to, pronounce and master every word in your daily routine. Let’s walk through exactly how it works — button by button.',
  ),
  PlayerGuideSlide(
    title: 'Player Listen',
    icon: _kListenIcon,
    img: 'assets/player/guide/02.png',
    heading: 'Listen & Navigate',
    desc:
        'Tap the centre Play button to hear the word pronounced aloud. Use the arrows on either side to move to the Previous or Next word, and tap Replay anytime to hear it again.',
  ),
  PlayerGuideSlide(
    title: 'Player Record',
    icon: _kPracticeIcon,
    img: 'assets/player/guide/03.png',
    heading: 'Practice & Get Scored',
    desc:
        'Tap Practice to record your own voice saying the word. Each syllable lights up as you speak it, and you get an instant pronunciation score — the more you repeat, the more it builds your streak.',
  ),
  PlayerGuideSlide(
    title: 'Player Library',
    icon: _kLibraryIcon,
    img: 'assets/player/guide/04.png',
    heading: 'Build Your Library & Sentences',
    desc:
        'Tap the Library icon to open every word you’ve unlocked. Every word you purchase is added here automatically — combine them to build your own healing sentences, saved for practice anytime.',
  ),
  PlayerGuideSlide(
    title: 'Player Settings',
    icon: _kSettingsIcon,
    img: 'assets/player/guide/05.png',
    heading: 'Word Info & Player Settings',
    desc:
        'Tap the info icon to see the word’s meaning, the organ it benefits, and healing detail. Tap the settings gear to switch the voice (male or female), turn Loop on, or change your rep target.',
  ),
  PlayerGuideSlide(
    title: 'Player Store',
    icon: _kStoreIcon,
    img: 'assets/player/guide/06.png',
    heading: 'Grow Your Collection',
    desc:
        'Tap the Store icon anytime to buy new words and meanings — every purchase instantly joins your Library, so you can keep expanding your personal word ritual.',
  ),
  PlayerGuideSlide(
    title: 'Signature Word',
    icon: _kStoreIcon,
    img: 'assets/player/guide/07.png',
    heading: 'Unlock a Signature Word',
    desc:
        'Signature words are the rarest word in each category — one per set, own only in a special gold edition. Look for the Signature tag in the Store to add one to your collection.',
  ),
  PlayerGuideSlide(
    title: 'Player Ready',
    icon: _kReadyIcon,
    img: 'assets/player/guide/08.png',
    heading: 'You’re All Set',
    desc:
        'That’s everything you need to know. Tap Begin to start your first practice session.',
    isFinal: true,
  ),
];

class PlayerGuideScreen extends StatefulWidget {
  const PlayerGuideScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<PlayerGuideScreen> createState() => _PlayerGuideScreenState();
}

class _PlayerGuideScreenState extends State<PlayerGuideScreen> {
  static const _navy = Color(0xFF060C18);
  late final PageController _pages;
  var _idx = 0;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final s in kPlayerGuideSlides) {
        precacheImage(AssetImage(s.img), context);
        precacheImage(AssetImage(s.icon), context);
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  PlayerGuideSlide get _slide => kPlayerGuideSlides[_idx];
  bool get _isLast => _idx == kPlayerGuideSlides.length - 1;

  void _go(int i) {
    if (i < 0 || i >= kPlayerGuideSlides.length) return;
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(kPlayerGuideSeenKey, true);
    }).catchError((_) {});
    widget.onDone();
  }

  TextStyle _dm({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.2,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      shadows: shadows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final topPad = pad.top < 20 ? 20.0 : pad.top;
    final bottomPad = pad.bottom < 20 ? 20.0 : pad.bottom;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _finish();
      },
      child: Material(
        color: _navy,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pages,
                    itemCount: kPlayerGuideSlides.length,
                    onPageChanged: (i) => setState(() => _idx = i),
                    itemBuilder: (context, i) {
                      final s = kPlayerGuideSlides[i];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          NwsbImage(
                            url: s.img,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x26060C18),
                                  Color(0x0D060C18),
                                  Color(0x80060C18),
                                  Color(0xEB060C18),
                                  Color(0xFF060C18),
                                ],
                                stops: [0, 0.28, 0.60, 0.84, 1],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 26,
                            right: 26,
                            bottom: 22,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.heading,
                                  style: _dm(
                                    size: 29,
                                    weight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.16,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x80000000),
                                        blurRadius: 14,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.desc,
                                  style: _dm(
                                    size: 14.5,
                                    weight: FontWeight.w300,
                                    color: const Color(0xC7FFFFFF),
                                    height: 1.6,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x80000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                GestureDetector(
                                  onTap: s.isFinal ? _finish : () => _go(i + 1),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Try it now',
                                          style: _dm(
                                            size: 14,
                                            weight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x99040A18),
                            Color(0x40040A18),
                            Color(0x00040A18),
                          ],
                          stops: [0, 0.55, 1],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, topPad, 20, 30),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _finish,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0x660A0E1A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _slide.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _dm(
                                  size: 19,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x80000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0x24E8D5A3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0x66E8D5A3),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x59000000),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: NwsbImage(
                                url: _slide.icon,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: _navy,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < kPlayerGuideSlides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: i == _idx ? 20 : 7,
                              height: 7,
                              margin: EdgeInsets.only(
                                right:
                                    i == kPlayerGuideSlides.length - 1 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: i == _idx
                                    ? Colors.white
                                    : const Color(0x40FFFFFF),
                                borderRadius: BorderRadius.circular(
                                  i == _idx ? 4 : 99,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (_idx > 0) ...[
                          _NavCircle(
                            filled: false,
                            onTap: () => _go(_idx - 1),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (_isLast)
                          Material(
                            color: Colors.white,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: _finish,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(26, 0, 26, 0),
                                child: SizedBox(
                                  height: 52,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Begin',
                                        style: _dm(
                                          size: 14,
                                          weight: FontWeight.w800,
                                          color: _navy,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: _navy,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          _NavCircle(
                            filled: true,
                            onTap: () => _go(_idx + 1),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Color(0xFF0A0F1E),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
    required this.filled,
    required this.onTap,
    required this.child,
  });

  final bool filled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      shape: CircleBorder(
        side: filled
            ? BorderSide.none
            : const BorderSide(color: Colors.white, width: 1.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(child: child),
        ),
      ),
    );
  }
}
