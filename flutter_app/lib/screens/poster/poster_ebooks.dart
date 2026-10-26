/// POSTER · eBooks — "THE SPINE".
/// Variation: a torn reading-room still with a giant READ and the pointer
/// cut-out peeking in from the left; then a shelf of book SPINES (Anton
/// titles run up the spine, never cut); then the centrepiece — the lead book
/// standing in 3D (cover, spine edge, page block) on a gold plinth — and
/// every volume opened as a contents sheet. Network covers are not used.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import 'poster_kit.dart';

const _slot = 'concept.PosterEbooks';

/// Live ebook price (bag id ebook:<title>; catalogue price as the shown one).
num bookPrice(EbBook b) => StorePrices.instance.priceFor('ebook:${b.title.toLowerCase()}', shown: b.price);
String _id(EbBook b) => 'ebook:${b.title.toLowerCase()}';

/// The real catalogue: the built-in volumes plus every live book the studio
/// published (ContentStore.books), de-duplicated by key — same merge the
/// old Ebooks store did.
/// [live] overrides ContentStore.instance.books (tests).
List<EbBook> posterBooks({List<Book>? live}) {
  live ??= ContentStore.instance.books;
  if (live.isEmpty) return kEbBooks;
  final keys = {for (final b in kEbBooks) b.key};
  final merged = [...kEbBooks];
  for (final b in live) {
    if (keys.add(b.key)) {
      merged.add(EbBook(
        key: b.key,
        title: b.title,
        sub: b.sub,
        price: b.price,
        cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
        about: b.sub,
        contents: const ['Published from the NowssB studio'],
      ));
    }
  }
  return merged;
}

const _spines = [kPPlum, kPGold, kPPaper, Color(0xFF1E3A4C)];

class PosterEbooks extends StatelessWidget {
  const PosterEbooks({
    super.key,
    required this.onBack,
    required this.onOpenStores,
    required this.onOpenBag,
    required this.onOpenBook,
    required this.onBuyBook,
    this.controller,
  });
  final VoidCallback onBack, onOpenStores, onOpenBag;

  /// Spine / jacket tap → openEbookDetail(context, b).
  final void Function(EbBook b) onOpenBook;

  /// "Own" → storeBuyNow(ebookBagItem(b)).
  final void Function(EbBook b) onBuyBook;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: ContentStore.instance, builder: (context, _) => _build(context, posterBooks()));

  Widget _build(BuildContext context, List<EbBook> books) {
    final lead = books.first;
    return PosterScaffold(
      slot: _slot,
      kicker: 'eBooks · The spine',
      controller: controller,
      onBack: onBack,
      onOpenStores: onOpenStores,
      onOpenBag: onOpenBag,
      tint: const Color(0xFF8C5A2E),
      children: [
        _Hero(count: books.length),
        const Kicker(_slot, 'The shelf'),
        _Shelf(books: books, onOpen: onOpenBook),
        const Kicker(_slot, 'Standing on the table'),
        _Book3D(b: lead, onOpen: () => onOpenBook(lead), onBuy: () => onBuyBook(lead)),
        const Kicker(_slot, 'Every volume, opened'),
        for (var i = 0; i < books.length; i++) _Jacket(b: books[i], i: i, onOpen: () => onOpenBook(books[i]), onBuy: () => onBuyBook(books[i])),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(builder: (context, box) {
          final W = box.maxWidth, H = W * .98;
          return SizedBox(
            height: H,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: W * .12,
                right: 0,
                top: 0,
                height: H * .78,
                child: Transform.rotate(
                  angle: .025,
                  child: ClipPath(
                    clipper: const TornClipper(41, depth: 1.5),
                    child: Stack(fit: StackFit.expand, children: [
                      Photo(PosterAssets.rail('ebooks'), slot: _slot, id: 'hero.photo'),
                      const DecoratedBox(decoration: BoxDecoration(color: Color(0x55060C18))),
                    ]),
                  ),
                ),
              ),
              Positioned(
                left: -W * .14,
                bottom: H * .06,
                width: W * .58,
                height: H * .9,
                child: const Sway(amp: .005, child: Cutout(PosterAssets.pointer, slot: _slot, id: 'hero.cutout', align: Alignment.bottomLeft, fadeBottom: .1)),
              ),
              Positioned(
                left: W * .2,
                right: 0,
                bottom: 0,
                height: H * .36,
                child: GiantWord('READ', align: Alignment.bottomRight, style: anton(H * .4, color: kPPaper, w: FontWeight.w800, ls: -6)),
              ),
              Positioned(right: 12, top: 12, child: GoldTag('$count volumes')),
            ]),
          );
        }),
      );
}

