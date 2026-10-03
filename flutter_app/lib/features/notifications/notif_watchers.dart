/// Two live triggers that need the app's own data:
///
///  · the inbox — users/{uid}/notifications. Every row written after this
///    session started is drawn once (nid `n_<docId>`, the same id the
///    server push carries, so a row that was also pushed is not drawn
///    twice). This also covers rows written straight to Firestore with no
///    push (e.g. a request fulfilled from the in-app admin console).
///  · new content — an ebook or word published to the library (Firestore
///    content/books, words) that this phone has not seen before.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/content.dart';
import '../../data/firebase.dart';
import '../../data/home_widget_sync.dart';
import 'notif_categories.dart';
import 'notif_center.dart';

class NotifWatchers {
  NotifWatchers._();
  static final NotifWatchers instance = NotifWatchers._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _inbox;
  String? _uid;
  bool _baseline = false;
  DateTime _lastRequestNotice = DateTime.fromMillisecondsSinceEpoch(0);

  static String routeForInbox(Map<String, dynamic> d) {
    final r = '${d['route'] ?? ''}';
    if (r.isNotEmpty) return r;
    final wordKey = '${d['wordKey'] ?? ''}';
    if (wordKey.isNotEmpty) return 'word:$wordKey';
    return NotifCategories.forKind('${d['kind'] ?? d['type'] ?? ''}').defaultRoute;
  }

  void bind(String? uid) {
    if (uid == _uid) return;
    _inbox?.cancel();
    _inbox = null;
    _uid = uid;
    _baseline = false;
    if (uid == null || !NwsbFirebase.ready) return;
    try {
      _inbox = FirebaseFirestore.instance
          .collection('users/$uid/notifications')
          .orderBy('at', descending: true)
          .limit(15)
          .snapshots()
          .listen(_onInbox, onError: (Object e) => debugPrint('NowssB inbox watch: $e'));
    } catch (_) {}
  }

  void _onInbox(QuerySnapshot<Map<String, dynamic>> snap) {
    // The first answer is what was already there.
    if (!_baseline) {
      _baseline = true;
      return;
    }
    for (final ch in snap.docChanges) {
      if (ch.type != DocumentChangeType.added) continue;
      final d = ch.doc.data() ?? {};
      if (d['read'] == true || ch.doc.metadata.hasPendingWrites) continue;
      final cat = NotifCategories.forKind('${d['kind'] ?? d['type'] ?? ''}');
      if (cat.id == NotifCategories.requests.id) _lastRequestNotice = DateTime.now();
      unawaited(NotifCenter.instance.present(NwsbNotice(
        category: cat,
        title: '${d['title'] ?? 'NowssB'}',
        body: '${d['body'] ?? ''}',
        route: routeForInbox(d),
        key: 'n_${ch.doc.id}',
      )));
    }
  }

  // ── new content ──
  static const _kBooks = 'nwsb_notif_known_books';
  static const _kWords = 'nwsb_notif_known_words';
  static const _kSince = 'nwsb_notif_known_since';

  /// First run (and the first minutes of it): whatever arrives is the
  /// starting catalogue, not news.
  static const settle = Duration(minutes: 3);
  bool _content = false;
  Timer? _debounce;

  void startContent() {
    if (_content) return;
    _content = true;
    ContentStore.instance.addListener(_contentChanged);
    _contentChanged();
  }

  void _contentChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(_checkContent()));
  }

  /// New keys in [now] that are not in [known] (pure, tested).
  static List<String> fresh(Iterable<String> now, Set<String> known) =>
      [for (final k in now) if (k.isNotEmpty && !known.contains(k)) k];

  Future<void> _checkContent() async {
    try {
      final p = await SharedPreferences.getInstance();
      final store = ContentStore.instance;
      final books = {for (final b in store.books) b.key: b};
      final words = {for (final w in store.library) w.key: w};
      final since = p.getInt(_kSince);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final knownBooks = _set(p.getString(_kBooks));
      final knownWords = _set(p.getString(_kWords));
      final settling = since == null || nowMs - since < settle.inMilliseconds;
      final newBooks = fresh(books.keys, knownBooks);
      final newWords = fresh(words.keys, knownWords);
      if (since == null) await p.setInt(_kSince, nowMs);
      if (newBooks.isEmpty && newWords.isEmpty) return;
      await p.setString(_kBooks, jsonEncode({...knownBooks, ...books.keys}.toList()));
      await p.setString(_kWords, jsonEncode({...knownWords, ...words.keys}.toList()));
      if (settling) return;
      if (newBooks.isNotEmpty) {
        final b = books[newBooks.first]!;
        await NotifCenter.instance.present(NwsbNotice(
          category: NotifCategories.newContent,
          title: newBooks.length == 1 ? 'New ebook · ${b.title}' : '${newBooks.length} new ebooks',
          body: newBooks.length == 1 && b.sub.trim().isNotEmpty ? b.sub.trim() : 'Now in the NowssB ebook store.',
          route: 'ebooks',
          key: 'books:${newBooks.join(',')}',
        ));
      }
      // A word someone asked for already got its own "request fulfilled".
      if (newWords.isNotEmpty && DateTime.now().difference(_lastRequestNotice) > const Duration(minutes: 30)) {
        final w = words[newWords.first]!;
        final line = HomeWidgetSync.lineFor(w);
        await NotifCenter.instance.present(NwsbNotice(
          category: NotifCategories.newContent,
          title: newWords.length == 1 ? 'New word · ${w.word}' : '${newWords.length} new words',
          body: newWords.length == 1
              ? (line.isEmpty ? 'Just added to the library.' : line)
              : 'Including ${w.word}. Open one and practise it today.',
          route: 'word:${w.key}',
          key: 'words:${newWords.take(20).join(',')}',
        ));
      }
    } catch (e) {
      debugPrint('NowssB content watch: $e');
    }
  }

  static Set<String> _set(String? raw) {
    try {
      final v = jsonDecode(raw ?? '[]');
      if (v is List) return v.map((e) => '$e').toSet();
    } catch (_) {}
    return {};
  }
}
