/// Pictures of what a store card is, not the same logo on every card.
library;

import 'store_flip_art.dart';

const kStoreRoomArt = <String, String>{
  'word': 'assets/rails/store-word.jpg',
  'meaning': 'assets/rails/store-meaning.jpg',
  'signature': 'assets/rails/store-signature.jpg',
  'ebooks': 'assets/rails/store-ebooks.jpg',
};

const kStorePool = <String>[
  'assets/rails/store-elements.jpg',
  'assets/rails/store-sacred.jpg',
  'assets/rails/store-mind.jpg',
  'assets/rails/store-cosmos.jpg',
  'assets/rails/store-nature.jpg',
  'assets/rails/store-family.jpg',
  'assets/rails/store-warriors.jpg',
  'assets/rails/store-ancient.jpg',
  'assets/rails/store-peace.jpg',
  'assets/rails/store-white.jpg',
  'assets/rails/store-black.jpg',
  'assets/rails/store-myth.jpg',
  'assets/rails/store-premium.jpg',
  'assets/rails/store-places.jpg',
  'assets/rails/store-word.jpg',
  'assets/rails/store-meaning.jpg',
  'assets/rails/store-signature.jpg',
  'assets/rails/store-ebooks.jpg',
];

const _byWord = <String, String>{
  'fire': 'assets/rails/store-elements.jpg',
  'water': 'assets/rails/store-nature.jpg',
  'earth': 'assets/rails/store-nature.jpg',
  'sun': 'assets/rails/store-cosmos.jpg',
  'moon': 'assets/rails/store-cosmos.jpg',
  'stone': 'assets/rails/store-ancient.jpg',
  'rain': 'assets/rails/store-nature.jpg',
  'thunder': 'assets/rails/store-elements.jpg',
  'storm': 'assets/rails/store-elements.jpg',
  'wind': 'assets/rails/store-nature.jpg',
  'ice': 'assets/rails/store-white.jpg',
  'lava': 'assets/rails/store-elements.jpg',
  'god': 'assets/rails/store-sacred.jpg',
  'soul': 'assets/rails/store-sacred.jpg',
  'spirit': 'assets/rails/store-sacred.jpg',
  'love': 'assets/rails/store-sacred.jpg',
  'truth': 'assets/rails/store-sacred.jpg',
  'light': 'assets/rails/store-white.jpg',
  'grace': 'assets/rails/store-sacred.jpg',
  'prayer': 'assets/rails/store-sacred.jpg',
  'mind': 'assets/rails/store-mind.jpg',
  'name': 'assets/rails/store-mind.jpg',
  'breath': 'assets/rails/store-mind.jpg',
  'dream': 'assets/rails/store-mind.jpg',
  'voice': 'assets/rails/store-mind.jpg',
  'vision': 'assets/rails/store-mind.jpg',
  'india': 'assets/rails/store-places.jpg',
  'time': 'assets/rails/store-cosmos.jpg',
  'space': 'assets/rails/store-cosmos.jpg',
  'star': 'assets/rails/store-cosmos.jpg',
  'cosmos': 'assets/rails/store-cosmos.jpg',
  'infinity': 'assets/rails/store-cosmos.jpg',
  'eternal': 'assets/rails/store-cosmos.jpg',
  'sky': 'assets/rails/store-nature.jpg',
  'sea': 'assets/rails/store-nature.jpg',
  'tree': 'assets/rails/store-nature.jpg',
  'river': 'assets/rails/store-nature.jpg',
  'forest': 'assets/rails/store-nature.jpg',
  'mountain': 'assets/rails/store-nature.jpg',
  'ocean': 'assets/rails/store-nature.jpg',
  'mother': 'assets/rails/store-family.jpg',
  'father': 'assets/rails/store-family.jpg',
  'child': 'assets/rails/store-family.jpg',
  'king': 'assets/rails/store-family.jpg',
  'queen': 'assets/rails/store-family.jpg',
  'warrior': 'assets/rails/store-warriors.jpg',
  'samurai': 'assets/rails/store-warriors.jpg',
  'viking': 'assets/rails/store-warriors.jpg',
  'spartan': 'assets/rails/store-warriors.jpg',
  'ninja': 'assets/rails/store-warriors.jpg',
  'blade': 'assets/rails/store-warriors.jpg',
  'shield': 'assets/rails/store-warriors.jpg',
  'dragon': 'assets/rails/store-myth.jpg',
  'phoenix': 'assets/rails/store-myth.jpg',
  'zeus': 'assets/rails/store-myth.jpg',
  'anubis': 'assets/rails/store-myth.jpg',
  'egypt': 'assets/rails/store-ancient.jpg',
  'rome': 'assets/rails/store-ancient.jpg',
  'troy': 'assets/rails/store-ancient.jpg',
  'peace': 'assets/rails/store-peace.jpg',
  'calm': 'assets/rails/store-peace.jpg',
  'silence': 'assets/rails/store-peace.jpg',
  'harmony': 'assets/rails/store-peace.jpg',
  'dark': 'assets/rails/store-black.jpg',
  'night': 'assets/rails/store-black.jpg',
  'shadow': 'assets/rails/store-black.jpg',
  'void': 'assets/rails/store-black.jpg',
  'abyss': 'assets/rails/store-black.jpg',
  'pure': 'assets/rails/store-white.jpg',
  'snow': 'assets/rails/store-white.jpg',
  'dawn': 'assets/rails/store-white.jpg',
  'crystal': 'assets/rails/store-white.jpg',
  'rupee': 'assets/rails/store-places.jpg',
  'yen': 'assets/rails/store-places.jpg',
  'dollar': 'assets/rails/store-places.jpg',
  'euro': 'assets/rails/store-places.jpg',
  'delhi': 'assets/rails/store-places.jpg',
  'tokyo': 'assets/rails/store-places.jpg',
  'paris': 'assets/rails/store-places.jpg',
  'cairo': 'assets/rails/store-places.jpg',
  'sanskrit': 'assets/rails/store-word.jpg',
  'latin': 'assets/rails/store-meaning.jpg',
  'greek': 'assets/rails/store-ancient.jpg',
  'arabic': 'assets/rails/store-signature.jpg',
  'english': 'assets/rails/store-ebooks.jpg',
  'hindi': 'assets/rails/store-word.jpg',
  'french': 'assets/rails/store-places.jpg',
  'japanese': 'assets/rails/store-warriors.jpg',
};

