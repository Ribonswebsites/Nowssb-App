/// Store catalogue constants — ported from the website JS.
///
/// Sources: app/js/part010.js (Word Atelier), part026.js (Meaning Store),
/// part074.js (Signature), part017.js (Ebooks). Prefer these over inventing.
library;

const kRmWordImg =
    "https://media.nowssb.com/migrated-images/35423222df3850a9_grok_image_1778520937416_jazknf.jpg";
const kRmSignatureImg =
    "https://media.nowssb.com/migrated-images/26780a9d82ed389f_file_00000000d39081faa073bf17312d89fc_q9ehat.png";
const kMsCardImg =
    "https://media.nowssb.com/migrated-images/ee0598260fbb63ea_7562ed60-5b68-11f1-af5d-9196714121d3_y4f80z.png";
const kMsSignatureImg =
    "https://media.nowssb.com/migrated-images/a7c5f95b3e9029e5_file_000000008eb081fba87f16fe9146e413_mk9wbe.png";
const kMsSignaturePrice = 299;

/// Collection banner art — assets/store/collections/{id}.webp
const Map<String, String> kCollectionBanner = {
  "off50": 'assets/store/collections/sale.webp',
  "elements": 'assets/store/collections/elements.webp',
  "sacred": 'assets/store/collections/sacred.webp',
  "identity": 'assets/store/collections/identity.webp',
  "cosmos": 'assets/store/collections/cosmos.webp',
  "nature": 'assets/store/collections/nature.webp',
  "family": 'assets/store/collections/family.webp',
  "elite": 'assets/store/collections/elite.webp',
  "premium": 'assets/store/collections/premium.webp',
  "mythical": 'assets/store/collections/mythical.webp',
  "warriors": 'assets/store/collections/warriors.webp',
  "ancient": 'assets/store/collections/ancient.webp',
  "peace": 'assets/store/collections/peace.webp',
  "white": 'assets/store/collections/white.webp',
  "black": 'assets/store/collections/black.webp',
};

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