/// The shelf: spines stand on a gold ledge, heights vary like real books.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.books, required this.onOpen});
  final List<EbBook> books;
  final void Function(EbBook) onOpen;
  static const _perLedge = 3;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(children: [
          // Three spines per ledge (the designed width); more live books
          // stack another ledge instead of thinning the spines.
          for (var s = 0; s < books.length; s += _perLedge) ...[
            if (s > 0) const SizedBox(height: 18),
            SizedBox(
              height: 330,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = s; i < s + _perLedge; i++) ...[
                  if (i > s) const SizedBox(width: 8),
                  Expanded(child: i < books.length ? _Spine(b: books[i], i: i, onTap: () => onOpen(books[i])) : const SizedBox()),
                ],
              ]),
            ),
            Container(
                height: 8,
                decoration: BoxDecoration(
                    color: kPGold,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 10, offset: Offset(0, 6))])),
          ],
        ]),
      );
}

class _Spine extends StatelessWidget {
  const _Spine({required this.b, required this.i, required this.onTap});
  final EbBook b;
  final int i;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final bg = _spines[i % _spines.length];
    final light = bg == kPPaper || bg == kPGold;
    final fg = light ? kPInk : Colors.white;
    final price = priceText(_id(b), bookPrice(b));
    return Semantics(
      button: true,
      label: 'Open ${b.title}',
      child: Tap(
        onTap: onTap,
        child: Container(
          height: 330 - (i % 3) * 26.0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: kPGold.withValues(alpha: .5)),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 10, offset: Offset(4, 6))],
          ),
          child: Column(children: [
            Container(height: 2, color: fg.withValues(alpha: .6)),
            const SizedBox(height: 8),
            // the WHOLE title, up the spine: two Anton lines, scaled (never cut)
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Text(b.title.toUpperCase().replaceFirst(': ', ':\n'),
                      textAlign: TextAlign.center, textScaler: TextScaler.noScaling, style: anton(30, color: fg, height: 1.05)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(price, maxLines: 1, style: gSub(color: fg))),
            const SizedBox(height: 6),
            Container(height: 2, color: fg.withValues(alpha: .6)),
          ]),
        ),
      ),
    );
  }
}

