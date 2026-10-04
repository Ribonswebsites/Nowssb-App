/// The remote override layer behind the live template editor.
///
/// `ui_overrides/{docId}` holds one replacement per slot:
///   { slot, type: image|video|text|orb, url?, text?, storagePath?,
///     style?: {...}, start?, end? (ms, optional schedule),
///     updatedAt, updatedBy }
/// `text: null` (or absent) with a `style` means "keep the words, change the
/// look" — see lib/admin/editor/style_props.dart for the style keys.
///
/// Same three-stage contract as lib/data/content.dart:
///   1. nothing at all — every slot shows what ships in the app;
///   2. the last copy seen, from disk, loaded before the first frame so a
///      replaced picture never flashes the old one on launch;
///   3. Firestore, WATCHED, so the owner's change reaches every open app.
///
/// Replacement pictures and clips are downloaded into the app's disk cache
/// (flutter_cache_manager, the same cache cached_network_image uses) as soon
/// as they are known, so after the first time they are local files.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';
import '../admin_state.dart';
import 'slot_keys.dart';
import '../layout/ui_layouts.dart';

class UiOverride {
  const UiOverride({
    required this.slot,
    required this.type,
    this.url = '',
    this.text = '',
    this.storagePath = '',
    this.updatedAt = 0,
    this.updatedBy = '',
    this.textSet = true,
    this.style = const {},
    this.start = 0,
    this.end = 0,
  });

  final String slot;
  final SlotType type;
  final String url;
  final String text;
  final String storagePath;
  final int updatedAt;
  final String updatedBy;

  /// False when only the look changed and the default words stay.
  final bool textSet;

  /// Look overrides (text style, button wrapper, orb choice). Empty = none.
  final Map<String, dynamic> style;

  /// Optional schedule, epoch ms; 0 = open-ended.
  final int start;
  final int end;

  bool get isMedia =>
      (type == SlotType.image || type == SlotType.video) && url.isNotEmpty;

  /// Inside its schedule (always true without one).
  bool get activeNow {
    if (start == 0 && end == 0) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (start == 0 || now >= start) && (end == 0 || now < end);
  }

