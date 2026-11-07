/// Two store promos that sit on the Store home and between every five
/// catalogue rows on Word, Meaning and eBooks.
///
/// [StoreDriftBanner] is the fashion-home store card, shifted: gold button,
/// a different kicker, and four stills that are not the bag poster.
/// [StoreSlashBanner] is a different object — a full-bleed cut, not a
/// product row.
///
/// Neither widget opens a product itself. Callers pass [onDeal] so this
/// file never imports the product page (that import loops through the
/// store screens).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store_prices.dart';
import '../../features/economy/money.dart';
import '../../widgets/auto_cycle.dart';
import '../fashion/home_cards.dart';
import 'daily_deals.dart';

const _driftArts = <String>[
  'assets/banners/promo/drift-ear.webp',
  'assets/banners/promo/drift-book.webp',
  'assets/banners/promo/drift-prism.webp',
  'assets/banners/promo/drift-seal.webp',
];

const _slashArts = <String>[
  'assets/banners/promo/slash-rings.webp',
  'assets/banners/promo/slash-arch.webp',
];

const _slashKick = <String>['Vortex', 'The gate'];

String _money(num value) {
  if (value <= 0) return 'Included';
  return FxBook.instance.formatPrice(value);
}

String _priceOf(DailyDeal d) =>
    _money(StorePrices.instance.priceFor('word:${d.word.toLowerCase()}'));

/// Close cousin of the fashion-home store carousel. New stills, gold bag.
class StoreDriftBanner extends StatelessWidget {
  const StoreDriftBanner({super.key, required this.onDeal});
  final void Function(DailyDeal deal) onDeal;

  @override
  Widget build(BuildContext context) {
    final deals = dailyDeals(count: 4);
    if (deals.isEmpty) return const SizedBox.shrink();
    return StoreNowCarousel(
      title: 'Fresh drop',
      kicker: 'New art · today',
      goldButton: true,
      items: [
        for (var i = 0; i < deals.length; i++)
          StoreNowItem(
            word: deals[i].title,
            category: deals[i].category,
            percent: realDealPercent(deals[i].word),
            price: _priceOf(deals[i]),
            art: _driftArts[i % _driftArts.length],
            onTap: () => onDeal(deals[i]),
          ),
      ],
    );
  }
}

/// Full-bleed cut. Not the product row — a wide still, a slash, huge type.
class StoreSlashBanner extends StatefulWidget {
  const StoreSlashBanner({super.key, required this.onDeal});
  final void Function(DailyDeal deal) onDeal;

  @override
  State<StoreSlashBanner> createState() => _StoreSlashBannerState();
}

class _StoreSlashBannerState extends State<StoreSlashBanner>
    with SingleTickerProviderStateMixin, AutoCycle {
  static const _base = 400;
  late final List<DailyDeal> _deals = dailyDeals(count: 6);
  late final _page = PageController(viewportFraction: .9, initialPage: _base);
  late int _ix = _base;

  @override
  Duration get period => const Duration(milliseconds: 4200);

  @override
  void onTick() {
    if (!mounted || !_page.hasClients || _deals.length < 2) return;
    _ix = (_page.page ?? _ix.toDouble()).round() + 1;
    _page.animateToPage(_ix, duration: const Duration(milliseconds: 640), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: SizedBox(
        height: 232,
        child: PageView.builder(
          controller: _page,
          padEnds: false,
          onPageChanged: (i) => _ix = i,
          itemBuilder: (_, i) {
            final deal = _deals[i % _deals.length];
            final art = _slashArts[i % _slashArts.length];
            final kick = _slashKick[i % _slashKick.length];
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SlashCard(
                art: art,
                kick: kick,
                deal: deal,
                price: _priceOf(deal),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDeal(deal);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SlashCard extends StatelessWidget {
  const _SlashCard({
    required this.art,
    required this.kick,
    required this.deal,
    required this.price,
    required this.onTap,
  });

  final String art;
  final String kick;
  final DailyDeal deal;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${deal.title}, ${deal.category}, $price',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(art, fit: BoxFit.cover, alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF120818))),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xCC050208), Color(0xF2060208)],
                  stops: [0.15, 0.62, 1],
                ),
              ),
            ),
            const CustomPaint(painter: _SlashPainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xE6110C16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x66E4C56A)),
                    ),
                    child: const Text('NOWSSB // CUT',
                        style: TextStyle(color: Color(0xFFE4C56A), fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w800, decoration: TextDecoration.none)),
                  ),
                  const Spacer(),
                  Text(kick.toUpperCase(),
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                ]),
                const Spacer(),
                Text(deal.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xB3E4C56A), fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(deal.title.toUpperCase(),
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 40, height: .9, fontWeight: FontWeight.w900, letterSpacing: -0.6, decoration: TextDecoration.none)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Text('$price  ·  step through',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.none)),
                  ),
                  const SizedBox(width: 8),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.skewX(-0.22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      color: const Color(0xFFE4C56A),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.skewX(0.22),
                        child: const Text('STEP IN',
                            style: TextStyle(color: Color(0xFF1A1200), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.3, decoration: TextDecoration.none)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xCCE4C56A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * .78, -4), Offset(size.width * .22, size.height + 4), gold);
    final haze = Paint()
      ..color = const Color(0x33C9A4FF)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * .84, 8), Offset(size.width * .30, size.height - 8), haze);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// After every five catalogue rows, drop both promos. A short page still
/// gets the pair once, at the end, so neither banner is missing.
List<Widget> everyFiveStoreRows(
  List<Widget> rows, {
  required void Function(DailyDeal deal) onDeal,
}) {
  final out = <Widget>[];
  var placed = false;
  for (var i = 0; i < rows.length; i++) {
    out.add(rows[i]);
    if ((i + 1) % 5 == 0) {
      out.add(StoreDriftBanner(key: ValueKey('drift-$i'), onDeal: onDeal));
      out.add(StoreSlashBanner(key: ValueKey('slash-$i'), onDeal: onDeal));
      placed = true;
    }
  }
  if (!placed) {
    out.add(StoreDriftBanner(key: const ValueKey('drift-end'), onDeal: onDeal));
    out.add(StoreSlashBanner(key: const ValueKey('slash-end'), onDeal: onDeal));
  }
  return out;
}
