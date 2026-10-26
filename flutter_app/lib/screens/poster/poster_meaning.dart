/// POSTER · Meaning Store — "THE ROOT".
/// Variation: a dictionary page. The word runs VERTICALLY down the left
/// edge, the blonde cut-out stands right, a black etymology strip carries the
/// root; the text sits on its own ruled band BELOW the figure (never over
/// MOTHER or the model). Below, an index: a giant Anton drop-cap per
/// category and a fanned, sideways-scrolling deck of dictionary flash cards.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import 'poster_kit.dart';

const _slot = 'concept.PosterMeaning';

/// Live price of a meaning (bag id meaning:<word>).
num meaningPrice(MsMeaning m) => StorePrices.instance.priceFor('meaning:${m.word.toLowerCase()}', shown: m.price);
String _id(MsMeaning m) => 'meaning:${m.word.toLowerCase()}';

String _blurb(String key) => (kMsWordBlurb[key] ?? '').replaceAll('&rsquo;', '’');

class PosterMeaning extends StatelessWidget {
  const PosterMeaning({
    super.key,
    required this.onBack,
    required this.onOpenStores,
    required this.onOpenBag,
    required this.onOpenMeaning,
    required this.onBuy,
    this.controller,
    this.now,
  });
  final VoidCallback onBack, onOpenStores, onOpenBag;

  /// Row / hero tap → openMeaningDetail(context, m).
  final void Function(MsMeaning m) onOpenMeaning;

  /// "Own · ₹price" pill → storeBuyNow(meaningBagItem(...)).
  final void Function(MsMeaning m) onBuy;
  final ScrollController? controller;
  final DateTime? now;

  static MsMeaning pick(DateTime now) => kMsBaseMeanings[(now.day * 7) % kMsBaseMeanings.length];

  @override
  Widget build(BuildContext context) {
    final m = pick(now ?? DateTime.now());
    return PosterScaffold(
      slot: _slot,
      kicker: 'Meanings · The root',
      controller: controller,
      onBack: onBack,
      onOpenStores: onOpenStores,
      onOpenBag: onOpenBag,
      tint: const Color(0xFF3E6B8C),
      children: [
        _Hero(m: m, onOpen: () => onOpenMeaning(m), onBuy: () => onBuy(m)),
        for (final cat in kMsCatSub.keys) ...[
          _Letter(cat: cat),
          _Deck(items: kMsBaseMeanings.where((x) => x.category == cat).toList(), onOpen: onOpenMeaning, onBuy: onBuy),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.m, required this.onOpen, required this.onBuy});
  final MsMeaning m;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: LayoutBuilder(builder: (context, box) {
          final W = box.maxWidth, H = W * 1.02;
          final price = priceOrNull(_id(m), meaningPrice(m));
          return Tap(
            onTap: onOpen,
            child: Container(
              decoration: BoxDecoration(color: kPPaper, borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.hardEdge,
              child: CustomPaint(
                painter: _Rules(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    height: H,
                    child: Stack(children: [
                      // vertical giant word in its own left column
                      Positioned(
                        left: 4,
                        top: 8,
                        bottom: 8,
                        width: W * .3,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: GiantWord(m.word.toUpperCase(), align: Alignment.center, style: anton(W * .3)),
                        ),
                      ),
                      // the model owns the right column only
                      Positioned(
                        left: W * .36,
                        right: 0,
                        top: H * .06,
                        bottom: 0,
                        child: const Cutout(PosterAssets.blonde, slot: _slot, id: 'hero.cutout', align: Alignment.bottomCenter, fadeBottom: .12),
                      ),
                      const Positioned(right: 12, top: 12, child: GoldTag('Meaning of the day')),
                    ]),
                  ),
                  Container(height: 2, color: kPInk),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(m.category, style: gHello(dark: false)),
                      Text(m.word, style: gTitle(dark: false)),
                      const SizedBox(height: 8),
                      InkTag(m.root),
                      const SizedBox(height: 8),
                      Text(_blurb(m.key), style: gSub(dark: false)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        GoldPill(label: price == null ? ownedLabel(_id(m)) : 'Own · $price', onTap: price == null ? onOpen : onBuy),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        }),
      );
}

class _Rules extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0x1A1A2E5A);
    for (var y = 40.0; y < s.height; y += 28) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
    c.drawLine(Offset(s.width * .33, 0), Offset(s.width * .33, s.width * 1.02), Paint()..color = const Color(0x55B0413E));
  }

  @override
  bool shouldRepaint(_Rules o) => false;
}

class _Letter extends StatelessWidget {
  const _Letter({required this.cat});
  final String cat;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox(
            width: 86,
            height: 96,
            child: GiantWord(cat[0], align: Alignment.bottomLeft, style: anton(120, color: kPGold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat, style: gTitle()),
              Text(kMsCatSub[cat] ?? '', style: gSub()),
            ]),
          ),
        ]),
      );
}

/// A category's meanings as a fanned deck of dictionary flash cards that
/// scrolls sideways (cards alternate paper / gold and tilt a hair).
class _Deck extends StatelessWidget {
  const _Deck({required this.items, required this.onOpen, required this.onBuy});
  final List<MsMeaning> items;
  final void Function(MsMeaning) onOpen, onBuy;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < items.length; i++) _Card(m: items[i], i: i, onOpen: () => onOpen(items[i]), onBuy: () => onBuy(items[i])),
          ]),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.m, required this.i, required this.onOpen, required this.onBuy});
  final MsMeaning m;
  final int i;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) {
    final price = priceOrNull(_id(m), meaningPrice(m));
    final gold = i.isOdd;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Transform.rotate(
        angle: (i.isEven ? -1 : 1) * .014,
        child: Semantics(
          button: true,
          label: 'Open ${m.word}',
          child: Tap(
            onTap: onOpen,
            child: Container(
              width: 232,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: gold ? kPGoldSoft : kPPaper,
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('No. ${(i + 1).toString().padLeft(2, '0')}', style: gSub(dark: false)),
                  const Spacer(),
                  Container(width: 26, height: 2, color: const Color(0xFFB0413E)),
                ]),
                SizedBox(height: 62, child: GiantWord(m.word.toUpperCase(), style: anton(62))),
                const SizedBox(height: 6),
                InkTag(m.root),
                const SizedBox(height: 8),
                Text(_blurb(m.key), style: gSub(dark: false)),
                const Spacer(),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: price == null ? 'Open ${m.word}' : 'Own ${m.word}',
                  child: Tap(
                    onTap: price == null ? onOpen : onBuy,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: kPInk, borderRadius: BorderRadius.circular(22)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(price == null ? ownedLabel(_id(m)) : 'Own · $price',
                                  maxLines: 1, softWrap: false, style: gHello(color: kPGoldSoft)))),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: kPGoldSoft, size: 18),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
