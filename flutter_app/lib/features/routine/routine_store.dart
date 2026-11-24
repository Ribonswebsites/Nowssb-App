/// My routine: routines the user builds from their own words, kept on the
/// phone per account (signed out uses the device-wide key, each account its
/// own `_<uid>` key, the same split as PracticeProgress).
///
/// A routine is an ordered list of words, each with its own minutes, a time
/// of day, the days it runs on and an optional reminder. The reminders are
/// planned by NotifScheduler like every other local notice.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';
import '../../data/models.dart';

class RoutineItem {
  const RoutineItem({required this.wordKey, required this.word, this.minutes = 3});
  final String wordKey;
  final String word;
  final int minutes;

  RoutineItem copyWith({int? minutes}) => RoutineItem(wordKey: wordKey, word: word, minutes: minutes ?? this.minutes);

  Map<String, dynamic> toJson() => {'key': wordKey, 'word': word, 'min': minutes};

  static RoutineItem? fromJson(Object? m) {
    if (m is! Map) return null;
    final key = '${m['key'] ?? ''}';
    final word = '${m['word'] ?? ''}';
    if (key.isEmpty || word.isEmpty) return null;
    final min = m['min'] is num ? (m['min'] as num).toInt() : 3;
    return RoutineItem(wordKey: key, word: word, minutes: min.clamp(1, 60));
  }
}

class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.items,
    this.minuteOfDay = 7 * 60,
    this.days = const {1, 2, 3, 4, 5, 6, 7},
    this.reminder = false,
  });

  final String id;
  final String name;
  final List<RoutineItem> items;

  /// 0..1439, local time.
  final int minuteOfDay;

  /// DateTime.monday (1) .. DateTime.sunday (7).
  final Set<int> days;
  final bool reminder;

  int get totalMinutes => items.fold(0, (s, i) => s + i.minutes);

  Routine copyWith({
    String? name,
    List<RoutineItem>? items,
    int? minuteOfDay,
    Set<int>? days,
    bool? reminder,
  }) =>
      Routine(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
        days: days ?? this.days,
        reminder: reminder ?? this.reminder,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': [for (final i in items) i.toJson()],
        'at': minuteOfDay,
        'days': (days.toList()..sort()),
        'remind': reminder,
      };

  static Routine? fromJson(Object? m) {
    if (m is! Map) return null;
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return null;
    final items = <RoutineItem>[
      if (m['items'] is List)
        for (final e in m['items'] as List)
          if (RoutineItem.fromJson(e) case final RoutineItem i) i,
    ];
    final days = <int>{
      if (m['days'] is List)
        for (final d in m['days'] as List)
          if (d is num && d >= 1 && d <= 7) d.toInt(),
    };
    final at = m['at'] is num ? (m['at'] as num).toInt() : 7 * 60;
    return Routine(
      id: id,
      name: '${m['name'] ?? ''}'.trim().isEmpty ? 'My routine' : '${m['name']}'.trim(),
      items: items,
      minuteOfDay: at.clamp(0, 1439),
      days: days,
      reminder: m['remind'] == true,
    );
  }

  /// "Mon, Wed, Fri" / "Every day" / "Weekdays" / "Weekends".
  static const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String get daysLabel {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days set';
    final s = days.toList()..sort();
    if (setEquals(days, {1, 2, 3, 4, 5})) return 'Weekdays';
    if (setEquals(days, {6, 7})) return 'Weekends';
    return s.map((d) => dayShort[d - 1]).join(', ');
  }

  String get timeLabel => formatMinute(minuteOfDay);

  static String formatMinute(int m) {
    final h = m ~/ 60, min = m % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${min.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }
}

class RoutineStore extends ChangeNotifier {
  RoutineStore._();
  static final RoutineStore instance = RoutineStore._();

  static const guestKey = 'nwsb_my_routines';

  final List<Routine> _routines = [];
  bool _started = false;
  bool _loaded = false;
  String? _uid;
  StreamSubscription<User?>? _authSub;
  Future<void>? _loading;

  List<Routine> get routines => List.unmodifiable(_routines);
  bool get loaded => _loaded;

  String get _key => _uid == null ? guestKey : '${guestKey}_$_uid';

  Future<void> start() {
    if (_started) return _loading ?? Future.value();
    _started = true;
    String? uid;
    if (NwsbFirebase.ready) {
      final u = FirebaseAuth.instance.currentUser;
      uid = (u == null || u.isAnonymous) ? null : u.uid;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        final id = (u == null || u.isAnonymous) ? null : u.uid;
        if (id != _uid) unawaited(_load(id));
      });
    }
    return _loading = _load(uid);
  }

  Future<void> _load(String? uid) async {
    _uid = uid;
    final list = <Routine>[];
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final e in decoded) {
            final r = Routine.fromJson(e);
            if (r != null) list.add(r);
          }
        }
      }
    } catch (_) {}
    if (_uid != uid) return;
    _routines
      ..clear()
      ..addAll(list);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode([for (final r in _routines) r.toJson()]));
    } catch (_) {}
  }

  Routine? byId(String id) {
    for (final r in _routines) {
      if (r.id == id) return r;
    }
    return null;
  }

  static String newId() => 'r${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

  /// Adds [r], or replaces the routine with the same id.
  Future<void> save(Routine r) async {
    final i = _routines.indexWhere((e) => e.id == r.id);
    if (i < 0) {
      _routines.add(r);
    } else {
      _routines[i] = r;
    }
    await _save();
  }

  Future<void> delete(String id) async {
    _routines.removeWhere((e) => e.id == id);
    await _save();
  }

  /// The words of [r] that are still in [library], in the routine's order.
  static List<(Word, RoutineItem)> resolve(Routine r, List<Word> library) {
    final byKey = {for (final w in library) w.key: w};
    final byName = {for (final w in library) w.word.toLowerCase(): w};
    return [
      for (final i in r.items)
        if ((byKey[i.wordKey] ?? byName[i.word.toLowerCase()]) case final Word w) (w, i),
    ];
  }

  /// Reminders to plan: one per routine with the reminder on and a day set.
  List<({String id, String name, int minute, Set<int> days})> get reminders => [
        for (final r in _routines)
          if (r.reminder && r.days.isNotEmpty && r.items.isNotEmpty)
            (id: r.id, name: r.name, minute: r.minuteOfDay, days: r.days),
      ];

  @visibleForTesting
  Future<void> debugReset() async {
    await _authSub?.cancel();
    _authSub = null;
    _started = false;
    _loaded = false;
    _loading = null;
    _uid = null;
    _routines.clear();
  }
}
