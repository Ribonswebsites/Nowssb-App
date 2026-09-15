/// Persisted user word requests + admin fulfillment (SharedPreferences).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<WordRequest> submit({required String word, String notes = ''}) async {
    await ensureLoaded();
    final cleaned = word.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Word is required');
    }
    final req = WordRequest(
      id: 'wr_${DateTime.now().millisecondsSinceEpoch}',
      word: cleaned,
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    _items.insert(0, req);
    await _persist();
    notifyListeners();
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
