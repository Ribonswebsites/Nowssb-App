/// Reader state — port of app/js/part065.js.
///
/// Preferences, per-page marks (highlights, notes, bookmarks) and reading
/// reminders live here so both the Meaning Reader and the eBook Reader open
/// the way they were last left. Nothing talks to a server.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'models.dart';
import 'notifications.dart';
import 'store_catalog.dart';

const kReaderFonts = ['Lora', 'Georgia', 'DM Sans', 'Iowan'];
const kReaderThemes = ['light', 'sepia', 'dark', 'black'];
const _kTest = bool.fromEnvironment('FLUTTER_TEST');

class ReaderPage {
  const ReaderPage({
    required this.chapter,
    required this.chapterName,
    required this.first,
    required this.title,
    this.root,
    this.body = const [],
    this.html,
    this.pending = false,
  });

  final int chapter;
  final String chapterName;
  final bool first;
  final String title;
  final String? root;
  final List<String> body;
  final String? html;
  final bool pending;

  String get plain {
    if (html != null && html!.isNotEmpty) {
      return html!
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    return [title, root ?? '', ...body].where((s) => s.isNotEmpty).join(' — ');
  }
}

class ReaderNote {
  const ReaderNote({
    required this.t,
    this.on = '',
    required this.at,
    this.auto = false,
  });

  final String t;
  final String on;
  final int at;
  final bool auto;

  Map<String, dynamic> toJson() => {
        't': t,
        'on': on,
        'at': at,
        if (auto) 'auto': 1,
      };

  static ReaderNote fromJson(Map<String, dynamic> m) => ReaderNote(
        t: '${m['t'] ?? ''}',
        on: '${m['on'] ?? ''}',
        at: (m['at'] is num)
            ? (m['at'] as num).toInt()
            : DateTime.now().millisecondsSinceEpoch,
        auto: m['auto'] == 1 || m['auto'] == true,
      );
}

class PageMarks {
  PageMarks({
    List<String>? hl,
    List<ReaderNote>? notes,
    this.mark = false,
  })  : hl = hl ?? [],
        notes = notes ?? [];

  final List<String> hl;
  final List<ReaderNote> notes;
  bool mark;

  Map<String, dynamic> toJson() => {
        'hl': hl,
        'notes': notes.map((n) => n.toJson()).toList(),
        'mark': mark,
      };

  static PageMarks fromJson(Map<String, dynamic>? m) {
    if (m == null) return PageMarks();
    return PageMarks(
      hl: [
        for (final v in (m['hl'] as List? ?? const []))
          if (v != null) '$v'
      ],
      notes: [
        for (final v in (m['notes'] as List? ?? const []))
          if (v is Map) ReaderNote.fromJson(Map<String, dynamic>.from(v))
      ],
      mark: m['mark'] == true,
    );
  }

  PageMarks copy() => PageMarks(
        hl: [...hl],
        notes: [...notes],
        mark: mark,
      );
}

class ReaderPrefs {
  const ReaderPrefs({
    this.theme = 'sepia',
    this.font = 'Lora',
    this.size = 18,
    this.spacing = 1,
    this.bright = 100,
  });

  final String theme;
  final String font;
  final int size;
  final int spacing;
  final int bright;

  ReaderPrefs copyWith({
    String? theme,
    String? font,
    int? size,
    int? spacing,
    int? bright,
  }) =>
      ReaderPrefs(
        theme: theme ?? this.theme,
        font: font ?? this.font,
        size: size ?? this.size,
        spacing: spacing ?? this.spacing,
        bright: bright ?? this.bright,
      );

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'font': font,
        'size': size,
        'spacing': spacing,
        'bright': bright,
      };

  static ReaderPrefs fromJson(Map<String, dynamic>? m) {
    if (m == null) return const ReaderPrefs();
    return ReaderPrefs(
      theme: kReaderThemes.contains(m['theme']) ? '${m['theme']}' : 'sepia',
      font: kReaderFonts.contains(m['font']) ? '${m['font']}' : 'Lora',
      size: _clampInt(m['size'], 14, 26, 18),
      spacing: _clampInt(m['spacing'], 0, 2, 1),
      bright: _clampInt(m['bright'], 35, 100, 100),
    );
  }
}

int _clampInt(dynamic v, int lo, int hi, int d) {
  final n = v is num ? v.toInt() : d;
  if (n < lo) return lo;
  if (n > hi) return hi;
  return n;
}