const _byCat = <String, String>{
  'off50': 'assets/rails/store-premium.jpg',
  'elements': 'assets/rails/store-elements.jpg',
  'sacred': 'assets/rails/store-sacred.jpg',
  'identity': 'assets/rails/store-mind.jpg',
  'cosmos': 'assets/rails/store-cosmos.jpg',
  'nature': 'assets/rails/store-nature.jpg',
  'family': 'assets/rails/store-family.jpg',
  'elite': 'assets/rails/store-premium.jpg',
  'premium': 'assets/rails/store-premium.jpg',
  'mythical': 'assets/rails/store-myth.jpg',
  'warriors': 'assets/rails/store-warriors.jpg',
  'ancient': 'assets/rails/store-ancient.jpg',
  'peace': 'assets/rails/store-peace.jpg',
  'white': 'assets/rails/store-white.jpg',
  'black': 'assets/rails/store-black.jpg',
  'Countries': 'assets/rails/store-places.jpg',
  'Capitals': 'assets/rails/store-ancient.jpg',
  'Currency': 'assets/rails/store-premium.jpg',
  'Language': 'assets/rails/store-word.jpg',
};

/// The Store mark: white leather frame, headphones, NOWSSB STORE.
const kNowssbStoreMark = 'assets/store/nowssb-store-mark.png';

/// Meaning store icon. Stays on one face of every meaning card.
const kMeaningsIcon = 'assets/store/meanings-icon.png';

/// Ebook store icon. Stays on one face of every ebook card.
const kEbooksIcon = 'assets/store/ebooks-icon.jpg';

String _artSlug(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String _fromSet(String name, Set<String> known, String folder, String fallback) {
  final slug = _artSlug(name);
  if (slug.isNotEmpty && known.contains(slug)) return 'assets/store/$folder/$slug.webp';
  return fallback;
}

/// Person in white headphones with a sound wave, for this word.
String storeWaveFor(String name) => _fromSet(name, kStoreWaveFrames, 'waves', kNowssbStoreMark);

/// Meaning icon edited for this word.
String storeMeaningFlip(String name) => _fromSet(name, kMeaningFlipFrames, 'meaning-flips', kMeaningsIcon);

/// Ebook icon edited for this book.
String storeEbookFlip(String name, {String? alt}) {
  final hit = _fromSet(name, kEbookFlipFrames, 'ebook-flips', '');
  if (hit.isNotEmpty) return hit;
  if (alt != null) {
    final altHit = _fromSet(alt, kEbookFlipFrames, 'ebook-flips', '');
    if (altHit.isNotEmpty) return altHit;
  }
  return kEbooksIcon;
}

/// A picture of the word, then of its row, then a different one from the pool.
String storeSubjectArt(String word, {String catId = ''}) {
  final key = word.toLowerCase();
  final named = _byWord[key];
  if (named != null) return named;
  final cat = _byCat[catId];
  final h = key.codeUnits.fold<int>(0, (a, b) => (a + b) % kStorePool.length);
  if (cat != null && h.isEven) return cat;
  return kStorePool[h];
}
String meaningFlipArt(String word) {
  const named = <String, String>{
    'earth': 'assets/rails/mean-earth.jpg',
    'water': 'assets/rails/mean-water.jpg',
    'fire': 'assets/rails/mean-fire.jpg',
    'sun': 'assets/rails/mean-sun.jpg',
    'moon': 'assets/rails/mean-moon.jpg',
    'light': 'assets/rails/mean-light.jpg',
    'dark': 'assets/rails/mean-dark.jpg',
    'body': 'assets/rails/mean-body.jpg',
    'mind': 'assets/rails/mean-mind.jpg',
    'soul': 'assets/rails/mean-soul.jpg',
    'blood': 'assets/rails/mean-blood.jpg',
    'breath': 'assets/rails/mean-breath.jpg',
    'love': 'assets/rails/mean-love.jpg',
    'fear': 'assets/rails/mean-fear.jpg',
    'joy': 'assets/rails/mean-joy.jpg',
    'god': 'assets/rails/mean-god.jpg',
    'time': 'assets/rails/mean-time.jpg',
    'space': 'assets/rails/mean-space.jpg',
    'truth': 'assets/rails/mean-truth.jpg',
    'country': 'assets/rails/mean-country.jpg',
    'india': 'assets/rails/mean-india.jpg',
    'mother': 'assets/rails/mean-mother.jpg',
    'father': 'assets/rails/mean-father.jpg',
    'name': 'assets/rails/mean-name.jpg',
  };
  final key = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  final hit = named[key];
  if (hit != null) return hit;
  final values = named.values.toList();
  final h = key.codeUnits.fold<int>(0, (a, b) => (a + b) % values.length);
  return values[h];
}
