/// Short horizontal row under the Fashion greeting: 8 mixed cards (black
/// iOS-like text banners, rounded-square quick buttons, coloured boxes),
/// rotated daily by a date seed. Every card opens a real page.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/glass_wrap.dart';

enum QuickStyle { banner, button, colour }

class QuickCard {
  const QuickCard(this.id, this.title, this.sub, this.icon, this.onTap, {this.colour = const Color(0xFF2B2B33)});
  final String id;
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  final Color colour;
}

/// Daily pick of [count] from [pool], date-seeded, with styles mixed.
List<(QuickCard, QuickStyle)> dailyQuickCards(List<QuickCard> pool, {DateTime? day, int count = 8}) {
  final d = day ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  final list = [...pool]..shuffle(math.Random(seed));
  final pick = list.take(count).toList();
  const pattern = [QuickStyle.banner, QuickStyle.button, QuickStyle.colour, QuickStyle.button];
  final off = seed % pattern.length;
  return [for (var i = 0; i < pick.length; i++) (pick[i], pattern[(i + off) % pattern.length])];
}

const kQuickColours = [
  Color(0xFFE4C56A), Color(0xFF7B5CFF), Color(0xFF1FB58F), Color(0xFFFF6B6B),
  Color(0xFF3A8DFF), Color(0xFFFF9F43), Color(0xFFE056FD), Color(0xFF00B8D9),
  Color(0xFFB8E986), Color(0xFFFF4FA3), Color(0xFF00C2A8), Color(0xFFFFD43B),
];

class HeroQuickRow extends StatelessWidget {
  const HeroQuickRow({super.key, required this.pool, this.day, this.squaresOnly = false});
  final List<QuickCard> pool;
  final DateTime? day;

  /// Second row: only small square boxes, each a different bright colour.
  final bool squaresOnly;

  static const double h = 58;

  @override
  Widget build(BuildContext context) {
    final cards = squaresOnly
        ? [for (final (c, _) in dailyQuickCards(pool, day: (day ?? DateTime.now()).add(const Duration(days: 3)))) (c, QuickStyle.button)]
        : dailyQuickCards(pool, day: day);
    var colourIx = (day ?? DateTime.now()).day;
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(8),
      radius: 12,
      child: SizedBox(
        height: h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (c, s) = cards[i];
            final colour = s == QuickStyle.colour ? kQuickColours[colourIx++ % kQuickColours.length] : c.colour;
            if (squaresOnly) return _tap(c, _square(c, kQuickColours[(i + colourIx) % kQuickColours.length]));
            return _tap(c, switch (s) {
              QuickStyle.banner => _banner(c),
              QuickStyle.button => _button(c),
              QuickStyle.colour => _colour(c, colour),
            });
          },
        ),
      ),
    );
  }

  Widget _tap(QuickCard c, Widget child) => Semantics(
        button: true,
        label: c.title,
        child: GestureDetector(
          key: ValueKey('quick-${c.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            c.onTap();
          },
          child: child,
        ),
      );

  static const _ink = TextStyle(color: Colors.white, decoration: TextDecoration.none);

  Widget _banner(QuickCard c) => Container(
        width: 168,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(c.sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 11.5, color: const Color(0x99FFFFFF))),
        ]),
      );

  Widget _button(QuickCard c) => Container(
        width: h,
        decoration: BoxDecoration(
          color: const Color(0xE6101014),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(c.icon, size: 20, color: Colors.white),
          const SizedBox(height: 3),
          Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _square(QuickCard c, Color colour) {
    final fg = colour.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    return Container(
      width: h,
      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(14)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(c.icon, size: 20, color: fg),
        const SizedBox(height: 3),
        Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ink.copyWith(color: fg, fontSize: 9.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _colour(QuickCard c, Color colour) {
    final dark = colour.computeLuminance() > 0.5;
    final fg = dark ? Colors.black : Colors.white;
    return Container(
      width: 124,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(c.icon, size: 18, color: fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: _ink.copyWith(color: fg, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.1)),
        ),
      ]),
    );
  }
}


/// Slightly taller Word Atelier banner: the atelier art plus today's
/// rotating deals with real local-currency prices. Tap opens the atelier.
class AtelierDealsBanner extends StatelessWidget {
  const AtelierDealsBanner({super.key, required this.deals, required this.onTap, this.image = 'assets/store/picker-words.png'});

  /// (word, category, percent, price, was) — already formatted prices.
  final List<(String, String, int, String, String)> deals;
  final VoidCallback onTap;
  final String image;

  @override
  Widget build(BuildContext context) {
    const ink = TextStyle(color: Colors.white, decoration: TextDecoration.none);
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(8),
      radius: 12,
      child: GestureDetector(
        key: const ValueKey('quick-atelier'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 104,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            SizedBox(width: 104, height: 104, child: Image.asset(image, fit: BoxFit.cover)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(children: [
                    Flexible(
                      child: Text('Word Atelier', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: ink.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Today · Buy / Sell', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: ink.copyWith(fontSize: 10.5, color: const Color(0xFFE4C56A), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  for (final (w, cat, pct, price, was) in deals.take(3))
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: w, style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: '  $cat', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 10.5)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ink.copyWith(fontSize: 12.5),
                          ),
                        ),
                        if (pct > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFFF4D4D), borderRadius: BorderRadius.circular(4)),
                            child: Text('-$pct%', style: ink.copyWith(fontSize: 9.5, fontWeight: FontWeight.w800)),
                          ),
                        Flexible(
                          child: Text(price, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: ink.copyWith(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
