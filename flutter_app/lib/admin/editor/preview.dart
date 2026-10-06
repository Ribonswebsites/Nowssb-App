/// The editor's canvas: the real page, full screen, edge to edge, with
/// every pending edit — the whole page, not one section at a time. In
/// "edit" mode the page takes no taps itself; [_TouchLayer] reads every
/// touch instead (see there), so the canvas works for any page in
/// kAppPages that lays itself out in sections.
library;

import 'dart:async';

import 'package:flutter/gestures.dart' show Drag;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/theme.dart';
import '../layout/app_pages.dart';
import '../layout/placed_orbs.dart';
import '../layout/scopes.dart';
import '../template/editable.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
import 'glass.dart';

/// Kept for callers that ask for "the page as a whole".
const kProbe = '__probe__';

class EditorPreview extends StatefulWidget {
  const EditorPreview({super.key, required this.c});
  final EditorController c;

  @override
  State<EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends State<EditorPreview> {
  final _pageKey = GlobalKey();
  String _page = '';
  String _order = '';
  bool _pick = true;

  EditorController get c => widget.c;

  @override
  void initState() {
    super.initState();
    _page = c.pageId;
    _pick = c.pickMode;
    c.addListener(_sync);
  }

  @override
  void dispose() {
    c.removeListener(_sync);
    super.dispose();
  }

  /// The editor screen does not rebuild the canvas on every change: drafts
  /// reach the page through EditorPreviewScope. It rebuilds only for a new
  /// page or a switch between editing and trying the page.
  void _sync() {
    if (!mounted) return;
    // A new set or order of sections: the controller re-finds its section.
    final sig = c.sections.map((s) => s.id).join('|');
    if (sig != _order) {
      _order = sig;
      c.onReported();
    }
    if (c.pageId != _page || c.pickMode != _pick) {
      _page = c.pageId;
      _pick = c.pickMode;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = appPage(c.pageId) ?? kAppPages.first;
    final screen = Theme(
      data: NwsbTheme.light,
      child: HeroMode(
        enabled: false,
        child: KeyedSubtree(key: ValueKey('page-${page.id}'), child: page.build()),
      ),
    );
    return EditorPreviewScope(
      controller: c.preview,
      child: Stack(children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: c.pickMode,
            child: RepaintBoundary(child: KeyedSubtree(key: _pageKey, child: screen)),
          ),
        ),
        if (c.pickMode)
          Positioned.fill(
            child: _TouchLayer(
              key: ValueKey('touch-${page.id}'),
              c: c,
              pageKey: _pageKey,
              child: _Hotspots(c: c, section: null),
            ),
          ),
      ]),
    );
  }
}

/// Tappable areas over every editable element on the page. Only the
/// picked section's elements are outlined (faintly), and the selected one
/// in gold; the rest are invisible until touched, so the page reads as it
/// ships.
class _Hotspots extends StatefulWidget {
  const _Hotspots({required this.c, required this.section});
  final EditorController c;
  final String? section;

  @override
  State<_Hotspots> createState() => _HotspotsState();
}

class _HotspotsState extends State<_Hotspots> {
  /// Where each outline is, as last measured.
  List<(PreviewSlot, Rect)> _spots = const [];
  var _watching = false;

  @override
  void initState() {
    super.initState();
    widget.c.addListener(_onEdit);
    _watch();
  }

  @override
  void didUpdateWidget(_Hotspots old) {
    super.didUpdateWidget(old);
    if (old.c != widget.c) {
      old.c.removeListener(_onEdit);
      widget.c.addListener(_onEdit);
    }
  }

  @override
  void dispose() {
    widget.c.removeListener(_onEdit);
    super.dispose();
  }

  /// Picked/changed colours follow the editor at once.
  void _onEdit() {
    if (mounted) setState(() {});
  }

