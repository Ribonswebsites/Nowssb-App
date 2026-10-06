/// Generic sections the owner adds from the UI Editor (Layout → Add
/// section) and fills with their own pictures, clips, words and a button
/// destination. They render from the entry's props only.
///
/// props: title, subtitle, body, cta, route, image, video, bg (ARGB),
///        bg2 (ARGB), height, cards: [{image, title, route}], align
///        coupons: [{amount, unit, code, …}] (coupon kinds, coupon_sections.dart)
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../../widgets/banner_mix.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/hype_rail.dart' show CouponTicketPromo;
import '../../widgets/sections/section_registry.dart';
import '../../widgets/stories_find_you_banner.dart';
import '../template/editable.dart';
import '../template/slot_keys.dart';
import 'app_pages.dart';
import 'carousel_fx.dart';
import 'coupon_sections.dart';
import 'layout_sections.dart';
import 'ui_layouts.dart';

/// Plain-words names for the Add section gallery.
const kTemplateNames = <String, String>{
  'imageBanner': 'Image banner',
  'videoBanner': 'Video banner',
  'splitPromo': 'Split promo banner',
  'cardRow': 'Horizontal card row',
  'textBlock': 'Text block',
  'cta': 'Button',
  'couponTicket': 'Coupon tickets (stacked)',
  'couponCards': 'Coupon cards (side by side)',
  'couponBanner': 'Coupon banner (sliding)',
  'couponPromo': 'Coupon ticket promo',
  'promoBanner': 'Colour promo banner',
  'glassyCarousel': 'Glassy carousel',
  'spotlight': 'Spotlight',
  'hypedRow': 'Hyped row',
  'artistCards': 'Artist cards',
  'categoryTiles': 'Category tiles',
  'bannerMix': 'Banner mix',
  'fourBanners': 'Four banners',
  'storiesBanner': 'Stories banner',
};

const kTemplateBlurbs = <String, String>{
  'imageBanner': 'A big picture with a headline and a button',
  'videoBanner': 'A looping clip with a headline and a button',
  'splitPromo': 'Words on one side, a picture on the other',
  'cardRow': 'Cards people swipe sideways',
  'textBlock': 'A heading and a paragraph',
  'cta': 'One button that goes somewhere',
  'couponTicket': 'Wide cut-out tickets: big amount, code, barcode — on white',
  'couponCards': 'Two portrait coupons with a coloured ribbon — on white',
  'couponBanner': 'Ticket offers that slide by themselves',
  'couponPromo': 'One gold coupon ticket that opens Coupons',
  'promoBanner': 'A coloured banner with a figure',
  'glassyCarousel': 'Glass cards that swipe sideways',
  'spotlight': 'One big card at a time',
  'hypedRow': 'Tall cards in a row',
  'artistCards': 'Artist cards in a row',
  'categoryTiles': 'Small tiles to browse',
  'bannerMix': 'A mixed banner',
  'fourBanners': 'Four banners stacked',
  'storiesBanner': 'Stories that find you',
};

/// Sections and banners in the drawer, in the order they are shown.
const kTemplateGallery = <String>[
  'couponTicket',
  'couponCards',
  'couponBanner',
  'couponPromo',
  'imageBanner',
  'videoBanner',
  'splitPromo',
  'promoBanner',
  'cardRow',
  'glassyCarousel',
  'spotlight',
  'hypedRow',
  'artistCards',
  'categoryTiles',
  'bannerMix',
  'fourBanners',
  'storiesBanner',
  'textBlock',
  'cta',
];

/// The ready-made sections drawn by the app's section registry.
const _registryKinds = {'couponBanner', 'glassyCarousel', 'spotlight', 'hypedRow', 'artistCards', 'categoryTiles'};

String templateTitle(SectionEntry e) {
  var t = '${e.props['title'] ?? ''}'.trim();
  if (t.isEmpty && (e.kind == 'couponTicket' || e.kind == 'couponCards')) {
    final first = couponsOf(e.props);
    if (first.isNotEmpty) t = '${first.first['code'] ?? ''}'.trim();
  }
  final kind = kTemplateNames[e.kind] ?? e.kind;
  return t.isEmpty ? kind : '$kind · $t';
}

