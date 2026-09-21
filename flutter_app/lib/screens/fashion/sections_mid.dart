/// Fashion home sections 7-15, in registry order.
///
/// tiles · store · trendwd · custom · fashplus · rx · connect · trendvid ·
/// storeban
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/enter_curve_stage.dart';
import '../../widgets/flip_brand_showcase.dart';
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
import '../widgets_page.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// 7 · tiles — tip rail + horizontal pages.
///
/// Page 0 = Flip glass brand showcase; pages 1+ = existing feature destination
/// cards (Enter / nav preserved). Auto-swipes and loops while on-screen.
class FashTiles extends StatefulWidget {
  const FashTiles({super.key, this.onTile, this.onOpen});

  /// Called with the tile's destination tab index (community card).
  final void Function(int)? onTile;

  /// Player / Library / Store / Reader on the destination card.
  final void Function(String id)? onOpen;

  @override
  State<FashTiles> createState() => _FashTilesState();
}

class _FashTilesState extends State<FashTiles> {
  static const _pageCount = 3; // Flip + 2 existing feature panes
  static const _autoMs = 5200;

  late final PageController _pager;
  Timer? _auto;
  var _index = 0;
  var _userPaging = false;

  @override
  void initState() {
    super.initState();
    _pager = PageController(viewportFraction: 0.94);
    _armAuto();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pager.dispose();
    super.dispose();
  }

  void _armAuto() {
    _auto?.cancel();
    // Flip page advances via onCycleComplete; other pages use a timer.
    if (_index == 0) return;
    _auto = Timer(const Duration(milliseconds: _autoMs), _autoAdvance);
  }

  void _autoAdvance() {
    if (!mounted || _userPaging) return;
    if (!TickerMode.of(context)) {
      _armAuto();
      return;
    }
    final next = (_index + 1) % _pageCount;
    _pager.animateToPage(
      next,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  void _onFlipCycleComplete() {
    if (!mounted || _index != 0 || _userPaging) return;
    final next = (_index + 1) % _pageCount;
    _pager.animateToPage(
      next,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  /// Destination card: Connect replaces Sound Library so the two cards never
  /// share a button. (Preserved existing card — now page index 2.)
  static const _tiles = [
    (
      'Connect',
      'NowssB community',
      '',
      NwsbMarks.connectPair,
      0,
    ),
    (
      'My Progress',
      'Healing journey',
      '',
      NwsbMarks.bars,
      4,
    ),
    (
      'Word Science',
      'NOWSBANSIU texts',
      '',
      NwsbMarks.wordBag,
      2,
    ),
    (
      'My Profile',
      'Your settings',
      '',
      NwsbMarks.people,
      4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // +2 slack kills the 2.0px BOTTOM OVERFLOW on the feature panes
    // (GlassWrap border + column math).
    const gridH = _tileHeight * 2 + 10;
    const railH = 22.0;
    const gap = 10.0;
    const padV = 22.0;
    const pageH = padV + railH + gap + gridH + 2;

    Widget pane(List<Widget> tiles) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: railH, child: _TilesRail()),
              const SizedBox(height: gap),
              _TwoByTwo(children: tiles),
            ],
          ),
        ),
      );
    }

