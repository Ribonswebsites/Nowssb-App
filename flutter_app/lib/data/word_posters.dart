/// Each practice word's own poster: the word three times in big white
/// letters, a model in white NowssB headphones and sunglasses, and a glowing
/// ribbon. Every word has its own model and its own background colour
/// (PRANA is Ribon's original on black).
///
/// Every place that shows a word as a picture (the Practice tab tiles, the
/// player's Next up card and queue) reads this first, so a word never shows
/// a generic theme still.
library;

import 'word_art.dart';

const kWordPosterDir = 'assets/word_posters';

/// Library words that have a bundled poster, keyed by [WordArt.keyOf].
const kWordPosters = <String, String>{
  'aarogya': '$kWordPosterDir/aarogya.webp',
  'prana': '$kWordPosterDir/prana.webp',
  'shakti': '$kWordPosterDir/shakti.webp',
  'ananda': '$kWordPosterDir/ananda.webp',
  'soma': '$kWordPosterDir/soma.webp',
  'tejas': '$kWordPosterDir/tejas.webp',
  'ojas': '$kWordPosterDir/ojas.webp',
  'vata': '$kWordPosterDir/vata.webp',
  'pitta': '$kWordPosterDir/pitta.webp',
  'kapha': '$kWordPosterDir/kapha.webp',
  'surya': '$kWordPosterDir/surya.webp',
  'chandra': '$kWordPosterDir/chandra.webp',
};

/// The NowssB poster, for a word that has no poster and no picture.
const kNowssbPoster = '$kWordPosterDir/nowssb.webp';

/// [word]'s own bundled poster, or null.
String? wordPosterFor(String word) => kWordPosters[WordArt.keyOf(word)];
