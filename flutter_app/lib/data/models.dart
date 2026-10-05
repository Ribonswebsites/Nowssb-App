/// The content model, ported from `nwsbNormWord` in app/js/part073.js.
///
/// This is a port, not a redesign. The website and this app read the SAME
/// four Firestore documents — content/library, content/books, content/words,
/// content/meanings — so a word published from the studio has to mean the
/// same thing on both. Where part073.js fills a missing field with an empty
/// string, so does this; where it clamps parts to five, so does this. The
/// day the two disagree is the day the studio can publish something that
/// renders on the website and throws here.
///
/// Everything is nullable-safe on the way in and non-null on the way out.
/// A half-filled word renders as a word with blanks, exactly as on the web.
library;

/// One pronunciation box: three to five of them make a word.
///
/// A NowssB word is not an English word — it is a sound written in
/// Devanagari, which has letters English does not have. There is no roman
/// spelling of ऋ that a reader can simply read out. So each box carries
/// something to look at (deva), something to read (roman), how long to hold
/// it, one plain sentence on how to make the sound, and if it exists, a
/// recording — which is the only thing that ever settles an argument.
class WordPart {
  const WordPart({
    required this.roman,
    required this.deva,
    required this.hold,
    required this.say,
    required this.audio,
  });

  final String roman;
  final String deva;
  final double hold;
  final String say;
  final String audio;

  static WordPart? from(dynamic raw) {
    if (raw is String) {
      final r = raw.trim();
      return r.isEmpty
          ? null
          : WordPart(roman: r, deva: '', hold: 1.5, say: '', audio: '');
    }
    if (raw is! Map) return null;
    final roman = _str(raw['roman']);
    final deva = _str(raw['deva']);
    if (roman.isEmpty && deva.isEmpty) return null;
    final hold = _num(raw['hold']).toDouble();
    return WordPart(
      roman: roman,
      deva: deva,
      hold: hold > 0 ? hold : 1.5,
      say: _str(raw['say']),
      audio: _str(raw['audio']),
    );
  }
}

class Word {
  const Word({
    required this.key,
    required this.word,
    required this.deva,
    required this.translit,
    required this.phonetic,
    required this.parts,
    required this.audioMale,
    required this.audioFemale,
    required this.organ,
    required this.origin,
    required this.benefit,
    required this.meaning,
    required this.mouthPos,
    required this.resonance,
    required this.mistake,
    required this.tip,
    required this.categories,
    required this.gender,
    required this.time,
    required this.price,
    required this.img,
    this.audio = '',
    this.description = '',
    this.meanings = const [],
    this.stage = '',
    this.video = '',
    this.videoPoster = '',
    this.images = const [],
    this.stages = const [],
    this.notes = '',
  });

  final String key;
  final String word;
  final String deva;
  final String translit;
  final String phonetic;
  final List<WordPart> parts;
  final String audioMale;
  final String audioFemale;
  final String organ;
  final String origin;
  final String benefit;
  final String meaning;
  final String mouthPos;
  final String resonance;
  final String mistake;
  final String tip;
  final List<String> categories;

  /// 'M', 'F' or 'both'.
  final String gender;

  /// 'morning', 'evening', 'night' or 'any'.
  final String time;

  final num price;
  final String img;

  /// The one recording of this word, uploaded from admin mode (Cloudflare
  /// R2). Empty means the app falls back to text-to-speech.
  final String audio;

  /// A longer write-up than [meaning], from admin mode. Optional.
  final String description;

  /// Several short meanings, from admin mode. Optional.
  final List<String> meanings;

  /// An optional per-word stage label. Stored, not used by the user flow —
  /// stages are still worked out from practice minutes.
  final String stage;

  /// A video for this word (Cloudflare R2), from admin mode. Optional.
  final String video;

  /// Still shown before the video plays. Optional.
  final String videoPoster;

  /// More pictures for this word, from admin mode. Optional.
  final List<String> images;