  /// Elements move (carousels, entrance animations, pictures loading).
  /// Instead of a timer rebuilding every 350 ms, re-measure after each frame
  /// the app draws anyway — an idle preview draws none, so this costs
  /// nothing then — and rebuild only when an outline actually moved.
  void _watch() {
    if (_watching) return;
    _watching = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (!mounted) return;
      final next = _measure();
      if (!_same(next, _spots)) setState(() => _spots = next);
      _watch();
    });
  }

  List<(PreviewSlot, Rect)> _measure() {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.attached || !me.hasSize) return const [];
    final out = <(PreviewSlot, Rect)>[];
    final seen = <String>{};
    for (final s in widget.c.preview.slots.values) {
      if (widget.section != null && s.section != widget.section) continue;
      if (!seen.add(s.slotKey)) continue;
      final box = s.box.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize || box.size.isEmpty) continue;
      final tl = me.globalToLocal(box.localToGlobal(Offset.zero));
      final br = me.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero)));
      final r = Rect.fromPoints(tl, br).intersect(Offset.zero & me.size);
      // A box mid-resize (or scaled to nothing) can't be placed.
      if (!r.isFinite || r.width < 4 || r.height < 4) continue;
      out.add((s, r));
    }
    return out;
  }

  static bool _same(List<(PreviewSlot, Rect)> a, List<(PreviewSlot, Rect)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1.slotKey != b[i].$1.slotKey) return false;
      final x = a[i].$2, y = b[i].$2;
      if ((x.left - y.left).abs() > 0.5 ||
          (x.top - y.top).abs() > 0.5 ||
          (x.width - y.width).abs() > 0.5 ||
          (x.height - y.height).abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final spots = <Widget>[];
    final c = widget.c;
    final pickedSection = c.sectionPicked && c.current != null ? '${c.layoutPage}/${c.current!.id}' : null;
    for (final (s, r) in _spots) {
      final picked = c.selectedSlot == s.slotKey;
      final changed = c.overrideOf(s.slotKey) != null;
      final shown = picked || (pickedSection != null && s.section == pickedSection);
      spots.add(Positioned.fromRect(
        rect: r,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            actFeel();
            final sec = s.section;
            final id = sec != null && sec.startsWith('${widget.c.layoutPage}/') ? sec.split('/').last : null;
            widget.c.selectIn(id, s.slotKey, s.type, s.defaultValue);
          },
          child: !shown
              ? const SizedBox.expand()
              : AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: picked ? kGold.withValues(alpha: 0.16) : Colors.transparent,
              border: Border.all(
                color: picked ? kGold : (changed ? kMint : const Color(0x66E8D5A3)),
                width: picked ? 3 : 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.topRight,
            child: r.width > 30 && r.height > 22
                ? Container(
                    margin: const EdgeInsets.all(3),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: picked ? kGold : (changed ? kMint : const Color(0xCCE8D5A3)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(slotIcon(s.type), size: 12, color: kInk),
                  )
                : null,
          ),
        ),
      ));
    }
    return Stack(children: spots);
  }
}

/// An effect from the drawer, dragged onto a section.
class FxDrop {
  const FxDrop(this.label, this.patch, {this.carouselOnly = false, this.apply});
  final String label;

  /// Props it sets on the section (null = remove).
  final Map<String, dynamic> patch;

  /// Page turns and auto-rotate only mean something on a sideways section.
  final bool carouselOnly;

  /// Instead of [patch], for effects that live elsewhere.
  final void Function(EditorController c, SectionInfo section)? apply;

  /// Drawer tiles may carry extra data alongside the effect.
  static FxDrop? of(Object? data) => switch (data) {
        FxDrop d => d,
        (FxDrop d, _) => d,
        _ => null,
      };
}

/// An animation (anims/anim_library.dart id) dragged out of the drawer,
/// to be placed where it is dropped.
class AnimDrop {
  const AnimDrop(this.id);
  final String id;
}

/// A brief Undo just under the pill at the top, clear of the + button,
/// the strip and the trash at the bottom.
void _undoBar(BuildContext context, EditorController c, String text) {
  final m = ScaffoldMessenger.maybeOf(context);
  final mq = MediaQuery.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: mq == null
        ? null
        : EdgeInsets.fromLTRB(16, 0, 16, (mq.size.height - mq.padding.top - 124).clamp(16.0, double.infinity)),
    backgroundColor: const Color(0xFF111A2B),
    duration: const Duration(seconds: 4),
    content: Text(text, style: const TextStyle(color: Colors.white)),
    action: SnackBarAction(label: 'Undo', textColor: kGold, onPressed: c.undo),
  ));
}

/// Deletes a section at once and offers Undo (no confirm dialog: undo is
/// always there, in the snackbar and in the history).
void deleteWithUndo(BuildContext context, EditorController c, String id, String title) {
  bigFeel();
  c.endStep();
  c.delete(id);
  c.unpick();
  c.endStep();
  _undoBar(context, c, 'Deleted “$title”');
}

enum _Grab { none, scroll, order, padTop, padBottom, pinchSection, pinchElement, moveElement, moveOrb, pinchOrb }

/// Places one drag up or down moves a section when no other section is
/// under the finger (kept for callers and tests of the step maths).
const kShiftStep = 90.0;

/// How many places a vertical drag of [dy] moves a section that can go
/// [up] places up and [down] places down.
int shiftSteps(double dy, int up, int down) =>
    (dy / kShiftStep).truncate().clamp(-up, down);

/// Height of the trash zone that shows at the bottom while something is
/// dragged.
const kTrashHeight = 96.0;

/// How close to a picked section's top/bottom edge a drag must start to
/// change the space above/below instead of moving it.
const kEdgeGrab = 22.0;

/// Where drags near the top, or just above the trash, scroll the page.
const kAutoScrollBand = 80.0;

/// Everything on the canvas is done by touching it:
///   tap                 pick an element, a placed orb, or a section
///   drag (nothing picked, or outside it)   scroll the page
///   drag the picked section    move it; the page makes room
///   drag its top/bottom edge   space above / below
///   drag the picked element    move it inside its section
///   drag a placed orb          move it anywhere on the page
///   … onto the trash at the bottom   delete (with Undo)
///   pinch               resize the orb, element or section under it
///   long-press          the short menu for a section or orb
/// Effects and orbs dragged out of the drawer land where they are dropped.
class _TouchLayer extends StatefulWidget {
  const _TouchLayer({super.key, required this.c, required this.pageKey, required this.child});
  final EditorController c;
  final GlobalKey pageKey;
  final Widget child;

