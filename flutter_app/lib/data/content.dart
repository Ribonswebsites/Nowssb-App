/// Content, on the same three-stage contract the website uses.
///
/// app/js/part069.js and part073.js both do this and this file is the port
/// of it. The order matters and it is not arbitrary:
///
///   1. What ships. Bundled JSON, read from the app itself, so no screen is
///      ever empty — not on first launch, not on a dead network, not while
///      Firestore is still connecting.
///   2. The last copy seen. Written to disk every time Firestore answers, so
///      a publish you already received survives being offline.
///   3. Firestore, WATCHED rather than fetched. A word published from the
///      studio reaches this app the moment it reaches the website, with no
///      Play release and no restart.
///
/// Each stage only ever overwrites the one before it if it actually has
/// something — an empty snapshot never blanks a screen that was full.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';
import 'models.dart';

class ContentStore extends ChangeNotifier {
  ContentStore._();
  static final ContentStore instance = ContentStore._();

  static const _kLibrary = 'nwsb_content_library';
  static const _kBooks = 'nwsb_content_books';
  static const _kWords = 'nwsb_content_words';
  static const _kMeanings = 'nwsb_content_meanings';

  List<Word> _library = const [];
  List<Book> _books = const [];
  List<Shelf> _shelves = const [];
  List<Meaning> _meanings = const [];

  List<Word> get library => _library;
  List<Book> get books => _books;
  List<Shelf> get shelves => _shelves;
  List<Meaning> get meanings => _meanings;

  bool _started = false;
  final List<StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _subs = [];

  /// Stages one and two, both synchronous as far as the UI is concerned:
  /// by the time the first frame is built there is already something to
  /// draw. Stage three is started and left running.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _loadShipped();
    await _loadCached();
    notifyListeners();

    _watch();
  }

  // ── 1. What ships ──────────────────────────────────────────────────
  Future<void> _loadShipped() async {
    _library = await _bundle('assets/content/library.json', Word.from);
    _books = await _bundle('assets/content/books.json', Book.from);
    _shelves = await _bundle('assets/content/words.json', Shelf.from);
    _meanings = await _bundle('assets/content/meanings.json', Meaning.from);
  }

  Future<List<T>> _bundle<T>(String path, T? Function(dynamic) parse) async {
    try {
      final raw = jsonDecode(await rootBundle.loadString(path));
      final items = raw is Map ? raw['items'] : raw;
      if (items is! List) return const [];
      return items.map(parse).whereType<T>().toList();
    } catch (e) {
      // A missing bundled file is not fatal — Firestore is still coming.
      debugPrint('NowssB content: no shipped copy at $path ($e)');
      return <T>[];
    }
  }

  // ── 2. The last copy seen ──────────────────────────────────────────
  Future<void> _loadCached() async {
    final p = await SharedPreferences.getInstance();
    _library = _cached(p, _kLibrary, Word.from) ?? _library;
    _books = _cached(p, _kBooks, Book.from) ?? _books;
    _shelves = _cached(p, _kWords, Shelf.from) ?? _shelves;
    _meanings = _cached(p, _kMeanings, Meaning.from) ?? _meanings;
  }

  List<T>? _cached<T>(
      SharedPreferences p, String key, T? Function(dynamic) parse) {
    final s = p.getString(key);
    if (s == null || s.isEmpty) return null;
    try {
      final raw = jsonDecode(s);
      if (raw is! List) return null;
      final out = raw.map(parse).whereType<T>().toList();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(String key, List<dynamic> raw) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, jsonEncode(raw));
    } catch (_) {
      // Out of disk, or a platform that refuses. The app still works; it
      // just starts from the shipped copy next time.
    }
  }

  // ── 3. Firestore, watched ──────────────────────────────────────────
  void _watch() {
    // No Firebase on this build yet — see lib/data/firebase.dart. The two
    // local stages above already ran, so the app is full rather than empty;
    // it just does not receive published edits until google-services.json
    // lands. Touching FirebaseFirestore.instance without an initialised app
    // throws, so this is a return and not a try/catch.
    if (!NwsbFirebase.ready) return;

    final db = FirebaseFirestore.instance;
    _bind(db, 'library', _kLibrary, Word.from, (v) => _library = v);
    _bind(db, 'books', _kBooks, Book.from, (v) => _books = v);
    _bind(db, 'words', _kWords, Shelf.from, (v) => _shelves = v);
    _bind(db, 'meanings', _kMeanings, Meaning.from, (v) => _meanings = v);
  }

  void _bind<T>(
    FirebaseFirestore db,
    String docId,
    String cacheKey,
    T? Function(dynamic) parse,
    void Function(List<T>) assign,
  ) {
    _subs.add(
      db.collection('content').doc(docId).snapshots().listen(
        (snap) {
          if (!snap.exists) return;
          final items = snap.data()?['items'];
          if (items is! List) return;
          final clean = items.map(parse).whereType<T>().toList();
          // An empty or unparseable publish never blanks a full screen.
          if (clean.isEmpty) return;
          assign(clean);
          notifyListeners();
          _cache(cacheKey, items);
        },
        // Offline, or refused by the rules. The cache stands and the app
        // carries on — exactly what the web does.
        onError: (e) => debugPrint('NowssB content: $docId — $e'),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}