  /// Ordered practice stages written for this word (title + text), from
  /// admin mode. Optional; the practice flow still works them out itself.
  final List<WordStage> stages;

  /// Free notes shown under the meanings. Optional.
  final String notes;

  /// The recording to play: this word's own voice first, then the older
  /// male/female fields the studio used to fill.
  String get voice => audio.isNotEmpty
      ? audio
      : (audioMale.isNotEmpty ? audioMale : audioFemale);

  /// Drop paid fields so a locked client never keeps public URLs in memory.
  Word stripPaid() {
    return Word(
      key: key,
      word: word,
      deva: deva,
      translit: translit,
      phonetic: phonetic,
      parts: [for (final p in parts) WordPart(roman: p.roman, deva: p.deva, hold: p.hold, say: p.say, audio: '')],
      audioMale: '',
      audioFemale: '',
      organ: organ,
      origin: origin,
      benefit: benefit,
      meaning: '',
      mouthPos: mouthPos,
      resonance: resonance,
      mistake: mistake,
      tip: tip,
      categories: categories,
      gender: gender,
      time: time,
      price: price,
      img: img,
      audio: '',
      description: description,
      meanings: const [],
      stage: stage,
      video: '',
      videoPoster: '',
      images: images,
      stages: [for (final s in stages) WordStage(title: s.title, text: s.text)],
      notes: notes,
    );
  }

