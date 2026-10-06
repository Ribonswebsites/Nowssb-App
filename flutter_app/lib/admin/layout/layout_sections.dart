/// Server-driven sections — how a page lets the owner reorder, hide,
/// duplicate, restyle and add to it from Admin → UI Editor.
///
/// RULE FOR NEW SECTIONS: build a page's scrolling body as a list of
/// sections with stable ids, and pass it through [applyLayout] (or
/// [layoutChildren] for a plain `children:` list). That is all it takes for
/// the section to show up in the editor, in its bundled place, for every
/// release after it ships:
///
///   children: layoutChildren(context, 'store.meaning', [
///     LSection('hero', 'Hero', _Hero()),
///     const SizedBox(height: 16),          // glue: travels with the one above
///     LSection('grid', 'Word grid', _Grid()),
///   ]),
///
/// Ids are forever: renaming one makes the owner's edits for it fall off.
/// With no saved layout the list comes back EXACTLY as given (same widgets,
/// same order, nothing wrapped), so the default look is pixel-identical.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../admin_state.dart';
import '../template/ui_overrides.dart';
import 'placed_orbs.dart';
import 'scopes.dart';
import 'section_pinch.dart';
import 'template_sections.dart';
import 'ui_layouts.dart';

/// One section of a page's list.
class LSection extends StatelessWidget {
  const LSection(this.id, this.title, this.child, {super.key, this.carousel = false, this.copyable = true});

  /// Several consecutive children that move together as one section (e.g.
  /// a department label and its card). Match [align] to the parent
  /// Column's crossAxisAlignment so the pixels stay the same (a ListView
  /// behaves like `stretch`).
  LSection.group(
    this.id,
    this.title,
    List<Widget> children, {
    super.key,
    this.carousel = false,
    this.copyable = true,
    CrossAxisAlignment align = CrossAxisAlignment.stretch,
  }) : child = Column(crossAxisAlignment: align, mainAxisSize: MainAxisSize.min, children: children);

  final String id;
  final String title;
  final Widget child;

  /// Scrolls sideways (the Animation tab offers transitions for it).
  final bool carousel;

  /// False when the section holds a GlobalKey: the editor then offers no
  /// Duplicate for it (two copies of one GlobalKey cannot be on screen).
  final bool copyable;

  @override
  Widget build(BuildContext context) => child;
}

/// A laid-out section: what to draw and its entry.
class SectionItem {
  const SectionItem(this.id, this.title, this.widget, {this.carousel = false, this.copyable = true});
  final String id;
  final String title;
  final Widget widget;
  final bool carousel;
  final bool copyable;
}

/// Titles/ids of every page's bundled sections, as last built on this
/// phone (the editor lists these).
class SectionCatalog {
  SectionCatalog._();
  static final SectionCatalog instance = SectionCatalog._();
  final Map<String, List<(String, String)>> pages = {};