  UiOverride copyWith({
    String? text,
    bool? textSet,
    String? url,
    String? storagePath,
    Map<String, dynamic>? style,
    int? start,
    int? end,
  }) =>
      UiOverride(
        slot: slot,
        type: type,
        url: url ?? this.url,
        text: text ?? this.text,
        storagePath: storagePath ?? this.storagePath,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        textSet: textSet ?? this.textSet,
        style: style ?? this.style,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  /// Nothing left to override (the editor deletes the doc instead).
  bool get isEmpty =>
      url.isEmpty && (!textSet || type != SlotType.text) && style.isEmpty;

  static UiOverride? from(Map<String, dynamic> m) {
    final slot = '${m['slot'] ?? ''}';
    final type = slotTypeFrom('${m['type'] ?? ''}');
    if (slot.isEmpty || type == null) return null;
    final at = m['updatedAt'];
    int ms(dynamic v) => v is Timestamp
        ? v.millisecondsSinceEpoch
        : (v is num ? v.toInt() : 0);
    final st = m['style'];
    return UiOverride(
      slot: slot,
      type: type,
      url: '${m['url'] ?? ''}',
      text: '${m['text'] ?? ''}',
      storagePath: '${m['storagePath'] ?? ''}',
      updatedAt: at is Timestamp
          ? at.millisecondsSinceEpoch
          : (at is num ? at.toInt() : 0),
      updatedBy: '${m['updatedBy'] ?? ''}',
      textSet: m.containsKey('text') ? m['text'] != null : type == SlotType.text,
      style: st is Map ? Map<String, dynamic>.from(st) : const {},
      start: ms(m['start']),
      end: ms(m['end']),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'type': type.name,
        'url': url,
        'text': textSet ? text : null,
        'storagePath': storagePath,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        if (style.isNotEmpty) 'style': style,
        if (start != 0) 'start': start,
        if (end != 0) 'end': end,
      };
}

class UiOverrides extends ChangeNotifier {
  UiOverrides._();
  static final UiOverrides instance = UiOverrides._();

  static const _kCache = 'nwsb_ui_overrides_v1';

  final Map<String, UiOverride> _byKey = {};
  final Map<String, String> _files = {};
  final Set<String> _fetching = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _started = false;

  Map<String, UiOverride> get all => Map.unmodifiable(_byKey);
  UiOverride? get(String key) => _byKey[key];

  /// The replacement text for [key], or null to show the default.
  String? textFor(String key) {
    final o = _byKey[key];
    if (o == null || o.type != SlotType.text || !o.textSet || !o.activeNow) {
      return null;
    }
    return o.text;
  }

  /// A replacement picture/clip for [key] that is ready to draw: a local
  /// file when it has been downloaded, else its URL.
  UiOverride? mediaFor(String key, SlotType type) {
    final o = _byKey[key];
    if (o == null || o.type != type || o.url.isEmpty || !o.activeNow) {
      return null;
    }
    return o;
  }

  /// The downloaded copy of [url], or null while it is still coming.
  String? fileFor(String url) => _files[url];

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadCached();
    _watch();
  }

  Future<void> _loadCached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final e in list) {
        if (e is! Map) continue;
        final o = UiOverride.from(Map<String, dynamic>.from(e));
        if (o != null) _byKey[o.slot] = o;
      }
      // Downloaded copies from last time — checked on disk, not fetched, so
      // this is quick and the first frame already draws the replacement.
      await Future.wait([
        for (final o in _byKey.values)
          if (o.isMedia) _fromDisk(o.url),
      ]).timeout(const Duration(seconds: 2), onTimeout: () => const []);
      for (final o in _byKey.values) {
        if (o.isMedia) unawaited(_ensure(o));
      }
    } catch (e) {
      debugPrint('NowssB overrides: cache unreadable ($e)');
    }
  }

  Future<void> _fromDisk(String url) async {
    try {
      final f = await DefaultCacheManager().getFileFromCache(url);
      if (f != null && await f.file.exists()) _files[url] = f.file.path;
    } catch (_) {}
  }

  void _watch() {
    if (!NwsbFirebase.ready) return;
    _sub = FirebaseFirestore.instance.collection('ui_overrides').snapshots().listen(
      (snap) {
        final next = <String, UiOverride>{};
        for (final d in snap.docs) {
          final o = UiOverride.from(d.data());
          if (o != null) next[o.slot] = o;
        }
        // A cache-only snapshot on a cold, offline start can be empty; it
        // must not wipe what the last online session saw.
        if (next.isEmpty && snap.metadata.isFromCache && _byKey.isNotEmpty) {
          return;
        }
        _byKey
          ..clear()
          ..addAll(next);
        notifyListeners();
        unawaited(_persist());
        for (final o in next.values) {
          if (o.isMedia) unawaited(_ensure(o));
        }
      },
      onError: (e) => debugPrint('NowssB overrides: $e'),
    );
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _kCache, jsonEncode(_byKey.values.map((o) => o.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _ensure(UiOverride o) async {
    final url = o.url;
    // `asset:` points at a file already in the app bundle (UI Editor SVG
    // library); nothing to download.
    if (!url.startsWith('http')) return;
    if (_files.containsKey(url) || _fetching.contains(url)) return;
    _fetching.add(url);
    try {
      final f = await DefaultCacheManager().getSingleFile(url);
      _files[url] = f.path;
      if (o.type == SlotType.image) {
        // Decode into the image cache now, so the first build that asks
        // for it paints it synchronously instead of flashing the default.
        final done = Completer<void>();
        final stream = FileImage(f).resolve(ImageConfiguration.empty);
        late final ImageStreamListener l;
        l = ImageStreamListener((_, __) {
          if (!done.isCompleted) done.complete();
        }, onError: (_, __) {
          if (!done.isCompleted) done.complete();
        });
        stream.addListener(l);
        await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
        stream.removeListener(l);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('NowssB overrides: could not fetch $url ($e)');
    } finally {
      _fetching.remove(url);
    }
  }

  /// Lets the admin see a just-saved override before Firestore echoes it.
  void applyLocal(UiOverride o) {
    _byKey[o.slot] = o;
    notifyListeners();
    unawaited(_persist());
    if (o.isMedia) unawaited(_ensure(o));
  }

  void removeLocal(String key) {
    if (_byKey.remove(key) != null) {
      notifyListeners();
      unawaited(_persist());
    }
  }

  /// A local file the admin just picked, shown before the upload finishes.
  void primeFile(String url, File file) {
    _files[url] = file.path;
  }

  static String sectionZoomKey(String pageId, String sectionId) =>
      'seczoom.$pageId.$sectionId';

  /// Saved pinch scale for one section. 1 means the section ships as drawn.
  double sectionZoomOf(String pageId, String sectionId) {
    final z = get(sectionZoomKey(pageId, sectionId))?.style['zoom'];
    if (z is! num) return 1;
    return z.toDouble().clamp(0.55, 1.85);
  }

  /// Writes the pinch scale live. Near 1 clears it so the section is untouched.
  Future<void> setSectionZoom(String pageId, String sectionId, double zoom) async {
    final key = sectionZoomKey(pageId, sectionId);
    final z = (zoom * 1000).round() / 1000;
    if ((z - 1).abs() < 0.015) {
      removeLocal(key);
      if (!NwsbFirebase.ready) return;
      try {
        await FirebaseFirestore.instance.collection('ui_overrides').doc(slotDocId(key)).delete();
      } catch (e) {
        debugPrint('NowssB section zoom: $e');
      }
      return;
    }
    applyLocal(UiOverride(
      slot: key,
      type: SlotType.text,
      text: '',
      textSet: false,
      style: {'zoom': z},
    ));
    if (!NwsbFirebase.ready) return;
    try {
      await FirebaseFirestore.instance.collection('ui_overrides').doc(slotDocId(key)).set({
        'slot': key,
        'type': 'text',
        'url': '',
        'text': null,
        'storagePath': '',
        'style': {'zoom': z},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NowssB section zoom: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// What the running app has actually drawn, so the All slots list can show
/// pages the manifest could not know about (dynamic labels, future widgets).
class SlotInfo {
  SlotInfo(this.key, this.type, this.defaultValue);
  final String key;
  final SlotType type;

  /// Asset path / URL for media, the default text for text.
  final String defaultValue;
}

class SlotRegistry {
  SlotRegistry._();
  static final SlotRegistry instance = SlotRegistry._();

  static const _kSeen = 'nwsb_admin_seen_slots_v1';

  final Map<String, SlotInfo> _seen = {};
  final Map<String, Set<String>> _bySection = {};
  bool _dirty = false;
  Timer? _flush;

  Map<String, SlotInfo> get seen => Map.unmodifiable(_seen);

  /// Slots drawn inside section `<pageId>/<sectionId>` (this session).
  Set<String> slotsIn(String sectionKey) => _bySection[sectionKey] ?? const {};

  void see(String key, SlotType type, String defaultValue, [String? section]) {
    if (section != null) (_bySection[section] ??= <String>{}).add(key);
    if (_seen.containsKey(key)) return;
    _seen[key] = SlotInfo(key, type, defaultValue);
    if (!AdminState.instance.isAdmin) return;
    _dirty = true;
    _flush ??= Timer(const Duration(seconds: 3), _save);
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kSeen);
      if (raw == null) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final e in list) {
        if (e is! List || e.length < 3) continue;
        final t = slotTypeFrom('${e[1]}');
        if (t == null) continue;
        _seen.putIfAbsent('${e[0]}', () => SlotInfo('${e[0]}', t, '${e[2]}'));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    _flush = null;
    if (!_dirty) return;
    _dirty = false;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _kSeen,
        jsonEncode([
          for (final s in _seen.values) [s.key, s.type.name, s.defaultValue],
        ]),
      );
    } catch (_) {}
  }
}

/// Put once above MaterialApp. Editable widgets depend on it, so a change
/// to the overrides, the edit mode or admin status rebuilds exactly them.
class UiScope extends InheritedNotifier<Listenable> {
  UiScope({super.key, required super.child}) : super(notifier: _merged);

  static final Listenable _merged = Listenable.merge([
    UiOverrides.instance,
    EditMode.instance,
    AdminState.instance,
    UiLayouts.instance,
  ]);

  /// Subscribe [context] to changes. Harmless where there is no scope
  /// (widget tests): the widget simply reads the current values.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<UiScope>();
  }
}