  /// Overlay a wordsPrivate /api/content/word payload onto this preview word.
  Word withPaid(Map<String, dynamic> paid) {
    String s(dynamic v) => v == null ? '' : '$v'.trim();
    final nextParts = <WordPart>[];
    final partsAudio = paid['partsAudio'];
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      final a = partsAudio is List && i < partsAudio.length ? s(partsAudio[i]) : p.audio;
      nextParts.add(WordPart(roman: p.roman, deva: p.deva, hold: p.hold, say: p.say, audio: a.isNotEmpty ? a : p.audio));
    }
    final nextStages = <WordStage>[];
    final stagesMedia = paid['stagesMedia'];
    if (paid['stages'] is List) {
      for (final raw in paid['stages'] as List) {
        final st = WordStage.from(raw);
        if (st != null) nextStages.add(st);
      }
    } else {
      for (var i = 0; i < stages.length; i++) {
        final st = stages[i];
        var audio = st.audio;
        var video = st.video;
        if (stagesMedia is List && i < stagesMedia.length && stagesMedia[i] is Map) {
          final m = stagesMedia[i] as Map;
          final a = s(m['audio']);
          final v = s(m['video']);
          if (a.isNotEmpty) audio = a;
          if (v.isNotEmpty) video = v;
        }
        nextStages.add(WordStage(title: st.title, text: st.text, audio: audio, video: video));
      }
    }
    final meaningsRaw = paid['meanings'];
    return Word(
      key: key,
      word: word,
      deva: deva,
      translit: translit,
      phonetic: phonetic,
      parts: nextParts.isEmpty ? parts : nextParts,
      audioMale: s(paid['audioMale']).isNotEmpty ? s(paid['audioMale']) : audioMale,
      audioFemale: s(paid['audioFemale']).isNotEmpty ? s(paid['audioFemale']) : audioFemale,
      organ: organ,
      origin: origin,
      benefit: benefit,
      meaning: s(paid['meaning']).isNotEmpty ? s(paid['meaning']) : meaning,
      mouthPos: mouthPos,
      resonance: resonance,
      mistake: mistake,
      tip: tip,
      categories: categories,
      gender: gender,
      time: time,
      price: price,
      img: img,
      audio: s(paid['audio']).isNotEmpty ? s(paid['audio']) : audio,
      description: description,
      meanings: meaningsRaw is List
          ? [for (final m in meaningsRaw) '$m'.trim()]
          : meanings,
      stage: stage,
      video: () {
        final v = s(paid['video']);
        if (v.isNotEmpty) return v;
        final u = s(paid['videoUrl']);
        return u.isNotEmpty ? u : video;
      }(),
      videoPoster: s(paid['videoPoster']).isNotEmpty ? s(paid['videoPoster']) : videoPoster,
      images: images,
      stages: nextStages.isEmpty ? stages : nextStages,
      notes: notes,
    );
  }

  /// The same shape [from] reads, for the admin editor and the cache.
  Map<String, dynamic> toMap() => {
        'key': key,
        'word': word,
        'deva': deva,
        'translit': translit,
        'phonetic': phonetic,
        'parts': [
          for (final p in parts)
            {
              'roman': p.roman,
              'deva': p.deva,
              'hold': p.hold,
              'say': p.say,
              'audio': p.audio,
            }
        ],
        'audioMale': audioMale,
        'audioFemale': audioFemale,
        'organ': organ,
        'origin': origin,
        'benefit': benefit,
        'meaning': meaning,
        'mouthPos': mouthPos,
        'resonance': resonance,
        'mistake': mistake,
        'tip': tip,
        'categories': categories,
        'gender': gender,
        'time': time,
        'price': price,
        'img': img,
        'audio': audio,
        'description': description,
        'meanings': meanings,
        'stage': stage,
        'video': video,
        'videoPoster': videoPoster,
        'images': images,
        'stages': [for (final st in stages) st.toMap()],
        'notes': notes,
      };

  /// Kept in step with [parts], the way part073.js keeps `syllables` filled
  /// from `parts` so every screen that already drew syllables keeps working.
  List<String> get syllables =>
      parts.map((p) => p.roman.isNotEmpty ? p.roman : p.deva).toList();

  /// Returns null for anything that is not a usable word — same test as the
  /// web: no `word` string, no record. A list is filtered on this, never
  /// patched around it.
  static Word? from(dynamic raw) {
    if (raw is! Map) return null;
    final w = _str(raw['word']);
    if (w.isEmpty) return null;

    var parts = <WordPart>[];
    final rawParts = raw['parts'];
    if (rawParts is List) {
      parts =
          rawParts.map(WordPart.from).whereType<WordPart>().take(5).toList();
    }

    // Older records carry `syllables` and no `parts`; build the boxes from
    // them rather than showing nothing.
    if (parts.isEmpty && raw['syllables'] is List) {
      parts = (raw['syllables'] as List)
          .take(5)
          .map((s) =>
              WordPart(roman: '$s', deva: '', hold: 1.5, say: '', audio: ''))
          .toList();
    }

    final phonetic = _str(raw['phonetic']);
    final gender = _str(raw['gender']);
    final time = _str(raw['time']);

    return Word(
      key: _str(raw['key']).isEmpty
          ? w.toLowerCase().replaceAll(RegExp(r'\s+'), '-')
          : _str(raw['key']).toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
      word: w,
      deva: _str(raw['deva']),
      translit: _str(raw['translit']),
      phonetic: phonetic.isNotEmpty
          ? phonetic
          : parts.map((p) => p.roman).join(' · '),
      parts: parts,
      audioMale: _str(raw['audioMale']),
      audioFemale: _str(raw['audioFemale']),
      organ: _str(raw['organ']),
      origin:
          _str(raw['origin']).isEmpty ? 'Natural Origin' : _str(raw['origin']),
      benefit: _str(raw['benefit']),
      meaning: _str(raw['meaning']),
      mouthPos: _str(raw['mouthPos']),
      resonance: _str(raw['resonance']),
      mistake: _str(raw['mistake']),
      tip: _str(raw['tip']),
      categories: raw['categories'] is List
          ? (raw['categories'] as List).map((c) => '$c').toList()
          : const [],
      gender: const ['M', 'F', 'both'].contains(gender) ? gender : 'both',
      time: const ['morning', 'evening', 'night', 'any'].contains(time)
          ? time
          : 'any',
      price: _num(raw['price']),
      img: _str(raw['img']),
      audio: _str(raw['audio']),
      description: _str(raw['description']),
      meanings: raw['meanings'] is List
          ? (raw['meanings'] as List)
              .map((m) => '$m'.trim())
              .where((m) => m.isNotEmpty)
              .toList()
          : const [],
      stage: _str(raw['stage']),
      video: _str(raw['video']),
      videoPoster: _str(raw['videoPoster']),
      images: raw['images'] is List
          ? (raw['images'] as List).map((m) => '$m'.trim()).where((m) => m.startsWith('http')).toList()
          : const [],
      stages: raw['stages'] is List
          ? (raw['stages'] as List).map(WordStage.from).whereType<WordStage>().toList()
          : const [],
      notes: _str(raw['notes']),
    );
  }
}