class ReaderReminder {
  const ReaderReminder({
    required this.at,
    required this.title,
    required this.which,
    required this.key,
    required this.idx,
  });

  final int at;
  final String title;
  final String which;
  final String key;
  final int idx;

  Map<String, dynamic> toJson() => {
        'at': at,
        'title': title,
        'which': which,
        'key': key,
        'idx': idx,
      };

  static ReaderReminder? fromJson(Map<String, dynamic> m) {
    final title = '${m['title'] ?? ''}';
    if (title.isEmpty) return null;
    return ReaderReminder(
      at: (m['at'] is num)
          ? (m['at'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
      title: title,
      which: '${m['which'] ?? 'meaning'}',
      key: '${m['key'] ?? ''}',
      idx: (m['idx'] is num) ? (m['idx'] as num).toInt() : 0,
    );
  }
}

class OpenedEpub {
  OpenedEpub({
    required this.key,
    required this.title,
    required this.sub,
    required this.pages,
    this.cover = '',
  });

  final String key;
  final String title;
  final String sub;
  final String cover;
  final List<ReaderPage> pages;
}

class ReaderStore extends ChangeNotifier {
  ReaderStore._();
  static final ReaderStore instance = ReaderStore._();

  static const _kPrefs = 'nwsb_reader_prefs';
  static const _kMarks = 'nwsb_reader_marks';
  static const _kRemind = 'nwsb_reader_reminders';
  static const _kLang = 'nwsb_reader_lang';
  static const _kFab = 'nwsb_rd_fab_pos';

  ReaderPrefs _prefs = const ReaderPrefs();
  Map<String, Map<String, PageMarks>> _marks = {};
  List<ReaderReminder> _reminders = [];
  String _lang = 'hi';
  double _fabX = 8;
  double _fabY = 280;
  final List<OpenedEpub> _epubs = [];
  Timer? _tick;
  bool _loaded = false;

  ReaderPrefs get prefs => _prefs;
  String get lang => _lang;
  double get fabX => _fabX;
  double get fabY => _fabY;
  List<OpenedEpub> get epubs => List.unmodifiable(_epubs);
  List<ReaderReminder> get reminders => List.unmodifiable(_reminders);

  @visibleForTesting
  void debugReset() {
    _prefs = const ReaderPrefs();
    _marks = {};
    _reminders = [];
    _lang = 'hi';
    _fabX = 8;
    _fabY = 280;
    _epubs.clear();
    _tick?.cancel();
    _tick = null;
    _loaded = false;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    try {
      final raw = p.getString(_kPrefs);
      if (raw != null) {
        _prefs = ReaderPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>?);
      }
    } catch (_) {}
    try {
      final raw = p.getString(_kMarks);
      if (raw != null) {
        final map = jsonDecode(raw);
        if (map is Map) {
          _marks = {
            for (final e in map.entries)
              if (e.value is Map)
                '${e.key}': {
                  for (final pge in (e.value as Map).entries)
                    '${pge.key}': PageMarks.fromJson(
                      pge.value is Map
                          ? Map<String, dynamic>.from(pge.value as Map)
                          : null,
                    ),
                },
          };
        }
      }
    } catch (_) {}
    try {
      final raw = p.getString(_kRemind);
      if (raw != null) {
        final list = jsonDecode(raw);
        if (list is List) {
          _reminders = [
            for (final v in list)
              if (v is Map)
                ReaderReminder.fromJson(Map<String, dynamic>.from(v))
          ].whereType<ReaderReminder>().toList();
        }
      }
    } catch (_) {}
    _lang = p.getString(_kLang) ?? 'hi';
    try {
      final raw = p.getString(_kFab);
      if (raw != null) {
        final pos = jsonDecode(raw);
        if (pos is Map) {
          _fabX = (pos['x'] is num) ? (pos['x'] as num).toDouble() : 8;
          _fabY = (pos['y'] is num) ? (pos['y'] as num).toDouble() : 280;
        }
      }
    } catch (_) {}
    notifyListeners();
    unawaited(dueReminders());
    _armTick();
  }

  void _armTick() {
    if (_kTest || _reminders.isEmpty || _tick != null) return;
    _tick = Timer.periodic(
        const Duration(minutes: 1), (_) => unawaited(dueReminders()));
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPrefs, jsonEncode(_prefs.toJson()));
  }

