/// Server-driven page layouts.
///
/// `ui_layouts/{pageId}` = {
///   page, version, updatedAt, updatedBy,
///   sections: [ { id, src, kind, visible, deleted, props: {...},
///                 start, end } ... ]
/// }
///
/// No document = the page's bundled order, exactly as it ships. A document
/// only exists once the owner saves a change from Admin → UI Editor, and it
/// always lists the whole page, so a user's app can rebuild it in order.
/// Sections the app has that the document does not mention (added in a
/// later release) keep their bundled place; ids the app no longer has are
/// skipped. Same cache → watch contract as the overrides: the last layout
/// seen is on the phone before the first frame (no flash of the old order).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';

/// What renders a section entry.
///   builtin   — a section the app ships (id or [src] names it)
///   imageBanner / videoBanner / splitPromo / cardRow / textBlock / cta /
///   couponTicket / couponCards
///             — generic template sections built from [props]
///   glassyCarousel / couponBanner / hypedRow / artistCards /
///   categoryTiles / spotlight / promoBanner / couponPromo /
///   bannerMix / fourBanners / storiesBanner
///             — the app's own ready-made sections and banners
const kTemplateKinds = <String>[
  'imageBanner',
  'videoBanner',
  'splitPromo',
  'cardRow',
  'textBlock',
  'cta',
  'couponTicket',
  'couponCards',
  ...kReadyKinds,
];

/// Ready-made sections and banners the app already ships, added whole.
const kReadyKinds = <String>[
  'couponBanner',
  'couponPromo',
  'promoBanner',
  'glassyCarousel',
  'spotlight',
  'hypedRow',
  'artistCards',
  'categoryTiles',
  'bannerMix',
  'fourBanners',
  'storiesBanner',
];

class SectionEntry {
  const SectionEntry({
    required this.id,
    this.src = '',
    this.kind = 'builtin',
    this.visible = true,
    this.deleted = false,
    this.props = const {},
    this.start = 0,
    this.end = 0,
  });

  /// Unique on the page. For a builtin it is the section's own id, or
  /// `<src>~<n>` for a duplicate.
  final String id;

  /// The builtin this entry draws (duplicates); '' = [id] itself.
  final String src;
  final String kind;
  final bool visible;

  /// Deleted by the owner: never drawn, listed under Deleted to restore.
  final bool deleted;

  /// height, padTop, padBottom, padH, entrance, transition, autoRotate,
  /// interval, and a template's own content (title, image, route…).
  final Map<String, dynamic> props;

  /// Optional schedule, epoch ms; 0 = open-ended.
  final int start;
  final int end;

  bool get isTemplate => kind != 'builtin';
  String get builtinId => src.isEmpty ? id : src;

  bool get inSchedule {
    if (start == 0 && end == 0) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (start == 0 || now >= start) && (end == 0 || now < end);
  }

  bool get showsNow => visible && !deleted && inSchedule;