const List<RmCategory> kRmCategories = [
  RmCategory(
    id: "off50",
    label: "50% OFF",
    badge: "Sale",
    sub: "Limited time — best words at half price",
    labelColor: 0xF2E8D5A3,
    words: [
      RmWordEntry("fire", "Proto-Indo-European"),
      RmWordEntry("god", "Proto-Germanic"),
      RmWordEntry("spirit", "Latin"),
      RmWordEntry("warrior", "Old French"),
      RmWordEntry("dragon", "Greek"),
      RmWordEntry("zeus", "Ancient Greek"),
      RmWordEntry("samurai", "Japanese"),
      RmWordEntry("earth", "Proto-Germanic"),
      RmWordEntry("soul", "Proto-Germanic"),
      RmWordEntry("thor", "Old Norse"),
      RmWordEntry("phoenix", "Greek"),
      RmWordEntry("odin", "Old Norse"),
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
      RmWordEntry("fire", "Proto-Indo-European"),
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
      RmWordEntry("india", "Persian"),
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
      RmWordEntry("sigil", "Latin"),
      RmWordEntry("mantra", "Sanskrit"),
      RmWordEntry("rune", "Old Norse"),
      RmWordEntry("glyph", "Greek"),
      RmWordEntry("totem", "Ojibwe"),
    ],
    signature: RmSignatureEntry(key: "premiumexclusive", name: "Premium Exclusive", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "mythical",
    label: "Mythical Edition",
    badge: "New",
    sub: "Gods, beasts & ancient forces",
    labelColor: 0xE6C89BFF,
    words: [
      RmWordEntry("zeus", "Ancient Greek"),
      RmWordEntry("anubis", "Ancient Egyptian"),
      RmWordEntry("medusa", "Greek"),
      RmWordEntry("kitsune", "Japanese"),
      RmWordEntry("oni", "Japanese"),
      RmWordEntry("valkyrie", "Old Norse"),
      RmWordEntry("dragon", "Greek"),
      RmWordEntry("phoenix", "Greek"),
      RmWordEntry("hydra", "Greek"),
      RmWordEntry("titan", "Greek"),
      RmWordEntry("odin", "Old Norse"),
      RmWordEntry("thor", "Old Norse"),
      RmWordEntry("cerberus", "Greek"),
      RmWordEntry("minotaur", "Greek"),
      RmWordEntry("griffon", "Old French"),
    ],
    signature: RmSignatureEntry(key: "mythicaledition", name: "Mythical Edition", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "warriors",
    label: "Warriors",
    badge: "New",
    sub: "Born in blood, forged in fire",
    labelColor: 0xE6FF825A,
    words: [
      RmWordEntry("samurai", "Japanese"),
      RmWordEntry("viking", "Old Norse"),
      RmWordEntry("spartan", "Greek"),
      RmWordEntry("centurion", "Latin"),
      RmWordEntry("ninja", "Japanese"),
      RmWordEntry("warrior", "Old French"),
      RmWordEntry("blade", "Old English"),
      RmWordEntry("shield", "Proto-Germanic"),
      RmWordEntry("gladiator", "Latin"),
      RmWordEntry("archer", "Old French"),
      RmWordEntry("berserker", "Old Norse"),
      RmWordEntry("ronin", "Japanese"),
      RmWordEntry("crusader", "Old French"),
      RmWordEntry("shaman", "Tungus"),
      RmWordEntry("warlord", "Old English"),
    ],
    signature: RmSignatureEntry(key: "warriorsedition", name: "Warriors Edition", img: kRmSignatureImg),
  ),
  RmCategory(
    id: "ancient",
    label: "Ancient Civilizations",
    badge: "New",
    sub: "Words from the dawn of history",
    labelColor: 0xE6FFD06E,
    words: [
      RmWordEntry("egypt", "Greek"),
      RmWordEntry("babylon", "Hebrew"),
      RmWordEntry("troy", "Greek"),
      RmWordEntry("sparta", "Greek"),
      RmWordEntry("rome", "Latin"),
      RmWordEntry("indus", "Persian"),
      RmWordEntry("maya", "Spanish"),
      RmWordEntry("aztec", "Spanish"),
      RmWordEntry("persia", "Greek"),
      RmWordEntry("carthage", "Phoenician"),
      RmWordEntry("athens", "Greek"),
      RmWordEntry("sumer", "Akkadian"),
      RmWordEntry("akkad", "Sumerian"),
      RmWordEntry("nubia", "Latin"),
      RmWordEntry("phoenicia", "Greek"),
    ],
    signature: RmSignatureEntry(key: "ancientcivilizations", name: "Ancient Civilizations", img: kRmSignatureImg),
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

class MsMeaning {
  const MsMeaning({required this.word, required this.key, required this.root, required this.category, required this.price, required this.img});
  final String word, key, root, category, img;
  final num price;
}

const List<MsMeaning> kMsBaseMeanings = [
  MsMeaning(word: "Earth", key: "earth", root: "Proto-Germanic · erþō", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/41f5e532b0c0e661_grok_image_1777030001969_2_mpmpu2.jpg"),
  MsMeaning(word: "Water", key: "water", root: "Proto-Indo-European · wódr̥", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/0d9f29f0abec0ed5_grok_image_1777029845867_2_abtxad.jpg"),
  MsMeaning(word: "Fire", key: "fire", root: "Proto-Indo-European · péh₂wr̥", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/fe881b289d00730d_1000033063-ezremove_r22cph.png"),
  MsMeaning(word: "Sun", key: "sun", root: "Proto-Indo-European · séh₂wl̥", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/fe881b289d00730d_1000033063-ezremove_r22cph.png"),
  MsMeaning(word: "Moon", key: "moon", root: "Proto-Germanic · mēnô", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/63bdfda9170e8c19_1000033096-ezremove_eb2gnu.png"),
  MsMeaning(word: "Light", key: "light", root: "Proto-Indo-European · leuk-", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/fe881b289d00730d_1000033063-ezremove_r22cph.png"),
  MsMeaning(word: "Dark", key: "dark", root: "Proto-Germanic · derkaz", category: "Elements", price: 49, img: "https://media.nowssb.com/migrated-images/63bdfda9170e8c19_1000033096-ezremove_eb2gnu.png"),
  MsMeaning(word: "Body", key: "body", root: "Old English · bodig", category: "Human", price: 49, img: "https://media.nowssb.com/migrated-images/5c4551501630cd00_1000033084-ezremove_ybzuzs.png"),
  MsMeaning(word: "Mind", key: "mind", root: "Proto-Indo-European · men-", category: "Human", price: 49, img: "https://media.nowssb.com/migrated-images/5c4551501630cd00_1000033084-ezremove_ybzuzs.png"),
  MsMeaning(word: "Soul", key: "soul", root: "Proto-Germanic · saiwalō", category: "Human", price: 49, img: "https://media.nowssb.com/migrated-images/d614abe902eccd10_1000033052-ezremove_vx4rib.png"),
  MsMeaning(word: "Blood", key: "blood", root: "Proto-Indo-European · bhel-", category: "Human", price: 49, img: "https://media.nowssb.com/migrated-images/fe881b289d00730d_1000033063-ezremove_r22cph.png"),
  MsMeaning(word: "Breath", key: "breath", root: "Proto-Germanic · brǣþ", category: "Human", price: 49, img: "https://media.nowssb.com/migrated-images/d614abe902eccd10_1000033052-ezremove_vx4rib.png"),
  MsMeaning(word: "Love", key: "love", root: "Proto-Indo-European · leubh-", category: "Emotions", price: 49, img: "https://media.nowssb.com/migrated-images/dd23331ed4a9b751_grok_image_1776753853585_luk2yh.jpg"),
  MsMeaning(word: "Fear", key: "fear", root: "Proto-Germanic · feraz", category: "Emotions", price: 49, img: "https://media.nowssb.com/migrated-images/63bdfda9170e8c19_1000033096-ezremove_eb2gnu.png"),
  MsMeaning(word: "Joy", key: "joy", root: "Old French · joie", category: "Emotions", price: 49, img: "https://media.nowssb.com/migrated-images/dd23331ed4a9b751_grok_image_1776753853585_luk2yh.jpg"),
  MsMeaning(word: "God", key: "god", root: "Proto-Germanic · ǵʰew-", category: "Cosmos", price: 49, img: "https://media.nowssb.com/migrated-images/63bdfda9170e8c19_1000033096-ezremove_eb2gnu.png"),
  MsMeaning(word: "Time", key: "time", root: "Proto-Indo-European · dī-", category: "Cosmos", price: 49, img: "https://media.nowssb.com/migrated-images/d59e474dabdaa2a5_grok_image_1777030062742_2_f7k7eo.jpg"),
  MsMeaning(word: "Space", key: "space", root: "Latin · spatium", category: "Cosmos", price: 49, img: "https://media.nowssb.com/migrated-images/63bdfda9170e8c19_1000033096-ezremove_eb2gnu.png"),
  MsMeaning(word: "Truth", key: "truth", root: "Proto-Germanic · trewwþō", category: "Cosmos", price: 49, img: "https://media.nowssb.com/migrated-images/41f5e532b0c0e661_grok_image_1777030001969_2_mpmpu2.jpg"),
  MsMeaning(word: "Country", key: "country", root: "Latin · contra", category: "Nations & People", price: 49, img: "https://media.nowssb.com/migrated-images/99dfe1e72e000cd5_grok_image_1777029510370_2_lilo5x.jpg"),
  MsMeaning(word: "India", key: "india", root: "Natural Origin · Sindhu", category: "Nations & People", price: 49, img: "https://media.nowssb.com/migrated-images/22792c141d392143_1000033069-ezremove_hz5p0s.png"),
  MsMeaning(word: "Mother", key: "mother", root: "Proto-Indo-European · méh₂tēr", category: "Nations & People", price: 49, img: "https://media.nowssb.com/migrated-images/99dfe1e72e000cd5_grok_image_1777029510370_2_lilo5x.jpg"),
  MsMeaning(word: "Father", key: "father", root: "Proto-Indo-European · ph₂tḗr", category: "Nations & People", price: 49, img: "https://media.nowssb.com/migrated-images/d59e474dabdaa2a5_grok_image_1777030062742_2_f7k7eo.jpg"),
  MsMeaning(word: "Name", key: "name", root: "Proto-Indo-European · h₁nómn̥", category: "Nations & People", price: 49, img: "https://media.nowssb.com/migrated-images/99dfe1e72e000cd5_grok_image_1777029510370_2_lilo5x.jpg"),
];

const Map<String, String> kMsCatSub = {
  "Elements": "The original sounds of the natural world",
  "Human": "The truth of body, mind and soul",
  "Emotions": "What every feeling really means",
  "Cosmos": "Origins beyond understanding",
  "Nations & People": "The people and places behind the words",
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
  "fire": "Fire is the spark that turns still matter into motion and light.",
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
  "country": "Country is the shared ground a people agree to call home.",
  "india": "India is the ancient root many of these very sounds first grew from.",
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