  @override
  State<_TouchLayer> createState() => _TouchLayerState();
}

typedef _OrbSpot = ({String section, PlacedOrb orb, Rect rect, Rect box});

class _TouchLayerState extends State<_TouchLayer> {
  EditorController get c => widget.c;

  var _grab = _Grab.none;
  double _base = 0;
  Offset _baseOffset = Offset.zero;
  Offset _start = Offset.zero;
  Offset _finger = Offset.zero;

  /// Where the finger first went down: a scale gesture only starts after
  /// the finger has moved a little, so its start point is already past it.
  Offset? _down;
  Drag? _scrollDrag;
  ScrollPosition? _scrollPos;
  Timer? _autoScroll;
  (String, String)? _orb;
  PreviewSlot? _element;

  /// Live sections on screen, top to bottom, and the placed orbs.
  List<(String, Rect)> _sections = const [];
  List<_OrbSpot> _orbs = const [];
  var _watching = false;
  int _lastIndex = -1;

  /// While an effect or orb from the drawer hovers over the page.
  Offset? _hover;

  @override
  void initState() {
    super.initState();
    c.addListener(_onC);
    _watch();
  }

  @override
  void dispose() {
    c.removeListener(_onC);
    _autoScroll?.cancel();
    super.dispose();
  }

  void _onC() {
    if (!mounted) return;
    // A section picked from elsewhere (the Sections list): bring it into view.
    if (c.sectionPicked && c.index != _lastIndex) {
      _lastIndex = c.index;
      final id = c.current?.id;
      final box = id == null ? null : c.preview.sectionBoxes['${c.layoutPage}/$id'];
      final me = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached && me != null && me.hasSize) {
        final r = _rectOf(box);
        if (r != null && (r.bottom < 0 || r.top > me.size.height)) {
          box.showOnScreen(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
        }
      }
    }
    setState(() {});
  }