/// One written practice stage of a word (admin mode).
class WordStage {
  const WordStage({required this.title, required this.text, this.audio = '', this.video = ''});
  final String title;
  final String text;
  final String audio;
  final String video;

  Map<String, dynamic> toMap() => {'title': title, 'text': text, 'audio': audio, 'video': video};

  static WordStage? from(dynamic raw) {
    if (raw is! Map) return null;
    final t = '${raw['title'] ?? ''}'.trim();
    final x = '${raw['text'] ?? ''}'.trim();
    if (t.isEmpty && x.isEmpty) return null;
    return WordStage(title: t, text: x, audio: '${raw['audio'] ?? ''}'.trim(), video: '${raw['video'] ?? ''}'.trim());
  }
}

/// An eBook — content/books. Thin by design, same as the web.
class Book {
  const Book({
    required this.key,
    required this.title,
    required this.sub,
    required this.cover,
    required this.price,
    required this.pages,
  });

  final String key;
  final String title;
  final String sub;
  final String cover;
  final num price;
  final int pages;

  static Book? from(dynamic raw) {
    if (raw is! Map) return null;
    final key = _str(raw['key']);
    final title = _str(raw['title']);
    // The web requires both and drops the record otherwise.
    if (key.isEmpty || title.isEmpty) return null;
    return Book(
      key: key,
      title: title,
      sub: _str(raw['sub']),
      cover: _str(raw['cover']).isEmpty ? _str(raw['img']) : _str(raw['cover']),
      price: _num(raw['price']),
      pages: _num(raw['pages']).toInt(),
    );
  }
}

/// A Meaning Store entry — content/meanings. A name, a price and a picture.
class Meaning {
  const Meaning({
    required this.key,
    required this.name,
    required this.price,
    required this.img,
    required this.sub,
  });

  final String key;
  final String name;
  final num price;
  final String img;
  final String sub;

  static Meaning? from(dynamic raw) {
    if (raw is! Map) return null;
    final name =
        _str(raw['name']).isEmpty ? _str(raw['word']) : _str(raw['name']);
    if (name.isEmpty) return null;
    return Meaning(
      key: _str(raw['key']).isEmpty
          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')
          : _str(raw['key']),
      name: name,
      price: _num(raw['price']),
      img: _str(raw['img']),
      sub: _str(raw['sub']),
    );
  }
}

/// A Word Atelier shelf — content/words. A name and a root.
class Shelf {
  const Shelf({required this.key, required this.name, required this.root});

  final String key;
  final String name;
  final String root;

  static Shelf? from(dynamic raw) {
    if (raw is! Map) return null;
    final name = _str(raw['name']);
    if (name.isEmpty) return null;
    return Shelf(
      key: _str(raw['key']).isEmpty
          ? name.toLowerCase().replaceAll(RegExp(r'\s+'), '-')
          : _str(raw['key']),
      name: name,
      root: _str(raw['root']),
    );
  }
}

String _str(dynamic v) => v == null ? '' : '$v'.trim();

num _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v) ?? 0;
  return 0;
}