  Future<void> _saveMarks() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kMarks,
      jsonEncode({
        for (final e in _marks.entries)
          e.key: {
            for (final pge in e.value.entries) pge.key: pge.value.toJson(),
          },
      }),
    );
  }

  Future<void> _saveReminders() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kRemind, jsonEncode(_reminders.map((r) => r.toJson()).toList()));
  }

  Future<void> setPref({
    String? theme,
    String? font,
    int? size,
    int? spacing,
    int? bright,
  }) async {
    _prefs = _prefs.copyWith(
      theme: theme,
      font: font,
      size: size,
      spacing: spacing,
      bright: bright,
    );
    notifyListeners();
    await _savePrefs();
  }

  Future<void> cycleFont(int dir) async {
    var i = kReaderFonts.indexOf(_prefs.font);
    if (i < 0) i = 0;
    await setPref(
        font: kReaderFonts[
            (i + dir + kReaderFonts.length) % kReaderFonts.length]);
  }

  Future<void> setLang(String c) async {
    _lang = c;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, c);
  }

  Future<void> setFabPos(double x, double y) async {
    _fabX = x;
    _fabY = y;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFab, jsonEncode({'x': x.round(), 'y': y.round()}));
  }

  PageMarks pageMarks(String bookKey, int idx) {
    return _marks[bookKey]?['$idx']?.copy() ?? PageMarks();
  }

  Future<void> _putMarks(String bookKey, int idx, PageMarks v) async {
    final book = Map<String, PageMarks>.from(_marks[bookKey] ?? {});
    book['$idx'] = v.copy();
    _marks = {..._marks, bookKey: book};
    notifyListeners();
    await _saveMarks();
  }

  Future<void> addHighlight(String bookKey, int idx, String text) async {
    final t = text.trim();
    if (t.length < 2) return;
    final pm = pageMarks(bookKey, idx);
    if (!pm.hl.contains(t)) pm.hl.add(t);
    await _putMarks(bookKey, idx, pm);
  }

  Future<void> addNote(
    String bookKey,
    int idx, {
    required String t,
    String on = '',
    bool auto = false,
  }) async {
    final text = t.trim();
    if (text.isEmpty) return;
    final pm = pageMarks(bookKey, idx);
    pm.notes.add(ReaderNote(
      t: text,
      on: on,
      at: DateTime.now().millisecondsSinceEpoch,
      auto: auto,
    ));
    await _putMarks(bookKey, idx, pm);
  }

  Future<void> swipeHighlight(String bookKey, int idx, String text) async {
    final t = text.trim();
    if (t.length < 2) return;
    final pm = pageMarks(bookKey, idx);
    if (!pm.hl.contains(t)) pm.hl.add(t);
    final dup = pm.notes.any((n) => n.t == t);
    if (!dup) {
      pm.notes.add(ReaderNote(
        t: t,
        on: '',
        at: DateTime.now().millisecondsSinceEpoch,
        auto: true,
      ));
    }
    await _putMarks(bookKey, idx, pm);
  }

  Future<void> drop(String bookKey, int page, String kind, int i) async {
    final pm = pageMarks(bookKey, page);
    if (kind == 'hl') {
      if (i < 0 || i >= pm.hl.length) return;
      pm.hl.removeAt(i);
    } else {
      if (i < 0 || i >= pm.notes.length) return;
      pm.notes.removeAt(i);
    }
    await _putMarks(bookKey, page, pm);
  }

  Future<bool> toggleBookmark(String bookKey, int idx) async {
    final pm = pageMarks(bookKey, idx);
    pm.mark = !pm.mark;
    await _putMarks(bookKey, idx, pm);
    return pm.mark;
  }

  Future<void> clearBook(String bookKey) async {
    if (!_marks.containsKey(bookKey)) return;
    _marks = {..._marks}..remove(bookKey);
    notifyListeners();
    await _saveMarks();
  }

  List<({int page, String kind, int i, String t, String on, bool auto})>
      bookEntries(String bookKey) {
    final m = _marks[bookKey] ?? {};
    final out =
        <({int page, String kind, int i, String t, String on, bool auto})>[];
    for (final e in m.entries) {
      final page = int.tryParse(e.key) ?? 0;
      final pm = e.value;
      for (var i = 0; i < pm.hl.length; i++) {
        out.add((
          page: page,
          kind: 'hl',
          i: i,
          t: pm.hl[i],
          on: '',
          auto: false,
        ));
      }
      for (var i = 0; i < pm.notes.length; i++) {
        final n = pm.notes[i];
        if (n.auto && pm.hl.contains(n.t)) {
          final at = out.indexWhere(
              (r) => r.page == page && r.kind == 'hl' && r.t == n.t);
          if (at >= 0) {
            out[at] = (
              page: out[at].page,
              kind: out[at].kind,
              i: out[at].i,
              t: out[at].t,
              on: out[at].on,
              auto: true,
            );
            continue;
          }
        }
        out.add((
          page: page,
          kind: 'notes',
          i: i,
          t: n.t,
          on: n.on,
          auto: n.auto,
        ));
      }
    }
    out.sort((a, b) {
      final p = a.page.compareTo(b.page);
      if (p != 0) return p;
      if (a.kind == b.kind) return a.i.compareTo(b.i);
      return a.kind == 'hl' ? -1 : 1;
    });
    return out;
  }

  Future<void> addReminder({
    required int minutes,
    required String title,
    required String which,
    required String key,
    required int idx,
  }) async {
    _reminders = [
      ..._reminders,
      ReaderReminder(
        at: DateTime.now().millisecondsSinceEpoch + minutes * 60000,
        title: title,
        which: which,
        key: key,
        idx: idx,
      ),
    ];
    await _saveReminders();
    _armTick();
    notifyListeners();
  }

  Future<void> dueReminders() async {
    if (_reminders.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final keep = <ReaderReminder>[];
    for (final r in _reminders) {
      if (r.at <= now) {
        await NotifStore.instance.notify(
          type: 'reader',
          title: 'Back to “${r.title}”',
          body: 'You asked to be reminded about this page.',
        );
      } else {
        keep.add(r);
      }
    }
    if (keep.length != _reminders.length) {
      _reminders = keep;
      await _saveReminders();
      if (_reminders.isEmpty) {
        _tick?.cancel();
        _tick = null;
      }
      notifyListeners();
    }
  }

  void rememberEpub(OpenedEpub book) {
    final at = _epubs.indexWhere((b) => b.key == book.key);
    if (at >= 0) {
      _epubs[at] = book;
    } else {
      _epubs.insert(0, book);
    }
    notifyListeners();
  }

  List<ReaderPage> meaningPages() {
    const src = kMsBaseMeanings;
    final byCat = <String, List<MsMeaning>>{};
    final order = <String>[];
    for (final m in src) {
      if (!byCat.containsKey(m.category)) {
        byCat[m.category] = [];
        order.add(m.category);
      }
      byCat[m.category]!.add(m);
    }
    final pages = <ReaderPage>[];
    var ch = 0;
    for (final cat in order) {
      ch++;
      final items = byCat[cat]!;
      for (var i = 0; i < items.length; i++) {
        final m = items[i];
        pages.add(ReaderPage(
          chapter: ch,
          chapterName: cat,
          first: i == 0,
          title: m.word,
          root: m.root,
          body: [
            'The word ${m.word} comes down to us through ${m.root.replaceFirst(' · ', ', from the root ')}.',
            'Spoken aloud, it is the sound that carries — not the spelling, and not the dictionary entry that came long after. The body answers the vibration first.',
            'Sit with it. Say it slowly. Notice where in you it lands before you reach for what it means.',
          ],
        ));
      }
    }
    return pages;
  }

  List<ReaderPage> bookPages(EbBook b, {List<ReaderPage>? epubPages}) {
    if (epubPages != null && epubPages.isNotEmpty) return epubPages;
    final opened = _epubs.where((e) => e.key == b.key).toList();
    if (opened.isNotEmpty && opened.first.pages.isNotEmpty) {
      return opened.first.pages;
    }
    final pages = <ReaderPage>[
      ReaderPage(
        chapter: 0,
        chapterName: 'About',
        first: true,
        title: b.title,
        root: b.sub,
        body: [b.about],
      ),
    ];
    for (var i = 0; i < b.contents.length; i++) {
      pages.add(ReaderPage(
        chapter: i + 1,
        chapterName: b.contents[i],
        first: true,
        title: b.contents[i],
        pending: true,
      ));
    }
    return pages;
  }

  List<EbBook> libraryBooks() {
    final live = ContentStore.instance.books;
    final merged = [...kEbBooks];
    final keys = {for (final b in kEbBooks) b.key};
    for (final b in live) {
      if (keys.contains(b.key)) continue;
      merged.add(EbBook(
        key: b.key,
        title: b.title,
        sub: b.sub,
        price: b.price,
        cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
        about: b.sub,
        contents: const ['Published from the NowssB studio'],
      ));
    }
    return merged;
  }
}
