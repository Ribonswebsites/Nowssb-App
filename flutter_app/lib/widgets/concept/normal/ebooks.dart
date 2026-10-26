/// NowssB eBooks — "Cover rack": the three eBooks' art from the store
/// (assets/store/ebook-flips). Those frames share one "E-books" mock-up, so
/// each cover is cropped below the printed lettering to its own figure and
/// given its own jacket colour (amber / indigo / teal). The catalog's real
/// cover files (store_catalog.dart EbBook.cover) are remote URLs, not
/// bundled, so a book is shown only when its art is bundled here. Covers stay side by side at every
/// width; labels share one size that fits the longest word.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

/// The eBook line animation (kept from home_v4; used only for eBooks).
const kNEbookLottie = 'assets/anim/loaders/book_pages_gold.json';

/// Bundled art per catalogue key (assets/store/ebook-flips/<key>.webp).
/// A catalogue book without bundled art is left out (never a stand-in).
const kNEbookArt = {
  'phonetic-field-guide': (cx: .50, top: .54, tint: Color(0xFF8A5A12)),
  'shabdapathy-codex': (cx: .47, top: .54, tint: Color(0xFF4B3FA8)),
  'sound-healing-atlas': (cx: .45, top: .585, tint: Color(0xFF136B66)),
};

class NEbooks extends StatefulWidget {
  const NEbooks({super.key, required this.onBrowse, required this.books});
  final VoidCallback onBrowse;
  /// Catalogue books as (key, title), store_catalog.dart kEbBooks order.
  final List<(String, String)> books;
  @override
  State<NEbooks> createState() => _NEbooksState();
}

class _NEbooksState extends State<NEbooks> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 5);
  static final _label = nSub.copyWith(color: nInk, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2);

  List<(String, String)> get _shown => [for (final b in widget.books) if (kNEbookArt.containsKey(b.$1)) b].take(3).toList();

  Widget _cover(int i, double t) {
    final glint = ((t * 3 - i) % 3) / 1.0;
    final b = _shown[i];
    final c = kNEbookArt[b.$1]!;
    return AspectRatio(aspectRatio: .74, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Stack(fit: StackFit.expand, children: [
      LayoutBuilder(builder: (_, k) => _Crop(asset: 'assets/store/ebook-flips/${b.$1}.webp', cx: c.cx, top: c.top, w: k.maxWidth, h: k.maxHeight)),
      // each book gets its own jacket colour so the three read apart
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [c.tint.withValues(alpha: .0), c.tint.withValues(alpha: .55)]))),
        Positioned(left: 0, right: 0, bottom: 0, height: 5, child: ColoredBox(color: c.tint)),
      if (glint < 1)
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment(-2 + 4 * glint, -1), end: Alignment(-1 + 4 * glint, 1),
          colors: const [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)]))),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Browse eBooks', onTap: widget.onBrowse, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NowssB eBooks', style: nHello),
          const Text('Read anywhere', style: nTitle),
          const SizedBox(height: 14),
          Container(decoration: neu(r: 20, pressed: true), padding: const EdgeInsets.all(8),
            child: LayoutBuilder(builder: (c, k) {
              // covers always side by side; one label size for all three,
              // small enough that the longest single word fits its column.
              const gap = 3.0;
              final cw = k.maxWidth / shown.length - 2 * gap;
              final ts = MediaQuery.textScalerOf(c);
              final words = [for (final b in shown) ...b.$2.split(' ')];
              final widest = words.map((w) => (TextPainter(text: TextSpan(text: w, style: DefaultTextStyle.of(c).style.merge(_label)),
                  textDirection: TextDirection.ltr, textScaler: ts)..layout()).width).reduce(math.max);
              final label = _label.copyWith(fontSize: _label.fontSize! * math.min(1.0, (cw - 2) / widest));
              return AnimatedBuilder(animation: loop, builder: (_, __) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var i = 0; i < shown.length; i++)
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: gap), child: Column(children: [
                    _cover(i, loop.value),
                    const SizedBox(height: 8),
                    Text(shown[i].$2, textAlign: TextAlign.center, style: label),
                  ]))),
              ]));
            })),
          const SizedBox(height: 10),
          const Text('Word science and sound healing, page by page.', style: nSub),
          const SizedBox(height: 6),
          const Text('Browse eBooks  →', style: nLinkStyle),
        ]),
      )));
  }
}

/// Crops a 1408² store frame to the band BELOW the printed "E-books"
/// lettering (per-book top, .29 of the frame tall), centred on the book's own figure.
class _Crop extends StatelessWidget {
  const _Crop({required this.asset, required this.cx, required this.top, required this.w, required this.h});
  final String asset;
  final double cx, top, w, h;
  static const _span = .29;
  @override
  Widget build(BuildContext context) {
    final iw = h / _span;
    return ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned(left: w / 2 - iw * cx, top: -iw * top, width: iw, height: iw,
          child: Image.asset(asset, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF15131C)))),
    ]));
  }
}
