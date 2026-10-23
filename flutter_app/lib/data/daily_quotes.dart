/// NowssB daily quotes. Exact wording from Ribon.
///
/// To add a quote: append a DailyQuote below. `emphasis` (optional) is the
/// word card 1 prints huge; it must appear in `text` (case-insensitive).
library;

class DailyQuote {
  const DailyQuote(this.text, {this.emphasis});
  final String text;
  final String? emphasis;
}

const List<DailyQuote> kDailyQuotes = [
  DailyQuote("Without a weapon in hand, the enlightened Buddha guided the world, not by the sword but by the power of words.",
      emphasis: "Buddha"),
  DailyQuote("The universal principle that transforms concepts into expressions of truth and virtue is a truth-oriented mechanism that opposes false mechanisms to transforms into concepts of noble and naturally virtuous thoughts for the virtuous emulation of nature; is the mechanism and mechanical process of articulating WordlessWords!",
      emphasis: "WordlessWords!"),
  DailyQuote("Utter the nectarous wisdom of WordlessWords, and let your mouth overflow with the nectar of life. WordlessWords are profound and sublime, imbuing every word with the essence of knowledge.",
      emphasis: "nectar"),
  DailyQuote("As silent words are left out of people's everyday conversation, the minute and sub-minute organs in the human body grow dormant and lifeless. Hence, reactivating and energizing these tiny organs through the utterance of silent words i.e. wordlesswords is vital role for human health and well-being.",
      emphasis: "silent"),
  DailyQuote("Speak your words with care! One word can heal, One word can wound.",
      emphasis: "care!"),
  DailyQuote("NowssB consistently advocated the principles of equality-based truth, truth-based equality, freedom, and fraternity through its WordlessWords.",
      emphasis: "equality"),
  DailyQuote("Through WordlessWords, we harness the scientifically unexplored power of sound vibrations to activate every organ in the human body and accelerate their movements and functioning.",
      emphasis: "vibrations"),
  DailyQuote("Wordlesswords utilize innovative linguistic knowledge, integrating new communication skills and creativity to connect with the world.",
      emphasis: "connect"),
  DailyQuote("Unite words with WordlessWords, and only then will the true name emerge! The more new words and letters come together, the more universal love will grow!",
      emphasis: "Unite"),
  DailyQuote("Through the pronunciation of innovative sounds guided by WordlessWords, the movements occurring within the human body can be stimulated to become more active and rapid.",
      emphasis: "sounds"),
  DailyQuote("WordlessWords are not merely a Pali or Prakrit language; they are a natural language intrinsically connected with the human body and nature, as well as with the Ayurvedic identification of plants and the preparation of medicinal formulations.",
      emphasis: "natural"),
  DailyQuote("WordlessWords are the knowledge of words and scientific inquiry, along with the pronunciation of words guided by wordlesswords sound vibrations, can provide first aid and treatment for the human body!",
      emphasis: "first aid"),
  DailyQuote("The Wordlesswords is our origin; the Word itself gave life to the soul! Having slain that very Word, we search for the Divine!",
      emphasis: "origin"),
  DailyQuote("Words hold the essence; bonds of affection are nurtured through the loving actions of WordlessWords! Come, let us weave bonds of universal friendship with the world through the WordlessWords!",
      emphasis: "friendship"),
  DailyQuote("The Divine resides in the WordlessWords of the world. Serve the world, O Divine Beings!",
      emphasis: "Divine"),
  DailyQuote("The purity of the words, the truth within the heart, and the awakening of the soul are all hidden within the words of world.",
      emphasis: "awakening"),
  DailyQuote("Words can heal, words can kill, words can pay the bill, words can bend the will. Words can build, words can break, words can give and words can take. Said with love, they light the way, said in rage, they make you pay. Every sentence means is a coin spent through word, some will wound and some will mend. Pick your tone, pick your sound, plant your voice on solid ground. Bill or will, it's all a deal, words decide how people feel. Heal or kill, the choice is real. Learn from NowssB.",
      emphasis: "heal"),
  DailyQuote("The corrected pure pronunciation of wordlesswords arising from truthful diversity as a foundation for universal unity in meditation, health, science, Discovery of nature, Discovery of truth, Discovery of non violence, and global peace of world can be scientifically validated over time through systematic experiments.",
      emphasis: "peace"),
  DailyQuote("Word itself is God! The Word is the life of the soul! Polish your words, refine your words, before you speak!",
      emphasis: "God!"),
  DailyQuote("Exercise your body through mindful awareness of words while walking and talking; not only that, but with the power of words, stimulate the subtle and subtlest organs of the body and give a sharper edge of exercise to the intellect of the brain!",
      emphasis: "mindful"),
  DailyQuote("Every sentence means a coin spent through words,",
      emphasis: "coin"),
  DailyQuote("NowssB, an innovative way to meditate; natural words that emerge under the guidance of wordlesswords sounds for meditation, physical and mental exercises of human body!",
      emphasis: "meditate;"),
  DailyQuote("The pure pronunciation of wordlesswords rooted in truthful diversity serves as a foundation for meditation, health, Discovery of nature, Discovery of truth, Discovery of non-violence along with unity in global peace of world.",
      emphasis: "unity"),
  DailyQuote("Every word is a seed of a sentence. You decide whether that seed will grow a garden or create a grave.",
      emphasis: "seed"),
  DailyQuote("Choose your words carefully. What has been broken by the wrong words can be mended again with the right words.",
      emphasis: "mended"),
];

/// Backgrounds for the Daily Quote card. Add a PNG with the figure on the
/// right and a black (or transparent) left half, then list it here.
/// One is picked per day, in turn.
const List<String> kDailyQuoteBackgrounds = [
  'assets/banners/gyro/buddha.png',
];

int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024, 1, 1)).inDays;

/// Today's quote index. Deterministic per date, never the same two days in a
/// row, and walks the whole list before repeating.
int quoteIndexFor(DateTime day, [int? length]) {
  final n = length ?? kDailyQuotes.length;
  if (n <= 1) return 0;
  // Stride 7 (coprime with most list sizes; falls back to 1 if not).
  final stride = n % 7 == 0 ? 1 : 7;
  return (_dayNumber(day) * stride) % n;
}

/// Background asset for [day], in turn.
String backgroundFor(DateTime day, [List<String> pool = kDailyQuoteBackgrounds]) =>
    pool[_dayNumber(day) % pool.length];

class DatedQuote {
  const DatedQuote(this.day, this.quote, this.background);
  final DateTime day;
  final DailyQuote quote;
  final String background;
}

/// Today first, then the six days before it. [override] lets a published
/// Firestore line replace the bundled quote for a day ('' = none).
List<DatedQuote> weekQuotes(
  DateTime now, {
  String Function(DateTime day)? override,
  List<DailyQuote> pool = kDailyQuotes,
  List<String> backgrounds = kDailyQuoteBackgrounds,
}) {
  final out = <DatedQuote>[];
  for (var i = 0; i < 7; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final o = (override?.call(d) ?? '').trim();
    final q = o.isNotEmpty ? DailyQuote(o) : pool[quoteIndexFor(d, pool.length)];
    out.add(DatedQuote(d, q, backgroundFor(d, backgrounds)));
  }
  return out;
}

/// Short lines (for the calm Breathe card), rotated daily.
String breatheLineFor(DateTime day) {
  final short = kDailyQuotes.where((q) => q.text.length <= 110).toList();
  if (short.isEmpty) return 'Breathe in. Let the word arrive.';
  return short[(_dayNumber(day) * 3) % short.length].text;
}