  SectionEntry copyWith({
    String? id,
    String? src,
    bool? visible,
    bool? deleted,
    Map<String, dynamic>? props,
    int? start,
    int? end,
  }) =>
      SectionEntry(
        id: id ?? this.id,
        src: src ?? this.src,
        kind: kind,
        visible: visible ?? this.visible,
        deleted: deleted ?? this.deleted,
        props: props ?? this.props,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  static SectionEntry? from(dynamic m) {
    if (m is! Map) return null;
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return null;
    int ms(dynamic v) => v is Timestamp
        ? v.millisecondsSinceEpoch
        : (v is num ? v.toInt() : 0);
    final p = m['props'];
    return SectionEntry(
      id: id,
      src: '${m['src'] ?? ''}',
      kind: '${m['kind'] ?? 'builtin'}',
      visible: m['visible'] != false,
      deleted: m['deleted'] == true,
      props: p is Map ? Map<String, dynamic>.from(p) : const {},
      start: ms(m['start']),
      end: ms(m['end']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (src.isNotEmpty) 'src': src,
        'kind': kind,
        'visible': visible,
        if (deleted) 'deleted': true,
        if (props.isNotEmpty) 'props': props,
        if (start != 0) 'start': start,
        if (end != 0) 'end': end,
      };

  @override
  bool operator ==(Object other) =>
      other is SectionEntry && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

class PageLayout {
  const PageLayout({required this.page, required this.sections, this.version = 0});

  final String page;
  final List<SectionEntry> sections;
  final int version;

  static PageLayout? from(String page, Map<String, dynamic> m) {
    final raw = m['sections'];
    if (raw is! List) return null;
    return PageLayout(
      page: page,
      version: (m['version'] is num) ? (m['version'] as num).toInt() : 0,
      sections: [
        for (final e in raw)
          if (SectionEntry.from(e) case final s?) s,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'version': version,
        'sections': [for (final s in sections) s.toJson()],
      };
}

/// Doc ids: page ids are dotted names (home.normal); Firestore accepts
/// dots, only '/' needs escaping.
String layoutDocId(String pageId) => pageId.replaceAll('/', '~');

/// Lays the stored entries over the bundled ids. Pure, so it is tested.
///   * stored order wins for every id it mentions;
///   * a bundled id it does not mention goes right after its bundled
///     predecessor (or first);
///   * builtin entries whose id the app no longer has are dropped.
List<SectionEntry> mergeLayout(
  List<String> bundled,
  PageLayout? stored, {
  Set<String> hiddenByDefault = const {},
}) {
  final defaults = [
    for (final id in bundled)
      SectionEntry(id: id, visible: !hiddenByDefault.contains(id)),
  ];
  if (stored == null || stored.sections.isEmpty) return defaults;
  final have = bundled.toSet();
  final out = <SectionEntry>[
    for (final s in stored.sections)
      if (s.isTemplate || have.contains(s.builtinId)) s,
  ];
  final mentioned = {for (final s in out) if (!s.isTemplate && s.src.isEmpty) s.id};
  for (var i = 0; i < bundled.length; i++) {
    final id = bundled[i];
    if (mentioned.contains(id)) continue;
    // After the nearest bundled predecessor that is placed.
    var at = 0;
    for (var j = i - 1; j >= 0; j--) {
      final k = out.indexWhere((s) => s.id == bundled[j]);
      if (k >= 0) {
        at = k + 1;
        break;
      }
    }
    out.insert(at, defaults[i]);
    mentioned.add(id);
  }
  return out;
}

class UiLayouts extends ChangeNotifier {
  UiLayouts._();
  static final UiLayouts instance = UiLayouts._();

  static const _kCache = 'nwsb_ui_layouts_v1';

  final Map<String, PageLayout> _byPage = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _started = false;

  PageLayout? layoutFor(String pageId) => _byPage[pageId];
  Map<String, PageLayout> get all => Map.unmodifiable(_byPage);

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
      final m = jsonDecode(raw);
      if (m is! Map) return;
      for (final e in m.entries) {
        if (e.value is! Map) continue;
        final l = PageLayout.from('${e.key}', Map<String, dynamic>.from(e.value as Map));
        if (l != null) _byPage['${e.key}'] = l;
      }
    } catch (e) {
      debugPrint('NowssB layouts: cache unreadable ($e)');
    }
  }

  void _watch() {
    if (!NwsbFirebase.ready) return;
    _sub = FirebaseFirestore.instance.collection('ui_layouts').snapshots().listen(
      (snap) {
        final next = <String, PageLayout>{};
        for (final d in snap.docs) {
          final data = d.data();
          final page = '${data['page'] ?? d.id}';
          final l = PageLayout.from(page, data);
          if (l != null) next[page] = l;
        }
        if (next.isEmpty && snap.metadata.isFromCache && _byPage.isNotEmpty) return;
        if (_same(next)) return;
        _byPage
          ..clear()
          ..addAll(next);
        notifyListeners();
        unawaited(_persist());
      },
      onError: (e) => debugPrint('NowssB layouts: $e'),
    );
  }

  bool _same(Map<String, PageLayout> next) {
    if (next.length != _byPage.length) return false;
    for (final e in next.entries) {
      final cur = _byPage[e.key];
      if (cur == null || jsonEncode(cur.toJson()) != jsonEncode(e.value.toJson())) {
        return false;
      }
    }
    return true;
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kCache,
          jsonEncode({for (final e in _byPage.entries) e.key: e.value.toJson()}));
    } catch (_) {}
  }

  /// The admin's just-saved layout, before Firestore echoes it.
  void applyLocal(PageLayout l) {
    _byPage[l.page] = l;
    notifyListeners();
    unawaited(_persist());
  }

  void removeLocal(String pageId) {
    if (_byPage.remove(pageId) != null) {
      notifyListeners();
      unawaited(_persist());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
