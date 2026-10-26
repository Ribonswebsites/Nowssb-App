/// POSTER · Signature — "THE SEAL".
/// Variation: black and gold. Cleopatra cropped tight and FLIPPED to the
/// left (unlike the centred Trending orbit), a giant gold outline SEAL behind
/// her and a wax seal sticker. Signature
/// words are perforated gold ticket stubs; signature meanings black/gold cards.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../store/store_shelf.dart' show kPlaceRows;
import 'poster_kit.dart';

const _slot = 'concept.PosterSignature';

/// Live price of a signature word (bag id signature:<name>).
num sigWordPrice(RmSignatureEntry s) => StorePrices.instance.priceFor('signature:${s.name.toLowerCase()}', kind: 'signature');

/// Live price of a signature meaning (bag id meaning:<word>, signature kind).
num sigMeaningPrice(MsSignatureEntry e) => StorePrices.instance.priceFor('meaning:${e.word.toLowerCase()}', kind: 'signature');

/// A signature meaning's display title: "Elements Signature" → "Elements".
String sigTitle(MsSignatureEntry e) => e.word.replaceAll(RegExp(r'\s*signature\s*', caseSensitive: false), ' ').trim();

/// The line above a signature card's title: the category, unless it would
/// just repeat the title ("Elements / Elements") — then the real root line.
/// Live price of a place-row signature word (Countries / Capitals / ...).
num sigPlacePrice(String name) => StorePrices.instance.priceFor('signature:${name.toLowerCase()}', kind: 'signature');

/// The four place decks, in the store's order.
const kSigPlaceGroups = ['Countries', 'Capitals', 'Currency', 'Language'];

String sigKicker(String cat, MsSignatureEntry e) => cat.toLowerCase() == sigTitle(e).toLowerCase() ? e.root : cat;

String _blurb(String key) => (kMsWordBlurb[key] ?? '').replaceAll('&rsquo;', '’');

class PosterSignature extends StatelessWidget {
  const PosterSignature({
    super.key,
    required this.onBack,
    required this.onOpenStores,
    required this.onOpenBag,
    required this.onOpenSignatureWord,
    required this.onBuySignatureWord,
    required this.onOpenSignatureMeaning,
    required this.onBuySignatureMeaning,
    required this.onOpenPlace,
    required this.onCartPlace,
    required this.onBuyPlace,
    required this.onRequest,
    this.controller,
  });
  final VoidCallback onBack, onOpenStores, onOpenBag;

  /// Stub tap → openAtelierWord(word: s.name, root: 'Most Exclusive', signature: true).
  final void Function(RmSignatureEntry s, num price) onOpenSignatureWord;

  /// Stub "Own" → storeBuyNow(wordBagItem(name: s.name, signature: true)).
  final void Function(RmSignatureEntry s, num price) onBuySignatureWord;

  /// Card tap → openMeaningDetail(MsMeaning(.. price: sigMeaningPrice(e)), signature: true).
  final void Function(String category, MsSignatureEntry e) onOpenSignatureMeaning;

  /// Card "Own" → storeBuyNow(meaningBagItem(.. signature: true)).
  final void Function(String category, MsSignatureEntry e) onBuySignatureMeaning;

  /// Place card "Open" → openAtelierWord(word: name, root: row root).
  final void Function((String, String, String) row) onOpenPlace;

  /// Place card "Add to cart" → storeAddToCart(wordBagItem(.. signature: true)) + cart hint.
  final void Function((String, String, String) row, num price) onCartPlace;

  /// Place card "Own" → storeBuyNow(wordBagItem(.. signature: true)).
  final void Function((String, String, String) row, num price) onBuyPlace;

