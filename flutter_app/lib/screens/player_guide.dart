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

/// Same URLs as `PWG_ICONS` / `PWG_*_IMG` in part054.js.
const _kBrand =
    'https://media.nowssb.com/migrated-images/2ab8b4bbd1a045b0_file_0000000039c8720893ebc07bba4d3afd_iq64ts.png';
const _kListenIcon =
    'https://media.nowssb.com/migrated-images/74d38b3c7b69b30b_e06d2880-7389-11f1-8c74-0593c060acc9_jy24tl.png';
const _kPracticeIcon =
    'https://media.nowssb.com/migrated-images/a8a2eb1bb04d59d1_27cbc180-7387-11f1-ac66-23a66b2b6053_mf6jdr.png';
const _kLibraryIcon =
    'https://media.nowssb.com/migrated-images/643dd804e986b5f6_3259c840-7387-11f1-ac66-23a66b2b6053_ikqafa.png';
const _kSettingsIcon =
    'https://media.nowssb.com/migrated-images/909b614a4f984b77_f90f56e0-7386-11f1-ac66-23a66b2b6053_n5ahnk.png';
const _kStoreIcon =
    'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png';
const _kReadyIcon =
    'https://media.nowssb.com/migrated-images/dc638b945c082954_file_000000003254720aab81c7118e7cc24a_ohsba3.png';

const kPlayerGuideSlides = <PlayerGuideSlide>[
  PlayerGuideSlide(
    title: 'NowssB Player Guide',
    icon: _kBrand,
    img:
        'https://media.nowssb.com/migrated-images/2ec9ad4747c6b76d_file_00000000d7e88209a05b0cd46d3c9204_yylblf.png',
    heading: 'Welcome to Your Practice Player',
    desc:
        'This is where you listen to, pronounce and master every word in your daily routine. Let’s walk through exactly how it works — button by button.',
  ),
  PlayerGuideSlide(
    title: 'Player Listen',
    icon: _kListenIcon,
    img:
        'https://media.nowssb.com/migrated-images/8f6e22d3e27e8f82_file_00000000e0948207852ee99ed468fbb0_gon5be.png',
    heading: 'Listen & Navigate',
    desc:
        'Tap the centre Play button to hear the word pronounced aloud. Use the arrows on either side to move to the Previous or Next word, and tap Replay anytime to hear it again.',
  ),
  PlayerGuideSlide(
    title: 'Player Record',
    icon: _kPracticeIcon,
    img:
        'https://media.nowssb.com/migrated-images/2c3aae23bdda443d_file_000000007b8081fa9f8bfa346747e79f_pbkbqy.png',
    heading: 'Practice & Get Scored',
    desc:
        'Tap Practice to record your own voice saying the word. Each syllable lights up as you speak it, and you get an instant pronunciation score — the more you repeat, the more it builds your streak.',
  ),
  PlayerGuideSlide(
    title: 'Player Library',
    icon: _kLibraryIcon,
    img:
        'https://media.nowssb.com/migrated-images/d21b96de1967b542_file_00000000bc3481fba068b600e71ed418_xt5arr.png',
    heading: 'Build Your Library & Sentences',
    desc:
        'Tap the Library icon to open every word you’ve unlocked. Every word you purchase is added here automatically — combine them to build your own healing sentences, saved for practice anytime.',
  ),
  PlayerGuideSlide(
    title: 'Player Settings',
    icon: _kSettingsIcon,
    img:
        'https://media.nowssb.com/migrated-images/db763251a11604b4_file_00000000cf00820b83f17dc392a0071d_hhm18g.png',
    heading: 'Word Info & Player Settings',
    desc:
        'Tap the info icon to see the word’s meaning, the organ it benefits, and healing detail. Tap the settings gear to switch the voice (male or female), turn Loop on, or change your rep target.',
  ),
  PlayerGuideSlide(
    title: 'Player Store',
    icon: _kStoreIcon,
    img:
        'https://media.nowssb.com/migrated-images/5808c91d1975b9fa_file_00000000c70081faab87b58c23b3edcb_yzyrbf.png',
    heading: 'Grow Your Collection',
    desc:
        'Tap the Store icon anytime to buy new words and meanings — every purchase instantly joins your Library, so you can keep expanding your personal word ritual.',
  ),
  PlayerGuideSlide(
    title: 'Signature Word',
    icon: _kStoreIcon,
    img:
        'https://media.nowssb.com/migrated-images/f3c17b36e07098ec_file_0000000035ac81fa8d163588e627b067_xjpm5r.png',
    heading: 'Unlock a Signature Word',
    desc:
        'Signature words are the rarest word in each category — one per set, own only in a special gold edition. Look for the Signature tag in the Store to add one to your collection.',
  ),
  PlayerGuideSlide(
    title: 'Player Ready',
    icon: _kReadyIcon,
    img:
        'https://media.nowssb.com/migrated-images/9f4113b898ea8bfe_file_00000000b6c481fab8074cb5a1d16756_thikfl.png',
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
