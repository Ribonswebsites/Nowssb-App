/// State of one UI Editor session: which page and section is on the
/// preview, which slot is picked, and every pending (unsaved) edit.
/// Nothing reaches users until [publish].
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../layout/app_pages.dart';
import '../layout/scopes.dart';
import '../layout/template_sections.dart';
import '../layout/ui_layouts.dart';
import '../template/slot_keys.dart';
import '../template/ui_overrides.dart';
import 'editor_store.dart';

class EditorController extends ChangeNotifier {
  EditorController() {
    preview.addListener(notifyListeners);
  }

  final EditorPreviewController preview = EditorPreviewController();

  String pageId = 'home.normal';
  int index = 0;
  bool largeFrame = true;

  /// true: taps on the preview pick an element. false: "Try it" — the
  /// preview scrolls and swipes like the app.
  bool pickMode = true;

  String? selectedSlot;
  SlotType? selectedType;
  String selectedDefault = '';

  /// Defaults of every override edited this session (for reset + history).
  final Map<String, String> _defaults = {};

  /// Section id to land on once the page reports its sections.
  String? _jump;

  bool busy = false;
  String? message;

  List<SectionInfo> get sections => preview.reported[pageId] ?? const [];
  SectionInfo? get current =>
      sections.isEmpty ? null : sections[index.clamp(0, sections.length - 1)];
  String get sectionKey => '$pageId/${current?.id ?? ''}';

  bool get sectioned => sections.isNotEmpty;

  int get pendingCount => preview.draftOverrides.length + preview.draftLayouts.length;

  bool get isHome => pageId == 'home.normal' || pageId == 'home.fashion';

  void openPage(String id) {
    final p = appPage(id);
    if (p?.jumpTo case (final page, final section)) {
      pageId = page;
      _jump = section;
    } else {
      pageId = id;
      _jump = null;
    }
    index = 0;
    clearSelection();
    notifyListeners();
  }

  /// Called by the preview after the page reports its sections.
  void onReported() {
    if (_jump != null) {
      final i = sections.indexWhere((s) => s.id == _jump);
      if (i >= 0) index = i;
      _jump = null;
    }
    if (index >= sections.length && sections.isNotEmpty) index = sections.length - 1;
  }

  void goTo(int i) {
    if (i == index) return;
    index = i;
    clearSelection(notify: false);
    notifyListeners();
  }

  void jumpToSection(String id) {
    final i = sections.indexWhere((s) => s.id == id);
    if (i >= 0) goTo(i);
  }

  void select(String key, SlotType type, String def) {
    selectedSlot = key;
    selectedType = type;
    selectedDefault = def;
    _defaults.putIfAbsent(key, () => def);
    preview.selectedSlot = key;
    notifyListeners();
  }

  void clearSelection({bool notify = true}) {
    selectedSlot = null;
    selectedType = null;
    preview.selectedSlot = null;
    if (notify) notifyListeners();
  }

  void setFrame(bool large) {
    largeFrame = large;
    notifyListeners();
  }

  void setPickMode(bool v) {
    pickMode = v;
    notifyListeners();
  }

  // ── Overrides ──────────────────────────────────────────────────────

  /// What the slot shows in the preview now (pending edit or live).
  UiOverride? overrideOf(String key) =>
      preview.draftOverrides.containsKey(key) ? preview.draftOverrides[key] : UiOverrides.instance.get(key);

  bool isPending(String key) => preview.draftOverrides.containsKey(key);

  void setOverride(String key, SlotType type, String def, UiOverride? o) {
    _defaults.putIfAbsent(key, () => def);
    final live = UiOverrides.instance.get(key);
    final next = (o == null || o.isEmpty) ? null : o;
    // Back to what is live = nothing pending.
    if ((next == null && live == null) ||
        (next != null && live != null && _same(next, live))) {
      preview.draftOverrides.remove(key);
    } else {
      preview.draftOverrides[key] = next;
    }
    preview.changed();
  }

  bool _same(UiOverride a, UiOverride b) {
    Map<String, dynamic> j(UiOverride o) => o.toJson()
      ..remove('updatedAt')
      ..remove('updatedBy');
    return jsonEncode(j(a)) == jsonEncode(j(b));
  }

  UiOverride blankOverride(String key, SlotType type) => UiOverride(slot: key, type: type, textSet: false);

  void setText(String key, String def, String text) {
    final cur = overrideOf(key) ?? blankOverride(key, SlotType.text);
    setOverride(key, SlotType.text, def,
        text == def ? cur.copyWith(textSet: false, text: '') : cur.copyWith(text: text, textSet: true));
  }

  void setMedia(String key, SlotType type, String def, String url, String storagePath) {
    final cur = overrideOf(key) ?? blankOverride(key, type);
    setOverride(key, type, def, cur.copyWith(url: url, storagePath: storagePath));
  }

  void setStyle(String key, SlotType type, String def, Map<String, dynamic> style) {
    final cur = overrideOf(key) ?? blankOverride(key, type);
    setOverride(key, type, def, cur.copyWith(style: style));
  }