  /// "Request a Signature" → openRequestWords.
  final VoidCallback onRequest;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // Real per-category signature words; the 'Sale' promo row is not a word.
    final cats = [
      for (final c in kRmCategories)
        if (c.signature != null && c.id != 'off50' && c.signature!.name.toLowerCase() != 'sale') c
    ];
    final meanings = kMsSignature.entries.toList();
    final lead = meanings.first;
    return PosterScaffold(
      slot: _slot,
      kicker: 'Signature · The seal',
      controller: controller,
      onBack: onBack,
      onOpenStores: onOpenStores,
      onOpenBag: onOpenBag,
      tint: kPGold,
      children: [
        _Hero(
          e: lead.value,
          onOpen: () => onOpenSignatureMeaning(lead.key, lead.value),
          onBuy: () => onBuySignatureMeaning(lead.key, lead.value),
        ),
        const Kicker(_slot, 'Signature words'),
        for (var i = 0; i < cats.length; i++)
          _Stub(
            cat: cats[i],
            i: i,
            onOpen: () => onOpenSignatureWord(cats[i].signature!, sigWordPrice(cats[i].signature!)),
            onBuy: () => onBuySignatureWord(cats[i].signature!, sigWordPrice(cats[i].signature!)),
          ),
        const Kicker(_slot, 'Signature meanings'),
        for (final e in meanings)
          _Card(cat: e.key, e: e.value, onOpen: () => onOpenSignatureMeaning(e.key, e.value), onBuy: () => onBuySignatureMeaning(e.key, e.value)),
        for (final g in kSigPlaceGroups) ...[
          Kicker(_slot, 'Signature $g'),
          _PlaceDeck(
            rows: [for (final r in kPlaceRows) if (r.$3 == g) r],
            onOpen: onOpenPlace,
            onCart: onCartPlace,
            onBuy: onBuyPlace,
          ),
        ],
        PosterRequest(
          tag: 'Signature · Request',
          title: 'Request a Signature',
          body: 'Personally crafted & delivered within 48 hours.',
          action: 'Request',
          onTap: onRequest,
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.e, required this.onOpen, required this.onBuy});
  final MsSignatureEntry e;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(builder: (context, box) {
          final W = box.maxWidth, H = W * 1.0;
          final id = 'meaning:${e.word.toLowerCase()}';
          final p = priceOrNull(id, sigMeaningPrice(e));
          return Tap(
            onTap: onOpen,
            child: Container(
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: kPGold, width: 1.5)),
              clipBehavior: Clip.hardEdge,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(
                    height: H,
                    child: Stack(children: [
                      Positioned(
                        left: -W * .04,
                        right: -W * .04,
                        top: H * .02,
                        height: H * .4,
                        child: GiantWord('SEAL',
                            align: Alignment.topCenter, style: anton(H * .4, w: FontWeight.w800, ls: -6), outline: kPGold.withValues(alpha: .8)),
                      ),
                      Positioned(
                        left: -W * .02,
                        top: H * .1,
                        width: W * .95,
                        height: H * .9,
                        child: const Cutout(PosterAssets.cleopatra, slot: _slot, id: 'hero.cutout', align: Alignment.bottomLeft, fadeBottom: .18),
                      ),
                      Positioned(right: 16, top: H * .36, child: Transform.rotate(angle: .18, child: const _Wax())),
                    ])),
                Container(height: 2, color: kPGold),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(e.root, style: gHello(color: kPGoldSoft)),
                    Text(sigTitle(e), style: gTitle()),
                    const SizedBox(height: 8),
                    InkTag(_blurb(e.key)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      GoldPill(label: p == null ? ownedLabel(id) : 'Own · $p', onTap: p == null ? onOpen : onBuy),
                      GoldPill(label: 'Look inside', onTap: onOpen, dark: true, arrow: true),
                    ]),
                  ]),
                ),
              ]),
            ),
          );
        }),
      );
}

