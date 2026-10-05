/// Live [SectionConfig] overrides from Firestore `ui_overrides` (type
/// `section`, slot `section.<pageId>.<sectionId>`).
///
/// Admin writes via `/api/admin/section-set`. Every client watches the same
/// collection (public read) so a save applies without an app update.
/// Bundled defaults stay until an override exists for that slot / id.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../admin/layout/scopes.dart';
import '../../data/firebase.dart';
import 'section_config.dart';

String sectionOverrideSlot(String pageId, String sectionId) =>
    'section.$pageId.$sectionId';

class SectionConfigs extends ChangeNotifier {
  SectionConfigs._();
  static final SectionConfigs instance = SectionConfigs._();

  static const _kCache = 'nwsb_ui_sections_v1';

  final Map<String, SectionConfig> _bySlot = {};
  final Map<String, SectionConfig> _byId = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _started = false;

  Map<String, SectionConfig> get bySlot => Map.unmodifiable(_bySlot);

  SectionConfig? forSlot(String slot) => _bySlot[slot];

  SectionConfig? forId(String id) => _byId[id];

  /// Prefer slot (page + section), then config id, else [fallback].
  SectionConfig resolve({
    String? pageId,
    String? sectionId,
    required SectionConfig fallback,
  }) {
    if (pageId != null &&
        pageId.isNotEmpty &&
        sectionId != null &&
        sectionId.isNotEmpty) {
      final hit = _bySlot[sectionOverrideSlot(pageId, sectionId)];
      if (hit != null) return hit;
    }
    final byId = _byId[fallback.id];
    if (byId != null) return byId;
    if (sectionId != null && sectionId.isNotEmpty) {
      final bySid = _byId[sectionId];
      if (bySid != null) return bySid;
    }
    return fallback;
  }

  /// Resolve using [SectionScope] when present.
  SectionConfig resolveIn(BuildContext context, SectionConfig fallback) {
    final scope = SectionScope.maybeOf(context);
    return resolve(
      pageId: scope?.pageId,
      sectionId: scope?.sectionId,
      fallback: fallback,
    );
  }

  /// Optional config + scope: returns live override or [fallback] (may be null).
  SectionConfig? resolveOptional(BuildContext context, SectionConfig? fallback) {
    final scope = SectionScope.maybeOf(context);
    if (scope != null) {
      final hit = _bySlot[sectionOverrideSlot(scope.pageId, scope.sectionId)];
      if (hit != null) return hit;
    }
    if (fallback != null) {
      return resolveIn(context, fallback);
    }
    return null;
  }

  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_SectionConfigsScope>();
  }

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
        final slot = '${e['slot'] ?? ''}';
        final cfg = SectionConfig.fromJson(e['config']);
        if (slot.isEmpty || cfg == null) continue;
        _bySlot[slot] = cfg;
        _byId[cfg.id] = cfg;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('NowssB section configs: cache unreadable ($e)');
    }
  }

  void _watch() {
    if (!NwsbFirebase.ready) return;
    _sub?.cancel();
    _sub = FirebaseFirestore.instance.collection('ui_overrides').snapshots().listen(
      (snap) {
        final nextSlot = <String, SectionConfig>{};
        final nextId = <String, SectionConfig>{};
        for (final d in snap.docs) {
          final data = d.data();
          final type = '${data['type'] ?? ''}';
          final slot = '${data['slot'] ?? d.id}';
          if (type != 'section' && !slot.startsWith('section.')) continue;
          final cfg = SectionConfig.fromJson(data['config']);
          if (cfg == null) continue;
          nextSlot[slot] = cfg;
          nextId[cfg.id] = cfg;
        }
        if (nextSlot.isEmpty && snap.metadata.isFromCache && _bySlot.isNotEmpty) {
          return;
        }
        _bySlot
          ..clear()
          ..addAll(nextSlot);
        _byId
          ..clear()
          ..addAll(nextId);
        notifyListeners();
        unawaited(_persist());
      },
      onError: (e) => debugPrint('NowssB section configs: $e'),
    );
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = [
        for (final e in _bySlot.entries)
          {'slot': e.key, 'config': e.value.toJson()},
      ];
      await p.setString(_kCache, jsonEncode(list));
    } catch (_) {}
  }

  /// Local mirror after an admin save (before the snapshot arrives).
  void applyLocal(String slot, SectionConfig? config) {
    if (config == null) {
      final old = _bySlot.remove(slot);
      if (old != null) _byId.remove(old.id);
    } else {
      _bySlot[slot] = config;
      _byId[config.id] = config;
    }
    notifyListeners();
    unawaited(_persist());
  }
}

class _SectionConfigsScope extends InheritedNotifier<SectionConfigs> {
  _SectionConfigsScope({required super.child})
      : super(notifier: SectionConfigs.instance);
}

/// Put near the app root so [SectionConfigs.watch] rebuilds dependents.
class SectionConfigsHost extends StatelessWidget {
  const SectionConfigsHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _SectionConfigsScope(child: child);
}