/// Starting props for a new template section.
Map<String, dynamic> templateStarter(String kind) => switch (kind) {
      'imageBanner' => {
          'title': 'Your headline',
          'subtitle': 'A line under it',
          'cta': 'Explore',
          'route': 'tab:3',
          'image': 'assets/banners/stories/aura.png',
          'height': 220,
        },
      'videoBanner' => {
          'title': 'Your headline',
          'cta': 'Watch',
          'route': 'tab:1',
          'image': 'assets/banners/stories/prana.png',
          'height': 240,
        },
      'splitPromo' => {
          'title': 'Split promo',
          'subtitle': 'Say what it is',
          'cta': 'Open',
          'route': 'tab:3',
          'bg': 0xFF1B2437,
          'image': 'assets/banners/promo/split-egyptian-gold.png',
          'height': 170,
        },
      'cardRow' => {
          'title': 'Picked for you',
          'cards': [
            {'title': 'Card one', 'route': 'tab:2', 'image': 'assets/store/collections/cosmos.webp'},
            {'title': 'Card two', 'route': 'tab:3', 'image': 'assets/store/collections/nature.webp'},
            {'title': 'Card three', 'route': 'tab:1', 'image': 'assets/store/collections/mythical.webp'},
          ],
          'height': 190,
        },
      'promoBanner' => {'variant': 0},
      'bannerMix' => {'variant': 0},
      'textBlock' => {'title': 'A heading', 'body': 'Write something people should read.'},
      'cta' => {'cta': 'Start now', 'route': 'tab:1'},
      'couponTicket' || 'couponCards' => couponStarter(kind),
      _ => {},
    };

class TemplateSection extends StatelessWidget {
  const TemplateSection({super.key, required this.entry, required this.pageId, this.thumb = false});
  final SectionEntry entry;
  final String pageId;

  /// A drawer thumbnail: plain words and pictures, nothing registered.
  final bool thumb;

  String get _slot => 'tpl.$pageId.${entry.id}';
  Map<String, dynamic> get p => entry.props;
  String _s(String k) => '${p[k] ?? ''}';
  double _h(double def) => p['height'] is num ? (p['height'] as num).toDouble() : def;
  BoxFit get _fit => '${p['fit']}' == 'contain' ? BoxFit.contain : BoxFit.cover;

  Widget _label(String id, String text, TextStyle style, {int? maxLines, TextAlign? align}) => text.isEmpty
      ? const SizedBox.shrink()
      : thumb
          ? Text(text, style: style, maxLines: maxLines, textAlign: align,
              overflow: maxLines == null ? null : TextOverflow.ellipsis)
          : EditableLabel(_slot, text, id: id, style: style, maxLines: maxLines, textAlign: align,
              overflow: maxLines == null ? null : TextOverflow.ellipsis);

  /// A picture the owner can tap in the editor to replace (prop [id]).
  Widget _picture(BuildContext context, String id, String url) => thumb
      ? NetPicture(url: url, fit: _fit)
      : TemplatePicture(slot: '$_slot.$id', url: url, fit: _fit);

