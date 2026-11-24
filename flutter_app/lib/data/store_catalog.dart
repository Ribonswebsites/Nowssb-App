/// Store catalogue constants — ported from the website JS.
///
/// Sources: app/js/part010.js (Word Atelier), part026.js (Meaning Store),
/// part074.js (Signature), part017.js (Ebooks). Prefer these over inventing.
library;

import 'content.dart' show ContentStore;

const kRmWordImg =
    "https://media.nowssb.com/migrated-images/35423222df3850a9_grok_image_1778520937416_jazknf.jpg";
const kRmSignatureImg =
    "https://media.nowssb.com/migrated-images/26780a9d82ed389f_file_00000000d39081faa073bf17312d89fc_q9ehat.png";
const kMsCardImg =
    "assets/meanings/meanings-device.png";
const kMsSignatureImg =
    "assets/meanings/meanings-branding.jpg";
const kMsSignaturePrice = 299;

/// Live site plays these from the website origin. Flutter maps them onto
/// bundled `assets/video/` clips so banners actually move on device —
/// remote nowssb.com URLs were dying with PlatformException VideoError.
const kNowssbVideoOrigin = 'https://nowssb.com/assets/video/';

String nwsbVideo(String fileName) {
  switch (fileName) {
    case kRmHeroVidFile:
    case kStoreWordDoorVidFile:
      return 'assets/video/hero-word-store.mp4';
    case kStoreMeaningDoorVidFile:
    case kMsMeaningVidFile:
      return 'assets/video/hero-meaning-store.mp4';
    case kMsSubscribeVidFile:
      return 'assets/video/subscription-a.mp4';
    default:
      final row = kRmRowVids.indexOf(fileName);
      if (row == 0) return 'assets/video/connect-banner.mp4';
      if (row == 1) return 'assets/video/signature-banner.mp4';
      if (row == 2) return 'assets/video/hero-ebooks.mp4';
      return 'assets/video/hero-word-store.mp4';
  }
}

/// Word Atelier category logo — `./assets/icons/collection-icon.webp` on web.
const kRmCatLogoAsset = 'assets/icons/collection-icon.webp';

/// Meaning Store category logo — MS_CAT_LOGO in part026.js.
const kMsCatLogoUrl =
    'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png';

/// ROW_VIDS from part010.js — inserted after every 5th category row.
const List<String> kRmRowVids = [
  '4fa2cc8a3160b945_grok_video_2026-07-31-15-36-41_blygoz.mp4',
  'b1e2c78385f45657_grok_video_2026-07-31-20-44-13_jlsimw.mp4',
  '8949dec81b7a28d7_grok_video_2026-07-31-20-40-30_vxozmt.mp4',
];

/// Atelier hero in index (`#sub-real-meaning`).
const kRmHeroVidFile = '928f93861b9beb26_grok_video_2026-07-31-20-43-13_qh2qjg.mp4';

/// Store hub word-library door (`#nssWordVid`).
const kStoreWordDoorVidFile = 'e2280a594872a9f8_grok_video_2026-05-28-14-02-13_zaoxnl.mp4';

/// Store hub meaning door + Meaning Store index hero (`#msBannerImg` / `#nssMeaningVid`).
const kStoreMeaningDoorVidFile = '6ea45e8d75a96578_grok_video_2026-05-29-04-36-47_cze9bz.mp4';

/// Meaning detail page hero clip — MS_MEANING_VID in part026.js.
const kMsMeaningVidFile = '4c1c17d70f5656d4_grok_video_2026-07-31-15-41-50_oxszei.mp4';

/// Subscribe banner on Meaning Store (index + detail) — part026 / index.
const kMsSubscribeVidFile = '67e02704e83fbf19_grok_video_2026-07-19-08-55-10_omybbr.mp4';

const kMsSubscribePillIcon =
    'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png';

class RmWordEntry {
  const RmWordEntry(this.word, this.root);
  final String word;
  final String root;
}

class RmSignatureEntry {
  const RmSignatureEntry({required this.key, required this.name, required this.img});
  final String key;
  final String name;
  final String img;
}