  void note(String pageId, List<SectionItem> items) {
    final list = [for (final i in items) (i.id, i.title)];
    final old = pages[pageId];
    if (old != null && old.length == list.length) {
      var same = true;
      for (var i = 0; i < list.length; i++) {
        if (old[i] != list[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    pages[pageId] = list;
  }
}

/// Lays a page's bundled sections out by its saved layout. Returns [items]
/// itself (same list, same widgets) when there is nothing saved and no
/// editor preview is looking at this page.
///
/// [hiddenByDefault] are sections that ship turned off: they stay off
/// unless the owner shows them.
List<SectionItem> applyLayout(
  BuildContext context,
  String pageId,
  List<SectionItem> items, {
  Set<String> hiddenByDefault = const {},
}) {
  UiScope.watch(context);
  SectionCatalog.instance.note(pageId, items);
  final preview = EditorPreviewScope.of(context);
  final stored = effectiveLayout(context, pageId);
  final iso = preview == null ? null : PreviewIsolateScope.of(context);
  final isolate = iso != null && iso.pageId == pageId ? iso.sectionId : null;

  if (stored == null && preview == null && hiddenByDefault.isEmpty && !_hasSectionOrbs(pageId)) return items;

  final byId = {for (final i in items) i.id: i};
  final entries = mergeLayout(
    [for (final i in items) i.id],
    stored,
    hiddenByDefault: hiddenByDefault,
  );

  if (preview != null) {
    preview.report(pageId, [
      for (final e in entries)
        SectionInfo(
          e.id,
          e.isTemplate
              ? templateTitle(e)
              : (e.src.isNotEmpty
                  ? '${byId[e.src]?.title ?? e.src} (copy)'
                  : byId[e.id]?.title ?? e.id),
          e,
          carousel: e.isTemplate ? e.kind == 'cardRow' : (byId[e.builtinId]?.carousel ?? false),
          copyable: e.isTemplate || (byId[e.builtinId]?.copyable ?? true),
        ),
    ]);
  }

  final out = <SectionItem>[];
  for (final e in entries) {
    if (isolate != null) {
      if (e.id != isolate) continue;
    } else if (!e.showsNow) {
      continue;
    }
    final Widget base;
    if (e.isTemplate) {
      base = TemplateSection(entry: e, pageId: pageId);
    } else {
      final item = byId[e.builtinId];
      if (item == null) continue;
      // A copy of a section that cannot be copied is never drawn.
      if (e.src.isNotEmpty && !item.copyable) continue;
      base = item.widget;
    }
    // In the editor preview every section gets its frame (it measures the
    // section and replays entrances); users keep the bare widget.
    final plain = e.props.isEmpty && !e.isTemplate && e.src.isEmpty && isolate == null && preview == null;
    out.add(SectionItem(
      e.id,
      byId[e.builtinId]?.title ?? e.id,
      plain && stored == null
          // An InheritedWidget only: same pixels, but slots and orbs inside
          // know which section they belong to.
          ? SectionScope(pageId: pageId, sectionId: e.id, child: base)
          : SectionFrame(
              key: ValueKey('sf-$pageId-${e.id}'),
              pageId: pageId,
              entry: e,
              veiled: isolate != null && !e.showsNow,
              child: base,
            ),
      carousel: byId[e.builtinId]?.carousel ?? false,
    ));
  }
  return out;
}

/// A per-section thinking-orb choice exists for [pageId] (it needs the
/// section scope even when the page has no saved layout).
bool _hasSectionOrbs(String pageId) {
  final prefix = 'orb.$pageId.';
  for (final k in UiOverrides.instance.all.keys) {
    if (k.startsWith(prefix)) return true;
  }
  return false;
}

/// [applyLayout] for a plain `children:` list of [LSection]s and glue.
/// Glue (anything that is not an LSection) travels with the section before
/// it; glue before the first section stays at the top.
List<Widget> layoutChildren(
  BuildContext context,
  String pageId,
  List<Widget> children, {
  Set<String> hiddenByDefault = const {},
}) {
  final lead = <Widget>[];
  final items = <SectionItem>[];
  final glue = <String, List<Widget>>{};
  String? last;
  for (final w in children) {
    if (w is LSection) {
      var id = w.id;
      var n = 2;
      while (glue.containsKey(id)) {
        id = '${w.id}-${n++}';
      }
      items.add(SectionItem(id, w.title, w.child, carousel: w.carousel, copyable: w.copyable));
      glue[id] = [];
      last = id;
    } else if (last == null) {
      lead.add(w);
    } else {
      glue[last]!.add(w);
    }
  }
  final laid = applyLayout(context, pageId, items, hiddenByDefault: hiddenByDefault);
  final editing = EditMode.instance.on;
  bool zoomed(String id) => (UiOverrides.instance.sectionZoomOf(pageId, id) - 1).abs() > 0.015;
  if (identical(laid, items) && !editing && !items.any((i) => zoomed(i.id))) {
    return children;
  }
  final iso = EditorPreviewScope.peek(context) == null
      ? null
      : context.getInheritedWidgetOfExactType<PreviewIsolateScope>();
  final isolated = iso != null && iso.pageId == pageId;
  if (identical(laid, items)) {
    return [
      for (final w in children)
        if (w is LSection && (editing || zoomed(w.id)))
          SectionPinch(pageId: pageId, sectionId: w.id, child: w)
        else
          w,
    ];
  }
  return [
    if (!isolated) ...lead,
    for (final s in laid) ...[
      SectionPinch(pageId: pageId, sectionId: s.id, child: s.widget),
      if (!isolated) ...?glue[s.id] ?? glue[_srcOf(s.id)],
    ],
  ];
}

/// [layoutChildren] for an existing `children:` list without touching the
/// children themselves: [ids] names which child starts each section
/// (index → (id, title); a negative index counts from the end, -1 = last).
/// Children not named travel with the section before them. Returns
/// [children] itself when nothing is saved.
///
///   children: layoutIndexed(context, 'store.meaning', const {
///     0: ('hero', 'Hero film'),
///     3: ('search', 'Search'),
///     -1: ('disclaimer', 'Disclaimer'),
///   }, [ …the original children… ]),
List<Widget> layoutIndexed(
  BuildContext context,
  String pageId,
  Map<int, (String, String)> ids,
  List<Widget> children, {
  Set<String> carousels = const {},
  Set<String> hiddenByDefault = const {},
  Set<String> noCopy = const {},
}) {
  final n = children.length;
  final at = <int, (String, String)>{
    for (final e in ids.entries) (e.key < 0 ? n + e.key : e.key): e.value,
  };
  final list = <Widget>[
    for (var i = 0; i < n; i++)
      if (at[i] case final t?)
        LSection(t.$1, t.$2, children[i], carousel: carousels.contains(t.$1), copyable: !noCopy.contains(t.$1))
      else
        children[i],
  ];
  final out = layoutChildren(context, pageId, list, hiddenByDefault: hiddenByDefault);
  return identical(out, list) ? children : out;
}

String _srcOf(String id) {
  final i = id.indexOf('~');
  return i < 0 ? id : id.substring(0, i);
}

/// Carousel settings a section gives the carousels inside it.
class SectionCarouselScope extends InheritedWidget {
  const SectionCarouselScope({
    super.key,
    required this.transition,
    required this.autoRotate,
    required this.interval,
    required super.child,
  });

  final String transition;
  final bool? autoRotate;
  final int interval;

  static SectionCarouselScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SectionCarouselScope>();

  @override
  bool updateShouldNotify(SectionCarouselScope old) =>
      old.transition != transition || old.autoRotate != autoRotate || old.interval != interval;
}

double? _d(dynamic v) => v is num ? v.toDouble() : null;

/// Height, spacing, entrance animation, carousel settings and the section
/// scope around one section.
class SectionFrame extends StatelessWidget {
  const SectionFrame({
    super.key,
    required this.pageId,
    required this.entry,
    required this.child,
    this.veiled = false,
  });

  final String pageId;
  final SectionEntry entry;
  final Widget child;

  /// Hidden/deleted/off-schedule, drawn only because the editor asked.
  final bool veiled;

  @override
  Widget build(BuildContext context) {
    final p = entry.props;
    Widget w = child;
    final h = _d(p['height']);
    // Builtins, and the templates that do not size themselves from props.
    // Scaled to the height both ways: pinching bigger grows the section
    // (a scale-down-only fit left it small on top of blank space).
    if (h != null && h > 0 && (!entry.isTemplate || entry.kind == 'textBlock' || entry.kind == 'cta')) {
      w = SectionFitHeight(height: h, width: MediaQuery.sizeOf(context).width, child: w);
    }
    // Orbs the owner dropped on this section (editor and published app).
    final orbs = placedOrbsOf(p);
    if (orbs.isNotEmpty) w = PlacedOrbLayer(orbs: orbs, child: w);
    final preview = EditorPreviewScope.peek(context);
    if (preview != null) {
      final key = '$pageId/${entry.id}';
      w = _MeasureHeight(
        onHeight: (h) => preview.sectionHeights[key] = h,
        onBox: (b) => preview.sectionBoxes[key] = b,
        child: w,
      );
    }
    final pt = _d(p['padTop']) ?? 0;
    final pb = _d(p['padBottom']) ?? 0;
    final ph = _d(p['padH']) ?? 0;
    if (pt != 0 || pb != 0 || ph != 0) {
      w = Padding(padding: EdgeInsets.fromLTRB(ph, pt, ph, pb), child: w);
    }
    // Sideways nudge only. A vertical offset ('dy', written by drags before
    // a drag reordered sections) painted the section over its neighbours
    // without moving them, so it is no longer drawn; moving a section up or
    // down is a reorder now and the page reflows.
    final dx = _d(p['dx']) ?? 0;
    if (dx.abs() > 0.5) {
      w = Transform.translate(offset: Offset(dx, 0), child: w);
    }
    final t = '${p['transition'] ?? ''}';
    final auto = p['autoRotate'] is bool ? p['autoRotate'] as bool : null;
    if (t.isNotEmpty || auto != null) {
      w = SectionCarouselScope(
        transition: t,
        autoRotate: auto,
        interval: (p['interval'] is num) ? (p['interval'] as num).toInt() : 4000,
        child: w,
      );
    }
    final ent = '${p['entrance'] ?? ''}';
    if (ent.isNotEmpty && ent != 'none') {
      w = SectionEntrance(kind: ent, child: w);
    }
    if (veiled) {
      w = Stack(children: [
        Opacity(opacity: 0.45, child: w),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(99)),
            child: Text(
              entry.deleted ? 'Deleted' : (!entry.visible ? 'Hidden' : 'Off schedule'),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]);
    }
    return SectionScope(pageId: pageId, sectionId: entry.id, child: w);
  }
}

/// Plays once when the section first appears.
///   fadeUp · slide · scale · blur · fade
class SectionEntrance extends StatefulWidget {
  const SectionEntrance({super.key, required this.kind, required this.child});
  final String kind;
  final Widget child;

  @override
  State<SectionEntrance> createState() => _SectionEntranceState();
}

class _SectionEntranceState extends State<SectionEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
  int? _tick;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only inside the editor preview: replay when the Animation tab asks.
    final tick = EditorPreviewScope.of(context)?.replayTick;
    if (_tick != null && tick != null && tick != _tick) _c.forward(from: 0);
    _tick = tick;
  }

  @override
  void didUpdateWidget(SectionEntrance old) {
    super.didUpdateWidget(old);
    if (old.kind != widget.kind) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => entranceTransform(widget.kind, Curves.easeOutCubic.transform(_c.value), child!),
    );
  }
}

/// One frame of an entrance animation at progress [t] (0 → 1).
Widget entranceTransform(String kind, double t, Widget child) {
  switch (kind) {
    case 'fadeUp':
      return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 28 * (1 - t)), child: child));
    case 'slide':
      return Opacity(opacity: t, child: Transform.translate(offset: Offset(60 * (1 - t), 0), child: child));
    case 'scale':
      return Opacity(opacity: t, child: Transform.scale(scale: 0.88 + 0.12 * t, child: child));
    case 'blur':
      final s = 10 * (1 - t);
      return Opacity(
        opacity: t,
        child: s < 0.05
            ? child
            : ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s), child: child),
      );
    case 'fade':
      return Opacity(opacity: t, child: child);
  }
  return child;
}

