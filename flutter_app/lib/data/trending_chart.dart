/// The one Trending ranking used by the home Trending card and the poster
/// TrendingScreen.
///
/// Source: the ContentStore library (library.json) in its order. There is
/// no play-count or trending field on the phone, so the chart is a daily
/// rotation through the real library (day + 3, step 5); no order is
/// invented beyond that. Returns library indices, #1 first, no repeats.
library;

import 'models.dart';

List<int> trendingChart(List<Word> lib, DateTime now, {int max = 7}) {
  if (lib.isEmpty) return const [];
  final out = <int>[];
  for (var i = 0; out.length < max && i < lib.length; i++) {
    final k = (now.day + 3 + i * 5) % lib.length;
    if (!out.contains(k) && lib[k].word.isNotEmpty) out.add(k);
  }
  return out;
}
