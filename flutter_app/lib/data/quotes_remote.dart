/// Quotes to live by, published from admin mode.
///
/// One Firestore document, `content/quotes` (public read, admin write):
///
///   {
///     byDate: { '2026-09-28': 'A line for that day', ... },
///     queue:  [ 'line', 'line', ... ],   // used, in turn, for days
///                                        // without a dated line
///     live:   'optional line pinned for today, over everything',
///     updatedAt, updatedBy
///   }
///
/// Same contract as the rest of the content: the seven built-in lines ship
/// with the app, the last copy seen is kept on the phone, and the document
/// is watched so a change reaches every phone without a release.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';

String quoteDayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class QuoteStore extends ChangeNotifier {
  QuoteStore._();
  static final QuoteStore instance = QuoteStore._();

  static const _kCache = 'nwsb_content_quotes_v1';

  Map<String, String> _byDate = const {};
  List<String> _queue = const [];
  String _live = '';
  bool _started = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  Map<String, String> get byDate => _byDate;
  List<String> get queue => _queue;
  String get live => _live;

  /// The published line for [day], or '' when admin mode has none for it.
  String lineFor(DateTime day) {
    final dated = (_byDate[quoteDayKey(day)] ?? '').trim();
    if (dated.isNotEmpty) return dated;
    if (_queue.isEmpty) return '';
    final n = DateTime.utc(day.year, day.month, day.day)
            .difference(DateTime.utc(2024, 1, 1))
            .inDays;
    return _queue[n % _queue.length];
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw != null && raw.isNotEmpty) _apply(jsonDecode(raw));
    } catch (_) {}
    if (!NwsbFirebase.ready) return;
    _sub = FirebaseFirestore.instance
        .collection('content')
        .doc('quotes')
        .snapshots()
        .listen((snap) {
      if (snap.metadata.isFromCache && !snap.exists) return;
      final d = snap.data() ?? const <String, dynamic>{};
      final clean = <String, dynamic>{
        'byDate': d['byDate'] is Map ? d['byDate'] : const {},
        'queue': d['queue'] is List ? d['queue'] : const [],
        'live': d['live'] is String ? d['live'] : '',
      };
      _apply(clean);
      SharedPreferences.getInstance()
          .then((p) => p.setString(_kCache, jsonEncode(clean)))
          .catchError((_) => true);
    }, onError: (e) => debugPrint('NowssB quotes: $e'));
  }

  void _apply(dynamic raw) {
    if (raw is! Map) return;
    final by = raw['byDate'];
    _byDate = {
      if (by is Map)
        for (final e in by.entries)
          if ('${e.value}'.trim().isNotEmpty) '${e.key}': '${e.value}'.trim(),
    };
    final q = raw['queue'];
    _queue = [
      if (q is List)
        for (final s in q)
          if ('$s'.trim().isNotEmpty) '$s'.trim(),
    ];
    _live = '${raw['live'] ?? ''}'.trim();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
