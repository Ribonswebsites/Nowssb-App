/// Paid word payloads (BF-1).
///
/// Public `words/{key}` and `content/library` keep free preview fields only
/// once the migration has run. Entitled clients load meaning / audio / video
/// / stage media from `POST https://nowssb.com/api/content/word` (service
/// account reads `wordsPrivate/{key}`, with a legacy fallback to the public
/// doc during cutover). Never treat public docs as the source of paid URLs.
///
/// media.nowssb.com is still a public R2 bucket — signed URLs are a follow-up.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'entitlements.dart';
import 'firebase.dart';
import 'models.dart';

class WordPrivateStore {
  WordPrivateStore._();
  static final WordPrivateStore instance = WordPrivateStore._();

  static const endpoint = 'https://nowssb.com/api/content/word';

  final Map<String, Map<String, dynamic>> _paid = {};
  final Map<String, Future<Map<String, dynamic>?>> _inflight = {};

  /// Whose paid fields [_paid] holds. The cache lived for the whole process,
  /// so after a subscriber signed out, a free account or a guest on the same
  /// phone was shown the paid fields the subscriber had opened.
  String? _owner;

  void _forOwner() {
    String? uid;
    try {
      uid = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser?.uid : null;
    } catch (_) {}
    if (uid == _owner) return;
    _owner = uid;
    _paid.clear();
    _inflight.clear();
  }

  /// Merge any cached paid payload onto [w] while this account may open it.
  /// Safe when nothing is cached.
  Word apply(Word w) {
    _forOwner();
    if (!Entitlements.instance.canOpenWord(w)) return w;
    final paid = _paid[w.key] ?? _paid[w.word.toLowerCase()];
    if (paid == null || paid.isEmpty) return w;
    return w.withPaid(paid);
  }

  /// Fetch paid fields when this account may open [w]. No-ops for locked or
  /// free words that already carry their fields on the public doc.
  Future<Word> resolve(Word w) async {
    if (!Entitlements.instance.canOpenWord(w)) return w.stripPaid();
    final paid = await prefetch(w);
    if (paid == null || paid.isEmpty) {
      // Entitled but nothing private yet (free word / migration pending) —
      // keep whatever the public doc still has.
      return w;
    }
    return w.withPaid(paid);
  }

  Future<Map<String, dynamic>?> prefetch(Word w) async {
    _forOwner();
    if (!NwsbFirebase.ready) return _paid[w.key];
    if (!Entitlements.instance.canOpenWord(w)) return null;
    final key = w.key.isNotEmpty ? w.key : w.word.toLowerCase();
    if (key.isEmpty) return null;
    final hit = _paid[key];
    if (hit != null) return hit;
    final existing = _inflight[key];
    if (existing != null) return existing;
    final fut = _fetch(key, w);
    _inflight[key] = fut;
    try {
      return await fut;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<Map<String, dynamic>?> _fetch(String key, Word w) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return null;
      final token = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'key': key,
              'word': w.word,
              'price': w.price,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 403) return null;
      if (res.statusCode == 501) {
        debugPrint('NowssB word private: API not configured (${res.statusCode})');
        return null;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('NowssB word private: HTTP ${res.statusCode}');
        return null;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final paid = decoded['paid'];
      if (paid is! Map) return null;
      final map = Map<String, dynamic>.from(paid);
      // Signed out / switched while this was in flight: not theirs to keep.
      if (FirebaseAuth.instance.currentUser?.uid != user.uid) return null;
      _paid[key] = map;
      return map;
    } on TimeoutException {
      debugPrint('NowssB word private: timeout');
      return null;
    } catch (e) {
      debugPrint('NowssB word private: $e');
      return null;
    }
  }

  @visibleForTesting
  void debugPut(String key, Map<String, dynamic> paid) => _paid[key] = paid;

  @visibleForTesting
  void debugClear() {
    _paid.clear();
    _inflight.clear();
  }
}