    // Same outer footprint as sibling panes (GlassWrap + horizontal inset).
    // No tip-rail / demo labels — Flip fills the card body.
    final flipPage = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: FlipBrandShowcase(
          active: _index == 0,
          onCycleComplete: _onFlipCycleComplete,
        ),
      ),
    );

    return SizedBox(
      height: pageH,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _userPaging = true;
            _auto?.cancel();
          } else if (n is ScrollEndNotification) {
            _userPaging = false;
            _armAuto();
          }
          return false;
        },
        child: PageView(
          controller: _pager,
          padEnds: true,
          onPageChanged: (i) {
            setState(() => _index = i);
            _armAuto();
          },
          children: [
            // Card 0 — Flip glass brand showcase
            flipPage,
            // Card 1 — existing Player / Library / Store / Reader (Enter)
            pane([
              for (final d in EnterCurveAssets.destinations)
                _BannerTile(
                  dest: d,
                  onTap: () => widget.onOpen?.call(d.id),
                ),
            ]),
            // Card 2 — existing Connect / Progress / Word Science / Profile
            pane([
              for (final (title, sub, art, mark, dest) in _tiles)
                _Tile(
                  title: title,
                  sub: sub,
                  art: art,
                  mark: mark,
                  onTap: () => widget.onTile?.call(dest),
                ),
            ]),
          ],
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
              const SizedBox(width: 10),
              cell(3),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.home-tile` in its DEFAULT look — `fashtile-black`, which is what
/// `savedFashStyle()` returns when nobody has chosen otherwise
/// (app/js/part059.js:69).
///
/// The stylesheet describes it exactly (nowssb-nm.css:3965): "2x2, and built
/// like the app's black banners: black card, icon puck, vertical rule, title
/// + subtitle, Enter pill bottom-right." A row, not a stack — `grid-template
/// -columns: auto 1px 1fr`, which is the puck, the rule, and the words.
///
/// What was here instead was the `fashtile-image` look, and only half of it:
/// the cover artwork stretched over the whole tile with a scrim on top. That
/// artwork has its own title painted into it, which is why every tile had a
/// giant word lying across it, and it is exactly why the real `image` look
/// hides the DOM text whenever it paints that layer.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.sub,
    required this.art,
    this.mark,
    this.onTap,
  });

  final String title, sub, art;
  final String? mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0x14FFFFFF)),
          // `body.fashcorner-rounded` is the default (part059.js:70) and it
          // is 18px.
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x6B000000),
              offset: Offset(0, 10),
              blurRadius: 26,
            ),
          ],
        ),
        child: Stack(
          children: [
            // `padding: 12px 10px 38px` — the 38 at the foot is the room the
            // Enter pill sits in, which is why the row is not centred in the
            // card.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 38),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // `.home-tile-icon` — 34px, a gold-tinted disc holding the
                  // real feature artwork, cover-fit and clipped round.
                  Container(
                    width: 34,
                    height: 34,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0x1AE8D5A3),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x3DE8D5A3)),
                    ),
                    child: mark != null
                        ? Center(
                            child: NwsbIcon(
                              mark!,
                              size: 16,
                              color: const Color(0xFFE8D5A3),
                            ),
                          )
                        : (art.isEmpty
                            ? const Center(
                                child: NwsbIcon(
                                  NwsbMarks.discover,
                                  size: 16,
                                  color: Color(0xFFE8D5A3),
                                ),
                              )
                            : NwsbImage(
                                url: art,
                                fit: BoxFit.cover,
                                fallback: const ColoredBox(
                                  color: Color(0x1AE8D5A3),
                                ),
                              )),
                  ),
                  const SizedBox(width: 8),
                  // `.home-tile-rule` — 1px, `align-self: stretch`.
                  Container(width: 1, color: const Color(0x2EFFFFFF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                            color: Color(0x80FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // `.home-tile-enter` — absolute, bottom 8 right 8.
            const Positioned(bottom: 8, right: 8, child: _TileEnter()),
          ],
        ),
      ),
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
            Image.asset(
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
          Text(
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

/// 10 · custom — index.html:2048. `.cust-panel` — the head, and the rows the
/// web fills from the layout registry. Reordering is out of scope, so the
/// panel is the door to Settings rather than a list of drag handles that
/// would not move anything.
class FashCustomize extends StatelessWidget {
  const FashCustomize({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _CustomizeExperienceBanner(onTap: onTap),
      SectionPane(
        child: Column(children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
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
          ]),
        ),
        const SizedBox(height: 16),
        _FashionCustomizeRow(title: 'Themes', sub: 'Black Edition', icon: Icons.grid_view_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WidgetsPage()))),
        _FashionCustomizeRow(title: 'Background', sub: 'Fashion backdrop', image: 'https://media.nowssb.com/migrated-images/cfc84fc5478b4b63_file_00000000b11472098a225d3703b04a60_phr6ph.png', icon: Icons.wallpaper_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FashionPlusScreen()))),
        _FashionCustomizeRow(title: 'Start Image', sub: 'Art behind the start', image: 'https://media.nowssb.com/migrated-images/5e8a9fdb18e034ec_file_000000009f10820bb6872a5ed8007148_pvqjaa.png', icon: Icons.image_outlined, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FashionPlusScreen()))),
        _FashionCustomizeRow(title: 'Quick Access', sub: 'Bottom nav bar', image: 'https://media.nowssb.com/migrated-images/272b820a002190fe_file_000000002cf4820b865caf6fc0554959_k7drqx.png', icon: Icons.apps_rounded, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickAccessScreen()))),
        ]),
      ),
    ]);
  }
}

class _CustomizeExperienceBanner extends StatefulWidget {
  const _CustomizeExperienceBanner({this.onTap});
  final VoidCallback? onTap;
  @override
  State<_CustomizeExperienceBanner> createState() => _CustomizeExperienceBannerState();
}

class _CustomizeExperienceBannerState extends State<_CustomizeExperienceBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<Offset> _slide = Tween(begin: Offset.zero, end: const Offset(-1.1, 0)).animate(CurvedAnimation(parent: _controller, curve: const Cubic(.7, 0, .2, 1)));
  Timer? _intro;
  @override
  void initState() {
    super.initState();
    if (_flutterTest) return;
    _intro = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) _controller.forward();
    });
  }
  @override
  void dispose() {
    _intro?.cancel();
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(.72, 1, curve: Curves.easeOut))),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              height: 96,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x29FFFFFF))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SizedBox(width: 230, child: Text('Customized\nyou app experiance', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 25, height: 1.08, fontWeight: FontWeight.w700, letterSpacing: -.3))),
                Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward, color: Color(0xFF060C18), size: 22)),
              ]),
            ),
          ),
        ),
      );
}

class _FashionCustomizeRow extends StatelessWidget {
  const _FashionCustomizeRow({required this.title, required this.sub, required this.icon, required this.onTap, this.image});
  final String title, sub;
  final IconData icon;
  final String? image;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x18FFFFFF))),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x33FFFFFF))), child: image == null ? Icon(icon, color: Colors.white, size: 24) : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(image!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, color: Colors.white, size: 24)))),
            const SizedBox(width: 16),
            Container(width: 1, height: 34, color: const Color(0x24FFFFFF)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(sub, style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 13))])),
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0x14FFFFFF), shape: BoxShape.circle, border: Border.all(color: const Color(0x2FFFFFFF))), child: const Icon(Icons.arrow_forward, color: Colors.white70, size: 20)),
          ]),
        ),
      );
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
                          'https://media.nowssb.com/migrated-images/b20d675b826ef760_grok_image_1784144472932_h242ko.jpg',
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
