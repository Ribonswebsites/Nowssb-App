/// The picture shown for a practice word.
///
/// Sound Library is the source of truth: [soundLibraryArtFor] returns the
/// same image the library screens already show (a WordArt upload or the
/// word's published image, else the Atelier collection banner). New
/// releases, Picked for you, the Practice tiles and the player cover all
/// read that first, so a word never shows a different picture there than
/// it does in the library.
///
/// Generated typography posters in [kWordPosters] are only used when a
/// word has no Sound Library image.
library;

import 'store_catalog.dart';
import 'word_art.dart';

const kWordPosterDir = 'assets/word_posters';

/// Library words that have a bundled typography poster, keyed by
/// [WordArt.keyOf]. Used only when [soundLibraryArtFor] returns null.
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

/// Collection banner file for each Atelier id — same table the Sound
/// Library uses for word tiles and category plates.
const kSoundLibraryCollectionFiles = <String, String>{
  'off50': 'sale',
  'elements': 'elements',
  'sacred': 'sacred',
  'identity': 'identity',
  'cosmos': 'cosmos',
  'nature': 'nature',
  'family': 'family',
  'elite': 'elite',
  'premium': 'premium',
  'mythical': 'mythical',
  'warriors': 'warriors',
  'ancient': 'ancient',
  'peace': 'peace',
  'white': 'white',
  'black': 'black',
};

/// Asset path of [category]'s Atelier collection banner.
String soundLibraryCollectionAsset(RmCategory category) {
  final file = kSoundLibraryCollectionFiles[category.id] ?? category.id;
  return 'assets/store/collections/$file.webp';
}

int _hash(String s) {
  var h = 0;
  for (final cu in s.codeUnits) {
    h = (h * 31 + cu) & 0x7fffffff;
  }
  return h;
}

Map<String, RmCategory>? _colByWord;

/// First Atelier category that lists [word], lowercased, same as Sound
/// Library's `_wordToCol`.
Map<String, RmCategory> soundLibraryWordToCollection() {
  final cached = _colByWord;
  if (cached != null) return cached;
  final out = <String, RmCategory>{};
  for (final c in kRmCategories) {
    for (final w in c.words) {
      out.putIfAbsent(w.word.toLowerCase(), () => c);
    }
  }
  return _colByWord = out;
}

/// The picture Sound Library shows for [word]: WordArt or the published
/// image ([img] is the same fallback the player already had), else the
/// collection banner for the word's Atelier category, else a stable hash
/// of the name into the category list (identical to `_artForWord`).
///
/// Returns null only when [word] is empty, so a typography poster can
/// still stand in for a nameless entry.
String? soundLibraryArtFor(String word, {String img = ''}) {
  final custom = WordArt.instance.imageFor(word, img).trim();
  if (custom.isNotEmpty) return custom;
  final key = word.toLowerCase();
  if (key.isEmpty) return null;
  final hit = soundLibraryWordToCollection()[key];
  if (hit != null) return soundLibraryCollectionAsset(hit);
  const cs = kRmCategories;
  if (cs.isEmpty) return null;
  return soundLibraryCollectionAsset(cs[_hash(key) % cs.length]);
}

/// [word]'s Sound Library picture, or its bundled typography poster, or
/// null.
String? wordPosterFor(String word) =>
    soundLibraryArtFor(word) ?? kWordPosters[WordArt.keyOf(word)];