class RmCategory {
  const RmCategory({
    required this.id,
    required this.label,
    this.badge,
    required this.sub,
    this.labelColor,
    required this.words,
    this.signature,
  });
  final String id;
  final String label;
  final String? badge;
  final String sub;
  final int? labelColor;
  final List<RmWordEntry> words;
  final RmSignatureEntry? signature;
}

/// The Store's word categories as shown. While only words with the
/// client's own recordings are shown ([ContentStore.recordedWordsOnly]),
/// that is one category holding just those words; every other word stays
/// in [kRmCategoriesAll] and comes back with its recording.
List<RmCategory> get kRmCategories {
  if (!ContentStore.recordedWordsOnly) return kRmCategoriesAll;
  final words = ContentStore.instance.library;
  if (words.isEmpty) return kRmCategoriesAll;
  final key = words.map((w) => w.key).join(',');
  if (_shownKey == key && _shown != null) return _shown!;
  _shownKey = key;
  return _shown = [
    RmCategory(
      id: 'sacred', // its collection art
      label: 'Teacher recorded',
      sub: 'Words in your teacher’s own voice',
      words: [for (final w in words) RmWordEntry(_titleCase(w.word), 'Teacher recorded')],
    ),
  ];
}

String? _shownKey;
List<RmCategory>? _shown;

String _titleCase(String s) => s
    .trim()
    .split(RegExp(r'\s+'))
    .where((p) => p.isNotEmpty)
    .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
    .join(' ');

