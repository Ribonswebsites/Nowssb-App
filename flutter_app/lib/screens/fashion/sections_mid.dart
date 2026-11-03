/// Fashion home sections 7-15, in registry order.
///
/// tiles · store · trendwd · custom · fashplus · rx · connect · trendvid ·
/// storeban
library;

import 'zen_glass_tile.dart';
import 'package:nowssb/widgets/home_text.dart';
import 'package:nowssb/data/day_part.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/neumorphic.dart';

import '../../widgets/enter_curve_stage.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';

import '../../data/content.dart';
import '../../data/settings.dart';
import '../../media/nwsb_image.dart';
import '../../media/nwsb_video.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/home_parts.dart';
import '../quick_access.dart';
import '../fashion_plus.dart';
import '../../admin/template/editable.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// 7 · tiles — the destination buttons only.
///
/// Player, Sound Library, Store. The flip showcase and the
/// Connect / Progress / Word Science / Profile page are gone.
class FashTiles extends StatelessWidget {
  const FashTiles({super.key, this.onTile, this.onOpen});

  /// Unused. Kept so existing call sites still compile.
  final void Function(int)? onTile;

  /// Player / Library / Store.
  final void Function(String id)? onOpen;

  @override
  Widget build(BuildContext context) {
    const gridH = _tileHeight * 2 + 10;
    const railH = 22.0;
    const gap = 10.0;
    const padV = 22.0;
    const pageH = padV + railH + gap + gridH + 2;
    return SizedBox(
      height: pageH,
      child: Padding(
        // Side room so the banner titles sit inside the screen edges.
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: _tilesShell(
          context,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: railH, child: _TilesRail()),
              const SizedBox(height: gap),
              _TwoByTwo(
                children: [
                  for (final d in EnterCurveAssets.destinations)
                    _BannerTile(
                      dest: d,
                      onTap: () => onOpen?.call(d.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TilesRail extends StatelessWidget {
  const _TilesRail();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chevron_left, size: 15, color: NwsbColors.goldLight),
        const Icon(Icons.chevron_left, size: 15, color: NwsbColors.goldLight),
        const SizedBox(width: 6),
        const Flexible(
          child: EditableLabel('sections_mid.TilesRail',
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
          child: EditableLabel('sections_mid.TilesRail',
            'Begin your healing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Color(0x8CFFFFFF)),
          ),
        ),
      ],
    );
  }
}

/// `height: 128px` — room for the Enter pill so it is not clipped.
const double _tileHeight = 128;

class _TwoByTwo extends StatelessWidget {
  const _TwoByTwo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) => Expanded(child: children[i]);
    return Column(
      children: [
        SizedBox(
          height: _tileHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(0),
              const SizedBox(width: 10),
              cell(1),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _tileHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(2),
              if (children.length > 3) ...[
                const SizedBox(width: 10),
                cell(3),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Second card: the four destination banners as tile backgrounds, Enter
/// sitting on the empty right of the still's own vertical line.
class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.dest, this.onTap});

  final EnterCurveDest dest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x14FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6B000000),
              offset: Offset(0, 10),
              blurRadius: 26,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Inset and scaled down so the banner's own title is not
            // clipped by the tile's rounded edges.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 34, 10),
              child: EditableImage.asset(
              dest.banner,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, sync) {
                if (sync || frame != null) return child;
                return const ColoredBox(color: Color(0xFF111111));
              },
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF111111)),
                  slot: 'sections_mid.BannerTile',
            ),
            ),
            // Top-right destination mark (restored SVG — was missing/broken).
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x22FFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: NwsbIcon(
                    dest.mark,
                    size: 13,
                    viewBox: dest.mark == NwsbMarks.enterArrow ? 12 : 24,
                    color: const Color(0xFF1A1A2E),
                    strokeWidth: 1.6,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(child: _TileEnter(compact: true)),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.home-tile-enter` — a white pill: the word, then the arrow in its own
/// circle. nowssb-nm.css:3992.
class _TileEnter extends StatelessWidget {
  const _TileEnter({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact
        ? const EdgeInsets.fromLTRB(8, 2, 2, 2)
        : const EdgeInsets.fromLTRB(11, 4, 4, 4);
    final font = compact ? 8.0 : 10.0;
    final go = compact ? 16.0 : 20.0;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EditableLabel('sections_mid.TileEnter',
            'Enter',
            style: TextStyle(
              fontSize: font,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: NwsbColors.ink,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Container(
            width: go,
            height: go,
            decoration: const BoxDecoration(
              color: Color(0x1A060C18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: NwsbIcon(
                NwsbMarks.enterArrow,
                size: compact ? 8 : 10,
                viewBox: 12,
                strokeWidth: 1.9,
                cap: 'square',
                color: NwsbColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 8 · store — Explore Store card (restored; no longer only in streak carousel).
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
                    const NwsbVideo(asset: 'assets/video/store-section.mp4', slot: 'sections_mid.FashStore'),
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
                          const EditableLabel('sections_mid.FashStore',
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
                                  text: 'Future of Meditation',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
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
                        ],
                      ),
                    ),
                    Align(
                      alignment: const Alignment(1.0, 0.28),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
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
                    const NwsbVideo(
                      asset:
                          'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b.mp4',
                      fit: BoxFit.cover,
                      slot: 'sections_mid.FashTrending',
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x00000000), Color(0x66040A18)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    TrendBannerLockup(word: word, onTap: onTap),
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


/// 11 · fashplus — index.html:2069. `.fps-mini`. The third line reports the
/// switch, exactly as `.fp-state-line` does.
class FashPlusMini extends StatelessWidget {
  const FashPlusMini({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = Settings.instance.fashionPlus;
    return ZenGlassTile(style: ZenGlassStyle.prism, on: on, onTap: onTap);
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
  static String _slotLabel(DateTime at) => dayPartFor(at).ritualTitle;
  static String _slotWord(DateTime at) => dayPartFor(at).slot;

  @override
  Widget build(BuildContext context) => DayPartBuilder(builder: (context, _, now) => _build(context, now));

  Widget _build(BuildContext context, DateTime now) {
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
                child: NwsbVideo(asset: 'assets/video/rx-banner.mp4', slot: 'sections_mid.FashPrescription'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 4),
                      color: NwsbColors.goldLight,
                    ),
                    const SizedBox(width: 10),
                    // Own line, wraps on word boundaries (B022: no ellipsis).
                    const Expanded(
                      child: EditableLabel('sections_mid.FashPrescription',
                        'AI PRESCRIPTION',
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: Text(
                    _slotLabel(now),
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x99FFFFFF),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: const Color(0x14FFFFFF)),
                const SizedBox(height: 14),
                Text(
                  '"Your $slot prescription — aligned to your current time '
                  'and healing goals."',
                  style: HomeText.subline.copyWith(color: const Color(0xCCFFFFFF), height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 114,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: picks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => onWord?.call(all.indexOf(picks[i])),
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
                      child: EditableLabel('sections_mid.FashPrescription',
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
                          'https://media.nowssb.com/migrated-images/b20d675b826ef760_grok_image_1784144472932_h242ko.jpg',
                      fallback: NwsbVideo(
                        asset: 'assets/video/connect-banner.mp4',
                        slot: 'sections_mid.FashConnect',
                      ),
                      slot: 'sections_mid.FashConnect',
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

/// 14 · trendvid — the square Today's offer lived here.
/// That card is the first page of the subscription offer now. This slot
/// stays in the registry so the home does not drift, and draws nothing.
class FashShopNow extends StatelessWidget {
  const FashShopNow({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Fashion: always glass. Normal: neo white (NeuCard flips to glass when mode on).
Widget _tilesShell(BuildContext context, {required Widget child}) {
  final fashion = HomeSkinScope.of(context) == HomeSkin.fashion;
  if (fashion) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: child,
    );
  }
  return NeuCard(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: child,
  );
}
