/// Two store promos.
///
/// [StoreDriftBanner] is a row of separate cards — the same width and glass
/// as the catalogue cards, not one card sliding inside a wrapper.
/// [StoreSlashBanner] is a single full-width picture, same side edges as
/// the black section bars, cool not gold.
///
/// Callers pass [onDeal]. This file does not import the product page.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store_prices.dart';
import '../../features/economy/money.dart';
import '../../widgets/hero_glass.dart';
import 'daily_deals.dart';

const _quietArts = <String>[
  'assets/banners/promo/quiet-water.webp',
  'assets/banners/promo/quiet-linen.webp',
  'assets/banners/promo/quiet-mist.webp',
  'assets/banners/promo/quiet-stone.webp',
];

const _roomArt = 'assets/banners/promo/quiet-room.webp';

String _money(num value) {
  if (value <= 0) return 'Included';
  return FxBook.instance.formatPrice(value);
}

String _priceOf(DailyDeal d) =>
    _money(StorePrices.instance.priceFor('word:${d.word.toLowerCase()}'));

/// Separate cards in a row. No outer glass, no pager.
/// [margin] is only for the Store home, which has no page padding.
/// Word, Meaning and eBooks already pad the page, so they pass nothing.
class StoreDriftBanner extends StatelessWidget {
  const StoreDriftBanner({super.key, required this.onDeal, this.margin = EdgeInsets.zero});
  final void Function(DailyDeal deal) onDeal;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final deals = dailyDeals(count: 4);
    if (deals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: margin.add(const EdgeInsets.only(top: 8, bottom: 8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
        const SizedBox(height: 12),
        SizedBox(
          height: 372,
          child: LayoutBuilder(builder: (context, box) {
            final width = math.min(300.0, box.maxWidth);
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: deals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final d = deals[i];
                return _QuietCard(
                  width: width,
                  art: _quietArts[i % _quietArts.length],
                  deal: d,
                  price: _priceOf(d),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDeal(d);
                  },
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.width, required this.art, required this.deal, required this.price, required this.onTap});
  final double width;
  final String art;
  final DailyDeal deal;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 372,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: HeroGlassRecipe.blurSigma, sigmaY: HeroGlassRecipe.blurSigma),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: HeroGlassRecipe.fill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: HeroGlassRecipe.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(art, height: 168, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF120818), child: SizedBox(height: 168, width: double.infinity))),
                ),
                const SizedBox(height: 14),
                Text(deal.category, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 12, decoration: TextDecoration.none)),
                const SizedBox(height: 4),
                Text(deal.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1, decoration: TextDecoration.none)),
                const SizedBox(height: 6),
                Text(price, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 13, decoration: TextDecoration.none)),
                const Spacer(),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFFF3E4B7), Color(0xFFC8A96E)]),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Open', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF060C18), decoration: TextDecoration.none)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF060C18)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One full-width picture. Same edges as the black section bars.
/// Not a pager, not a gold slash.
class StoreSlashBanner extends StatelessWidget {
  const StoreSlashBanner({super.key, required this.onDeal, this.margin = EdgeInsets.zero});
  final void Function(DailyDeal deal) onDeal;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final deals = dailyDeals(count: 4);
    if (deals.isEmpty) return const SizedBox.shrink();
    final deal = deals.last;
    return Padding(
      padding: margin.add(const EdgeInsets.only(top: 10, bottom: 14)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onDeal(deal);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 196,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(_roomArt, fit: BoxFit.cover, alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF100818))),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xF0080612), Color(0x99080612), Color(0x33080612)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(deal.category, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none)),
                      const SizedBox(height: 6),
                      Text(deal.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 28, height: 1.02, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
                      const SizedBox(height: 8),
                      Text(_priceOf(deal), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The card row and the picture sit in different places, never stacked.
/// A long page gets the row after 5 and 15, the picture after 10 and 20.
/// A short page gets the row in the middle and the picture at the end.
List<Widget> everyFiveStoreRows(
  List<Widget> rows, {
  required void Function(DailyDeal deal) onDeal,
}) {
  if (rows.isEmpty) return rows;
  final out = <Widget>[];
  if (rows.length < 10) {
    final mid = rows.length ~/ 2;
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (mid > 0 && i + 1 == mid) {
        out.add(StoreDriftBanner(key: ValueKey('drift-$i'), onDeal: onDeal));
      }
    }
    out.add(StoreSlashBanner(key: const ValueKey('slash-end'), onDeal: onDeal));
    return out;
  }
  for (var i = 0; i < rows.length; i++) {
    out.add(rows[i]);
    final n = i + 1;
    if (n % 10 == 5) out.add(StoreDriftBanner(key: ValueKey('drift-$i'), onDeal: onDeal));
    if (n % 10 == 0) out.add(StoreSlashBanner(key: ValueKey('slash-$i'), onDeal: onDeal));
  }
  return out;
}