  /// Re-measure after frames the app draws anyway (an idle page draws
  /// none), and rebuild only when something moved.
  void _watch() {
    if (_watching) return;
    _watching = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (!mounted) return;
      final secs = _measureSections();
      final orbs = _measureOrbs();
      if (!_sameSecs(secs, _sections) || !_sameOrbs(orbs, _orbs)) {
        setState(() {
          _sections = secs;
          _orbs = orbs;
        });
      }
      _watch();
    });
  }

  static bool _near(Rect a, Rect b) =>
      (a.left - b.left).abs() < 0.5 &&
      (a.top - b.top).abs() < 0.5 &&
      (a.width - b.width).abs() < 0.5 &&
      (a.height - b.height).abs() < 0.5;

  static bool _sameSecs(List<(String, Rect)> a, List<(String, Rect)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || !_near(a[i].$2, b[i].$2)) return false;
    }
    return true;
  }

  static bool _sameOrbs(List<_OrbSpot> a, List<_OrbSpot> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].section != b[i].section ||
          a[i].orb.id != b[i].orb.id ||
          a[i].orb.orb != b[i].orb.orb ||
          a[i].orb.circle != b[i].orb.circle ||
          !_near(a[i].rect, b[i].rect)) {
        return false;
      }
    }
    return true;
  }

  Rect? _rectOf(RenderBox? box) {
    final me = context.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.attached || !me.attached || !box.hasSize || !me.hasSize) return null;
    final tl = me.globalToLocal(box.localToGlobal(Offset.zero));
    final br = me.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero)));
    final r = Rect.fromPoints(tl, br);
    return r.isFinite ? r : null;
  }

  RenderBox? _boxOf(String id) {
    final b = c.preview.sectionBoxes['${c.layoutPage}/$id'];
    return b != null && b.attached ? b : null;
  }

  List<(String, Rect)> _measureSections() {
    final out = <(String, Rect)>[];
    for (final s in c.sections) {
      if (!s.entry.showsNow) continue;
      final r = _rectOf(_boxOf(s.id));
      if (r != null && r.height > 0) out.add((s.id, r));
    }
    return out;
  }

  List<_OrbSpot> _measureOrbs() {
    final out = <_OrbSpot>[];
    for (final e in c.entries) {
      if (!e.showsNow) continue;
      final orbs = placedOrbsOf(e.props);
      if (orbs.isEmpty) continue;
      final box = _boxOf(e.id);
      final r = _rectOf(box);
      if (box == null || r == null) continue;
      for (final o in orbs) {
        out.add((section: e.id, orb: o, rect: o.rectIn(box.size).shift(r.topLeft), box: r));
      }
    }
    return out;
  }

  // ── Hit tests ──────────────────────────────────────────────────────

  String? _sectionAt(Offset p) {
    for (final (id, r) in _sections) {
      if (r.contains(p)) return id;
    }
    return null;
  }

  Rect? _sectionRect(String? id) {
    for (final (sid, r) in _sections) {
      if (sid == id) return r;
    }
    return null;
  }

  _OrbSpot? _orbAt(Offset p) {
    for (final o in _orbs.reversed) {
      if (o.rect.inflate(8).contains(p)) return o;
    }
    return null;
  }

  _OrbSpot? get _pickedOrb {
    final sel = c.selectedOrb;
    if (sel == null) return null;
    for (final o in _orbs) {
      if (o.section == sel.$1 && o.orb.id == sel.$2) return o;
    }
    return null;
  }

  PreviewSlot? get _selectedSlot {
    final k = c.selectedSlot;
    if (k == null) return null;
    for (final s in c.preview.slots.values) {
      if (s.slotKey == k && s.box.currentContext != null) return s;
    }
    return null;
  }

  Rect? _slotRect(PreviewSlot? s) => _rectOf(s?.box.currentContext?.findRenderObject() as RenderBox?);

  Map<String, dynamic> get _props => c.current?.entry.props ?? const {};
  double _num(String k) => _props[k] is num ? (_props[k] as num).toDouble() : 0;

  bool _overTrash(Offset p) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.hasSize) return false;
    return p.dy > me.size.height - kTrashHeight;
  }

  /// The page's own vertical scroll (the outermost one that can scroll).
  ScrollPosition? _findScroll() {
    ScrollableState? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        final s = e.state as ScrollableState;
        final p = s.position;
        if (axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
            p.hasContentDimensions &&
            p.maxScrollExtent > p.minScrollExtent) {
          found = s;
          return;
        }
      }
      e.visitChildren(visit);
    }

    final ctx = widget.pageKey.currentContext;
    if (ctx is Element) ctx.visitChildren(visit);
    return found?.position;
  }

  // ── Gestures ───────────────────────────────────────────────────────

  void _startPinch(Offset focal) {
    _endScroll(0);
    final orb = _pickedOrb ?? _orbAt(focal);
    if (orb != null && orb.rect.inflate(48).contains(focal)) {
      if (c.selectedOrb != (orb.section, orb.orb.id)) c.selectedOrb = (orb.section, orb.orb.id);
      _orb = (orb.section, orb.orb.id);
      _base = orb.orb.size;
      _grab = _Grab.pinchOrb;
      return;
    }
    final sel = _selectedSlot;
    final sr = _slotRect(sel);
    if (sel != null && sr != null && sr.inflate(20).contains(focal)) {
      final st = c.overrideOf(sel.slotKey)?.style ?? const {};
      _element = sel;
      if (sel.type == SlotType.text) {
        _base = st['size'] is num
            ? (st['size'] as num).toDouble()
            : (_fontSize(sel.box.currentContext?.findRenderObject()) ?? 16);
      } else {
        _base = st['scale'] is num ? (st['scale'] as num).toDouble() : 1;
      }
      _grab = _Grab.pinchElement;
      return;
    }
    final id = _sectionAt(focal) ?? (c.sectionPicked ? c.current?.id : null);
    if (id == null) {
      _grab = _Grab.none;
      return;
    }
    if (!c.sectionPicked || c.current?.id != id) c.pickSection(id);
    _base = _num('height');
    if (_base < 1) _base = c.preview.sectionHeights['${c.layoutPage}/$id'] ?? 200;
    _grab = _Grab.pinchSection;
  }

  static double? _fontSize(RenderObject? r) {
    if (r == null) return null;
    if (r is RenderParagraph) return r.text.style?.fontSize;
    double? found;
    r.visitChildren((x) => found ??= _fontSize(x));
    return found;
  }

  void _endScroll(double velocity) {
    final d = _scrollDrag;
    _scrollDrag = null;
    d?.end(DragEndDetails(velocity: Velocity(pixelsPerSecond: Offset(0, velocity)), primaryVelocity: velocity));
  }

  void _onStart(ScaleStartDetails d) {
    c.endStep();
    _start = _down ?? d.localFocalPoint;
    _finger = d.localFocalPoint;
    _orb = null;
    _element = null;
    if (d.pointerCount >= 2) {
      _startPinch(d.localFocalPoint);
      setState(() {});
      return;
    }
    final orb = _orbAt(_start);
    final sel = _selectedSlot;
    final sr = _slotRect(sel);
    final cur = c.sectionPicked ? _sectionRect(c.current?.id) : null;
    if (orb != null) {
      c.selectedOrb = (orb.section, orb.orb.id);
      c.sectionPicked = false;
      c.clearSelection();
      _orb = (orb.section, orb.orb.id);
      _baseOffset = Offset(orb.orb.x * orb.box.width, orb.orb.y);
      _grab = _Grab.moveOrb;
    } else if (sel != null && sr != null && sr.contains(_start)) {
      final st = c.overrideOf(sel.slotKey)?.style ?? const {};
      double n(String k) => st[k] is num ? (st[k] as num).toDouble() : 0;
      _element = sel;
      _baseOffset = Offset(n('dx'), n('dy'));
      _grab = _Grab.moveElement;
    } else if (cur != null && cur.contains(_start)) {
      if ((_start.dy - cur.top).abs() < kEdgeGrab) {
        _grab = _Grab.padTop;
        _base = _num('padTop');
      } else if ((_start.dy - cur.bottom).abs() < kEdgeGrab) {
        _grab = _Grab.padBottom;
        _base = _num('padBottom');
      } else {
        _grab = _Grab.order;
      }
    } else if (cur != null && ((_start.dy - cur.top).abs() < kEdgeGrab || (_start.dy - cur.bottom).abs() < kEdgeGrab)) {
      // Just outside the edge still grabs it (the bar sits on the edge).
      final top = (_start.dy - cur.top).abs() < kEdgeGrab;
      _grab = top ? _Grab.padTop : _Grab.padBottom;
      _base = _num(top ? 'padTop' : 'padBottom');
    } else {
      _grab = _Grab.scroll;
      _scrollPos = _findScroll();
      _scrollDrag = _scrollPos?.drag(
        DragStartDetails(globalPosition: d.focalPoint, localPosition: d.localFocalPoint),
        () => _scrollDrag = null,
      );
      // The movement made before the gesture was recognised.
      final pre = d.localFocalPoint.dy - _start.dy;
      if (pre.abs() > 0) {
        _scrollDrag?.update(DragUpdateDetails(
          globalPosition: d.focalPoint,
          delta: Offset(0, pre),
          primaryDelta: pre,
        ));
      }
    }
    setState(() {});
  }

  bool get _carrying => _grab == _Grab.order || _grab == _Grab.moveOrb || _grab == _Grab.moveElement;

  /// Tells the screen something is being carried (it clears the bottom so
  /// the trash is in plain sight).
  void _syncCarry() {
    c.carrying.value = _carrying && (_finger - _start).distance > 6;
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 &&
        _grab != _Grab.pinchSection &&
        _grab != _Grab.pinchElement &&
        _grab != _Grab.pinchOrb) {
      _startPinch(d.localFocalPoint);
      setState(() {});
    }
    final total = d.localFocalPoint - _start;
    switch (_grab) {
      case _Grab.none:
        return;
      case _Grab.scroll:
        _scrollDrag?.update(DragUpdateDetails(
          globalPosition: d.focalPoint,
          delta: Offset(0, d.focalPointDelta.dy),
          primaryDelta: d.focalPointDelta.dy,
        ));
      case _Grab.pinchOrb:
        final o = _orb;
        if (o == null) return;
        final v = (_base * d.scale).clamp(PlacedOrb.kMinSize, PlacedOrb.kMaxSize).roundToDouble();
        c.updateOrb(o.$1, o.$2, (x) => x.copyWith(size: v));
      case _Grab.pinchElement:
        final sel = _element;
        if (sel == null) return;
        if (sel.type == SlotType.text) {
          final v = (_base * d.scale).clamp(8.0, 120.0).roundToDouble();
          c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {'size': v});
        } else {
          final v = double.parse((_base * d.scale).clamp(0.3, 4.0).toStringAsFixed(2));
          c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {'scale': (v - 1).abs() < 0.02 ? null : v});
        }
      case _Grab.pinchSection:
        final id = c.current?.id;
        if (id == null) return;
        c.patchProps(id, {'height': (_base * d.scale).clamp(60.0, 1400.0).roundToDouble()});
      case _Grab.padTop || _Grab.padBottom:
        final id = c.current?.id;
        if (id == null) return;
        final v = (_base + total.dy).clamp(0.0, 200.0).roundToDouble();
        c.patchProps(id, {_grab == _Grab.padTop ? 'padTop' : 'padBottom': v < 1 ? null : v});
      case _Grab.moveElement:
        final sel = _element;
        if (sel == null) return;
        final p = _baseOffset + total;
        setState(() => _finger = d.localFocalPoint);
        c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {
          'dx': p.dx.abs() < 1 ? null : p.dx.roundToDouble(),
          'dy': p.dy.abs() < 1 ? null : p.dy.roundToDouble(),
        });
        _autoScrollFor(d.localFocalPoint);
      case _Grab.moveOrb:
        final o = _orb;
        final spot = _pickedOrb;
        if (o == null || spot == null) return;
        final p = _baseOffset + total;
        setState(() => _finger = d.localFocalPoint);
        c.updateOrb(o.$1, o.$2, (x) => x.copyWith(x: spot.box.width <= 0 ? x.x : p.dx / spot.box.width, y: p.dy));
        _autoScrollFor(d.localFocalPoint);
      case _Grab.order:
        final before = _target();
        setState(() => _finger = d.localFocalPoint);
        if (_target() != before) tapFeel();
        _autoScrollFor(d.localFocalPoint);
    }
    _syncCarry();
  }

  /// Near the top, or just above the trash, a carried thing scrolls the page.
  void _autoScrollFor(Offset p) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.hasSize) return;
    final h = me.size.height;
    double speed = 0;
    if (p.dy < kAutoScrollBand) {
      speed = -8;
    } else if (p.dy > h - kTrashHeight - kAutoScrollBand && p.dy < h - kTrashHeight) {
      speed = 8;
    }
    if (speed == 0) {
      _autoScroll?.cancel();
      _autoScroll = null;
      return;
    }
    _scrollPos ??= _findScroll();
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final pos = _scrollPos;
      if (pos == null || !_carrying) {
        _autoScroll?.cancel();
        _autoScroll = null;
        return;
      }
      final next = (pos.pixels + speed).clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (next != pos.pixels) pos.jumpTo(next);
    });
  }

  /// The live section the dragged one would land on (index among the
  /// sections on screen), or null when it stays.
  int? _target() {
    final cur = c.current?.id;
    final from = _sections.indexWhere((s) => s.$1 == cur);
    if (from < 0) return null;
    for (var i = 0; i < _sections.length; i++) {
      final r = _sections[i].$2;
      if (_finger.dy >= r.top && _finger.dy < r.bottom) return i == from ? null : i;
    }
    return null;
  }

  void _onEnd(ScaleEndDetails d) {
    final grab = _grab;
    final moved = (_finger - _start).distance > 12;
    final trash = (grab == _Grab.order || grab == _Grab.moveOrb || grab == _Grab.moveElement) && moved && _overTrash(_finger);
    final target = grab == _Grab.order ? _target() : null;
    _autoScroll?.cancel();
    _autoScroll = null;
    if (grab == _Grab.scroll) _endScroll(d.velocity.pixelsPerSecond.dy);
    setState(() => _grab = _Grab.none);
    _syncCarry();
    switch (grab) {
      case _Grab.order:
        final cur = c.current;
        if (cur == null) break;
        if (trash) {
          deleteWithUndo(context, c, cur.id, cur.title);
        } else if (target != null) {
          final from = _sections.indexWhere((s) => s.$1 == cur.id);
          // Steps count live sections, the same ones the page shows.
          final targetId = _sections[target].$1;
          final live = [for (final s in c.sections) if (!s.entry.deleted) s.id];
          final steps = live.indexOf(targetId) - live.indexOf(cur.id);
          if (from >= 0 && steps != 0) {
            bigFeel();
            c.endStep();
            c.shift(cur.id, steps);
            c.endStep();
            c.pickSection(cur.id);
          }
        }
      case _Grab.moveOrb:
        final o = _orb;
        if (o == null) break;
        if (trash) {
          bigFeel();
          c.endStep();
          c.deleteOrb(o.$1, o.$2);
          c.endStep();
          _undoBar(context, c, 'Orb removed');
          break;
        }
        // Lands in the section under it (it may have crossed into another).
        final to = _sectionAt(_finger);
        final spot = _pickedOrb;
        if (to != null && to != o.$1 && spot != null) {
          final r = _sectionRect(to)!;
          final centre = spot.rect.center;
          c.moveOrb(o.$1, to, o.$2, ((centre.dx - r.left) / r.width).clamp(0.0, 1.0), centre.dy - r.top);
        }
      case _Grab.moveElement:
        final sel = _element;
        if (sel == null || !trash) break;
        bigFeel();
        c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {'hidden': true, 'dx': null, 'dy': null});
        c.endStep();
        _undoBar(context, c, 'Removed “${slotFriendly(sel.slotKey, sel.type, sel.defaultValue)}”');
      default:
        break;
    }
    c.endStep();
  }

  void _onTapUp(TapUpDetails d) {
    final p = d.localPosition;
    final orb = _orbAt(p);
    if (orb != null) {
      actFeel();
      c.clearSelection(notify: false);
      c.sectionPicked = false;
      c.selectedOrb = (orb.section, orb.orb.id);
      c.changedSelection();
      return;
    }
    final id = _sectionAt(p);
    if (id != null) {
      actFeel();
      c.pickSection(id);
    } else {
      c.unpick();
    }
  }

  Future<void> _menu(LongPressStartDetails d) async {
    final p = d.localPosition;
    final orb = _orbAt(p);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(d.globalPosition & const Size(1, 1), Offset.zero & overlay.size);
    PopupMenuItem<String> item(String v, IconData icon, String label, {Color color = Colors.white}) => PopupMenuItem(
          value: v,
          height: 44,
          child: Row(children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ]),
        );
    if (orb != null) {
      actFeel();
      c.selectedOrb = (orb.section, orb.orb.id);
      c.changedSelection();
      final v = await showMenu<String>(context: context, color: const Color(0xFF111A2B), position: pos, items: [
        item('circle', Icons.circle, orb.orb.circle ? 'No circle' : 'Black circle'),
        item('del', Icons.delete_outline_rounded, 'Delete', color: const Color(0xFFFF8A8A)),
      ]);
      if (!mounted || v == null) return;
      c.endStep();
      if (v == 'circle') {
        c.updateOrb(orb.section, orb.orb.id, (o) => o.copyWith(circle: !o.circle));
      } else {
        c.deleteOrb(orb.section, orb.orb.id);
        if (mounted) _undoBar(context, c, 'Orb removed');
      }
      c.endStep();
      return;
    }
    final id = _sectionAt(p);
    if (id == null) return;
    actFeel();
    if (!c.sectionPicked || c.current?.id != id) c.pickSection(id);
    final cur = c.current;
    if (cur == null) return;
    final pictureKind = cur.entry.isTemplate && const {'imageBanner', 'videoBanner', 'splitPromo'}.contains(cur.entry.kind);
    final whole = '${cur.entry.props['fit'] ?? ''}' == 'contain';
    final v = await showMenu<String>(
      context: context,
      color: const Color(0xFF111A2B),
      position: pos,
      items: [
        item('back', Icons.restart_alt_rounded, 'Put back'),
        if (pictureKind)
          item('fit', whole ? Icons.crop_rounded : Icons.fit_screen_rounded, whole ? 'Fill picture' : 'Whole picture'),
        if (cur.copyable) item('dup', Icons.copy_rounded, 'Duplicate'),
        item('hide', Icons.visibility_off_rounded, 'Hide'),
        item('del', Icons.delete_outline_rounded, 'Delete', color: const Color(0xFFFF8A8A)),
      ],
    );
    if (!mounted || v == null) return;
    switch (v) {
      case 'back':
        c.putBack(cur.id);
      case 'fit':
        c.endStep();
        c.patchProps(cur.id, {'fit': whole ? null : 'contain'});
        c.endStep();
      case 'dup':
        c.endStep();
        c.duplicate(cur.id);
        c.endStep();
      case 'hide':
        c.endStep();
        c.setVisible(cur.id, false);
        c.unpick();
        c.endStep();
        if (mounted) _undoBar(context, c, 'Hidden “${cur.title}”');
      case 'del':
        deleteWithUndo(context, c, cur.id, cur.title);
    }
  }

  // ── Drops from the drawer ──────────────────────────────────────────

  bool _accepts(Object? data) {
    if (data is AnimDrop) return true;
    final fx = FxDrop.of(data);
    if (fx == null) return false;
    return true;
  }

  void _onDrop(DragTargetDetails<Object> d) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null) return;
    // Drawer tiles are dragged by the point under the finger.
    final p = me.globalToLocal(d.offset);
    setState(() => _hover = null);
    final id = _sectionAt(p);
    final data = d.data;
    if (id == null) {
      _say(c.sectioned ? 'Drop it on the page.' : 'This page is one block for now — effects and orbs need sections.');
      return;
    }
    final r = _sectionRect(id)!;
    c.endStep();
    if (data is AnimDrop) {
      bigFeel();
      c.addAnim(id, data.id, ((p.dx - r.left) / r.width).clamp(0.0, 1.0), p.dy - r.top);
      c.endStep();
      c.fxDropped();
      return;
    }
    final fx = FxDrop.of(data);
    if (fx == null) return;
    final sec = c.sections.firstWhere((s) => s.id == id);
    if (fx.carouselOnly && !sec.carousel) {
      _say('“${fx.label}” is for sections that slide sideways.');
      return;
    }
    bigFeel();
    // Entrances and loops dropped on the picked element go on it.
    final sel = _selectedSlot;
    final onElement = fx.apply == null &&
        fx.patch.keys.every(const {'entrance', 'loop'}.contains) &&
        sel != null &&
        (_slotRect(sel)?.inflate(12).contains(p) ?? false);
    if (onElement) {
      c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, fx.patch);
      c.endStep();
      c.fxDropped();
      WidgetsBinding.instance.addPostFrameCallback((_) => c.preview.replay());
      return;
    }
    c.pickSection(id);
    if (fx.apply != null) {
      fx.apply!(c, sec);
    } else {
      c.patchProps(id, fx.patch);
    }
    c.endStep();
    c.fxDropped();
    // Play it right away, once the page has the new props.
    WidgetsBinding.instance.addPostFrameCallback((_) => c.preview.replay());
  }

  void _say(String text) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.sectionPicked ? _sectionRect(c.current?.id) : null;
    final moved = (_finger - _start).distance > 6;
    final carrying = _carrying && moved;
    final ordering = _grab == _Grab.order && moved;
    final trash = carrying && _overTrash(_finger);
    final target = ordering && !trash ? _target() : null;
    final hoverId = _hover == null ? null : _sectionAt(_hover!);
    final hoverRect = _sectionRect(hoverId);
    final orbSel = c.selectedOrb;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _down = e.localPosition,
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (d) => _accepts(d.data),
        onMove: (d) {
          final me = context.findRenderObject() as RenderBox?;
          if (me != null) setState(() => _hover = me.globalToLocal(d.offset));
        },
        onLeave: (_) => setState(() => _hover = null),
        onAcceptWithDetails: _onDrop,
        builder: (context, _, __) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          onScaleStart: _onStart,
          onScaleUpdate: _onUpdate,
          onScaleEnd: _onEnd,
          onLongPressStart: _menu,
          child: Stack(fit: StackFit.expand, children: [
            widget.child,
            // Placed orbs: a ring on the picked one.
            for (final o in _orbs)
              if (orbSel == (o.section, o.orb.id))
                Positioned.fromRect(
                  rect: o.rect.inflate(6),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGold, width: 3)),
                    ),
                  ),
                ),
            if (cur != null) ...[
              Positioned.fromRect(
                rect: ordering ? cur.shift(Offset(0, _finger.dy - _start.dy)) : cur,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ordering ? kGold.withValues(alpha: 0.14) : null,
                      border: Border.all(color: kGold, width: ordering ? 3 : 2),
                    ),
                  ),
                ),
              ),
              if (!ordering) ...[
                _EdgeBar(center: Offset(cur.center.dx, cur.top), active: _grab == _Grab.padTop),
                _EdgeBar(center: Offset(cur.center.dx, cur.bottom), active: _grab == _Grab.padBottom),
              ],
            ],
            if (target != null)
              Builder(builder: (_) {
                final r = _sections[target].$2;
                final from = _sections.indexWhere((s) => s.$1 == c.current?.id);
                final y = target > from ? r.bottom : r.top;
                return Positioned(
                  left: 12,
                  right: 12,
                  top: y - 3,
                  height: 6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                );
              }),
            if (hoverRect != null)
              Positioned.fromRect(
                rect: hoverRect,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.10),
                      border: Border.all(color: kGold, width: 3),
                    ),
                  ),
                ),
              ),
            if (carrying)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: kTrashHeight,
                child: IgnorePointer(child: _Trash(hot: trash)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _EdgeBar extends StatelessWidget {
  const _EdgeBar({required this.center, required this.active});
  final Offset center;
  final bool active;

  @override
  Widget build(BuildContext context) => Positioned(
        left: center.dx - 22,
        top: center.dy - 4,
        width: 44,
        height: 8,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: active ? kGold : const Color(0xE6E8D5A3),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      );
}

/// Shows at the bottom while something is dragged: drop it here to delete.
class _Trash extends StatelessWidget {
  const _Trash({required this.hot});
  final bool hot;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [hot ? const Color(0xEEE5484D) : const Color(0xCC1B1F2A), const Color(0x00000000)],
          ),
        ),
        alignment: Alignment.center,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: hot ? 1.25 : 1,
          child: Icon(Icons.delete_rounded, color: hot ? Colors.white : const Color(0xCCFFFFFF), size: 40),
        ),
      );
}

