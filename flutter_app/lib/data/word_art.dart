/// One picture for a word, used everywhere that word is shown.
///
/// Uploading Aarogya on the library, the meaning card, the signature card,
/// or the ebook writes the same record. Every surface reads it back, so the
/// owner does not upload the picture again for each place the word appears.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';
import 'firebase.dart';
import 'models.dart';

class WordPicture {
  const WordPicture({this.image = '', this.video = '', this.scale = 1});

  final String image;
  final String video;
  final double scale;

  WordPicture copy({String? image, String? video, double? scale}) => WordPicture(
        image: image ?? this.image,
        video: video ?? this.video,
        scale: scale ?? this.scale,
      );

  Map<String, dynamic> toJson() => {
        'image': image,
        'video': video,
        'scale': scale,
      };

  static WordPicture from(dynamic raw) {
    if (raw is! Map) return const WordPicture();
    final z = raw['scale'];
    return WordPicture(
      image: '${raw['image'] ?? ''}',
      video: '${raw['video'] ?? ''}',
      scale: z is num ? z.toDouble() : 1,
    );
  }
}

class WordArt extends ChangeNotifier {
  WordArt._();
  static final instance = WordArt._();

  static const _kCache = 'nwsb_word_art_v1';

  final Map<String, WordPicture> _by = {};
  final Map<String, List<WordPicture>> _hist = {};
  // Kept so the Firestore listener is not cancelled.
  // ignore: unused_field
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  var _started = false;

  /// Letters and digits only, so "AAROGYA", "aarogya" and "Aarogya" are one key.
  static String keyOf(String word) =>
      word.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  bool tracked(String word) => _by.containsKey(keyOf(word));

  bool has(String word) {
    final p = _by[keyOf(word)];
    return p != null && (p.image.isNotEmpty || p.video.isNotEmpty);
  }

  bool canUndo(String word) => (_hist[keyOf(word)] ?? const []).isNotEmpty;

  String? imageOf(String word) {
    final p = _by[keyOf(word)];
    if (p == null || p.image.isEmpty) return null;
    return p.image;
  }

  String? videoOf(String word) {
    final p = _by[keyOf(word)];
    if (p == null || p.video.isEmpty) return null;
    return p.video;
  }

  double scaleOf(String word) {
    final p = _by[keyOf(word)];
    if (p == null) return 1;
    return p.scale.clamp(0.5, 2.6);
  }

  /// The picture to draw: the shared upload, else the published word image,
  /// else [fallback] (the bundled art).
  String imageFor(String word, String fallback) {
    final hit = imageOf(word);
    if (hit != null) return hit;
    final w = _libraryWord(word);
    final img = w?.img.trim() ?? '';
    if (img.isNotEmpty) return img;
    return fallback;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadCache();
    ContentStore.instance.addListener(notifyListeners);
    if (!NwsbFirebase.ready) return;
    _sub = FirebaseFirestore.instance.collection('word_art').snapshots().listen(
      (snap) {
        if (snap.metadata.isFromCache && snap.docs.isEmpty && _by.isNotEmpty) return;
        for (final d in snap.docs) {
          final m = d.data();
          _by[d.id] = WordPicture.from(m);
          final raw = m['history'];
          if (raw is List) {
            _hist[d.id] = [for (final h in raw) WordPicture.from(h)];
          }
        }
        notifyListeners();
        unawaited(_saveCache());
      },
      onError: (e) => debugPrint('NowssB word art: $e'),
    );
  }

  /// Saves the shared picture. [pushHistory] keeps the previous one for Undo.
  Future<void> set(
    String word, {
    String? image,
    String? video,
    double? scale,
    bool pushHistory = true,
  }) async {
    final k = keyOf(word);
    if (k.isEmpty) return;
    final prev = _by[k] ?? WordPicture(image: _libraryWord(word)?.img.trim() ?? '');
    final next = prev.copy(
      image: image,
      video: video,
      scale: scale == null ? null : scale.clamp(0.5, 2.6),
    );
    if (next.image == prev.image && next.video == prev.video && next.scale == prev.scale && _by.containsKey(k)) {
      return;
    }
    if (pushHistory) {
      final h = List<WordPicture>.from(_hist[k] ?? const []);
      h.add(prev);
      if (h.length > 12) h.removeAt(0);
      _hist[k] = h;
    }
    _by[k] = next;
    notifyListeners();
    await _saveCache();
    await _write(k, word, next);
  }

  Future<bool> undo(String word) async {
    final k = keyOf(word);
    final h = _hist[k];
    if (h == null || h.isEmpty) return false;
    final prev = h.removeLast();
    _by[k] = prev;
    notifyListeners();
    await _saveCache();
    await _write(k, word, prev);
    return true;
  }

  Future<void> _write(String k, String word, WordPicture pic) async {
    if (!NwsbFirebase.ready) return;
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('word_art').doc(k).set({
        'word': word,
        ...pic.toJson(),
        'history': [for (final h in _hist[k] ?? const <WordPicture>[]) h.toJson()],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final ref = db.collection('words').doc(k);
      final snap = await ref.get();
      final data = snap.data();
      if (snap.exists && data != null && '${data['word'] ?? ''}'.isNotEmpty) {
        await ref.set({'img': pic.image, 'imgScale': pic.scale}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('NowssB word art save: $e');
    }
  }

  Future<void> _loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw);
      if (map is! Map) return;
      map.forEach((k, v) {
        if (k is! String) return;
        if (v is Map && v['picture'] is Map) {
          _by[k] = WordPicture.from(v['picture']);
          final h = v['history'];
          if (h is List) _hist[k] = [for (final e in h) WordPicture.from(e)];
        } else {
          _by[k] = WordPicture.from(v);
        }
      });
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final out = <String, dynamic>{};
      for (final e in _by.entries) {
        out[e.key] = {
          'picture': e.value.toJson(),
          'history': [for (final h in _hist[e.key] ?? const <WordPicture>[]) h.toJson()],
        };
      }
      await p.setString(_kCache, jsonEncode(out));
    } catch (_) {}
  }

  Word? _libraryWord(String word) {
    final k = keyOf(word);
    if (k.isEmpty) return null;
    for (final w in ContentStore.instance.library) {
      if (keyOf(w.word) == k || keyOf(w.key) == k) return w;
    }
    return null;
  }
}
