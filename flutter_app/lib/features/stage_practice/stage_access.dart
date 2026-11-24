/// Which of a word's stages this account can open, and the "next 3 stages"
/// purchase.
///
/// Owning a word opens its first [kStagesIncluded] stages. Each purchase of
/// `stage:<wordKey>:<from>-<to>` (one Store line, ₹99 by default, through the
/// usual cart / checkout; the server already accepts the `stage` kind) opens
/// the next [kStageBundleSize]. Admins see every stage.
library;

import 'dart:math' as math;

import '../../data/cart_bag.dart';
import '../../data/entitlements.dart';
import '../../data/store_prices.dart';
import '../../data/word_photos.dart';

const kStagesIncluded = 3;
const kStageBundleSize = 3;

/// Store id for the stages [from]..[from]+2 of [wordKey].
String stageBundleId(String wordKey, int from) =>
    'stage:${wordKey.toLowerCase()}:$from-${from + kStageBundleSize - 1}';

/// How many of [total] stages of [wordKey] are open (bought or included).
int stagesOpenFor(String wordKey, int total) {
  if (total <= 0) return 0;
  if (Entitlements.instance.isAdmin) return total;
  var open = kStagesIncluded;
  while (open < total && Entitlements.instance.ownsItem(stageBundleId(wordKey, open + 1))) {
    open += kStageBundleSize;
  }
  return math.min(open, total);
}

/// The Store line that opens the next 3 stages after [openCount].
BagItem stageBundleItem({
  required String wordKey,
  required String wordTitle,
  required int openCount,
  required int total,
}) {
  final from = openCount + 1;
  final to = math.min(openCount + kStageBundleSize, total);
  final id = stageBundleId(wordKey, from);
  return BagItem(
    id: id,
    title: '$wordTitle · Stages $from–$to',
    subtitle: 'The next ${to - from + 1} stages of $wordTitle',
    image: wordPhotoFor(wordKey) ?? 'assets/store/nowssb-store-mark.png',
    price: StorePrices.instance.priceFor(id, kind: 'stage'),
    kind: 'Stage',
  );
}
