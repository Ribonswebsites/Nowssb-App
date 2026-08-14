/// Fashion home sections that appear ONLY on that home.
///
/// offer · shabda · promovid · wsearch · msearch · shabvid
///
/// The other nine of this stretch are in lib/screens/shared_sections.dart —
/// the Normal home carries them too. `offer` and `shopvid` were dropped from
/// `REG.norm.items` outright (app/js/part062.js:129), and Word Search and
/// Meaning Search were taken off the Normal home when the one search bar at
/// its head replaced them.
///
/// Copy is transcribed from index.html rather than paraphrased. Line numbers
/// on each class say where.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';

import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_parts.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/tv_frame.dart';

/// 19 · offer — index.html:2252. The coupon art — a clip, not a picture,
/// since app/js/part067.js:110 turned it into one — with Shop Now on it, and
/// Today's Offer underneath.
class FashOffer extends StatelessWidget {
  const FashOffer({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const NwsbVideo(
                      asset: 'assets/video/coupon-a.mp4',
                      priority: ClipPriority.decoration,
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ScreenCta(label: 'Shop Now', onTap: onTap),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: "Today's Offer",
            sub: "Rotating store coupons — tap to redeem today's deal",
            mark: NwsbMarks.bag,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 21 · shabda — index.html:2347. `defOff`. Featured / Shabdapathy
/// Foundations, and its bar.
class FashShabdapathy extends StatelessWidget {
  const FashShabdapathy({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhotoCard(
            background: const NwsbImage(
              url:
                  'https://res.cloudinary.com/eenvubod/image/upload/v1785054819/file_000000002a1481fbae984a694c298783_lkwus2.png',
              fallback: ColoredBox(color: Color(0xFF060C18)),
            ),
            label: 'Featured',
            title: 'Shabdapathy Foundations',
            sub: 'Ancient word science meets modern wellness. Explore the '
                'healing power of natural word origins.',
            onTap: onTap,
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Shabdapathy Foundations',
            sub: 'Ancient word science, meets modern wellness',
            mark: NwsbMarks.book,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 26 · promovid — index.html:2400. `#fashPromoVid` — the promo clip on the
/// landscape tablet, and nothing else.
///
/// It used to be a bare 16:9 box whose wrapper was `background: transparent`,
/// which is why it had nothing behind it.
class FashPromoVideo extends StatelessWidget {
  const FashPromoVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: TvFrame(
        asset: 'assets/video/orb-loop.mp4',
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.decoration,
        onTap: onTap,
      ),
    );
  }
}

/// 27 · wsearch — index.html:2411. `defOff`. The promo picture, then Word
/// Search: the clip, the copy and the field.
class FashWordSearch extends StatelessWidget {
  const FashWordSearch({super.key, this.onOpen});

  /// Called with whatever is in the field, empty when the section itself is
  /// tapped — the website opens the page either way and only runs a search
  /// when there is something to search for.
  final void Function(String query)? onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRect(
              child: NwsbImage(
                url:
                    'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778656121/grok_image_1778655491471_ss3vax.jpg',
                fallback: ColoredBox(color: Color(0xFF0A0F1C)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchPanel(
            eyebrow: 'Shabdapathy',
            title: 'Word Search',
            sub: 'Discover the natural origin and healing frequency of any '
                'word.',
            hint: 'Enter a word...',
            clip: 'assets/video/word-acts.mp4',
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

/// 28 · msearch — index.html:2438. `defOff`. The promo picture, then Know
/// The Real Meaning: the clip, the field at its foot, and the hint.
class FashMeaningSearch extends StatelessWidget {
  const FashMeaningSearch({super.key, this.onOpen});
  final void Function(String query)? onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRect(
              child: NwsbImage(
                url:
                    'https://res.cloudinary.com/dcbs8xr1l/image/upload/q_auto/f_auto/v1778656146/grok_image_1778656028544_cih9iy.jpg',
                fallback: ColoredBox(color: Color(0xFF0A0F1C)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchPanel(
            eyebrow: 'Sound Before Meaning',
            title: 'Know The Real Meaning',
            sub: 'Earth · Water · God · Your Name · Your Country',
            hint: 'Type any word, name or country...',
            clip: 'assets/video/orb-loop.mp4',
            onOpen: onOpen,
          ),
        ],
      ),
    );
  }
}

/// The shape both search sections take: a clip, the copy over it, and a
/// field that opens the page with whatever was typed.
class _SearchPanel extends StatefulWidget {
  const _SearchPanel({
    required this.eyebrow,
    required this.title,
    required this.sub,
    required this.hint,
    required this.clip,
    this.onOpen,
  });

  final String eyebrow, title, sub, hint, clip;
  final void Function(String query)? onOpen;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _go() => widget.onOpen?.call(_c.text.trim());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onOpen?.call(''),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(asset: widget.clip, priority: ClipPriority.decoration),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x59000000), Color(0xF2000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.eyebrow,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sub,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xB3FFFFFF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        border: Border.all(color: const Color(0x2EFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _c,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _go(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: widget.hint,
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0x73FFFFFF),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _go,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              child: const NwsbIcon(NwsbMarks.arrow, size: 16, color: NwsbColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 29 · shabvid — index.html:2547. The 16:9 banner above the footer, on the
/// landscape tablet, with the three lines and the wordmark.
class FashShabdaVideo extends StatelessWidget {
  const FashShabdaVideo({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: TvFrame(
        asset: 'assets/video/word-acts.mp4',
        frame: DeviceFrame.tabletLandscape,
        priority: ClipPriority.decoration,
        onTap: onTap,
        overlay: const Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xD9000000), Color(0x1A000000)],
                ),
              ),
            ),
            // The copy and the wordmark are placed against the screen, not
            // stacked in a Flex. A tablet aperture is a FIXED box — a
            // vertical Column inside one overflows the moment the type is a
            // line taller than expected, which at a large text scale it is.
            // `.hvb-text` and `.hvb-label` are absolutely positioned on the
            // web for exactly this reason.
            Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shabdapathy',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 20, height: 1.25),
                          children: [
                            TextSpan(
                              text: 'Before language\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w200,
                                color: Color(0xEBFFFFFF),
                              ),
                            ),
                            TextSpan(
                              text: 'was written,\n',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'it was sound.',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: NwsbColors.goldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Natural Origin of Word Science',
                        style:
                            TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Nowsbansiu',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Color(0x8CFFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
