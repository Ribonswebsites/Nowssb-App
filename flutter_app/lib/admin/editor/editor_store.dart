/// Saving from the UI Editor: overrides (`ui_overrides`), page layouts
/// (`ui_layouts`) and the history of both (`ui_history`), in one batch so a
/// publish is all-or-nothing. Every write is admin-only in firestore.rules.
///
/// ui_history/{auto} = { page, kind: 'slot'|'layout', target,
///                       before, after, at, by, note }
/// `before`/`after` are the whole override / whole layout (null = none),
/// so any entry can be put back exactly — including deleted sections.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin_log.dart';
import '../layout/ui_layouts.dart';
import '../template/slot_keys.dart';
import '../template/ui_overrides.dart';

class HistoryEntry {
  HistoryEntry(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;

  String get page => '${data['page'] ?? ''}';
  String get kind => '${data['kind'] ?? ''}';
  String get target => '${data['target'] ?? ''}';
  String get by => '${data['by'] ?? ''}';
  String get note => '${data['note'] ?? ''}';
  dynamic get at => data['at'];
  Map<String, dynamic>? get before =>
      data['before'] is Map ? Map<String, dynamic>.from(data['before'] as Map) : null;
  Map<String, dynamic>? get after =>
      data['after'] is Map ? Map<String, dynamic>.from(data['after'] as Map) : null;
  int get atMs {
    final v = data['at'];
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return v is num ? v.toInt() : 0;
  }
}

class EditorStore {
  EditorStore._();
  static final EditorStore instance = EditorStore._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _who {
    final u = FirebaseAuth.instance.currentUser;
    return u?.email ?? u?.uid ?? '';
  }

  Map<String, dynamic> _overrideDoc(UiOverride o, String def) => {
        'slot': o.slot,
        'type': o.type.name,
        'url': o.url,
        'text': o.textSet ? o.text : null,
        'storagePath': o.storagePath,
        if (o.style.isNotEmpty) 'style': o.style,
        'start': o.start,
        'end': o.end,
        'default': def,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _who,
      };

  /// Publishes pending edits. [overrides]: key → (new override or null to
  /// reset, default value). [layouts]: whole new page layouts (null value
  /// = back to the bundled page).
  Future<void> publish({
    required String page,
    Map<String, (UiOverride?, String)> overrides = const {},
    Map<String, PageLayout?> layouts = const {},
    String note = '',
  }) async {
    final batch = _db.batch();
    final hist = _db.collection('ui_history');
    final applied = <void Function()>[];
    for (final e in overrides.entries) {
      final key = e.key;
      final (next, def) = e.value;
      final before = UiOverrides.instance.get(key);
      final ref = _db.collection('ui_overrides').doc(slotDocId(key));
      if (next == null || next.isEmpty) {
        batch.delete(ref);
        applied.add(() => UiOverrides.instance.removeLocal(key));
      } else {
        batch.set(ref, _overrideDoc(next, def));
        applied.add(() => UiOverrides.instance.applyLocal(next));
      }
      batch.set(hist.doc(), {
        'page': page,
        'kind': 'slot',
        'target': key,
        'default': def,
        'before': before?.toJson(),
        'after': (next == null || next.isEmpty) ? null : next.toJson(),
        'at': FieldValue.serverTimestamp(),
        'by': _who,
        'note': note,
      });
    }
    for (final e in layouts.entries) {
      final pageId = e.key;
      final next = e.value;
      final before = UiLayouts.instance.layoutFor(pageId);
      final ref = _db.collection('ui_layouts').doc(layoutDocId(pageId));
      if (next == null) {
        batch.delete(ref);
        applied.add(() => UiLayouts.instance.removeLocal(pageId));
      } else {
        final v = PageLayout(page: pageId, sections: next.sections, version: (before?.version ?? 0) + 1);
        batch.set(ref, {
          ...v.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _who,
        });
        applied.add(() => UiLayouts.instance.applyLocal(v));
      }
      batch.set(hist.doc(), {
        'page': pageId,
        'kind': 'layout',
        'target': pageId,
        'before': before?.toJson(),
        'after': next?.toJson(),
        'at': FieldValue.serverTimestamp(),
        'by': _who,
        'note': note,
      });
    }
    await batch.commit();
    for (final f in applied) {
      f();
    }
    await adminLog('ui.publish', page, {
      'slots': overrides.length,
      'layouts': layouts.length,
      if (note.isNotEmpty) 'note': note,
    });
  }

  /// This page's history, newest first (one equality filter, sorted here,
  /// so no composite index is needed).
  Stream<List<HistoryEntry>> history(String page) => _db
      .collection('ui_history')
      .where('page', isEqualTo: page)
      .limit(300)
      .snapshots()
      .map((s) {
        final list = [for (final d in s.docs) HistoryEntry(d.id, d.data())];
        list.sort((a, b) => b.atMs.compareTo(a.atMs));
        return list;
      });

  /// Puts a history entry's `before` (undo) or `after` (restore) back live.
  Future<void> restore(HistoryEntry h, {required bool undo}) async {
    final snap = undo ? h.before : h.after;
    if (h.kind == 'layout') {
      final l = snap == null ? null : PageLayout.from(h.target, snap);
      await publish(page: h.page, layouts: {h.target: l}, note: undo ? 'undo' : 'restore');
    } else {
      final o = snap == null ? null : UiOverride.from(snap);
      await publish(
        page: h.page,
        overrides: {h.target: (o, '${h.data['default'] ?? ''}')},
        note: undo ? 'undo' : 'restore',
      );
    }
  }
}