/// A real wax seal: an irregular poured-wax blob (crimson, lit from top
/// left), a pressed inner ring and the NowssB "N" stamped in gold.
class _Wax extends StatelessWidget {
  const _Wax();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 100,
        height: 100,
        child: CustomPaint(
          painter: _WaxPainter(),
          child: Center(
            child: Text('N',
                textScaler: TextScaler.noScaling,
                style: anton(40, color: const Color(0xFFE8C77A)).copyWith(shadows: const [
                  Shadow(color: Color(0xCC3A0508), offset: Offset(1.5, 1.5), blurRadius: 1),
                  Shadow(color: Color(0x66FFD9A0), offset: Offset(-1, -1), blurRadius: 1),
                ])),
          ),
        ),
      );
}

class _WaxPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2 - 4;
    // poured edge: radius wobbles like cooled wax
    final blob = Path();
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * math.pi;
      final k = 1 + .045 * math.sin(a * 7 + .6) + .03 * math.sin(a * 13 + 2.1) + .02 * math.cos(a * 3);
      final p = ctr + Offset(math.cos(a), math.sin(a)) * r * k;
      i == 0 ? blob.moveTo(p.dx, p.dy) : blob.lineTo(p.dx, p.dy);
    }
    blob.close();
    c.drawShadow(blob, Colors.black, 6, false);
    c.drawPath(
        blob,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.35, -.4),
            colors: [Color(0xFFC0392B), Color(0xFF8E1B1B), Color(0xFF4F0A0C)],
            stops: [0, .55, 1],
          ).createShader(Offset.zero & s));
    // pressed stamp well
    final well = r * .72;
    c.drawCircle(ctr, well, Paint()..color = const Color(0xFF6E1114));
    c.drawCircle(
        ctr + const Offset(-1, -1),
        well,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFF3A0508));
    c.drawCircle(
        ctr + const Offset(1.2, 1.2),
        well,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x88E06A5A));
    // dotted gold border inside the stamp
    final dot = Paint()..color = const Color(0xCCE8C77A);
    for (var i = 0; i < 28; i++) {
      final a = i / 28 * 2 * math.pi;
      c.drawCircle(ctr + Offset(math.cos(a), math.sin(a)) * well * .84, 1.3, dot);
    }
    // gloss
    c.drawOval(Rect.fromCenter(center: ctr + Offset(-r * .42, -r * .5), width: r * .5, height: r * .22), Paint()..color = const Color(0x44FFFFFF));
  }

  @override
  bool shouldRepaint(_WaxPainter o) => false;
}

