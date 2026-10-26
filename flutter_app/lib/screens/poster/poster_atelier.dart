/// POSTER · Word Atelier — "THE CUTTING TABLE".
/// Variation: the pointer cut-out stands on the RIGHT and points into a torn
/// PICK poster; below, every catalogue category is a torn photo tile with
/// its giant label, followed by a grid of word swatches (word, root, price).
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import 'poster_kit.dart';

const _slot = 'concept.PosterAtelier';

class PosterAtelier extends StatelessWidget {
  const PosterAtelier({
    super.key,
    required this.onBack,
    required this.onOpenStores,
    required this.onOpenBag,
    required this.onOpenWord,
    required this.onAddToCart,
    required this.onBuy,
    required this.onOpenCategory,
    this.controller,
    this.now,
  });
  final VoidCallback onBack, onOpenStores, onOpenBag;

  /// Swatch tap → openAtelierWord(word: e.word, root: e.root, price: price).
  final void Function(RmWordEntry e, num price) onOpenWord;

  /// "+" on a swatch → storeAddToCart(wordBagItem(...)).
  final void Function(RmWordEntry e, num price) onAddToCart;

  /// "Own this word" (hero / dock) → storeBuyNow(wordBagItem(...)).
  final void Function(RmWordEntry e, num price) onBuy;

  /// "All N words" under a category → the category's full rail.
  final void Function(RmCategory c) onOpenCategory;
  final ScrollController? controller;
  final DateTime? now;

  /// Today's cut: rotates daily through the first category's words.
  static RmWordEntry pick(DateTime now) {
    final w = kRmCategories.firstWhere((c) => c.id != 'off50', orElse: () => kRmCategories.first).words;
    return w[now.day % w.length];
  }

  /// Each category's words, de-duplicated across the whole page (a word shows
  /// once, under the first category that lists it). The "50% OFF" rail only
  /// survives with words that are REALLY on sale today (regularIfOnSale).
  static List<(RmCategory, List<RmWordEntry>)> rails() {
    final seen = <String>{};
    final out = <(RmCategory, List<RmWordEntry>)>[];
    for (final c in kRmCategories) {
      final ws = <RmWordEntry>[];
      for (final e in c.words) {
        final k = e.word.toLowerCase();
        if (k.isEmpty || seen.contains(k)) continue;
        if (c.id == 'off50' && StorePrices.instance.regularIfOnSale('word:$k') == null) continue;
        seen.add(k);
        ws.add(e);
      }
      if (ws.isNotEmpty) out.add((c, ws));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rails = PosterAtelier.rails();
    final hero = pick(now ?? DateTime.now());
    final heroPrice = wordPrice(hero.word);
    return PosterScaffold(
      slot: _slot,
      kicker: 'Word Atelier · The cutting table',
      controller: controller,
      onBack: onBack,
      onOpenStores: onOpenStores,
      onOpenBag: onOpenBag,
      tint: kPGold,
      dock: _Dock(word: hero, price: heroPrice, onBuy: () => onBuy(hero, heroPrice), onOpen: () => onOpenWord(hero, heroPrice)),
      children: [
        _Hero(word: hero, price: heroPrice, onBuy: () => onBuy(hero, heroPrice), onOpen: () => onOpenWord(hero, heroPrice)),
        for (var i = 0; i < rails.length; i++) ...[
          _CategoryTile(cat: rails[i].$1, index: i, onTap: () => onOpenCategory(rails[i].$1)),
          _Swatches(
            cat: rails[i].$1,
            words: rails[i].$2,
            index: i,
            onOpen: (e, p) => onOpenWord(e, p),
            onAdd: (e, p) => onAddToCart(e, p),
            onAll: () => onOpenCategory(rails[i].$1),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.word, required this.price, required this.onBuy, required this.onOpen});
  final RmWordEntry word;
  final num price;
  final VoidCallback onBuy, onOpen;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: LayoutBuilder(builder: (context, box) {
          final W = box.maxWidth, H = W * 1.0;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: H,
              child: Stack(clipBehavior: Clip.none, children: [
                // torn photo poster, tilted left
                Positioned(
                  left: 0,
                  top: H * .04,
                  width: W * .8,
                  height: H * .9,
                  child: Transform.rotate(
                    angle: -.035,
                    child: ClipPath(
                      clipper: const TornClipper(12, depth: 1.4),
                      child: Stack(fit: StackFit.expand, children: [
                        Photo(PosterAssets.rail('word'), slot: _slot, id: 'hero.photo'),
                        const DecoratedBox(decoration: BoxDecoration(color: Color(0x66060C18))),
                      ]),
                    ),
                  ),
                ),
                // giant PICK behind the figure
                Positioned(
                  left: 10,
                  top: H * .1,
                  width: W * .42,
                  height: H * .2,
                  child: GiantWord('PICK', style: anton(H * .3, color: Colors.white, w: FontWeight.w800, ls: -6)),
                ),
                // pointer cut-out on the right, pointing in
                Positioned(
                  right: -W * .12,
                  top: H * .02,
                  width: W * .6,
                  height: H,
                  child: const Sway(
                      amp: .006, child: Cutout(PosterAssets.pointer, slot: _slot, id: 'hero.cutout', flip: true, fadeBottom: .1, align: Alignment.bottomRight)),
                ),
                const Positioned(left: 14, top: 0, child: GoldTag('Cut today')),
                // the word she points at, in front
                Positioned(
                  left: 8,
                  right: W * .3,
                  top: H * .31,
                  height: H * .24,
                  child: Tap(
                    onTap: onOpen,
                    child: GiantWord(word.word.toUpperCase(),
                        style:
                            anton(H * .2, color: kPPaper, w: FontWeight.w800, ls: -2).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 20)])),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  InkTag('Root · ${word.root}'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    GoldPill(
                        label: priceOrNull(_id(word), price) == null ? ownedLabel(_id(word)) : 'Own · ${priceOrNull(_id(word), price)}',
                        onTap: priceOrNull(_id(word), price) == null ? onOpen : onBuy),
                    GoldPill(label: 'Open', onTap: onOpen, dark: true, arrow: true),
                  ]),
                ])),
          ]);
        }),
      );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.cat, required this.index, required this.onTap});
  final RmCategory cat;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final left = index.isEven;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 34, 14, 12),
      child: Tap(
        onTap: onTap,
        child: Transform.rotate(
          angle: left ? -.02 : .02,
          child: ClipPath(
            clipper: TornClipper(index * 11 + 3),
            child: SizedBox(
              height: 190,
              child: Stack(fit: StackFit.expand, children: [
                Photo(PosterAssets.rail(cat.id, index), slot: _slot, id: 'cat.${cat.id}.photo'),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xDD060C18)]),
                  ),
                ),
                if (cat.badge != null) Positioned(right: 12, top: 12, child: GoldTag(cat.badge!)),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 80,
                        child: GiantWord(cat.label.toUpperCase(),
                            align: left ? Alignment.bottomLeft : Alignment.bottomRight, style: anton(96, color: Colors.white, w: FontWeight.w800, ls: -2)),
                      ),
                      const SizedBox(height: 4),
                      Text(cat.sub, textAlign: left ? TextAlign.left : TextAlign.right, style: gSub(color: Colors.white)),
                    ],
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