  Widget _cta(BuildContext context, {bool light = false}) {
    final label = _s('cta');
    if (label.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => openRoute(context, _s('route')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: light ? Colors.white : const Color(0xFFE8D5A3),
          borderRadius: BorderRadius.circular(99),
        ),
        child: _label('cta', label,
            const TextStyle(color: Color(0xFF060C18), fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _overlayText(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('title', _s('title'),
              const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
              maxLines: 2),
          if (_s('subtitle').isNotEmpty) ...[
            const SizedBox(height: 6),
            _label('subtitle', _s('subtitle'), const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14), maxLines: 2),
          ],
          if (_s('cta').isNotEmpty) ...[const SizedBox(height: 12), _cta(context)],
        ],
      );

  /// The words, shrunk to fit when the owner writes more than the box holds.
  Widget _fitText(BuildContext context) => LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(width: box.maxWidth, child: _overlayText(context)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (entry.kind) {
      case 'imageBanner':
      case 'videoBanner':
        final media = entry.kind == 'videoBanner' && _s('video').isNotEmpty && !thumb
            ? NetVideo(url: _s('video'), fit: _fit, poster: _s('image'))
            : _picture(context, 'image', _s('image'));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: _h(220),
              child: Stack(fit: StackFit.expand, children: [
                media,
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xAA000000)],
                    ),
                  ),
                ),
                Positioned(left: 18, right: 18, bottom: 18, top: 18, child: Align(alignment: Alignment.bottomLeft, child: _fitText(context))),
              ]),
            ),
          ),
        );
      case 'splitPromo':
        final bg = Color(p['bg'] is num ? (p['bg'] as num).toInt() : 0xFF1B2437);
        final bg2 = p['bg2'] is num ? Color((p['bg2'] as num).toInt()) : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: _h(170),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bg2 == null ? bg : null,
              gradient: bg2 == null ? null : LinearGradient(colors: [bg, bg2]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.all(18), child: _fitText(context)),
              ),
              Expanded(child: _picture(context, 'image', _s('image'))),
            ]),
          ),
        );
      case 'cardRow':
        final cards = p['cards'] is List ? (p['cards'] as List).whereType<Map>().toList() : const <Map>[];
        return _CardRow(slot: _slot, title: _s('title'), cards: cards, height: _h(190), thumb: thumb);
      case 'textBlock':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('title', _s('title'),
                const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            if (_s('body').isNotEmpty) ...[
              const SizedBox(height: 8),
              _label('body', _s('body'), const TextStyle(color: Color(0xCCFFFFFF), fontSize: 15, height: 1.45)),
            ],
          ]),
        );
      case 'cta':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Center(child: _cta(context)),
        );
      case 'couponTicket':
      case 'couponCards':
        return CouponSection(kind: entry.kind, props: p, slot: thumb ? null : _slot);
      case 'promoBanner':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ColoredSplitPromoBanner(
            spec: SplitPromoExtras.at(_variant, onTap: () => openRoute(context, _s('route'))),
            margin: EdgeInsets.zero,
          ),
        );
      case 'couponPromo':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CouponTicketPromo(onPressed: _s('route').isEmpty ? null : () => openRoute(context, _s('route'))),
        );
      case 'bannerMix':
        return BannerMix(seed: _variant);
      case 'fourBanners':
        return const FourBanners();
      case 'storiesBanner':
        return const StoriesFindYouBanner();
    }
    if (_registryKinds.contains(entry.kind)) {
      ensureSectionRegistry();
      final r = SectionRegistry.instance;
      var config = r.defaultConfigFor(entry.kind, id: _slot);
      // The sideways ones start at the first card and stop at the last.
      // A little more room than where the app places them, for larger text.
      if (entry.kind == 'glassyCarousel') {
        config = config.copyWith(
          behavior: config.behavior.copyWith(loop: false),
          layout: config.layout.copyWith(height: 244, cardHeight: 224),
        );
      } else if (entry.kind == 'couponBanner') {
        config = config.copyWith(layout: config.layout.copyWith(height: 264));
      }
      return r.build(context, config);
    }
    return const SizedBox.shrink();
  }

  int get _variant => p['variant'] is num ? (p['variant'] as num).toInt() : 0;
}

/// A template's picture: tappable in the editor (its slot), replaced into
/// the section's own props (EditorController.setMedia).
class TemplatePicture extends StatelessWidget {
  const TemplatePicture({super.key, required this.slot, required this.url, this.fit = BoxFit.cover});
  final String slot;
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      slotChrome(context, slot, SlotType.image, url, SizedBox.expand(child: NetPicture(url: url, fit: fit)));
}

