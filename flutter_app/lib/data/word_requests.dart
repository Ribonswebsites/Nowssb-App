/// Word requests: kept on this phone (the person's own list) AND sent to
/// Firestore `requests` — the same collection the website writes and the
/// studio / admin mode reads. A request made while signed out (or offline)
/// is parked and goes out the next time someone is signed in.
library;

import 'app_control.dart';
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase.dart';

class WordRequest {
  WordRequest({
    required this.id,
    required this.word,
    required this.notes,
    required this.createdAt,
    this.fulfilled = false,
    this.fulfilledAt,
  });

  final String id;
  final String word;
  final String notes;
  final DateTime createdAt;
  bool fulfilled;
  DateTime? fulfilledAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'fulfilled': fulfilled,
        'fulfilledAt': fulfilledAt?.toIso8601String(),
      };

  factory WordRequest.fromJson(Map<String, dynamic> j) => WordRequest(
        id: j['id'] as String? ?? '',
        word: j['word'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        fulfilled: j['fulfilled'] as bool? ?? false,
        fulfilledAt: j['fulfilledAt'] == null
            ? null
            : DateTime.tryParse(j['fulfilledAt'] as String),
      );
}

class WordRequestStore extends ChangeNotifier {
  WordRequestStore._();
  static final WordRequestStore instance = WordRequestStore._();

  static const _prefsKey = 'nwsb_word_requests_v1';
  static const _queueKey = 'nwsb_word_requests_outbox_v1';
  StreamSubscription<User?>? _authSub;

  /// Flushes parked requests whenever someone signs in.
  void startSync() {
    if (!NwsbFirebase.ready || _authSub != null) return;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (u != null) unawaited(_flush());
    });
  }

  Map<String, dynamic> _row(User u, String word, String notes, int at, [String kind = 'word']) => {
        'kind': kind,
        'word': word.length > 80 ? word.substring(0, 80) : word,
        'notes': notes.length > 500 ? notes.substring(0, 500) : notes,
        'uid': u.uid,
        'email': u.email,
        'name': u.displayName,
        'status': 'new',
        'at': at,
        'source': 'flutter',
      };

  /// One document per request (`{uid}_{at}`), so a retry or a flush of a
  /// parked copy can never create a second request.
  DocumentReference<Map<String, dynamic>> _doc(User u, int at) =>
      FirebaseFirestore.instance.collection('requests').doc('${u.uid}_$at');

  /// Sends one request, or parks it. Never throws.
  Future<bool> _send(String word, String notes, int at, [String kind = 'word']) async {
    final u = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    if (u != null) {
      try {
        await _doc(u, at).set(_row(u, word, notes, at, kind)).timeout(const Duration(seconds: 12));
        return true;
      } on TimeoutException {
        // Offline: Firestore keeps the write queued and sends it when the
        // phone is back online. Parking a copy too would send it twice.
        return true;
      } catch (e) {
        debugPrint('NowssB request not sent: $e');
      }
    }
    try {
      final p = await SharedPreferences.getInstance();
      final q = p.getStringList(_queueKey) ?? <String>[];
      // Parked under the account that made it ('' = signed out).
      q.add(jsonEncode({'word': word, 'notes': notes, 'at': at, 'kind': kind, 'uid': u?.uid ?? ''}));
      await p.setStringList(_queueKey, q.length > 30 ? q.sublist(q.length - 30) : q);
    } catch (_) {}
    return false;
  }

  /// Sends parked requests that belong to the signed-in account (or were made
  /// signed out); another account's parked requests stay parked for it.
  Future<void> _flush() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final p = await SharedPreferences.getInstance();
    final q = p.getStringList(_queueKey) ?? const <String>[];
    if (q.isEmpty) return;
    await p.remove(_queueKey);
    final keep = <String>[];
    for (final raw in q) {
      try {
        final m = jsonDecode(raw) as Map;
        final owner = '${m['uid'] ?? ''}';
        if (owner.isNotEmpty && owner != u.uid) {
          keep.add(raw);
          continue;
        }
        final at = (m['at'] as num).toInt();
        final ref = _doc(u, at);
        try {
          await ref.set(_row(u, '${m['word']}', '${m['notes'] ?? ''}', at, '${m['kind'] ?? 'word'}'));
        } catch (_) {
          // Already delivered earlier (the doc exists and only admins may
          // update it): drop the parked copy. Otherwise keep it for later.
          final have = await ref.get().then((d) => d.exists, onError: (_) => false);
          if (!have) keep.add(raw);
        }
      } catch (_) {
        keep.add(raw);
      }
    }
    if (keep.isNotEmpty) {
      final now = p.getStringList(_queueKey) ?? <String>[];
      await p.setStringList(_queueKey, [...keep, ...now]);
    }
  }

  final List<WordRequest> _items = [];
  bool _loaded = false;

  List<WordRequest> get items => List.unmodifiable(_items);
  List<WordRequest> get pending =>
      _items.where((e) => !e.fulfilled).toList(growable: false);
  List<WordRequest> get fulfilled =>
      _items.where((e) => e.fulfilled).toList(growable: false);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            _items.add(WordRequest.fromJson(e));
          } else if (e is Map) {
            _items.add(WordRequest.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      } catch (_) {
        // Corrupt prefs — start fresh.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  /// [kind] 'word' (default), 'sentence', 'healing' or 'verify' — the admin
  /// Requests queue shows it.
  Future<WordRequest> submit({required String word, String notes = '', String kind = 'word'}) async {
    await ensureLoaded();
    final cleaned = word.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Word is required');
    }
    final stop = AppControl.instance.blockFor('requests');
    if (stop != null) throw ArgumentError(stop);
    final req = WordRequest(
      id: 'wr_${DateTime.now().millisecondsSinceEpoch}',
      word: cleaned,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    _items.insert(0, req);
    await _persist();
    notifyListeners();
    unawaited(_send(req.word, req.notes, req.createdAt.millisecondsSinceEpoch, kind));
    return req;
  }

  Future<void> markFulfilled(String id) async {
    await ensureLoaded();
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i].fulfilled = true;
    _items[i].fulfilledAt = DateTime.now();
    await _persist();
    notifyListeners();
  }

  Future<void> reopen(String id) async {
    await ensureLoaded();
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _items[i].fulfilled = false;
    _items[i].fulfilledAt = null;
    await _persist();
    notifyListeners();
  }
}