String _id(RmWordEntry e) => 'word:${e.word.toLowerCase()}';

/// Cloth colours for the swatches — dyed fabric, not cream cards.
const _cloth = [Color(0xFF5A1F2B), Color(0xFF1F3A35), Color(0xFF2B2150), Color(0xFF6B4A12), Color(0xFF1B2A44), Color(0xFF4A2A1A)];

class _Swatches extends StatelessWidget {
  const _Swatches({required this.cat, required this.words, required this.index, required this.onOpen, required this.onAdd, required this.onAll});
  final RmCategory cat;
  final List<RmWordEntry> words;
  final int index;
  final void Function(RmWordEntry, num) onOpen, onAdd;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) {
    final shown = words.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, box) {
        final w = (box.maxWidth - 12) / 2;
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Wrap(spacing: 12, runSpacing: 14, children: [
            for (var i = 0; i < shown.length; i++)
              SizedBox(
                width: w,
                child: Transform.rotate(
                  angle: (i.isEven ? -1 : 1) * .02,
                  child: _Swatch(e: shown[i], cloth: _cloth[(index * 2 + i) % _cloth.length], onOpen: onOpen, onAdd: onAdd),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          GoldPill(label: 'All ${cat.words.length} words', onTap: onAll, dark: true, arrow: true),
        ]);
      }),
    );
  }
}