  void patchStyle(String key, SlotType type, String def, Map<String, dynamic> patch) {
    final cur = overrideOf(key)?.style ?? const {};
    final next = Map<String, dynamic>.from(cur);
    patch.forEach((k, v) => v == null ? next.remove(k) : next[k] = v);
    setStyle(key, type, def, next);
  }

  void setOverrideSchedule(String key, SlotType type, String def, int start, int end) {
    final cur = overrideOf(key);
    if (cur == null) return;
    setOverride(key, type, def, cur.copyWith(start: start, end: end));
  }

  void resetSlot(String key, SlotType type, String def) => setOverride(key, type, def, null);

  // ── Layout ─────────────────────────────────────────────────────────

  /// The page's full entry list as the preview shows it now.
  List<SectionEntry> get entries {
    final d = preview.draftLayouts[pageId];
    if (d != null && d.version != -1) return d.sections;
    return [for (final s in sections) s.entry];
  }

  void _setEntries(List<SectionEntry> list) {
    final live = UiLayouts.instance.layoutFor(pageId);
    final l = PageLayout(page: pageId, sections: list, version: live?.version ?? 0);
    String enc(List<SectionEntry> x) => jsonEncode([for (final e in x) e.toJson()]);
    if (live != null && enc(live.sections) == enc(list)) {
      preview.draftLayouts.remove(pageId);
    } else {
      preview.draftLayouts[pageId] = l;
    }
    preview.changed();
  }

  void updateEntry(String id, SectionEntry Function(SectionEntry) f) {
    _setEntries([for (final e in entries) e.id == id ? f(e) : e]);
  }

  void patchProps(String id, Map<String, dynamic> patch) {
    updateEntry(id, (e) {
      final p = Map<String, dynamic>.from(e.props);
      patch.forEach((k, v) => v == null ? p.remove(k) : p[k] = v);
      return e.copyWith(props: p);
    });
  }

  void move(int from, int to) {
    final list = [...entries];
    if (from < 0 || from >= list.length) return;
    to = to.clamp(0, list.length - 1);
    final e = list.removeAt(from);
    list.insert(to, e);
    final curId = current?.id;
    _setEntries(list);
    if (curId != null) {
      final i = list.indexWhere((x) => x.id == curId);
      if (i >= 0) index = i;
    }
    notifyListeners();
  }

  void setVisible(String id, bool v) => updateEntry(id, (e) => e.copyWith(visible: v));

  void delete(String id) {
    final e = entries.firstWhere((x) => x.id == id);
    if (e.isTemplate || e.src.isNotEmpty) {
      // Added by the owner: removed outright (history can bring it back).
      _setEntries([for (final x in entries) if (x.id != id) x]);
    } else {
      updateEntry(id, (x) => x.copyWith(deleted: true));
    }
  }

  void restore(String id) => updateEntry(id, (x) => x.copyWith(deleted: false, visible: true));

  void duplicate(String id) {
    final list = [...entries];
    final i = list.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final e = list[i];
    final base = e.isTemplate ? e.kind : e.builtinId;
    var n = 2;
    while (list.any((x) => x.id == '$base~$n')) {
      n++;
    }
    final copy = SectionEntry(
      id: '$base~$n',
      src: e.isTemplate ? '' : e.builtinId,
      kind: e.kind,
      visible: true,
      props: Map<String, dynamic>.from(e.props),
    );
    list.insert(i + 1, copy);
    _setEntries(list);
    index = i + 1;
    notifyListeners();
  }

  void addTemplate(String kind) {
    final list = [...entries];
    var n = 1;
    while (list.any((x) => x.id == '$kind~$n')) {
      n++;
    }
    final at = (index + 1).clamp(0, list.length);
    list.insert(at, SectionEntry(id: '$kind~$n', kind: kind, props: templateStarter(kind)));
    _setEntries(list);
    index = at;
    notifyListeners();
  }

  void setSchedule(String id, int start, int end) => updateEntry(id, (e) => e.copyWith(start: start, end: end));

  /// Back to the page exactly as it ships (pending until published).
  void resetPage() {
    preview.draftLayouts[pageId] = PageLayout(page: pageId, sections: const [], version: -1);
    preview.changed();
  }

  // ── Publish ────────────────────────────────────────────────────────

  void discard() {
    preview.draftOverrides.clear();
    preview.draftLayouts.clear();
    preview.changed();
  }

  Future<String?> publish({String note = ''}) async {
    if (pendingCount == 0) return null;
    busy = true;
    message = 'Publishing…';
    notifyListeners();
    try {
      await EditorStore.instance.publish(
        page: pageId,
        overrides: {
          for (final e in preview.draftOverrides.entries)
            e.key: (e.value, _defaults[e.key] ?? ''),
        },
        layouts: {
          for (final e in preview.draftLayouts.entries)
            e.key: e.value.sections.isEmpty && e.value.version == -1 ? null : e.value,
        },
        note: note,
      );
      discard();
      message = 'Live — every open app shows it now.';
      return null;
    } catch (e) {
      message = 'Could not publish: $e';
      return message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    preview.removeListener(notifyListeners);
    preview.dispose();
    super.dispose();
  }
}
