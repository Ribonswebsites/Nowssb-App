/// Short horizontal row under the Fashion greeting: 8 mixed cards (black
/// iOS-like text banners, rounded-square quick buttons, coloured boxes),
/// rotated daily by a date seed. Every card opens a real page.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/glass_wrap.dart';
import 'home_cards.dart' show AutoMarquee;
import '../normal/home_v4.dart' show V4Lottie;

enum QuickStyle { banner, button, colour }

class QuickCard {
  const QuickCard(this.id, this.title, this.sub, this.icon, this.onTap, {this.colour = const Color(0xFF2B2B33), this.lottie});
  /// Optional concept animation shown instead of [icon].
  final String? lottie;
  final String id;
  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
  final Color colour;
}

/// Daily pick of [count] from [pool], date-seeded, with styles mixed.
/// Rewards stays the small box. Daily tasks stays the wide rectangle.
List<(QuickCard, QuickStyle)> dailyQuickCards(List<QuickCard> pool, {DateTime? day, int count = 8, Set<String> pinned = const {}}) {
  final d = day ?? DateTime.now();
  final seed = d.year * 10000 + d.month * 100 + d.day;
  final list = [...pool]..shuffle(math.Random(seed));
  final pins = <QuickCard>[];
  for (final id in const ['rewards', 'tasks']) {
    if (!pinned.contains(id)) continue;
    for (final c in pool) {
      if (c.id == id) pins.add(c);
    }
  }
  for (final c in pool) {
    if (pinned.contains(c.id) && !pins.any((p) => p.id == c.id)) pins.add(c);
  }
  final pick = [...pins, ...list.where((c) => !pins.any((p) => p.id == c.id))].take(count).toList();
  // Rewards is the small box. Daily tasks is the wide rectangle. The rest rotate.
  const rest = [QuickStyle.colour, QuickStyle.button, QuickStyle.banner];
  return [
    for (var i = 0; i < pick.length; i++)
      (
        pick[i],
        pick[i].id == 'rewards'
            ? QuickStyle.button
            : pick[i].id == 'tasks'
                ? QuickStyle.banner
                : rest[(i + seed) % rest.length],
      ),
  ];
}

const kQuickColours = [
  Color(0xFFE4C56A), Color(0xFF7B5CFF), Color(0xFF1FB58F), Color(0xFFFF6B6B),
  Color(0xFF3A8DFF), Color(0xFFFF9F43), Color(0xFFE056FD), Color(0xFF00B8D9),
  Color(0xFFB8E986), Color(0xFFFF4FA3), Color(0xFF00C2A8), Color(0xFFFFD43B),
];

class HeroQuickRow extends StatelessWidget {
  const HeroQuickRow({super.key, required this.pool, this.day, this.squaresOnly = false, this.pinned = const {'rewards', 'tasks'}});
  final Set<String> pinned;
  final List<QuickCard> pool;
  final DateTime? day;

  /// Second row: only small square boxes, each a different bright colour.
  final bool squaresOnly;

  static const double h = 58;

  @override
  Widget build(BuildContext context) {
    final cards = squaresOnly
        ? [for (final (c, _) in dailyQuickCards(pool, day: (day ?? DateTime.now()).add(const Duration(days: 3)))) (c, QuickStyle.button)]
        : dailyQuickCards(pool, day: day, pinned: pinned);
    var colourIx = (day ?? DateTime.now()).day;
    if (squaresOnly) {
      // Quick picks: every box its own bright colour, drifting slowly.
      final n = cards.length;
      return GlassWrap(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(8),
        radius: 12,
        child: AutoMarquee(
          height: h,
          children: [
            for (var i = 0; i < n; i++) _tap(cards[i].$1, _square(cards[i].$1, kQuickColours[(i + colourIx) % kQuickColours.length])),
          ],
        ),
      );
    }
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(8),
      radius: 12,
      child: AutoMarquee(
        height: h,
        children: [
          for (var i = 0; i < cards.length; i++)
            _tap(cards[i].$1, switch (cards[i].$2) {
              QuickStyle.banner => _banner(cards[i].$1),
              QuickStyle.button => _button(cards[i].$1),
              QuickStyle.colour => _colour(cards[i].$1, kQuickColours[(colourIx + i) % kQuickColours.length]),
            }),
        ],
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

  Widget _mark(QuickCard c, double size, Color colour) =>
      c.lottie != null ? V4Lottie(c.lottie!, size: size + 6) : Icon(c.icon, size: size, color: colour);

  Widget _button(QuickCard c) => Container(
        width: h,
        decoration: BoxDecoration(
          color: const Color(0xE6101014),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          _mark(c, 20, Colors.white),
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
        _mark(c, 20, fg),
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
        _mark(c, 18, fg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: _ink.copyWith(color: fg, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.1)),
        ),
      ]),
    );
  }
}


