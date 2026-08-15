/// Fashion home sections 7-15, in registry order.
///
/// tiles · store · trendwd · custom · fashplus · rx · connect · trendvid ·
/// storeban
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_icon.dart';

import '../../data/content.dart';
import '../../data/settings.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/home_parts.dart';

/// 7 · tiles — index.html:1939. The tip rail, then four tiles two-up.
class FashTiles extends StatelessWidget {
  const FashTiles({super.key, this.onTile});

  /// Called with the tile's destination tab index.
  final void Function(int)? onTile;

  /// (title, sub, cover URL, icon, destination) — the four in the markup.
  static const _tiles = [
    (
      'Sound Library',
      'Root frequencies',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899463/file_000000008bf881faa9949f7b7d9824bf_niqhps.png',
      Icons.graphic_eq,
      2,
    ),
    (
      'Word Science',
      'NOWSBANSIU texts',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899472/file_00000000a24081fa83eeab9164647db8_w2fzuq.png',
      Icons.science_outlined,
      2,
    ),
    (
      'My Profile',
      'Your settings',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784896734/file_0000000080688207a9599e17a28e7710_oefkxy.png',
      Icons.person_outline,
      4,
    ),
    (
      'The Store',
      'Words and meanings',
      'https://res.cloudinary.com/eenvubod/image/upload/v1784899463/file_000000008bf881faa9949f7b7d9824bf_niqhps.png',
      Icons.storefront_outlined,
      3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.htg-rail` — "Tap to restyle" at one end, "Begin your healing"
          // at the other.
          Row(
            children: [
              const Icon(Icons.chevron_left,
                  size: 15, color: NwsbColors.goldLight),
              const Icon(Icons.chevron_left,
                  size: 15, color: NwsbColors.goldLight),
              const SizedBox(width: 6),
              // Both ends give way rather than one pushing the other off the
              // rail: at a narrow width or a large text scale the two lines
              // together are wider than the pane, and a Spacer between two
              // rigid Texts simply overflows.
              const Flexible(
                child: Text(
                  'Tap to restyle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Color(0xB3FFFFFF)),
                ),
              ),
              const Spacer(),
              Container(width: 1, height: 14, color: const Color(0x24FFFFFF)),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Begin your healing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.86,
            children: [
              for (final (title, sub, cover, icon, dest) in _tiles)
                _Tile(
                  title: title,
                  sub: sub,
                  cover: cover,
                  icon: icon,
                  onTap: () => onTile?.call(dest),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.sub,
    required this.cover,
    required this.icon,
    this.onTap,
  });

  final String title, sub, cover;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            NwsbImage(
              url: cover,
              fallback: const ColoredBox(color: Color(0xFF0A0F1C)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x59000000), Color(0xF7000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 22, color: NwsbColors.goldLight),
                  const Spacer(),
                  Container(
                      height: 1, width: 26, color: const Color(0x40FFFFFF)),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0x8CFFFFFF)),
                  ),
                  const SizedBox(height: 10),
                  const EnterPill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 8 · store — index.html:2490. Head, then `.nss-store-trigger` — the tall
/// card carrying the portrait render, with the eyebrow and title at its head
/// and the copy, the four pills and Explore Store at its foot. Then the bar.
///
/// The card is NOT framed. The store's clip is its own full-bleed background
/// here; the tablet bezel belongs to the banner further down the page, and
/// putting the portrait film in a landscape banner is the mistake the
/// comment at index.html:2502 was written about.
class FashStore extends StatelessWidget {
  const FashStore({super.key, this.onTap});
  final VoidCallback? onTap;

  static const _pills = [
    'Word Library',
    'Meaning Library',
    'Organ Targeting',
    'AI-Decoded',
  ];

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Words and meanings',
            title: 'The NowssB Store',
            mark: NwsbMarks.bag,
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const NwsbVideo(asset: 'assets/video/store-section.mp4'),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x99000000),
                            Color(0x33000000),
                            Color(0xF2000000),
                          ],
                          stops: [0, 0.42, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shabdapathy · Collections',
                            style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: NwsbColors.goldLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 27,
                                color: Colors.white,
                                height: 1.15,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Enter the\n',
                                  style: TextStyle(fontWeight: FontWeight.w300),
                                ),
                                TextSpan(
                                  text: 'NowssB Store',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Word Library & Meaning Library — own the sounds '
                            'that heal, unlock the origins that were hidden.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xB3FFFFFF),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in _pills)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x14FFFFFF),
                                    border: Border.all(
                                        color: const Color(0x2EFFFFFF)),
                                  ),
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xD9FFFFFF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            color: Colors.white,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Explore Store',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: NwsbColors.ink,
                                  ),
                                ),
                                SizedBox(width: 8),
                                NwsbIcon(NwsbMarks.arrow,
                                    size: 14, color: NwsbColors.ink),
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
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Enter the Store',
            sub: 'Word Library & Meaning Library, in one place',
            mark: NwsbMarks.bag,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 9 · trendwd — index.html:2022. A clip with the trending word over it, and
/// its bar.
class FashTrending extends StatelessWidget {
  const FashTrending({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final word = words.isEmpty
        ? ''
        : words[(DateTime.now().day + 3) % words.length].word;

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
                    const NwsbImage(
                      url:
                          'https://res.cloudinary.com/eenvubod/video/upload/f_auto,q_auto/v1784370276/grok_video_2026-07-18-15-53-02_ubjx5b.mp4',
                      fallback: NwsbVideo(
                        asset: 'assets/video/word-acts.mp4',
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xCC000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: "Today's Trending",
            sub: 'See which words are healing the most people right now',
            mark: NwsbMarks.trending,
            markViewBox: 22,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 10 · custom — index.html:2048. `.cust-panel` — the head, and the rows the
/// web fills from the layout registry. Reordering is out of scope, so the
/// panel is the door to Settings rather than a list of drag handles that
/// would not move anything.
class FashCustomize extends StatelessWidget {
  const FashCustomize({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: const Icon(Icons.tune, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Customize',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Make this home yours',
                    style: TextStyle(fontSize: 12, color: Color(0x8CFFFFFF)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xB3FFFFFF)),
          ],
        ),
      ),
    );
  }
}

/// 11 · fashplus — index.html:2069. `.fps-mini`. The third line reports the
/// switch, exactly as `.fp-state-line` does.
class FashPlusMini extends StatelessWidget {
  const FashPlusMini({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = Settings.instance.fashionPlus;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Image.asset(
                  'assets/fashion/fashion-icon.webp',
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome_motion_outlined,
                      size: 22,
                      color: NwsbColors.goldLight),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Experience',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: NwsbColors.gold,
                      ),
                    ),
                    const Text(
                      'Fashion Plus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      on
                          ? 'On — the tiles, the practice card and every '
                              'photo background are playing'
                          : 'Off — pages keep their photographs',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0x8CFFFFFF),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              EnterPill(onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// 12 · rx — index.html:2085, filled by app/js/part037.js. The banner clip,
/// the AI PRESCRIPTION label with its time slot, the reason, and three word
/// pills taken from the library.
class FashPrescription extends StatelessWidget {
  const FashPrescription({super.key, this.onTap, this.onWord});
  final VoidCallback? onTap;
  final void Function(int index)? onWord;

  /// HOUR_LABELS — app/js/part037.js:8.
  static String _slotLabel(DateTime at) {
    final h = at.hour;
    if (h < 12) return 'Morning Ritual';
    if (h < 17) return 'Afternoon Session';
    if (h < 21) return 'Evening Practice';
    return 'Night Restoration';
  }

  static String _slotWord(DateTime at) {
    final h = at.hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    if (h < 21) return 'evening';
    return 'night';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = ContentStore.instance.library;
    final slot = _slotWord(now);
    final picks =
        all.where((w) => w.time == slot || w.time == 'any').take(3).toList();

    return SectionPane(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: NwsbVideo(asset: 'assets/video/rx-banner.mp4'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      color: NwsbColors.goldLight,
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'AI PRESCRIPTION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 10),
                    // Night Restoration is the longest slot label and the
                    // widest this row ever gets — it gives way before the
                    // heading does.
                    Flexible(
                      child: Text(
                        _slotLabel(now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: const Color(0x14FFFFFF)),
                const SizedBox(height: 14),
                Text(
                  '"Your $slot prescription — aligned to your current time '
                  'and healing goals."',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xCCFFFFFF),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: picks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => onWord?.call(i),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 168,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0B12),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              picks[i].word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: NwsbColors.goldLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              picks[i].organ,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xB3FFFFFF),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Targeted for $slot healing.',
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0x8CFFFFFF),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Tap word to practice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 12, color: Color(0x8CFFFFFF)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14141C),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: EnterPill(onTap: onTap),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 13 · connect — index.html:2091. The clip on the slim portrait tablet,
/// with the wordmark and the paragraph under it.
class FashConnect extends StatelessWidget {
  const FashConnect({super.key, this.onTap});
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
              aspectRatio: 768 / 1168,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const NwsbImage(
                      url:
                          'https://res.cloudinary.com/eenvubod/image/upload/f_auto,q_auto,w_900/v1784144639/grok_image_1784144472932_h242ko.jpg',
                      fallback: NwsbVideo(
                        asset: 'assets/video/connect-banner.mp4',
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x40000000), Color(0xF2000000)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: 'NowssB '),
                                TextSpan(
                                  text: 'Connect',
                                  style: TextStyle(color: NwsbColors.goldLight),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'The social space of NowssB — share your daily '
                            'practice, post your frequency journey, and '
                            'connect with a community of sound healers and '
                            'word-science practitioners.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xB3FFFFFF),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          EnterPill(onTap: onTap),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 14 · trendvid — index.html:2113. The Shop Now strip.
class FashShopNow extends StatelessWidget {
  const FashShopNow({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    final w =
        words.isEmpty ? null : words[(DateTime.now().day + 1) % words.length];

    return SectionPane(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF14141C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_outlined,
                    size: 19, color: NwsbColors.goldLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w == null ? 'HEALS' : 'HEALS ${w.organ.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.4,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                    Text(
                      w?.word ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 34, color: const Color(0x1FFFFFFF)),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(color: NwsbColors.goldLight),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 15, color: NwsbColors.ink),
                    SizedBox(width: 7),
                    Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.ink,
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

/// 15 · storeban — index.html:2148. The head, then the Shop the Library bar
/// with the store banner clip between them.
class FashStoreBanner extends StatelessWidget {
  const FashStoreBanner({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SectionPane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaneHead(
            eyebrow: 'Own the sounds that heal',
            title: 'Inside the Store',
            mark: NwsbMarks.bag,
          ),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: const AspectRatio(
              aspectRatio: 1136 / 800,
              child: ClipRect(
                child: NwsbVideo(
                  asset: 'assets/video/store-banner-fash.mp4',
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SecBanner(
            title: 'Shop the Library',
            sub: 'Words, meanings and the origins behind them',
            mark: NwsbMarks.bag,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