/// A fabric swatch: pinking-shear edges, gold running stitch, an eyelet and
/// a paper price tag hanging off it. The word is set in Anton on the cloth.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.e, required this.cloth, required this.onOpen, required this.onAdd});
  final RmWordEntry e;
  final Color cloth;
  final void Function(RmWordEntry, num) onOpen, onAdd;
  @override
  Widget build(BuildContext context) {
    final p = wordPrice(e.word);
    final id = _id(e);
    final shown = priceOrNull(id, p);
    final was = shown == null ? null : StorePrices.instance.regularIfOnSale(id);
    final name = e.word.isEmpty ? e.word : e.word[0].toUpperCase() + e.word.substring(1);
    return Semantics(
      button: true,
      label: 'Open $name',
      child: Tap(
        onTap: () => onOpen(e, p),
        child: ClipPath(
          clipper: const _Pinked(),
          child: CustomPaint(
            foregroundPainter: _Stitch(),
            child: Container(
              color: cloth,
              padding: const EdgeInsets.fromLTRB(12, 18, 10, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF060C18), border: Border.all(color: kPGold, width: 2))),
                  const Spacer(),
                  Text('Root', style: gSub(color: kPGoldSoft)),
                ]),
                const SizedBox(height: 8),
                SizedBox(height: 40, child: GiantWord(name.toUpperCase(), style: anton(44, color: kPPaper))),
                const SizedBox(height: 4),
                Text(e.root, style: gSub(color: kPGoldSoft)),
                const SizedBox(height: 10),
                // The tag keeps its natural width; at 320 / large text the "+"
                // drops below it instead of squeezing the price.
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 6, children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: kPPaper, borderRadius: BorderRadius.circular(2)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        // Full-size type (never scaled down); "In your plan" wraps on a space.
                        Text(shown ?? ownedLabel(id),
                            maxLines: 2, style: gSub(dark: false, color: kPInk).copyWith(fontSize: 14, fontWeight: FontWeight.w700, height: 1.15)),
                        if (was != null)
                          Text(inr(was, sku: id),
                              maxLines: 1, style: gSub(dark: false, color: kPInk).copyWith(decoration: TextDecoration.lineThrough)),
                      ]),
                    ),
                  ),
                  if (shown != null)
                    Semantics(
                      button: true,
                      label: 'Add $name to bag',
                      child: Tap(
                        onTap: () => onAdd(e, p),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: kPGold, shape: BoxShape.circle, border: Border.all(color: kPInk, width: 2)),
                          child: const Icon(Icons.add_rounded, color: kPInk, size: 22),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pinked extends CustomClipper<Path> {
  const _Pinked();
  @override
  Path getClip(Size s) {
    const t = 7.0, d = 4.0;
    final p = Path()..moveTo(0, d);
    for (var x = 0.0; x < s.width; x += t) {
      p.lineTo(x + t / 2, 0);
      p.lineTo(x + t, d);
    }
    for (var y = d; y < s.height; y += t) {
      p.lineTo(s.width - d, y + t / 2);
      p.lineTo(s.width, y + t);
    }
    for (var x = s.width; x > 0; x -= t) {
      p.lineTo(x - t / 2, s.height);
      p.lineTo(x - t, s.height - d);
    }
    for (var y = s.height; y > d; y -= t) {
      p.lineTo(d, y - t / 2);
      p.lineTo(0, y - t);
    }
    return p..close();
  }

  @override
  bool shouldReclip(_Pinked o) => false;
}

class _Stitch extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xCCC9A24C)
      ..strokeWidth = 1.4;
    const m = 9.0, dash = 6.0, gap = 4.0;
    void line(Offset a, Offset b) {
      final len = (b - a).distance, dir = (b - a) / len;
      for (var t = 0.0; t < len; t += dash + gap) {
        c.drawLine(a + dir * t, a + dir * (t + dash).clamp(0, len), p);
      }
    }

    line(const Offset(m, m), Offset(s.width - m, m));
    line(Offset(s.width - m, m), Offset(s.width - m, s.height - m));
    line(Offset(s.width - m, s.height - m), Offset(m, s.height - m));
    line(Offset(m, s.height - m), const Offset(m, m));
  }

  @override
  bool shouldRepaint(_Stitch o) => false;
}

class _Dock extends StatelessWidget {
  const _Dock({required this.word, required this.price, required this.onBuy, required this.onOpen});
  final RmWordEntry word;
  final num price;
  final VoidCallback onBuy, onOpen;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
        decoration:
            BoxDecoration(color: const Color(0xF0161008), borderRadius: BorderRadius.circular(40), border: Border.all(color: kPGold.withValues(alpha: .6))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Cut today', style: gSub(color: kPGoldSoft)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(word.word.isEmpty ? '' : word.word[0].toUpperCase() + word.word.substring(1), maxLines: 1, softWrap: false, style: gTitle()),
              ),
            ]),
          ),
          GoldPill(
              label: priceOrNull(_id(word), price) == null ? ownedLabel(_id(word)) : 'Own · ${priceOrNull(_id(word), price)}',
              onTap: priceOrNull(_id(word), price) == null ? onOpen : onBuy),
        ]),
      );
}