/// Plain-words name for a slot key, for lists.
String slotFriendly(String key, SlotType type, String def) {
  if (type == SlotType.text) {
    final t = def.replaceAll('\n', ' ').trim();
    return t.length > 42 ? '${t.substring(0, 42)}…' : t;
  }
  if (type == SlotType.orb) return 'Thinking orb';
  final f = def.split('/').last.split('?').first;
  return f.isEmpty ? key.split('.').last : f;
}

/// Full-screen live preview: the whole page exactly as users will see it,
/// with every pending (unpublished) edit applied and fully interactive.
/// Uses its own preview controller holding a copy of the drafts, so the
/// editor's state is untouched.
class FullPagePreview extends StatefulWidget {
  const FullPagePreview({super.key, required this.c});
  final EditorController c;

  @override
  State<FullPagePreview> createState() => _FullPagePreviewState();
}

class _FullPagePreviewState extends State<FullPagePreview> {
  final EditorPreviewController _p = EditorPreviewController();
  bool _chrome = true;

  @override
  void initState() {
    super.initState();
    _p.draftOverrides.addAll(widget.c.preview.draftOverrides);
    _p.draftLayouts.addAll(widget.c.preview.draftLayouts);
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = appPage(widget.c.pageId) ?? kAppPages.first;
    final n = widget.c.pendingCount;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(
          child: EditorPreviewScope(
            controller: _p,
            child: Theme(data: NwsbTheme.light, child: HeroMode(enabled: false, child: page.build())),
          ),
        ),
        Positioned(
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 14,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _chrome
                ? Glass(
                    key: const ValueKey('bar'),
                    radius: 99,
                    fill: const Color(0xCC070B14),
                    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.visibility_rounded, color: kGold, size: 16),
                      const SizedBox(width: 6),
                      Text(n == 0 ? 'Live preview' : 'Preview · $n draft${n == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      IconButton(
                        tooltip: 'Hide this bar',
                        onPressed: () => setState(() => _chrome = false),
                        icon: const Icon(Icons.visibility_off_rounded, color: kDim, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Back to the editor',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ]),
                  )
                : GestureDetector(
                    key: const ValueKey('dot'),
                    onTap: () => setState(() => _chrome = true),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: const Color(0x99000000), shape: BoxShape.circle, border: Border.all(color: kGold)),
                      child: const Icon(Icons.visibility_rounded, color: kGold, size: 16),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