class _Stub extends StatelessWidget {
  const _Stub({required this.cat, required this.i, required this.onOpen, required this.onBuy});
  final RmCategory cat;
  RmSignatureEntry get s => cat.signature!;
  final int i;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) {
    final id = 'signature:${s.name.toLowerCase()}';
    final price = priceOrNull(id, sigWordPrice(s));
    return Padding(
      padding: EdgeInsets.fromLTRB(i.isEven ? 16 : 28, 0, i.isEven ? 28 : 16, 10),
      child: Transform.rotate(
        angle: (i.isEven ? -1 : 1) * .012,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Open ${s.name}',
                child: Tap(
                  onTap: onOpen,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: const BoxDecoration(color: kPGold, borderRadius: BorderRadius.horizontal(left: Radius.circular(6))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Full size, wrapping on word boundaries (never shrunk to fit).
                      Text('No. ${(i + 1).toString().padLeft(2, '0')} · ${cat.words.length} words inside', maxLines: 3, style: gSub(color: kPInk)),
                      // Wraps between words; a single word wider than the stub shrinks whole (never split).
                      // Wrap hands each word the stub's width as its max.
                      Wrap(spacing: 8, children: [
                        for (final w in s.name.split(' '))
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(w, maxLines: 1, softWrap: false, style: gTitle(dark: false))),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            CustomPaint(size: const Size(2, 10), painter: _Perf()),
            Semantics(
              button: true,
              label: 'Own ${s.name}',
              child: Tap(
                onTap: onBuy,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(color: kPGoldSoft, borderRadius: BorderRadius.horizontal(right: Radius.circular(6))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(price == null ? ownedLabel(id) : 'Own', textAlign: TextAlign.center, style: gSub(color: kPInk)),
                    if (price != null) Text(price, style: gHello(color: kPInk).copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Perf extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = kPGoldSoft);
    final p = Paint()..color = Colors.black;
    for (var y = 4.0; y < s.height; y += 9) {
      c.drawCircle(Offset(s.width / 2, y), 2.2, p);
    }
  }

  @override
  bool shouldRepaint(_Perf o) => false;
}

class _Card extends StatelessWidget {
  const _Card({required this.cat, required this.e, required this.onOpen, required this.onBuy});
  final String cat;
  final MsSignatureEntry e;
  final VoidCallback onOpen, onBuy;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Tap(
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6), border: Border.all(color: kPGold.withValues(alpha: .7))),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                right: -4,
                top: -10,
                child: Transform.rotate(
                  angle: -math.pi / 14,
                  child: SizedBox(
                      width: 90,
                      height: 90,
                      child: GiantWord(cat[0], align: Alignment.topRight, style: anton(110, w: FontWeight.w800), outline: kPGold.withValues(alpha: .35))),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sigKicker(cat, e), style: gHello(color: kPGoldSoft)),
                Text(sigTitle(e), style: gTitle()),
                const SizedBox(height: 6),
                Text(_blurb(e.key), style: gSub()),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  GoldPill(
                      label: priceOrNull('meaning:${e.word.toLowerCase()}', sigMeaningPrice(e)) == null
                          ? ownedLabel('meaning:${e.word.toLowerCase()}')
                          : 'Own · ${priceOrNull('meaning:${e.word.toLowerCase()}', sigMeaningPrice(e))}',
                      onTap: priceOrNull('meaning:${e.word.toLowerCase()}', sigMeaningPrice(e)) == null ? onOpen : onBuy),
                  GoldPill(label: 'Open', onTap: onOpen, dark: true, arrow: true),
                ]),
              ]),
            ]),
          ),
        ),
      );
}

/// A sideways deck of gold-edged place tickets (Countries, Capitals, ...).
class _PlaceDeck extends StatelessWidget {
  const _PlaceDeck({required this.rows, required this.onOpen, required this.onCart, required this.onBuy});
  final List<(String, String, String)> rows;
  final void Function((String, String, String)) onOpen;
  final void Function((String, String, String), num) onCart, onBuy;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 6, 12),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < rows.length; i++)
              _Place(row: rows[i], i: i, onOpen: () => onOpen(rows[i]), onCart: (p) => onCart(rows[i], p), onBuy: (p) => onBuy(rows[i], p)),
          ]),
        ),
      );
}

class _Place extends StatelessWidget {
  const _Place({required this.row, required this.i, required this.onOpen, required this.onCart, required this.onBuy});
  final (String, String, String) row;
  final int i;
  final VoidCallback onOpen;
  final void Function(num) onCart, onBuy;
  @override
  Widget build(BuildContext context) {
    final p = sigPlacePrice(row.$1);
    final id = 'signature:${row.$1.toLowerCase()}';
    final shown = priceOrNull(id, p);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        button: true,
        label: 'Open ${row.$1}',
        child: Tap(
          onTap: onOpen,
          child: Container(
            width: 220,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6), border: Border.all(color: kPGold.withValues(alpha: .7))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('No. ${(i + 1).toString().padLeft(2, '0')} · ${row.$2}', style: gSub(color: kPGoldSoft)),
              const SizedBox(height: 6),
              SizedBox(height: 44, child: GiantWord(row.$1.toUpperCase(), style: anton(48, color: kPGold))),
              const Spacer(),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GoldPill(label: shown == null ? ownedLabel(id) : 'Own · $shown', onTap: shown == null ? onOpen : () => onBuy(p)),
                if (shown != null) GoldPill(label: 'Add to cart', onTap: () => onCart(p), dark: true),
                GoldPill(label: 'Open', onTap: onOpen, dark: true, arrow: true),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