/// CENTREPIECE: the lead book standing in 3D — typographic cover, a visible
/// spine edge and page block, cast shadow on a gold plinth.
class _Book3D extends StatelessWidget {
  const _Book3D({required this.b, required this.onOpen, required this.onBuy});
  final EbBook b;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) {
    final price = priceOrNull(_id(b), bookPrice(b));
    final big = b.title.split(' ').firstWhere((w) => w.length > 4, orElse: () => b.title).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: LayoutBuilder(builder: (context, box) {
        final W = box.maxWidth;
        final bw = W * .62, bh = bw * 1.42, depth = bw * .13;
        return Column(children: [
          Tap(
            onTap: onOpen,
            child: SizedBox(
              height: bh + 40,
              child: Stack(alignment: Alignment.bottomCenter, children: [
                // plinth + shadow
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: W * .86,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8C6A2E), kPGold, Color(0xFF8C6A2E)]),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [BoxShadow(color: Color(0xCC000000), blurRadius: 30, offset: Offset(0, 18))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 22,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .0012)
                      ..rotateY(-.42)
                      ..rotateX(.04),
                    child: SizedBox(
                      width: bw + depth,
                      height: bh,
                      child: Stack(children: [
                        // page block (right edge)
                        Positioned(
                          right: 0,
                          top: 6,
                          bottom: 6,
                          width: depth + 6,
                          child: CustomPaint(painter: _Pages()),
                        ),
                        // cover
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: bw,
                          child: _Cover(b: b, big: big),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text(b.title, textAlign: TextAlign.center, style: gTitle()),
          const SizedBox(height: 4),
          Text(b.sub, textAlign: TextAlign.center, style: gHello()),
          const SizedBox(height: 14),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            GoldPill(label: price == null ? ownedLabel(_id(b)) : 'Own · $price', onTap: price == null ? onOpen : onBuy),
            GoldPill(label: 'Look inside', onTap: onOpen, dark: true, arrow: true),
          ]),
        ]);
      }),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.b, required this.big});
  final EbBook b;
  final String big;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A2160), kPPlum, Color(0xFF120A1F)]),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(3), right: Radius.circular(6)),
          border: Border.all(color: kPGold, width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 18, offset: Offset(-8, 10))],
        ),
        child: Stack(children: [
          // hinge crease
          Positioned(left: 10, top: 0, bottom: 0, child: Container(width: 2, color: const Color(0x55000000))),
          Positioned(left: 13, top: 0, bottom: 0, child: Container(width: 1, color: const Color(0x33E8D5A3))),
          Positioned(
            left: 22,
            right: 14,
            top: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NowssB · Volume ${posterBooks().indexWhere((x) => x.key == b.key) + 1}', textScaler: TextScaler.noScaling, style: gSub(color: kPGoldSoft)),
              const SizedBox(height: 10),
              Container(height: 1, color: kPGold),
            ]),
          ),
          Positioned(
            left: 18,
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(child: SizedBox(height: 120, child: GiantWord(big, align: Alignment.center, style: anton(120, color: kPGold)))),
          ),
          Positioned(
            left: 22,
            right: 14,
            bottom: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 1, color: kPGold),
              const SizedBox(height: 10),
              Text(b.title, textScaler: TextScaler.noScaling, style: gSub(color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          // gloss
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment(.2, .2), colors: [Color(0x22FFFFFF), Color(0x00FFFFFF)]),
                ),
              ),
            ),
          ),
        ]),
      );
}

class _Pages extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9DFC8));
    final p = Paint()..color = const Color(0x33000000);
    for (var x = 2.0; x < s.width; x += 2.2) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    c.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(colors: [Color(0x66000000), Color(0x00000000)]).createShader(Offset.zero & s));
  }

  @override
  bool shouldRepaint(_Pages o) => false;
}

class _Jacket extends StatelessWidget {
  const _Jacket({required this.b, required this.i, required this.onOpen, required this.onBuy});
  final EbBook b;
  final int i;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) {
    final price = priceOrNull(_id(b), bookPrice(b));
    final big = b.title.split(' ').firstWhere((w) => w.length > 4, orElse: () => b.title).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Tap(
        onTap: onOpen,
        child: Transform.rotate(
          angle: (i.isEven ? -1 : 1) * .01,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: i.isOdd ? kPGoldSoft : kPPaper,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 12))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('0${i + 1}', textScaler: TextScaler.noScaling, style: anton(44, color: const Color(0xFFB0413E))),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 50, child: GiantWord(big, style: anton(60)))),
              ]),
              const SizedBox(height: 6),
              Text(b.sub, style: gHello(dark: false)),
              const SizedBox(height: 10),
              InkTag(b.about, maxLines: 40),
              const SizedBox(height: 10),
              for (final c in b.contents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('—  ', style: gSub(dark: false)),
                    Expanded(child: Text(c, style: gSub(dark: false))),
                  ]),
                ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GoldPill(label: price == null ? ownedLabel(_id(b)) : 'Own · $price', onTap: price == null ? onOpen : onBuy),
                GoldPill(label: 'Look inside', onTap: onOpen, dark: true, arrow: true),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
