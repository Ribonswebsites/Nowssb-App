/// The big live preview: the real page, in a phone frame, drawing only one
/// section at a time (with every pending edit), swiped sideways section by
/// section. In "Tap to edit" mode the page takes no taps — instead every
/// editable element on it gets a hotspot that picks it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/theme.dart';
import '../layout/app_pages.dart';
import '../layout/scopes.dart';
import '../template/editable.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
import 'glass.dart';

const kProbe = '__probe__';

class EditorPreview extends StatefulWidget {
  const EditorPreview({super.key, required this.c});
  final EditorController c;

  @override
  State<EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends State<EditorPreview> {
  late PageController _pages = PageController(initialPage: widget.c.index);
  String _page = '';
  int _count = 0;

  EditorController get c => widget.c;

  @override
  void initState() {
    super.initState();
    _page = c.pageId;
    c.addListener(_sync);
  }

  @override
  void dispose() {
    c.removeListener(_sync);
    _pages.dispose();
    super.dispose();
  }

  /// What the phone frames depend on. The editor screen no longer rebuilds
  /// the preview on every change (each keystroke used to rebuild the whole
  /// page); drafts reach the page through EditorPreviewScope, and the frames
  /// rebuild only when one of these changes.
  Object _frameState() => (
        c.index,
        c.pickMode,
        c.largeFrame,
        c.sections.map((s) => s.id).join('|'),
      );
  Object? _shown;

  void _sync() {
    if (!mounted) return;
    if (c.pageId != _page) {
      _page = c.pageId;
      _pages.dispose();
      _pages = PageController(initialPage: 0);
      _shown = _frameState();
      setState(() {});
      return;
    }
    final n = c.sections.length;
    if (n != _count) {
      _count = n;
      c.onReported();
    }
    final now = _frameState();
    if (now != _shown) {
      _shown = now;
      setState(() {});
    }
    if (_pages.hasClients) {
      final cur = (_pages.page ?? _pages.initialPage.toDouble()).round();
      if (cur != c.index && c.index < n) {
        _pages.animateToPage(c.index, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = appPage(c.pageId) ?? kAppPages.first;
    final secs = c.sections;
    _shown = _frameState();
    return EditorPreviewScope(
      controller: c.preview,
      child: secs.isEmpty
          // First paint (and pages not split into sections yet): the page
          // as a whole. A sectioned page reports its sections from here.
          ? _Frame(key: ValueKey('whole-${page.id}'), c: c, page: page, sectionId: kProbe, active: true)
          : PageView.builder(
              key: ValueKey('pv-${page.id}'),
              controller: _pages,
              // Sideways swipes turn to the next section; up/down drags and
              // pinches belong to the section (see _TouchLayer). In "Try it"
              // the page itself takes the touches.
              physics: c.pickMode ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
              itemCount: secs.length,
              onPageChanged: (i) {
                tapFeel();
                c.goTo(i);
              },
              itemBuilder: (context, i) => _Frame(
                key: ValueKey('f-${page.id}-${secs[i].id}'),
                c: c,
                page: page,
                sectionId: secs[i].id,
                active: i == c.index,
              ),
            ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({super.key, required this.c, required this.page, required this.sectionId, required this.active});
  final EditorController c;
  final AppPage page;
  final String sectionId;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final size = c.largeFrame ? const Size(430, 932) : const Size(360, 740);
    final pageId = page.jumpTo?.$1 ?? page.id;
    final mq = MediaQuery.of(context);
    Widget screen = MediaQuery(
      data: mq.copyWith(
        size: size,
        padding: const EdgeInsets.only(top: 28, bottom: 18),
        viewPadding: const EdgeInsets.only(top: 28, bottom: 18),
        viewInsets: EdgeInsets.zero,
      ),
      child: Theme(
        data: NwsbTheme.light,
        child: HeroMode(
          enabled: false,
          child: PreviewIsolateScope(
            pageId: pageId,
            sectionId: sectionId,
            child: page.build(),
          ),
        ),
      ),
    );
    screen = AbsorbPointer(absorbing: c.pickMode, child: screen);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Container(
          // 8 padding + 2 border on each side: the screen gets exactly [size].
          width: size.width + 20,
          height: size.height + 20,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(52),
            border: Border.all(color: const Color(0x33FFFFFF), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 40, offset: Offset(0, 18))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(44),
            child: SizedBox.fromSize(
              size: size,
              child: Stack(children: [
                Positioned.fill(child: RepaintBoundary(child: screen)),
                // Everything is done by touching the section itself: tap an
                // element to select it, drag up/down to move, pinch to
                // resize, drag its top/bottom edge for space, long-press for
                // the few things left, drop an effect from the drawer on it.
                if (active && c.pickMode)
                  Positioned.fill(
                    child: _FxDropZone(
                      c: c,
                      child: _TouchLayer(
                        c: c,
                        sectionId: sectionId == kProbe ? null : sectionId,
                        child: _Hotspots(c: c, section: sectionId == kProbe ? null : '$pageId/$sectionId'),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable outlines over every editable element of the current section.
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
      if (r.width < 4 || r.height < 4) continue;
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
    for (final (s, r) in _spots) {
      final picked = widget.c.selectedSlot == s.slotKey;
      final changed = widget.c.overrideOf(s.slotKey) != null;
      spots.add(Positioned.fromRect(
        rect: r,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            actFeel();
            widget.c.select(s.slotKey, s.type, s.defaultValue);
          },
          child: AnimatedContainer(
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

/// An effect from the Animation drawer, dragged onto a section.
class FxDrop {
  const FxDrop(this.label, this.patch, {this.carouselOnly = false, this.apply});
  final String label;

  /// Props it sets on the section (null = remove).
  final Map<String, dynamic> patch;

  /// Page turns and auto-rotate only mean something on a sideways section.
  final bool carouselOnly;

  /// Instead of [patch], for effects that live elsewhere (the orb).
  final void Function(EditorController c, SectionInfo section)? apply;

  /// Drawer tiles may carry extra data alongside the effect.
  static FxDrop? of(Object? data) => switch (data) {
        FxDrop d => d,
        (FxDrop d, _) => d,
        _ => null,
      };
}

/// Deletes a section at once and offers Undo (no confirm dialog: undo is
/// always there, in the snackbar and in the history).
void deleteWithUndo(BuildContext context, EditorController c, String id, String title) {
  bigFeel();
  c.endStep();
  c.delete(id);
  c.endStep();
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF111A2B),
    duration: const Duration(seconds: 4),
    content: Text('Deleted “$title”', style: const TextStyle(color: Colors.white)),
    action: SnackBarAction(label: 'Undo', textColor: kGold, onPressed: c.undo),
  ));
}

/// Takes effects dragged from the drawer and puts them on the section on
/// the preview.
class _FxDropZone extends StatelessWidget {
  const _FxDropZone({required this.c, required this.child});
  final EditorController c;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        final fx = FxDrop.of(d.data);
        final cur = c.current;
        return fx != null && cur != null && (!fx.carouselOnly || cur.carousel);
      },
      onAcceptWithDetails: (d) {
        final fx = FxDrop.of(d.data);
        final cur = c.current;
        if (fx == null || cur == null) return;
        bigFeel();
        c.endStep();
        if (fx.apply != null) {
          fx.apply!(c, cur);
        } else {
          c.patchProps(cur.id, fx.patch);
        }
        c.endStep();
        // Play it on the phone right away.
        c.preview.replay();
      },
      builder: (context, candidates, rejected) => Stack(fit: StackFit.expand, children: [
        child,
        if (candidates.isNotEmpty || rejected.any((r) => FxDrop.of(r) != null))
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (candidates.isNotEmpty ? kGold : const Color(0xFFFF6B6B)).withValues(alpha: 0.12),
                border: Border.all(color: candidates.isNotEmpty ? kGold : const Color(0xFFFF6B6B), width: 4),
              ),
            ),
          ),
      ]),
    );
  }
}

enum _Grab { none, order, padTop, padBottom, pinchSection, pinchText }

/// Places one drag up or down moves a section: one place per this many
/// points of the phone picture.
const kShiftStep = 90.0;

/// How many places a vertical drag of [dy] (phone points) moves a section
/// that can go [up] places up and [down] places down.
int shiftSteps(double dy, int up, int down) =>
    (dy / kShiftStep).truncate().clamp(-up, down);

/// Height of the trash zone that shows at the bottom while a section is
/// dragged (phone points).
const kTrashHeight = 96.0;

/// How close to a section's top/bottom edge a drag must start to change the
/// space above/below instead of moving it (phone points).
const kEdgeGrab = 22.0;

/// The touch surface over the section on the preview.
///   drag up/down        move it (the page makes room); onto the trash = delete
///   drag its top/bottom edge   space above / below
///   pinch               resize the section, or the selected text
///   long-press          Put back · Duplicate · Hide · Delete
/// Taps go through to [child] (the element outlines) to select.
class _TouchLayer extends StatefulWidget {
  const _TouchLayer({required this.c, required this.sectionId, required this.child});
  final EditorController c;

  /// Null when the page is one block (only elements can be touched).
  final String? sectionId;
  final Widget child;

  @override
  State<_TouchLayer> createState() => _TouchLayerState();
}

class _TouchLayerState extends State<_TouchLayer> {
  EditorController get c => widget.c;

  var _grab = _Grab.none;
  double _base = 0;
  Offset _start = Offset.zero;
  Offset _finger = Offset.zero;
  double _drag = 0;
  (int, int) _range = (0, 0);

  /// The section's content on this surface, as last measured.
  Rect? _rect;
  var _watching = false;

  @override
  void initState() {
    super.initState();
    _watch();
  }

  /// Same as the outlines: re-measure after frames drawn anyway.
  void _watch() {
    if (_watching) return;
    _watching = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watching = false;
      if (!mounted) return;
      final r = _measure();
      if (!_near(r, _rect)) setState(() => _rect = r);
      _watch();
    });
  }

  static bool _near(Rect? a, Rect? b) {
    if (a == null || b == null) return a == b;
    return (a.left - b.left).abs() < 0.5 &&
        (a.top - b.top).abs() < 0.5 &&
        (a.width - b.width).abs() < 0.5 &&
        (a.height - b.height).abs() < 0.5;
  }

  Rect? _rectOf(RenderBox? box) {
    final me = context.findRenderObject() as RenderBox?;
    if (box == null || me == null || !box.attached || !me.attached || !box.hasSize || !me.hasSize) return null;
    final tl = me.globalToLocal(box.localToGlobal(Offset.zero));
    final br = me.globalToLocal(box.localToGlobal(box.size.bottomRight(Offset.zero)));
    return Rect.fromPoints(tl, br);
  }

  Rect? _measure() {
    final id = widget.sectionId;
    if (id == null) return null;
    return _rectOf(c.preview.sectionBoxes['${c.layoutPage}/$id']);
  }

  PreviewSlot? get _selected {
    final k = c.selectedSlot;
    if (k == null) return null;
    for (final s in c.preview.slots.values) {
      if (s.slotKey == k && s.box.currentContext != null) return s;
    }
    return null;
  }

  Map<String, dynamic> get _props => c.current?.entry.props ?? const {};
  double _num(String k) => _props[k] is num ? (_props[k] as num).toDouble() : 0;
  bool get _mine => widget.sectionId != null && c.current?.id == widget.sectionId;

  /// Bottom strip of this surface where a dragged section is dropped to
  /// delete it.
  bool _overTrash(Offset p) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.hasSize) return false;
    return p.dy > me.size.height - kTrashHeight;
  }

  void _startPinch(Offset focal) {
    final sel = _selected;
    if (sel != null && sel.type == SlotType.text) {
      final r = _rectOf(sel.box.currentContext?.findRenderObject() as RenderBox?);
      if (r != null && r.inflate(16).contains(focal)) {
        final st = c.overrideOf(sel.slotKey)?.style ?? const {};
        _base = st['size'] is num
            ? (st['size'] as num).toDouble()
            : (_fontSize(sel.box.currentContext?.findRenderObject()) ?? 16);
        _grab = _Grab.pinchText;
        return;
      }
    }
    if (!_mine) {
      _grab = _Grab.none;
      return;
    }
    _base = _num('height');
    if (_base < 1) {
      // No saved height yet: start from the size the section has now.
      _base = c.preview.sectionHeights['${c.layoutPage}/${widget.sectionId}'] ?? 200;
    }
    _grab = _Grab.pinchSection;
  }

  static double? _fontSize(RenderObject? r) {
    if (r == null) return null;
    if (r is RenderParagraph) return r.text.style?.fontSize;
    double? found;
    r.visitChildren((x) => found ??= _fontSize(x));
    return found;
  }

  /// Where the finger first went down: a scale gesture only starts after
  /// the finger has moved a little, so its start point is already past it.
  Offset? _down;

  void _onStart(ScaleStartDetails d) {
    c.endStep();
    _start = _down ?? d.localFocalPoint;
    _finger = d.localFocalPoint;
    // Count the movement made before the gesture was recognised.
    _drag = d.pointerCount >= 2 ? 0 : d.localFocalPoint.dy - _start.dy;
    if (d.pointerCount >= 2) {
      _startPinch(d.localFocalPoint);
      return;
    }
    if (!_mine) {
      _grab = _Grab.none;
      return;
    }
    final r = _rect;
    final p = _start;
    if (r != null && p.dx >= r.left && p.dx <= r.right && (p.dy - r.top).abs() < kEdgeGrab) {
      _grab = _Grab.padTop;
      _base = _num('padTop');
    } else if (r != null && p.dx >= r.left && p.dx <= r.right && (p.dy - r.bottom).abs() < kEdgeGrab) {
      _grab = _Grab.padBottom;
      _base = _num('padBottom');
    } else {
      _grab = _Grab.order;
      _range = c.shiftRange(widget.sectionId!);
    }
    setState(() {});
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 && _grab != _Grab.pinchSection && _grab != _Grab.pinchText) {
      _startPinch(d.localFocalPoint);
      setState(() {});
    }
    final id = widget.sectionId;
    switch (_grab) {
      case _Grab.none:
        return;
      case _Grab.pinchText:
        final sel = _selected;
        if (sel == null) return;
        final v = (_base * d.scale).clamp(8.0, 96.0).roundToDouble();
        c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {'size': v});
      case _Grab.pinchSection:
        if (!_mine) return;
        final next = (_base * d.scale).clamp(70.0, 720.0);
        c.patchProps(id!, {'height': next.roundToDouble()});
      case _Grab.padTop || _Grab.padBottom:
        if (!_mine) return;
        // focalPointDelta is in this surface's own (phone point) space.
        _drag += d.focalPointDelta.dy;
        // Dragging the top edge down, or the bottom edge down, adds space.
        final v = (_base + _drag).clamp(0.0, 160.0).roundToDouble();
        c.patchProps(id!, {_grab == _Grab.padTop ? 'padTop' : 'padBottom': v < 1 ? null : v});
      case _Grab.order:
        final before = _steps;
        setState(() {
          _drag += d.focalPointDelta.dy;
          _finger = d.localFocalPoint;
        });
        if (_steps != before) tapFeel();
    }
  }

  int get _steps => shiftSteps(_drag, _range.$1, _range.$2);

  void _onEnd(ScaleEndDetails d) {
    final grab = _grab;
    final id = widget.sectionId;
    final trash = grab == _Grab.order && (_finger - _start).distance > 12 && _overTrash(_finger);
    final steps = grab == _Grab.order ? _steps : 0;
    setState(() {
      _grab = _Grab.none;
      _drag = 0;
    });
    c.endStep();
    if (id == null || !_mine) return;
    if (trash) {
      deleteWithUndo(context, c, id, c.current?.title ?? id);
      return;
    }
    if (steps != 0) {
      bigFeel();
      c.shift(id, steps);
      c.endStep();
    }
  }

  Future<void> _menu(LongPressStartDetails d) async {
    final cur = c.current;
    if (!_mine || cur == null) return;
    actFeel();
    final pictureKind =
        cur.entry.isTemplate && const {'imageBanner', 'videoBanner', 'splitPromo'}.contains(cur.entry.kind);
    final whole = '${cur.entry.props['fit'] ?? ''}' == 'contain';
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final at = d.globalPosition;
    PopupMenuItem<String> item(String v, IconData icon, String label, {Color color = Colors.white}) => PopupMenuItem(
          value: v,
          height: 44,
          child: Row(children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ]),
        );
    final v = await showMenu<String>(
      context: context,
      color: const Color(0xFF111A2B),
      position: RelativeRect.fromRect(at & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        item('back', Icons.restart_alt_rounded, 'Put back'),
        if (pictureKind)
          item('fit', whole ? Icons.crop_rounded : Icons.fit_screen_rounded, whole ? 'Fill picture' : 'Whole picture'),
        if (cur.copyable) item('dup', Icons.copy_rounded, 'Duplicate'),
        item('hide', cur.entry.visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            cur.entry.visible ? 'Hide' : 'Show'),
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
        c.setVisible(cur.id, !cur.entry.visible);
        c.endStep();
      case 'del':
        deleteWithUndo(context, c, cur.id, cur.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _rect;
    final ordering = _grab == _Grab.order && (_finger - _start).distance > 6;
    final trash = ordering && _overTrash(_finger);
    final steps = ordering && !trash ? _steps : 0;
    final lift = ordering ? _drag.clamp(-kShiftStep * 3, kShiftStep * 3) : 0.0;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _down = e.localPosition,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onStart,
        onScaleUpdate: _onUpdate,
        onScaleEnd: _onEnd,
        onLongPressStart: widget.sectionId == null ? null : _menu,
        child: Stack(fit: StackFit.expand, children: [
          widget.child,
          if (r != null && _mine) ...[
            // The section itself: outline (following the finger while it is
            // moved) and a grab bar on its top and bottom edge.
            Positioned.fromRect(
              rect: r.shift(Offset(0, lift)),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ordering ? kGold.withValues(alpha: 0.14) : null,
                    border: Border.all(color: ordering ? kGold : const Color(0x99E8D5A3), width: ordering ? 3 : 1.5),
                  ),
                ),
              ),
            ),
            if (!ordering) ...[
              _EdgeBar(center: Offset(r.center.dx, r.top), active: _grab == _Grab.padTop),
              _EdgeBar(center: Offset(r.center.dx, r.bottom), active: _grab == _Grab.padBottom),
            ],
          ],
          if (steps != 0)
            Positioned(
              left: (_finger.dx - 34).clamp(4.0, double.infinity),
              top: (_finger.dy - 64).clamp(4.0, double.infinity),
              child: IgnorePointer(child: _Badge(steps)),
            ),
          if (ordering)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: kTrashHeight,
              child: IgnorePointer(child: _Trash(hot: trash)),
            ),
        ]),
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
              color: active ? kGold : const Color(0xCCE8D5A3),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      );
}

/// "↑ 2" / "↓ 1": how many places the section will move.
class _Badge extends StatelessWidget {
  const _Badge(this.steps);
  final int steps;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(steps < 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: kInk, size: 22),
          const SizedBox(width: 4),
          Text('${steps.abs()}', style: const TextStyle(color: kInk, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      );
}

/// Shows at the bottom while a section is dragged: drop it here to delete.
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
