/// Generic sections the owner adds from the UI Editor (Layout → Add
/// section) and fills with their own pictures, clips, words and a button
/// destination. They render from the entry's props only.
///
/// props: title, subtitle, body, cta, route, image, video, bg (ARGB),
///        bg2 (ARGB), height, cards: [{image, title, route}], align
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../template/editable.dart';
import 'app_pages.dart';
import 'carousel_fx.dart';
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
};

const kTemplateBlurbs = <String, String>{
  'imageBanner': 'A big picture with a headline and a button',
  'videoBanner': 'A looping clip with a headline and a button',
  'splitPromo': 'Words on one side, a picture on the other',
  'cardRow': 'Cards people swipe sideways',
  'textBlock': 'A heading and a paragraph',
  'cta': 'One button that goes somewhere',
};

String templateTitle(SectionEntry e) {
  final t = '${e.props['title'] ?? ''}'.trim();
  final kind = kTemplateNames[e.kind] ?? e.kind;
  return t.isEmpty ? kind : '$kind · $t';
}

/// Starting props for a new template section.
Map<String, dynamic> templateStarter(String kind) => switch (kind) {
      'imageBanner' => {'title': 'Your headline', 'subtitle': 'A line under it', 'cta': 'Explore', 'route': 'tab:3', 'height': 220},
      'videoBanner' => {'title': 'Your headline', 'cta': 'Watch', 'route': 'tab:1', 'height': 240},
      'splitPromo' => {'title': 'Split promo', 'subtitle': 'Say what it is', 'cta': 'Open', 'route': 'tab:3', 'bg': 0xFF1B2437, 'height': 170},
      'cardRow' => {
          'title': 'Picked for you',
          'cards': [
            {'title': 'Card one', 'route': 'tab:2'},
            {'title': 'Card two', 'route': 'tab:3'},
            {'title': 'Card three', 'route': 'tab:1'},
          ],
          'height': 190,
        },
      'textBlock' => {'title': 'A heading', 'body': 'Write something people should read.'},
      'cta' => {'cta': 'Start now', 'route': 'tab:1'},
      _ => {},
    };

class TemplateSection extends StatelessWidget {
  const TemplateSection({super.key, required this.entry, required this.pageId});
  final SectionEntry entry;
  final String pageId;

  String get _slot => 'tpl.$pageId.${entry.id}';
  Map<String, dynamic> get p => entry.props;
  String _s(String k) => '${p[k] ?? ''}';
  double _h(double def) => p['height'] is num ? (p['height'] as num).toDouble() : def;
  BoxFit get _fit => '${p['fit']}' == 'contain' ? BoxFit.contain : BoxFit.cover;

  Widget _label(String id, String text, TextStyle style, {int? maxLines, TextAlign? align}) => text.isEmpty
      ? const SizedBox.shrink()
      : EditableLabel(_slot, text, id: id, style: style, maxLines: maxLines, textAlign: align,
          overflow: maxLines == null ? null : TextOverflow.ellipsis);

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
        final media = entry.kind == 'videoBanner' && _s('video').isNotEmpty
            ? NetVideo(url: _s('video'), fit: _fit)
            : NetPicture(url: _s('image'), fit: _fit);
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
              Expanded(child: NetPicture(url: _s('image'), fit: _fit)),
            ]),
          ),
        );
      case 'cardRow':
        final cards = p['cards'] is List ? (p['cards'] as List).whereType<Map>().toList() : const <Map>[];
        return _CardRow(slot: _slot, title: _s('title'), cards: cards, height: _h(190));
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
    }
    return const SizedBox.shrink();
  }
}

class _CardRow extends StatefulWidget {
  const _CardRow({required this.slot, required this.title, required this.cards, required this.height});
  final String slot;
  final String title;
  final List<Map> cards;
  final double height;

  @override
  State<_CardRow> createState() => _CardRowState();
}

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
          child: EditableLabel(widget.slot, widget.title,
              id: 'title', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
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
                        NetPicture(url: '${m['image'] ?? ''}'),
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
                          child: Text('${m['title'] ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
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
  const NetVideo({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

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
    try {
      final f = await DefaultCacheManager().getSingleFile(widget.url);
      if (!mounted) return;
      final c = VideoPlayerController.file(File(f.path), videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
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
    if (c == null || !c.value.isInitialized) return const NetPicture(url: '');
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