const List<RmCategory> kRmCategoriesAll = [
  RmCategory(
    id: "off50",
    label: "50% OFF",
    badge: "Sale",
    sub: "Limited time — best words at half price",
    labelColor: 0xF2E8D5A3,
    words: [
      RmWordEntry("god", "Proto-Germanic"),
      RmWordEntry("spirit", "Latin"),
      RmWordEntry("warrior", "Old French"),
      RmWordEntry("earth", "Proto-Germanic"),
      RmWordEntry("soul", "Proto-Germanic"),
      RmWordEntry("king", "Proto-Germanic"),
      RmWordEntry("cosmos", "Greek"),
      RmWordEntry("infinity", "Latin"),
    ],
    signature: RmSignatureEntry(key: "sale", name: "Sale", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "elements",
    label: "Elements",
    sub: "The original sounds of the natural world",
    words: [
      RmWordEntry("earth", "Proto-Germanic"),
      RmWordEntry("water", "Proto-Indo-European"),
      RmWordEntry("sun", "Proto-Indo-European"),
      RmWordEntry("moon", "Proto-Indo-European"),
      RmWordEntry("stone", "Proto-Germanic"),
      RmWordEntry("rain", "Proto-Germanic"),
      RmWordEntry("thunder", "Proto-Germanic"),
      RmWordEntry("storm", "Proto-Germanic"),
      RmWordEntry("wind", "Proto-Germanic"),
      RmWordEntry("ice", "Proto-Germanic"),
      RmWordEntry("lava", "Italian"),
      RmWordEntry("dust", "Old English"),
      RmWordEntry("ash", "Old English"),
      RmWordEntry("tide", "Old English"),
    ],
    signature: RmSignatureEntry(key: "elements", name: "Elements", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "sacred",
    label: "Sacred & Divine",
    sub: "Words that carry consciousness itself",
    words: [
      RmWordEntry("god", "Proto-Germanic"),
      RmWordEntry("soul", "Proto-Germanic"),
      RmWordEntry("love", "Old English"),
      RmWordEntry("truth", "Old English"),
      RmWordEntry("light", "Old English"),
      RmWordEntry("grace", "Old French"),
      RmWordEntry("prayer", "Old French"),
      RmWordEntry("spirit", "Latin"),
      RmWordEntry("divine", "Latin"),
      RmWordEntry("holy", "Old English"),
      RmWordEntry("sacred", "Latin"),
      RmWordEntry("faith", "Old French"),
      RmWordEntry("blessing", "Old English"),
      RmWordEntry("worship", "Old English"),
      RmWordEntry("heaven", "Old English"),
    ],
    signature: RmSignatureEntry(key: "sacreddivine", name: "Sacred Divine", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "identity",
    label: "Identity & Mind",
    sub: "The sounds of self — who you are",
    words: [
      RmWordEntry("name", "Proto-Indo-European"),
      RmWordEntry("mind", "Old English"),
      RmWordEntry("breath", "Old English"),
      RmWordEntry("blood", "Old English"),
      RmWordEntry("dream", "Old English"),
      RmWordEntry("voice", "Old French"),
      RmWordEntry("vision", "Latin"),
      RmWordEntry("thought", "Old English"),
      RmWordEntry("self", "Old English"),
      RmWordEntry("ego", "Latin"),
      RmWordEntry("will", "Old English"),
      RmWordEntry("memory", "Latin"),
      RmWordEntry("belief", "Old English"),
      RmWordEntry("identity", "Latin"),
    ],
    signature: RmSignatureEntry(key: "identitymind", name: "Identity Mind", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "cosmos",
    label: "Time & Cosmos",
    sub: "Words born from the infinite",
    words: [
      RmWordEntry("time", "Old English"),
      RmWordEntry("space", "Old French"),
      RmWordEntry("dark", "Old English"),
      RmWordEntry("star", "Old English"),
      RmWordEntry("cosmos", "Greek"),
      RmWordEntry("void", "Old French"),
      RmWordEntry("eternal", "Latin"),
      RmWordEntry("infinity", "Latin"),
      RmWordEntry("abyss", "Greek"),
      RmWordEntry("dawn", "Old English"),
      RmWordEntry("dusk", "Old English"),
      RmWordEntry("epoch", "Greek"),
      RmWordEntry("rift", "Middle English"),
      RmWordEntry("nebula", "Latin"),
      RmWordEntry("orbit", "Latin"),
    ],
    signature: RmSignatureEntry(key: "cosmostime", name: "Cosmos Time", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "nature",
    label: "Nature",
    sub: "The living world around you",
    words: [
      RmWordEntry("sky", "Old Norse"),
      RmWordEntry("sea", "Old English"),
      RmWordEntry("tree", "Old English"),
      RmWordEntry("wind", "Proto-Germanic"),
      RmWordEntry("river", "Old French"),
      RmWordEntry("forest", "Old French"),
      RmWordEntry("mountain", "Old French"),
      RmWordEntry("ocean", "Old French"),
      RmWordEntry("jungle", "Hindi"),
      RmWordEntry("desert", "Old French"),
      RmWordEntry("glacier", "French"),
      RmWordEntry("valley", "Old French"),
      RmWordEntry("cliff", "Old English"),
      RmWordEntry("reef", "Dutch"),
      RmWordEntry("savanna", "Spanish"),
    ],
    signature: RmSignatureEntry(key: "natureforest", name: "Nature Forest", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "family",
    label: "Family & Being",
    sub: "The words we are made of",
    words: [
      RmWordEntry("mother", "Proto-Indo-European"),
      RmWordEntry("father", "Proto-Indo-European"),
      RmWordEntry("child", "Old English"),
      RmWordEntry("man", "Old English"),
      RmWordEntry("woman", "Old English"),
      RmWordEntry("king", "Proto-Germanic"),
      RmWordEntry("queen", "Old English"),
      RmWordEntry("brother", "Proto-Indo-European"),
      RmWordEntry("sister", "Proto-Indo-European"),
      RmWordEntry("elder", "Old English"),
      RmWordEntry("tribe", "Latin"),
      RmWordEntry("clan", "Scottish Gaelic"),
      RmWordEntry("birth", "Old Norse"),
      RmWordEntry("life", "Old English"),
      RmWordEntry("death", "Old English"),
    ],
    signature: RmSignatureEntry(key: "familylove", name: "Family Love", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "elite",
    label: "Elite Words",
    sub: "The rarest words in existence",
    labelColor: 0xE6E8D5A3,
    words: [
      RmWordEntry("spirit", "Latin"),
      RmWordEntry("life", "Old English"),
      RmWordEntry("death", "Old English"),
      RmWordEntry("power", "Old French"),
      RmWordEntry("heart", "Old English"),
      RmWordEntry("peace", "Old French"),
      RmWordEntry("wisdom", "Old English"),
      RmWordEntry("freedom", "Old English"),
      RmWordEntry("karma", "Sanskrit"),
      RmWordEntry("energy", "Greek"),
      RmWordEntry("destiny", "Old French"),
      RmWordEntry("legacy", "Latin"),
      RmWordEntry("glory", "Latin"),
      RmWordEntry("honor", "Old French"),
      RmWordEntry("crown", "Old French"),
    ],
    signature: RmSignatureEntry(key: "elitesovereign", name: "Elite Sovereign", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "premium",
    label: "Premium",
    badge: "New",
    sub: "Exclusive — limited release words",
    labelColor: 0xE6B4DCFF,
    words: [
      RmWordEntry("aura", "Latin"),
      RmWordEntry("cipher", "Arabic"),
      RmWordEntry("apex", "Latin"),
      RmWordEntry("zenith", "Arabic"),
      RmWordEntry("prime", "Latin"),
      RmWordEntry("sovereign", "Old French"),
      RmWordEntry("cardinal", "Latin"),
      RmWordEntry("oracle", "Latin"),
      RmWordEntry("nexus", "Latin"),
      RmWordEntry("axiom", "Greek"),
      RmWordEntry("mantra", "Sanskrit"),
      RmWordEntry("rune", "Old Norse"),
      RmWordEntry("glyph", "Greek"),
      RmWordEntry("totem", "Ojibwe"),
    ],
    signature: RmSignatureEntry(key: "premiumexclusive", name: "Premium Exclusive", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "warriors",
    label: "Warriors",
    badge: "New",
    sub: "Words of strength and courage",
    labelColor: 0xE6FF825A,
    words: [
      RmWordEntry("warrior", "Old French"),
      RmWordEntry("blade", "Old English"),
      RmWordEntry("shield", "Proto-Germanic"),
      RmWordEntry("archer", "Old French"),
      RmWordEntry("shaman", "Tungus"),
    ],
    signature: RmSignatureEntry(key: "warriorsedition", name: "Warriors Edition", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "peace",
    label: "Peace Edition",
    badge: "New",
    sub: "Words of stillness and surrender",
    labelColor: 0xE6C8E1FF,
    words: [
      RmWordEntry("peace", "Old French"),
      RmWordEntry("calm", "French"),
      RmWordEntry("silence", "Latin"),
      RmWordEntry("harmony", "Latin"),
      RmWordEntry("still", "Old English"),
      RmWordEntry("breathe", "Old English"),
      RmWordEntry("forgive", "Old English"),
      RmWordEntry("release", "Old French"),
      RmWordEntry("serenity", "Latin"),
      RmWordEntry("gentle", "Old French"),
      RmWordEntry("tender", "Old French"),
      RmWordEntry("refuge", "Old French"),
      RmWordEntry("solace", "Old French"),
      RmWordEntry("grace", "Old French"),
      RmWordEntry("bloom", "Old Norse"),
    ],
    signature: RmSignatureEntry(key: "peaceedition", name: "Peace Edition", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "white",
    label: "White Edition",
    badge: "New",
    sub: "Minimal. Pure. Eternal.",
    labelColor: 0xE6F0F0FF,
    words: [
      RmWordEntry("pure", "Old French"),
      RmWordEntry("light", "Old English"),
      RmWordEntry("snow", "Old English"),
      RmWordEntry("clarity", "Latin"),
      RmWordEntry("dawn", "Old English"),
      RmWordEntry("ivory", "Old French"),
      RmWordEntry("pristine", "Latin"),
      RmWordEntry("crystal", "Old French"),
      RmWordEntry("blank", "Old French"),
      RmWordEntry("void", "Old French"),
      RmWordEntry("clean", "Old English"),
      RmWordEntry("white", "Old English"),
      RmWordEntry("frost", "Old Norse"),
      RmWordEntry("pearl", "Old French"),
      RmWordEntry("alba", "Latin"),
    ],
    signature: RmSignatureEntry(key: "whiteedition", name: "White Edition", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "black",
    label: "Black Edition",
    badge: "New",
    sub: "Dark. Rare. Unstoppable.",
    labelColor: 0xE69696B4,
    words: [
      RmWordEntry("dark", "Old English"),
      RmWordEntry("abyss", "Greek"),
      RmWordEntry("void", "Old French"),
      RmWordEntry("shadow", "Old English"),
      RmWordEntry("night", "Old English"),
      RmWordEntry("obsidian", "Latin"),
      RmWordEntry("onyx", "Latin"),
      RmWordEntry("eclipse", "Greek"),
      RmWordEntry("noir", "French"),
      RmWordEntry("raven", "Old English"),
      RmWordEntry("dusk", "Old English"),
      RmWordEntry("midnight", "Old English"),
      RmWordEntry("smoke", "Old English"),
      RmWordEntry("ash", "Old English"),
      RmWordEntry("depth", "Old English"),
    ],
    signature: RmSignatureEntry(key: "blackedition", name: "Black Edition", img: kRmSignatureImg),
  ),
];

/// Words taken out of the catalogue (Nov 23, 2026): "Fire", and every word
/// that is only a country, a city, a language, a currency or a greeting in
/// another language. Anything a phone still holds for one of these (a cart
/// or wishlist line, a published library doc) is dropped on read, so they
/// show up nowhere.
const Set<String> kRemovedWordKeys = {
  'fire', 'country', 'india',
  'egypt', 'babylon', 'troy', 'sparta', 'rome', 'athens', 'carthage',
  'persia', 'phoenicia', 'nubia', 'sumer', 'akkad',
  // The old Countries / Capitals / Currency / Language store rows.
  'japan', 'greece', 'france', 'brazil', 'kenya', 'canada',
  'delhi', 'tokyo', 'cairo', 'paris', 'brasilia', 'nairobi', 'ottawa',
  'rupee', 'yen', 'pound', 'dollar', 'euro', 'dinar', 'krone', 'peso',
  'sanskrit', 'latin', 'greek', 'arabic', 'english', 'hindi', 'french', 'japanese',
  // Fantasy and mythical filler words, warrior titles and ancient peoples (Nov 23).
  'zeus', 'anubis', 'medusa', 'kitsune', 'oni', 'valkyrie', 'dragon', 'phoenix', 'hydra', 'titan', 'odin', 'thor', 'cerberus', 'minotaur', 'griffon', 'samurai', 'viking', 'spartan', 'centurion', 'ninja', 'gladiator', 'berserker', 'ronin', 'crusader', 'warlord', 'indus', 'maya', 'aztec', 'sigil',
};

/// True when [word] (any case or spacing) is one of [kRemovedWordKeys].
bool isRemovedWord(String word) =>
    kRemovedWordKeys.contains(word.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ''));

/// True when a bag / ownership id (`word:fire`, `meaning:india` ...) points
/// at a removed word.
bool isRemovedItemId(String id) {
  final i = id.indexOf(':');
  if (i < 0) return false;
  final kind = id.substring(0, i);
  if (kind != 'word' && kind != 'meaning') return false;
  return isRemovedWord(id.substring(i + 1));
}

class MsMeaning {
  const MsMeaning({required this.word, required this.key, required this.root, required this.category, required this.price, required this.img});
  final String word, key, root, category, img;
  final num price;
}

const List<MsMeaning> kMsBaseMeanings = [
  MsMeaning(word: "Earth", key: "earth", root: "Proto-Germanic · erþō", category: "Elements", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Water", key: "water", root: "Proto-Indo-European · wódr̥", category: "Elements", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Sun", key: "sun", root: "Proto-Indo-European · séh₂wl̥", category: "Elements", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Moon", key: "moon", root: "Proto-Germanic · mēnô", category: "Elements", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Light", key: "light", root: "Proto-Indo-European · leuk-", category: "Elements", price: 49, img: "assets/meanings/meanings-clean.jpg"),
  MsMeaning(word: "Dark", key: "dark", root: "Proto-Germanic · derkaz", category: "Elements", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Body", key: "body", root: "Old English · bodig", category: "Human", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Mind", key: "mind", root: "Proto-Indo-European · men-", category: "Human", price: 49, img: "assets/meanings/meanings-clean.jpg"),
  MsMeaning(word: "Soul", key: "soul", root: "Proto-Germanic · saiwalō", category: "Human", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Blood", key: "blood", root: "Proto-Indo-European · bhel-", category: "Human", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Breath", key: "breath", root: "Proto-Germanic · brǣþ", category: "Human", price: 49, img: "assets/meanings/meanings-clean.jpg"),
  MsMeaning(word: "Love", key: "love", root: "Proto-Indo-European · leubh-", category: "Emotions", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Fear", key: "fear", root: "Proto-Germanic · feraz", category: "Emotions", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Joy", key: "joy", root: "Old French · joie", category: "Emotions", price: 49, img: "assets/meanings/meanings-clean.jpg"),
  MsMeaning(word: "God", key: "god", root: "Proto-Germanic · ǵʰew-", category: "Cosmos", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Time", key: "time", root: "Proto-Indo-European · dī-", category: "Cosmos", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Space", key: "space", root: "Latin · spatium", category: "Cosmos", price: 49, img: "assets/meanings/meanings-clean.jpg"),
  MsMeaning(word: "Truth", key: "truth", root: "Proto-Germanic · trewwþō", category: "Cosmos", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Mother", key: "mother", root: "Proto-Indo-European · méh₂tēr", category: "Nations & People", price: 49, img: "assets/meanings/meanings-device.png"),
  MsMeaning(word: "Father", key: "father", root: "Proto-Indo-European · ph₂tḗr", category: "Nations & People", price: 49, img: "assets/meanings/meanings-branding.jpg"),
  MsMeaning(word: "Name", key: "name", root: "Proto-Indo-European · h₁nómn̥", category: "Nations & People", price: 49, img: "assets/meanings/meanings-clean.jpg"),
];

const Map<String, String> kMsCatSub = {
  "Elements": "The original sounds of the natural world",
  "Human": "The truth of body, mind and soul",
  "Emotions": "What every feeling really means",
  "Cosmos": "Origins beyond understanding",
  "Nations & People": "The people and names behind the meanings",
};

class MsSignatureEntry {
  const MsSignatureEntry({required this.key, required this.word, required this.root});
  final String key, word, root;
}

const Map<String, MsSignatureEntry> kMsSignature = {
  "Elements": MsSignatureEntry(key: "elementssignature", word: "Elements Signature", root: "Most Exclusive"),
  "Human": MsSignatureEntry(key: "humansignature", word: "Human Signature", root: "Most Exclusive"),
  "Emotions": MsSignatureEntry(key: "emotionssignature", word: "Emotions Signature", root: "Most Exclusive"),
  "Cosmos": MsSignatureEntry(key: "cosmossignature", word: "Cosmos Signature", root: "Most Exclusive"),
  "Nations & People": MsSignatureEntry(key: "nationssignature", word: "Nations Signature", root: "Most Exclusive"),
};

const Map<String, String> kMsWordBlurb = {
  "earth": "Earth is the place where we live — solid ground beneath every step.",
  "water": "Water is what moves through everything alive, the first thing the body remembers.",
  "sun": "Sun is the source every living rhythm on this planet keeps time by.",
  "moon": "Moon is the quiet pull that shapes tides, sleep, and the turning of months.",
  "light": "Light is what makes anything visible at all — the first sense to arrive.",
  "dark": "Dark is the space light hasn&rsquo;t reached yet — rest, depth, the unseen.",
  "body": "Body is the vessel every sound, breath, and feeling moves through.",
  "mind": "Mind is the quiet voice that names, remembers, and decides.",
  "soul": "Soul is the part of you that stays the same through every change.",
  "blood": "Blood is the current that carries life to every corner of the body.",
  "breath": "Breath is the one rhythm that never stops until everything else does.",
  "love": "Love is the pull that makes distance feel like the wrong direction.",
  "fear": "Fear is the body&rsquo;s oldest warning, still firing long after the danger is real.",
  "joy": "Joy is what the body does when nothing needs fixing anymore.",
  "god": "God is the word every culture reaches for when explaining feels impossible.",
  "time": "Time is the one thing spent by everyone, saved by no one.",
  "space": "Space is the distance that makes it possible for anything to move at all.",
  "truth": "Truth is what&rsquo;s still standing after everything false has been said.",
  "mother": "Mother is the first voice, the first shape, the first safety.",
  "father": "Father is the first structure — the one who shows what holding steady looks like.",
  "name": "Name is the sound a person is called back to, again and again.",
  "elementssignature": "The complete elemental set — every natural force, one origin story.",
  "humansignature": "The full human story — body, mind and soul in one unlocked meaning.",
  "emotionssignature": "Every core feeling, decoded to its first phonetic root.",
  "cosmossignature": "The largest ideas we have words for, traced back to pure sound.",
  "nationssignature": "Where a people, a land and a name become one meaning.",
};

class EbBook {
  const EbBook({required this.key, required this.title, required this.sub, required this.price, required this.cover, required this.about, required this.contents});
  final String key, title, sub, cover, about;
  final num price;
  final List<String> contents;
}

const List<EbBook> kEbBooks = [
  EbBook(
    key: "shabdapathy-codex",
    title: "The Shabdapathy Codex",
    sub: "The complete origin science, in one volume.",
    price: 499,
    cover: "https://media.nowssb.com/migrated-images/4ee1d0740a290ecc_file_000000007fec81f4b097aaae4e7ac297_ohtqy9.png",
    about: "The foundational text of Shabdapathy — how sound carried meaning long before dictionaries existed, and why the human body still responds to the original vibration of a word rather than its spelling.",
    contents: [
      "What Shabdapathy is, and what it is not",
      "The natural origin of sound, before written language",
      "Why the body reacts to vibration, not definition",
      "Reading a word back to its first sound",
      "Daily practice: building your own routine",
    ],
  ),
  EbBook(
    key: "phonetic-field-guide",
    title: "Phonetic Origins: A Field Guide",
    sub: "Trace any word back to its first sound.",
    price: 399,
    cover: "https://media.nowssb.com/migrated-images/741bfd1ea84543f4_file_000000007af081f49748cd0a1b77c566_f8qslq.png",
    about: "A practical companion for tracing any word back through its phonetic ancestry. Built as a working field guide rather than a theory book — open it mid-practice and follow the method on whatever word you are holding.",
    contents: [
      "The tracing method, step by step",
      "Root syllables and how to isolate them",
      "Common false trails and how to spot them",
      "Cross-language sound families",
      "Worked examples you can follow along with",
    ],
  ),
  EbBook(
    key: "sound-healing-atlas",
    title: "The Sound Healing Atlas",
    sub: "Which sounds reach which parts of the body.",
    price: 599,
    cover: "https://media.nowssb.com/migrated-images/2f10e08211dd8561_file_00000000ee688208950f4126ed15d9b3_esohnw.png",
    about: "A mapped reference of sound to the body — which syllables carry to which regions, why speaking aloud lands differently than thinking a word, and how to build a session around the area you actually want to work on.",
    contents: [
      "The body map: sound to region",
      "Why aloud differs from silent",
      "Breath, pitch and placement",
      "Building a session around one area",
      "Sequencing and how long to hold",
    ],
  ),
];

const kEbDisclaimer =
    'For educational and wellness purposes only — not medical advice, and not a replacement for professional diagnosis or treatment.';

const kEbHeroImg =
    'https://media.nowssb.com/migrated-images/fba7611b6670d593_grok_image_1784957219264_oulqx7.jpg';

