/// Deal of the Day: a deterministic daily rotation.
///
/// Seeded by the calendar date, so every user sees the same deals on the
/// same day, and the next day different words from different categories go
/// on sale at different discounts (20–60%, not always 50%).
library;

import 'dart:math';

import '../../data/store_catalog.dart';
import 'store_shelf.dart';

class DailyDeal {
  const DailyDeal({required this.word, required this.root, required this.category, required this.percent});
  final String word;
  final String root;
  final String category;
  final int percent;

  String get title => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';
}

const kDealPercents = [20, 25, 30, 35, 40, 45, 50, 55, 60];

int _seedFor(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

/// Every word category in the store: the Word Atelier rows plus the
/// Countries / Capitals / Currency / Language place rows.
Map<String, List<(String, String)>> dealPool() {
  final pool = <String, List<(String, String)>>{};
  for (final c in kRmCategories) {
    if (c.id == 'off50') continue;
    pool[c.label] = [for (final w in c.words) (w.word, w.root)];
  }
  for (final r in kPlaceRows) {
    (pool[r.$3] ??= []).add((r.$1, r.$2));
  }
  pool.removeWhere((_, v) => v.isEmpty);
  return pool;
}

/// Today's deals: [count] words, each from a different category.
List<DailyDeal> dailyDeals({DateTime? day, int count = 5}) {
  final d = day ?? DateTime.now();
  final rnd = Random(_seedFor(d));
  final pool = dealPool();
  final cats = pool.keys.toList()..shuffle(rnd);
  final out = <DailyDeal>[];
  for (var i = 0; i < cats.length && out.length < count; i++) {
    final words = pool[cats[i]]!;
    final w = words[rnd.nextInt(words.length)];
    out.add(DailyDeal(word: w.$1, root: w.$2, category: cats[i], percent: kDealPercents[rnd.nextInt(kDealPercents.length)]));
  }
  return out;
}

/// The biggest discount on today's deals, for the "Up to X% off" headline.
int maxDailyPercent({DateTime? day, int count = 5}) =>
    dailyDeals(day: day, count: count).fold(0, (m, e) => max(m, e.percent));

/// Today's discount on [word] (null when it is not on deal today).
int? dailyPercentFor(String word, {DateTime? day, int count = 5}) {
  final k = word.toLowerCase();
  for (final e in dailyDeals(day: day, count: count)) {
    if (e.word.toLowerCase() == k) return e.percent;
  }
  return null;
}