/// Reports its child's laid-out height (editor preview only).
class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required this.onBox, required super.child});
  final ValueChanged<double> onHeight;
  final ValueChanged<RenderBox> onBox;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureHeight(onHeight, onBox);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureHeight r) => r
    ..onHeight = onHeight
    ..onBox = onBox;
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight, this.onBox);
  ValueChanged<double> onHeight;
  ValueChanged<RenderBox> onBox;

  @override
  void performLayout() {
    super.performLayout();
    if (size.height.isFinite && size.height > 0) onHeight(size.height);
    onBox(this);
  }
}

/// Turns pages on its own when the section's Animation tab says so.
/// Wrap a carousel's PageView: `CarouselAutoRotate(controller: c, count: n, child: PageView…)`.
class CarouselAutoRotate extends StatefulWidget {
  const CarouselAutoRotate({
    super.key,
    required this.controller,
    required this.count,
    required this.child,
  });

  final PageController controller;
  final int count;
  final Widget child;

  @override
  State<CarouselAutoRotate> createState() => _CarouselAutoRotateState();
}

class _CarouselAutoRotateState extends State<CarouselAutoRotate> {
  Timer? _t;
  int _interval = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SectionCarouselScope.of(context);
    final on = s?.autoRotate == true;
    final iv = on ? s!.interval.clamp(1200, 20000) : 0;
    if (iv == _interval) return;
    _interval = iv;
    _t?.cancel();
    _t = null;
    if (iv > 0) {
      _t = Timer.periodic(Duration(milliseconds: iv), (_) {
        final c = widget.controller;
        if (!mounted || !c.hasClients || widget.count < 2) return;
        final cur = (c.page ?? c.initialPage.toDouble()).round();
        final next = (cur + 1) % widget.count;
        if (next == 0) {
          c.jumpToPage(0);
        } else {
          c.animateToPage(next, duration: const Duration(milliseconds: 520), curve: Curves.easeOutCubic);
        }
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