/// A live, real-size template drawn small (the drawer's tiles).
class TemplateThumb extends StatelessWidget {
  const TemplateThumb({super.key, required this.kind, this.width = 412});
  final String kind;

  /// The phone width it is drawn at before it is shrunk.
  final double width;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TemplateSection(
                  entry: SectionEntry(id: 'thumb', kind: kind, props: templateStarter(kind)),
                  pageId: '_thumb',
                  thumb: true,
                ),
              ),
            ),
          ),
        ),
      );
}

class _CardRow extends StatefulWidget {
  const _CardRow({required this.slot, required this.title, required this.cards, required this.height, this.thumb = false});
  final String slot;
  final String title;
  final List<Map> cards;
  final double height;
  final bool thumb;

  @override
  State<_CardRow> createState() => _CardRowState();
}

const _titleStyle = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800);
const _cardStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15);

class _CardRowState extends State<_CardRow> {
  final _c = PageController(viewportFraction: 0.72);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.title.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: widget.thumb
              ? Text(widget.title, style: _titleStyle)
              : EditableLabel(widget.slot, widget.title, id: 'title', style: _titleStyle),
        ),
      SizedBox(
        height: widget.height,
        child: CarouselAutoRotate(
          controller: _c,
          count: widget.cards.length,
          child: PageView.builder(
            controller: _c,
            padEnds: false,
            itemCount: widget.cards.length,
            itemBuilder: (context, i) {
              final m = widget.cards[i];
              return carouselFxItem(
                context,
                _c,
                i,
                GestureDetector(
                  onTap: () => openRoute(context, '${m['route'] ?? ''}'),
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(fit: StackFit.expand, children: [
                        if (widget.thumb)
                          NetPicture(url: '${m['image'] ?? ''}')
                        else
                          TemplatePicture(slot: '${widget.slot}.card$i', url: '${m['image'] ?? ''}'),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x99000000)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: widget.thumb || '${m['title'] ?? ''}'.isEmpty
                              ? Text('${m['title'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: _cardStyle)
                              : EditableLabel(widget.slot, '${m['title'] ?? ''}',
                                  id: 'card${i}title', maxLines: 2, overflow: TextOverflow.ellipsis, style: _cardStyle),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}

/// A picture from a URL (the owner's upload), cached; a soft gradient
/// while it loads or when there is none yet.
class NetPicture extends StatelessWidget {
  const NetPicture({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  static const _empty = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF1B2437), Color(0xFF0B1120)]),
    ),
    child: Center(child: Icon(Icons.image_outlined, color: Colors.white24, size: 36)),
  );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _empty;
    if (!url.startsWith('http')) {
      return Image.asset(url, fit: fit, errorBuilder: (_, __, ___) => _empty);
    }
    return CachedNetworkImage(imageUrl: url, fit: fit, placeholder: (_, __) => _empty, errorWidget: (_, __, ___) => _empty);
  }
}

/// A muted looping clip from a URL, downloaded once into the disk cache.
class NetVideo extends StatefulWidget {
  const NetVideo({super.key, required this.url, this.fit = BoxFit.cover, this.poster = ''});
  final String url;
  final BoxFit fit;

  /// Shown until the clip plays.
  final String poster;

  @override
  State<NetVideo> createState() => _NetVideoState();
}

class _NetVideoState extends State<NetVideo> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(NetVideo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _c?.dispose();
      _c = null;
      _open();
    }
  }

  Future<void> _open() async {
    final url = widget.url;
    if (url.isEmpty) return;
    try {
      final f = await DefaultCacheManager().getSingleFile(url);
      if (!mounted || url != widget.url) return;
      final c = VideoPlayerController.file(File(f.path), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      // Gone, or the owner swapped the clip while this one was loading.
      if (!mounted || url != widget.url) {
        await c.dispose();
        return;
      }
      _c?.dispose();
      setState(() => _c = c);
    } catch (_) {}
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) return NetPicture(url: widget.poster, fit: widget.fit);
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
