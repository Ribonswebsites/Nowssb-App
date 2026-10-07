/// The two scopes the layout layer and the editor put into the tree.
///
///   SectionScope        — which page/section a widget is drawn in, so the
///                         editor knows which slots belong to a section.
///   EditorPreviewScope  — only inside Admin → UI Editor's live preview:
///                         pending (unsaved) edits, which single section to
///                         draw, and the tappable slot markers.
///
/// Neither costs anything for a normal user: SectionScope is a plain
/// InheritedWidget read without a dependency, and EditorPreviewScope is
/// never in their tree.
library;

import 'package:flutter/widgets.dart';

import '../template/slot_keys.dart';
import '../template/ui_overrides.dart';
import 'ui_layouts.dart';

class SectionScope extends InheritedWidget {
  const SectionScope({
    super.key,
    required this.pageId,
    required this.sectionId,
    required super.child,
  });

  final String pageId;
  final String sectionId;

  String get sectionKey => '$pageId/$sectionId';

  static SectionScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SectionScope>();

  static String? keyOf(BuildContext context) => maybeOf(context)?.sectionKey;

  @override
  bool updateShouldNotify(SectionScope old) =>
      old.pageId != pageId || old.sectionId != sectionId;
}

/// A slot drawn in the preview, with where it is on screen.
class PreviewSlot {
  PreviewSlot(this.slotKey, this.type, this.defaultValue, this.box, this.section);
  final String slotKey;
  final SlotType type;
  final String defaultValue;
  final GlobalKey box;
  final String? section;
}

class EditorPreviewController extends ChangeNotifier {
  /// Pending override edits. A key mapped to null = "back to original".
  final Map<String, UiOverride?> draftOverrides = {};

  /// Pending layouts by page.
  final Map<String, PageLayout> draftLayouts = {};

  /// Sections each page reported the last time it laid itself out:
  /// pageId → [(entryId, title)] in drawn order, hidden/deleted included.
  final Map<String, List<SectionInfo>> reported = {};

  /// Slot markers currently mounted in the preview.
  final Map<GlobalKey, PreviewSlot> slots = {};

  String? selectedSlot;

  bool _pending = false;
  void _soon() {
    if (_pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  bool _disposed = false;

  void changed() => notifyListeners();

  /// Bumped to play every section's entrance again (the Animation tab does
  /// it on each pick, so the owner sees the animation they chose).
  int replayTick = 0;
  void replay() {
    replayTick++;
    notifyListeners();
  }

  /// Rendered height of each section in the preview ('<page>/<section>'),
  /// so a pinch starts from the size on screen instead of a guess.
  final Map<String, double> sectionHeights = {};

  /// Where each section's content is drawn in the preview ('<page>/<section>'),
  /// so the editor can outline it and put its edge handles on it.
  final Map<String, RenderBox> sectionBoxes = {};

  /// Where each thing put beside a section is drawn ('<page>/<section>/<id>').
  final Map<String, RenderBox> besideBoxes = {};

  /// The page id that reported last — for a page with tabs
  /// ('<pageId>.<tabId>', program_kit.dart) the tab on screen.
  String? lastReported;

  void report(String pageId, List<SectionInfo> list) {
    lastReported = pageId;
    final old = reported[pageId];
    if (old != null &&
        old.length == list.length &&
        List.generate(list.length, (i) => old[i] == list[i]).every((x) => x)) {
      return;
    }
    reported[pageId] = list;
    _soon();
  }

  void mountSlot(PreviewSlot s) {
    slots[s.box] = s;
    _soon();
  }

  void unmountSlot(GlobalKey k) {
    if (slots.remove(k) != null) _soon();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SectionInfo {
  const SectionInfo(this.id, this.title, this.entry, {this.carousel = false, this.copyable = true});
  final String id;
  final String title;
  final SectionEntry entry;
  final bool carousel;

  /// False for sections that hold a GlobalKey (two copies cannot coexist).
  final bool copyable;

  @override
  bool operator ==(Object other) =>
      other is SectionInfo &&
      other.id == id &&
      other.title == title &&
      other.entry == entry &&
      other.carousel == carousel;

  @override
  int get hashCode => Object.hash(id, title, entry, carousel);
}

class EditorPreviewScope extends InheritedNotifier<EditorPreviewController> {
  const EditorPreviewScope({
    super.key,
    required EditorPreviewController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Depends on the scope: a preview widget rebuilds on draft changes.
  static EditorPreviewController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorPreviewScope>()?.notifier;

  static EditorPreviewController? peek(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EditorPreviewScope>()?.notifier;
}

/// The override a slot should draw right now: a pending edit in the
/// preview, else the live one (inside its schedule).
UiOverride? effectiveOverride(BuildContext context, String key) {
  final p = EditorPreviewScope.of(context);
  if (p != null && p.draftOverrides.containsKey(key)) return p.draftOverrides[key];
  final o = UiOverrides.instance.get(key);
  if (o == null) return null;
  if (p == null && !o.activeNow) return null;
  return o;
}

/// The layout a page should draw: a pending one in the preview, else live.
PageLayout? effectiveLayout(BuildContext context, String pageId) {
  final p = EditorPreviewScope.of(context);
  if (p != null && p.draftLayouts.containsKey(pageId)) return p.draftLayouts[pageId];
  return UiLayouts.instance.layoutFor(pageId);
}

/// One page of the editor's preview: draw only [sectionId] of [pageId]
/// (the page's chrome stays, the rest of its list is left out).
class PreviewIsolateScope extends InheritedWidget {
  const PreviewIsolateScope({
    super.key,
    required this.pageId,
    required this.sectionId,
    required super.child,
  });

  final String pageId;
  final String sectionId;

  static PreviewIsolateScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreviewIsolateScope>();

  @override
  bool updateShouldNotify(PreviewIsolateScope old) =>
      old.pageId != pageId || old.sectionId != sectionId;
}
