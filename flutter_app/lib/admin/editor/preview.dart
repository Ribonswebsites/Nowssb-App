/// The editor's canvas: the real page, full screen, edge to edge, with
/// every pending edit — the whole page, not one section at a time. In
/// "edit" mode the page takes no taps itself; [_TouchLayer] reads every
/// touch instead (see there), so the canvas works for any page in
/// kAppPages that lays itself out in sections.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show Drag;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../theme/theme.dart';
import '../layout/anims/anim_library.dart' show animById;
import '../layout/app_pages.dart';
import '../layout/image_frame.dart';
import '../layout/placed_orbs.dart';
import '../layout/scopes.dart';
import '../layout/section_pinch.dart' show RenderSectionFitHeight;
import '../layout/side_row.dart';
import '../template/editable.dart';
import '../template/slot_keys.dart';
import 'bin.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'tab_layout.dart' show SectionDrop;

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

  /// The words being typed in place (a picked line tapped again).
  PreviewSlot? _editing;
  TextEditingController? _edit;
  final _focus = FocusNode();

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
    _edit?.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Picked/changed colours follow the editor at once.
  void _onEdit() {
    if (!mounted) return;
    // Something else picked: the words typed so far stay.
    if (_editing != null && widget.c.selectedSlot != _editing!.slotKey) _editing = null;
    setState(() {});
  }

  static String? _textOf(RenderObject? r) {
    if (r == null) return null;
    if (r is RenderParagraph) return r.text.toPlainText();
    String? found;
    r.visitChildren((x) => found ??= _textOf(x));
    return found;
  }

  /// A picked line tapped again: type over it right there.
  void _startTyping(PreviewSlot s) {
    final text = _textOf(s.box.currentContext?.findRenderObject()) ?? s.defaultValue;
    _edit?.dispose();
    _edit = TextEditingController(text: text)..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    widget.c.endStep();
    setState(() => _editing = s);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _doneTyping() {
    if (_editing == null) return;
    widget.c.endStep();
    _focus.unfocus();
    setState(() => _editing = null);
  }

  Widget _typingBox(PreviewSlot s, Rect r, Size screen) {
    final w = (r.width + 16).clamp(180.0, screen.width - 16);
    final left = (r.left - 8).clamp(8.0, screen.width - w - 8);
    return Positioned(
      key: const ValueKey('type-in-place'),
      left: left,
      top: (r.top - 8).clamp(8.0, screen.height - 60),
      width: w,
      child: Material(
        color: const Color(0xF2111A2B),
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGold, width: 2),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _edit,
                focusNode: _focus,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                cursorColor: kGold,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(12, 10, 4, 10),
                ),
                onChanged: (v) => widget.c.setText(s.slotKey, s.defaultValue, v),
                onSubmitted: (_) => _doneTyping(),
              ),
            ),
            IconButton(
              key: const ValueKey('type-done'),
              tooltip: 'Done',
              onPressed: _doneTyping,
              icon: const Icon(Icons.check_rounded, color: kGold),
            ),
          ]),
        ),
      ),
    );
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
      final shown = picked;
      spots.add(Positioned.fromRect(
        rect: r,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            actFeel();
            // Tapped again: type in place, or replace the picture.
            if (picked && s.type == SlotType.text) return _startTyping(s);
            if (picked && (s.type == SlotType.image || s.type == SlotType.video)) {
              widget.c.openWords?.call();
              return;
            }
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
    final ed = _editing;
    if (ed != null) {
      for (final (s, r) in _spots) {
        if (s.slotKey == ed.slotKey) {
          final me = context.findRenderObject() as RenderBox?;
          spots.add(_typingBox(s, r, me != null && me.hasSize ? me.size : MediaQuery.sizeOf(context)));
          break;
        }
      }
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
/// A picture, words or a button from the drawer, put beside a section.
class ElementDrop {
  const ElementDrop(this.kind);
  final BesideKind kind;
}

class AnimDrop {
  const AnimDrop(this.id);
  final String id;
}

/// Something deleted (from the strip's Delete).
void trashFeel() => HapticFeedback.heavyImpact();

/// Deletes the element [key] for real (not hidden: gone from the page for
/// everyone), with Undo. It goes to the Deleted bin.
void deleteElementWithUndo(BuildContext context, EditorController c, String key, SlotType type, String def) {
  trashFeel();
  final name = slotFriendly(key, type, def);
  final sec = c.current;
  RenderBox? box;
  for (final s in c.preview.slots.values) {
    if (s.slotKey == key && s.box.currentContext != null) {
      box = s.box.currentContext!.findRenderObject() as RenderBox?;
      break;
    }
  }
  // Taken from its section's picture (an element's own layer may be
  // mid-animation or scaled).
  final secBox = sec == null ? null : c.preview.sectionBoxes['${c.layoutPage}/${sec.id}'];
  Future<Uint8List?> shot;
  if (box != null && box.attached && box.hasSize && secBox != null && secBox.attached && secBox.hasSize) {
    final tl = secBox.globalToLocal(box.localToGlobal(Offset.zero));
    shot = captureBox(secBox, local: (tl & box.size).inflate(6));
  } else {
    shot = captureBox(box);
  }
  final item = BinItem(
    id: newBinId(),
    kind: BinKind.element,
    page: c.pageId,
    layout: c.layoutPage,
    label: type == SlotType.text ? '“$name”' : (type == SlotType.video ? 'Video · $name' : 'Picture · $name'),
    where: '${binPageTitle(c)}${sec == null ? '' : ', in “${sec.title}”'}',
    at: DateTime.now().millisecondsSinceEpoch,
    data: {'key': key, 'type': type.name, 'default': def, 'section': sec?.id},
    by: binWho(),
  );
  c.endStep();
  c.patchStyle(key, type, def, {'removed': true, 'hidden': null, 'dx': null, 'dy': null});
  c.clearSelection();
  c.endStep();
  _toBin(item, shot);
  _undoBar(context, c, 'Deleted “$name” · in the Bin', item.id);
}

/// The page's name as the owner knows it.
String binPageTitle(EditorController c) => appPage(c.pageId)?.title ?? c.pageId;

void _toBin(BinItem item, Future<Uint8List?> shot) {
  final bin = BinStore.instance;
  unawaited(bin.add(item));
  unawaited(shot.then((png) {
    if (png != null) return bin.setThumb(item.id, png);
  }));
}

/// A brief Undo just under the pill at the top, clear of the + button
/// and the strip at the bottom. Undo also takes it out of the bin.
void _undoBar(BuildContext context, EditorController c, String text, [String? binId]) {
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
    action: SnackBarAction(
      label: 'Undo',
      textColor: kGold,
      onPressed: () {
        c.undo();
        if (binId != null) unawaited(BinStore.instance.remove(binId));
      },
    ),
  ));
}

/// Deletes the orb [id] in [section], with Undo. It goes to the bin.
void deleteOrbWithUndo(BuildContext context, EditorController c, String section, String id) {
  trashFeel();
  final o = c.orbById(section, id);
  final box = c.preview.sectionBoxes['${c.layoutPage}/$section'];
  final shot = o == null || box == null || !box.attached || !box.hasSize
      ? Future<Uint8List?>.value()
      : captureBox(box, local: o.rectIn(box.size).inflate(6));
  final title = c.sections.where((s) => s.id == section).firstOrNull?.title;
  final spec = o == null ? null : (animById(o.anim) ?? animById(o.animId));
  final item = BinItem(
    id: newBinId(),
    kind: BinKind.orb,
    page: c.pageId,
    layout: c.layoutPage,
    label: spec?.name ?? 'Animation',
    where: '${binPageTitle(c)}${title == null ? '' : ', on “$title”'}',
    at: DateTime.now().millisecondsSinceEpoch,
    data: {'section': section, 'orb': o?.toJson()},
    by: binWho(),
  );
  c.endStep();
  c.deleteOrb(section, id);
  c.endStep();
  if (o != null) _toBin(item, shot);
  _undoBar(context, c, '${item.label} deleted · in the Bin', item.id);
}

/// Deletes a section at once and offers Undo (no confirm dialog: undo is
/// always there, in the snackbar, the history and the Deleted bin).
void deleteWithUndo(BuildContext context, EditorController c, String id, String title) {
  trashFeel();
  final e = c.entries.where((x) => x.id == id).firstOrNull;
  final place = c.placeOf(id);
  String? titleOf(String? sid) => sid == null ? null : c.sections.where((s) => s.id == sid).firstOrNull?.title;
  final before = titleOf(place.before);
  final after = titleOf(place.after);
  final shot = captureBox(c.preview.sectionBoxes['${c.layoutPage}/$id']);
  final banner = e != null && RegExp('anner|oupon|romo').hasMatch(e.kind);
  final item = BinItem(
    id: newBinId(),
    kind: banner ? BinKind.banner : BinKind.section,
    page: c.pageId,
    layout: c.layoutPage,
    label: title,
    where: '${binPageTitle(c)}, ${before != null ? 'after “$before”' : (after != null ? 'at the top, before “$after”' : 'section ${place.index + 1}')}',
    at: DateTime.now().millisecondsSinceEpoch,
    data: {'entry': e?.toJson(), 'before': place.before, 'after': place.after, 'index': place.index},
    by: binWho(),
  );
  c.endStep();
  c.delete(id);
  c.unpick();
  c.endStep();
  if (e != null) _toBin(item, shot);
  _undoBar(context, c, 'Deleted “$title” · in the Bin', item.id);
}

enum _Grab { none, scroll, order, pinchSection, pinchElement, moveElement, moveOrb, pinchOrb, panImage, zoomImage, frameEdge, moveBeside, boxEdge, mediaEdge }

/// Places one drag up or down moves a section when no other section is
/// under the finger (kept for callers and tests of the step maths).
const kShiftStep = 90.0;

/// How many places a vertical drag of [dy] moves a section that can go
/// [up] places up and [down] places down.
int shiftSteps(double dy, int up, int down) =>
    (dy / kShiftStep).truncate().clamp(-up, down);

/// Where carrying something near the top or bottom scrolls the page.
const kAutoScrollBand = 80.0;

/// Everything on the canvas is done by touching it:
///   tap                 pick an element, a placed orb, or a section
///   drag / fling        ALWAYS scrolls the page, picked or not: a scroll
///                       never moves or deletes anything
///   long-press, then drag   pick it up and carry it: a section to a new
///                       place (the page makes room), an element inside
///                       its section, an orb anywhere on the page
///   long-press, let go  the short menu (Put back, Hide, Duplicate…)
///   pinch               resize the orb, element or section under it
/// Deleting is only the strip's labelled Delete, with Undo.
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
  double _shrinkBase = 1;
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

  /// While a section from the drawer is carried: the gap it would land in.
  int? _hoverGap;
  /// (section id, on the right) while a new section is over a side, not a row gap.
  (String, bool)? _hoverSide;

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

  /// The smallest editable element under [p].
  PreviewSlot? _slotAt(Offset p) {
    PreviewSlot? best;
    var area = double.infinity;
    for (final s in c.preview.slots.values) {
      final r = _slotRect(s);
      if (r == null || !r.contains(p) || r.width < 4 || r.height < 4) continue;
      final a = r.width * r.height;
      if (a < area) {
        area = a;
        best = s;
      }
    }
    return best;
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

  // ── A smaller section: its side, and what is beside it ──────────────

  RenderSectionFitHeight? _fitIn(RenderObject? r) {
    if (r == null) return null;
    if (r is RenderSectionFitHeight) return r;
    RenderSectionFitHeight? found;
    r.visitChildren((x) => found ??= _fitIn(x));
    return found;
  }

  /// Where section [id] itself is drawn when made smaller than its row
  /// (null when it fills its row).
  Rect? _shrunkRect(String? id) {
    final row = _sectionRect(id);
    final box = c.preview.sectionBoxes['${c.layoutPage}/$id'];
    final fit = _fitIn(box);
    if (row == null || fit == null || !fit.attached || !fit.hasSize) return null;
    final r = _rectOf(fit);
    if (r == null) return null;
    final inner = fit.contentRect.shift(r.topLeft);
    return inner.width < row.width - 40 ? inner : null;
  }

  /// The thing beside a section under [p]: (section, item, its rect).
  (String, BesideItem, Rect)? _besideAt(Offset p) {
    for (final (id, _) in _sections) {
      for (final i in c.besideIn(id)) {
        final r = _rectOf(c.preview.besideBoxes['${c.layoutPage}/$id/${i.id}']);
        if (r != null && r.inflate(8).contains(p)) return (id, i, r);
      }
    }
    return null;
  }

  (String, String)? _beside;
  Offset _besideStart = Offset.zero;

  Future<String?> _askWords(String now) {
    final t = TextEditingController(text: now);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Words'),
        content: TextField(key: const ValueKey('beside-words'), controller: t, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, t.text), child: const Text('Save')),
        ],
      ),
    );
  }

  // ── A picked picture: pan, zoom and frame handles ───────────────────

  static const _frameKeys = ['imgZoom', 'imgX', 'imgY', 'frameL', 'frameT', 'frameR', 'frameB'];

  /// The picked element when it is a picture (image or video).
  PreviewSlot? get _pickedPicture {
    final s = _selectedSlot;
    return s != null && (s.type == SlotType.image || s.type == SlotType.video) ? s : null;
  }

  ImageFraming _framingOf(PreviewSlot s) =>
      framingOf(c.overrideOf(s.slotKey)?.style ?? const {}) ?? const ImageFraming();

  /// The picture's own box on screen. Dragging stays inside this, never a
  /// frame that can grow over the rest of the page.
  Rect? _pictureFrame(PreviewSlot? s) => _slotRect(s);

  (int, int) _edge = (0, 0);
  Map<String, double> _frameBase = const {};
  Size _pictureBase = Size.zero;

  void _patchFrame(PreviewSlot s, Map<String, double> v) {
    double r(double x) => double.parse(x.toStringAsFixed(3));
    final out = <String, dynamic>{};
    for (final k in _frameKeys) {
      if (!v.containsKey(k)) continue;
      final x = r(v[k]!);
      out[k] = (k == 'imgZoom' ? (x - 1).abs() < 0.01 : x.abs() < 0.002) ? null : x;
    }
    c.patchStyle(s.slotKey, s.type, s.defaultValue, out);
  }

  Rect? _slotRect(PreviewSlot? s) => _rectOf(s?.box.currentContext?.findRenderObject() as RenderBox?);

  Map<String, dynamic> get _props => c.current?.entry.props ?? const {};
  double _num(String k) => _props[k] is num ? (_props[k] as num).toDouble() : 0;

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
    final pic = _pickedPicture;
    if (pic != null) {
      // Image or video is selected: a pinch only moves that picture.
      // It must not shrink the section around it.
      _element = pic;
      _base = _framingOf(pic).zoom;
      _grab = _Grab.zoomImage;
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
    _shrinkBase = _num('shrink');
    if (_shrinkBase <= 0) _shrinkBase = 1;
    _base = _num('boxH');
    if (_base < 1) _base = _num('height');
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
    // A picked picture: the bottom edge changes how tall the picture is.
    // The section around it stays the size it already is.
    final pic = _pickedPicture;
    final base = _slotRect(pic);
    if (pic != null && base != null && (_start.dy - base.bottom).abs() < 28 && _start.dx >= base.left - 12 && _start.dx <= base.right + 12) {
      _element = pic;
      _base = _framingOf(pic).bottom;
      _grab = _Grab.mediaEdge;
      setState(() {});
      return;
    }
    if (pic != null && base != null && base.inflate(12).contains(_start)) {
      final f = _framingOf(pic);
      _element = pic;
      _pictureBase = base.size;
      _frameBase = {
        'imgZoom': f.zoom, 'imgX': f.x, 'imgY': f.y,
        'frameL': f.left, 'frameT': f.top, 'frameR': f.right, 'frameB': f.bottom,
      };
      _edge = (0, 0);
      _grab = _Grab.panImage;
      setState(() {});
      return;
    }
    // Section picked: the bottom edge changes the section window only.
    // It does not zoom the video.
    final secId = c.sectionPicked ? c.current?.id : null;
    final secR = _shrunkRect(secId) ?? _sectionRect(secId);
    if (secId != null && secR != null && c.selectedSlot == null && (_start.dy - secR.bottom).abs() < 32 && _start.dx >= secR.left && _start.dx <= secR.right) {
      _base = _num('boxH');
      if (_base < 1) _base = secR.height;
      _grab = _Grab.boxEdge;
      setState(() {});
      return;
    }
    {
      // One finger scrolls, whatever is picked: carrying starts only
      // with a long-press (onLongPress*).
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

  /// Long-press: pick up what is under the finger (an orb, an element,
  /// else its section). Let go without moving: its menu.
  Offset _pressGlobal = Offset.zero;

  void _onLongStart(LongPressStartDetails d) {
    _endScroll(0);
    c.endStep();
    _start = d.localPosition;
    _finger = _start;
    _pressGlobal = d.globalPosition;
    _orb = null;
    _element = null;
    final p = _start;
    _beside = null;
    final orb = _orbAt(p);
    final side = orb == null ? _besideAt(p) : null;
    if (side != null) {
      final row = _sectionRect(side.$1)!;
      _beside = (side.$1, side.$2.id);
      _besideStart = Offset(side.$2.x * row.width, side.$2.y * row.height);
      _grab = _Grab.moveBeside;
    } else if (orb != null) {
      c.selectedOrb = (orb.section, orb.orb.id);
      c.sectionPicked = false;
      c.clearSelection();
      _orb = (orb.section, orb.orb.id);
      _baseOffset = Offset(orb.orb.x * orb.box.width, orb.orb.y);
      _grab = _Grab.moveOrb;
    } else if (c.sectionPicked && c.selectedSlot == null && (_shrunkRect(c.current?.id)?.contains(p) ?? false)) {
      // A picked smaller section is held by itself (not the words in it),
      // so it can be carried to the left, the middle or the right.
      _grab = _Grab.order;
    } else {
      final sel = _selectedSlot;
      var el = sel != null && (_slotRect(sel)?.contains(p) ?? false) ? sel : _slotAt(p);
      // An element filling its section (a hero picture) lifts the section.
      if (el != null && el.slotKey != c.selectedSlot) {
        final er = _slotRect(el), sr = _sectionRect(_sectionAt(p));
        if (er != null && sr != null && er.width * er.height > 0.6 * sr.width * sr.height) el = null;
      }
      if (el != null) {
        final sec = el.section;
        final sid = sec != null && sec.startsWith('${c.layoutPage}/') ? sec.split('/').last : null;
        if (c.selectedSlot != el.slotKey) c.selectIn(sid, el.slotKey, el.type, el.defaultValue);
        final st = c.overrideOf(el.slotKey)?.style ?? const {};
        double n(String k) => st[k] is num ? (st[k] as num).toDouble() : 0;
        _element = el;
        _baseOffset = Offset(n('dx'), n('dy'));
        _grab = _Grab.moveElement;
      } else {
        final id = _sectionAt(p);
        if (id == null) {
          _grab = _Grab.none;
          return;
        }
        if (!c.sectionPicked || c.current?.id != id) c.pickSection(id);
        _grab = _Grab.order;
      }
    }
    actFeel();
    setState(() {});
  }

  void _onLongMove(LongPressMoveUpdateDetails d) {
    _carryTo(d.localPosition);
    _syncCarry();
  }

  void _onLongEnd(LongPressEndDetails d) {
    final grab = _grab;
    final moved = (_finger - _start).distance > 12;
    _autoScroll?.cancel();
    _autoScroll = null;
    setState(() => _grab = _Grab.none);
    _syncCarry();
    if (!moved) {
      _menu(_start, _pressGlobal);
      return;
    }
    _finish(grab, moved);
    c.endStep();
  }

  /// Moves what is carried to under the finger.
  void _carryTo(Offset local) {
    final total = local - _start;
    switch (_grab) {
      case _Grab.moveBeside:
        final b = _beside;
        final row = _sectionRect(b?.$1);
        if (b == null || row == null || row.isEmpty) return;
        setState(() => _finger = local);
        final at = _besideStart + total;
        c.updateBeside(b.$1, b.$2,
            (i) => i.copyWith(x: (at.dx / row.width).clamp(0.0, 1.0), y: (at.dy / row.height).clamp(0.0, 1.0)));
        return;
      case _Grab.moveElement:
        final sel = _element;
        if (sel == null) return;
        final p = _baseOffset + total;
        setState(() => _finger = local);
        c.patchStyle(sel.slotKey, sel.type, sel.defaultValue, {
          'dx': p.dx.abs() < 1 ? null : p.dx.roundToDouble(),
          'dy': p.dy.abs() < 1 ? null : p.dy.roundToDouble(),
        });
        _autoScrollFor(local);
      case _Grab.moveOrb:
        final o = _orb;
        final spot = _pickedOrb;
        if (o == null || spot == null) return;
        final p = _baseOffset + total;
        setState(() => _finger = local);
        c.updateOrb(o.$1, o.$2, (x) => x.copyWith(x: spot.box.width <= 0 ? x.x : p.dx / spot.box.width, y: p.dy));
        _autoScrollFor(local);
      case _Grab.order:
        final before = _target();
        setState(() => _finger = local);
        if (_target() != before) tapFeel();
        _autoScrollFor(local);
      default:
        break;
    }
  }

  bool get _carrying =>
      _grab == _Grab.order || _grab == _Grab.moveOrb || _grab == _Grab.moveElement || _grab == _Grab.moveBeside;

  /// Tells the screen something is being carried (it clears the bottom).
  void _syncCarry() {
    final now = _carrying && (_finger - _start).distance > 6;
    // Picked up: a firm tick the moment it leaves its place.
    if (now && !c.carrying.value) bigFeel();
    c.carrying.value = now;
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 &&
        _grab != _Grab.pinchSection &&
        _grab != _Grab.pinchElement &&
        _grab != _Grab.pinchOrb &&
        _grab != _Grab.zoomImage) {
      _startPinch(d.localFocalPoint);
      setState(() {});
    }
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
      case _Grab.panImage:
        final s = _element;
        final fr = _pictureFrame(s);
        if (s == null || fr == null || fr.isEmpty) return;
        final m = _moved(d.localFocalPoint);
        _patchFrame(s, {
          'imgX': (_frameBase['imgX']! + m.dx / fr.width).clamp(-2.0, 2.0),
          'imgY': (_frameBase['imgY']! + m.dy / fr.height).clamp(-2.0, 2.0),
        });
      case _Grab.zoomImage:
        final s = _element;
        if (s == null) return;
        _patchFrame(s, {'imgZoom': (_base * d.scale).clamp(ImageFraming.kMinZoom, ImageFraming.kMaxZoom)});
      case _Grab.mediaEdge:
        final s = _element;
        if (s == null) return;
        final next = (_base + (d.localFocalPoint.dy - _start.dy) / 220).clamp(-0.2, 0.9);
        _patchFrame(s, {'frameB': next});
      case _Grab.boxEdge:
        final id = c.current?.id;
        if (id == null) return;
        final next = (_base + (d.localFocalPoint.dy - _start.dy)).clamp(72.0, 1400.0).roundToDouble();
        c.patchProps(id, {'boxH': next, 'height': null});
      case _Grab.frameEdge:
        final s = _element;
        final w = _pictureBase.width, h = _pictureBase.height;
        if (s == null || w < 1 || h < 1) return;
        final m = _moved(d.localFocalPoint);
        final b = _frameBase;
        // The frame never gets smaller than 32dp across.
        final minW = 32 / w - 1, minH = 32 / h - 1;
        final v = <String, double>{};
        if (_edge.$1 < 0) v['frameL'] = (b['frameL']! - m.dx / w).clamp(-0.9, 4.0).clamp(minW - b['frameR']!, 4.0);
        if (_edge.$1 > 0) v['frameR'] = (b['frameR']! + m.dx / w).clamp(-0.9, 4.0).clamp(minW - b['frameL']!, 4.0);
        if (_edge.$2 < 0) v['frameT'] = (b['frameT']! - m.dy / h).clamp(-0.9, 4.0).clamp(minH - b['frameB']!, 4.0);
        if (_edge.$2 > 0) v['frameB'] = (b['frameB']! + m.dy / h).clamp(-0.9, 4.0).clamp(minH - b['frameT']!, 4.0);
        _patchFrame(s, v);
      case _Grab.pinchSection:
        final id = c.current?.id;
        if (id == null) return;
        final cur = c.current!;
        // Added banners and templates get narrower (and shorter) when
        // pinched in, so they can sit side by side; out again, full width
        // and then taller.
        final fixed = cur.entry.isTemplate && cur.entry.kind != 'textBlock' && cur.entry.kind != 'cta';
        final v = _shrinkBase * d.scale;
        if (fixed && v < 0.995) {
          c.patchProps(id, {'shrink': double.parse(v.clamp(0.3, 1.0).toStringAsFixed(3))});
        } else if (fixed && _shrinkBase < 0.995) {
          c.patchProps(id, {'shrink': null});
        } else {
          // Section window, not a zoom. The video keeps its size.
          c.patchProps(id, {'boxH': (_base * d.scale).clamp(72.0, 1400.0).roundToDouble(), 'height': null});
        }
      case _Grab.moveElement || _Grab.moveOrb || _Grab.order || _Grab.moveBeside:
        _carryTo(d.localFocalPoint);
    }
    _syncCarry();
  }

  /// How far the finger went since the gesture began.
  Offset _moved(Offset p) {
    _finger = p;
    return p - _start;
  }

  /// Near the top or the bottom, a carried thing scrolls the page.
  void _autoScrollFor(Offset p) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null || !me.hasSize) return;
    final h = me.size.height;
    double speed = 0;
    final bottom = h;
    if (p.dy < kAutoScrollBand) {
      speed = -8;
    } else if (p.dy > bottom - kAutoScrollBand && p.dy < bottom) {
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
      if (pos == null || (!_carrying && _hover == null)) {
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
    _autoScroll?.cancel();
    _autoScroll = null;
    if (grab == _Grab.scroll) _endScroll(d.velocity.pixelsPerSecond.dy);
    setState(() => _grab = _Grab.none);
    _syncCarry();
    _finish(grab, moved);
    c.endStep();
  }

  /// A carried thing let go: a section lands in its new place, an orb in
  /// the section under it. Nothing is ever deleted by a gesture.
  void _finish(_Grab grab, bool moved) {
    switch (grab) {
      case _Grab.order:
        final cur = c.current;
        final beside = _sideOfOther();
        if (cur != null && beside != null) {
          _sitBeside(cur.id, beside.$1, beside.$2);
          break;
        }
        // A smaller section carried sideways: it sits left, middle or right
        // and leaves the other side open.
        final small = _shrunkRect(cur?.id);
        final row = _sectionRect(cur?.id);
        final side = _finger.dx - _start.dx;
        final rise = _finger.dy - _start.dy;
        if (cur != null && row != null && side.abs() > 48 && side.abs() > rise.abs()) {
          final across = ((_finger.dx - row.left) / row.width).clamp(0.0, 1.0);
          bigFeel();
          c.endStep();
          c.patchProps(cur.id, {
            if (small == null) 'shrink': 0.62,
            'align': alignFor(across),
            'height': null,
          });
          c.endStep();
          break;
        }
        final target = _target();
        if (cur == null || target == null) break;
        // Steps count live sections, the same ones the page shows.
        final targetId = _sections[target].$1;
        final live = [for (final s in c.sections) if (!s.entry.deleted) s.id];
        final steps = live.indexOf(targetId) - live.indexOf(cur.id);
        if (steps != 0) {
          bigFeel();
          c.endStep();
          c.shift(cur.id, steps);
          c.endStep();
          c.pickSection(cur.id);
        }
      case _Grab.moveOrb:
        final o = _orb;
        if (o == null) break;
        // Lands in the section under it (it may have crossed into another).
        final to = _sectionAt(_finger);
        final spot = _pickedOrb;
        if (to != null && to != o.$1 && spot != null) {
          final r = _sectionRect(to)!;
          final centre = spot.rect.center;
          c.moveOrb(o.$1, to, o.$2, ((centre.dx - r.left) / r.width).clamp(0.0, 1.0), centre.dy - r.top);
        }
        bigFeel();
      case _Grab.moveElement:
        if (moved) bigFeel();
      default:
        break;
    }
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

  Future<void> _menu(Offset p, Offset global) async {
    final side = _besideAt(p);
    if (side != null) {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
      final pos = RelativeRect.fromRect(global & const Size(1, 1), Offset.zero & overlay.size);
      final (sec, item, _) = side;
      final words = item.kind == BesideKind.text || item.kind == BesideKind.button;
      final v = await showMenu<String>(context: context, color: const Color(0xFF111A2B), position: pos, items: [
        if (words)
          const PopupMenuItem(
              value: 'words',
              height: 48,
              child: Text('Change words', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        const PopupMenuItem(
            value: 'delete',
            height: 48,
            child: Text('Delete', style: TextStyle(color: Color(0xFFFF8A80), fontWeight: FontWeight.w600))),
      ]);
      if (!mounted || v == null) return;
      if (v == 'words') {
        final t = await _askWords(item.value.isEmpty ? BesideItem.defaultValue(item.kind) : item.value);
        if (t == null || !mounted) return;
        c.endStep();
        c.updateBeside(sec, item.id, (i) => i.copyWith(value: t));
        c.endStep();
      } else {
        trashFeel();
        c.endStep();
        c.removeBeside(sec, item.id);
        c.endStep();
        if (mounted) _undoBar(context, c, '${BesideItem.label(item.kind)} deleted');
      }
      return;
    }
    final orb = _orbAt(p);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = RelativeRect.fromRect(global & const Size(1, 1), Offset.zero & overlay.size);
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
      ]);
      if (!mounted || v == null) return;
      c.endStep();
      c.updateOrb(orb.section, orb.orb.id, (o) => o.copyWith(circle: !o.circle));
      c.endStep();
      return;
    }
    // An element (unless it fills its section and is not the picked one:
    // then the section's menu, so a hero picture never hides it).
    var el = _slotAt(p);
    if (el != null && el.slotKey != c.selectedSlot) {
      final er = _slotRect(el), sr = _sectionRect(_sectionAt(p));
      if (er != null && sr != null && er.width * er.height > 0.6 * sr.width * sr.height) el = null;
    }
    if (el != null) {
      actFeel();
      final sec = el.section;
      final sid = sec != null && sec.startsWith('${c.layoutPage}/') ? sec.split('/').last : null;
      c.selectIn(sid, el.slotKey, el.type, el.defaultValue);
      final st = c.overrideOf(el.slotKey)?.style ?? const {};
      final hidden = st['hidden'] == true;
      final v = await showMenu<String>(context: context, color: const Color(0xFF111A2B), position: pos, items: [
        item('back', Icons.restart_alt_rounded, 'Put back'),
        item('hide', hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded, hidden ? 'Show' : 'Hide'),
      ]);
      if (!mounted || v == null) return;
      switch (v) {
        case 'back':
          c.endStep();
          c.patchStyle(el.slotKey, el.type, el.defaultValue,
              {'dx': null, 'dy': null, 'scale': null, 'size': null, 'hidden': null, 'cropZoom': null, 'cropX': null, 'cropY': null, for (final k in _frameKeys) k: null});
          c.endStep();
        case 'hide':
          c.endStep();
          c.patchStyle(el.slotKey, el.type, el.defaultValue, {'hidden': hidden ? null : true});
          c.endStep();
          if (!hidden && mounted) _undoBar(context, c, 'Hidden “${slotFriendly(el.slotKey, el.type, el.defaultValue)}”');
      }
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
    }
  }

  // ── Drops from the drawer ──────────────────────────────────────────

  bool _accepts(Object? data) {
    if (data is AnimDrop || data is SectionDrop || data is ElementDrop) return true;
    final fx = FxDrop.of(data);
    if (fx == null) return false;
    return true;
  }

  void _onDrop(DragTargetDetails<Object> d) {
    final me = context.findRenderObject() as RenderBox?;
    if (me == null) return;
    // Drawer tiles are dragged by the point under the finger.
    final p = me.globalToLocal(d.offset);
    _autoScroll?.cancel();
    _autoScroll = null;
    setState(() {
      _hover = null;
      _hoverGap = null;
      _hoverSide = null;
    });
    final data = d.data;
    final side = data is SectionDrop ? _dropSide(p) : null;
    if (data is SectionDrop && side != null) {
      final room = side.$1;
      final onRight = side.$2;
      bigFeel();
      c.endStep();
      c.patchProps(room, {
        'shrink': 0.58,
        'align': onRight ? 'left' : 'right',
        'height': null,
      });
      final at = onRight ? c.entryIndexBefore(room) + 1 : c.entryIndexBefore(room);
      final id = c.insertTemplate(data.kind, at);
      c.patchProps(id, {'shrink': 0.42, 'align': onRight ? 'right' : 'left'});
      c.endStep();
      c.pickSection(id);
      c.fxDropped();
      return;
    }
    // Pictures, words and buttons still sit in the free room.
    final beside = data is ElementDrop;
    final room = _sectionAt(p);
    if (beside && (room ?? _nearestSection(p)) != null) {
      final id = room ?? _nearestSection(p)!;
      final r = _sectionRect(id)!;
      bigFeel();
      c.endStep();
      c.addBeside(
        id,
        data.kind,
        (p.dx - r.left) / r.width,
        (p.dy - r.top) / r.height,
      );
      c.endStep();
      c.fxDropped();
      return;
    }
    if (data is SectionDrop) {
      _dropSection(data, p);
      return;
    }
    // Between sections, or past the last one: the nearest section takes it.
    final id = _sectionAt(p) ?? _nearestSection(p);
    if (id == null) {
      _say('This page can’t take drops yet.');
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

  /// The section closest to [p] (by height on the page).
  String? _nearestSection(Offset p) {
    String? best;
    var dist = double.infinity;
    for (final (id, r) in _sections) {
      final d = p.dy < r.top ? r.top - p.dy : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
      if (d < dist) {
        dist = d;
        best = id;
      }
    }
    return best;
  }

  /// Another section's left or right side under the finger, while a section
  /// is being carried. The middle of a section stays an up/down move.
  (String, bool)? _sideOfOther() {
    final cur = c.current?.id;
    if ((_finger - _start).distance < 24) return null;
    for (final (id, r) in _sections) {
      if (id == cur || r.width < 1) continue;
      if (_finger.dy < r.top + 6 || _finger.dy > r.bottom - 6) continue;
      final x = (_finger.dx - r.left) / r.width;
      if (x >= 0.56) return (id, true);
      if (x <= 0.44) return (id, false);
    }
    return null;
  }

  /// Puts [moving] on the left or right of [host]. Both get narrower so
  /// they share the row. Neither one is zoomed to do it.
  void _sitBeside(String moving, String host, bool onRight) {
    final live = [for (final s in c.sections) if (!s.entry.deleted) s.id];
    final hi = live.indexOf(host);
    final mi = live.indexOf(moving);
    if (hi < 0 || mi < 0 || hi == mi) return;
    final want = (onRight ? (mi < hi ? hi : hi + 1) : (mi < hi ? hi - 1 : hi)).clamp(0, live.length - 1);
    bigFeel();
    c.endStep();
    final steps = want - mi;
    if (steps != 0) c.shift(moving, steps);
    c.patchProps(host, {'shrink': 0.58, 'align': onRight ? 'left' : 'right', 'height': null});
    c.patchProps(moving, {'shrink': 0.42, 'align': onRight ? 'right' : 'left', 'height': null});
    c.endStep();
    c.pickSection(moving);
  }

  /// A drawer section over the side of a row, not between rows.
  (String, bool)? _dropSide(Offset p) {
    final room = _sectionAt(p);
    final row = _sectionRect(room);
    if (room == null || row == null || row.width < 1) return null;
    if (p.dy < row.top || p.dy > row.bottom) return null;
    final small = _shrunkRect(room);
    if (small != null && !small.inflate(8).contains(p)) {
      return (room, p.dx >= small.center.dx);
    }
    final x = (p.dx - row.left) / row.width;
    if (x <= 0.30) return (room, false);
    if (x >= 0.70) return (room, true);
    return null;
  }

  /// Where a section carried at [p] lands: the gap before live section
  /// `_sections[i]` (i == length: after the last). The upper half of a
  /// section puts it above, the lower half below.
  int? _gapAt(Offset p) {
    if (_sections.isEmpty) return null;
    for (var i = 0; i < _sections.length; i++) {
      if (p.dy < _sections[i].$2.center.dy) return i;
    }
    return _sections.length;
  }

  /// The height of the insertion line for gap [g].
  double _gapY(int g) {
    if (g <= 0) return _sections.first.$2.top;
    if (g >= _sections.length) return _sections.last.$2.bottom;
    return (_sections[g - 1].$2.bottom + _sections[g].$2.top) / 2;
  }

  void _dropSection(SectionDrop d, Offset p) {
    final g = _gapAt(p);
    if (g == null) {
      _say('This page can’t take new sections yet.');
      return;
    }
    final at = g < _sections.length
        ? c.entryIndexBefore(_sections[g].$1)
        : c.entryIndexBefore(_sections.last.$1) + 1;
    bigFeel();
    c.endStep();
    final id = c.insertTemplate(d.kind, at);
    c.endStep();
    c.sectionPicked = true;
    c.fxDropped();
    // Picked once the page has drawn it, and its entrance plays.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      c.pickSection(id);
      c.preview.replay();
    });
  }

  void _say(String text) {
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.sectionPicked ? (_shrunkRect(c.current?.id) ?? _sectionRect(c.current?.id)) : null;
    final moved = (_finger - _start).distance > 6;
    final carrying = _carrying && moved;
    final ordering = _grab == _Grab.order && moved;
    final sideNow = ordering ? _sideOfOther() : null;
    final target = ordering && sideNow == null ? _target() : null;
    final hoverGap = _hoverGap != null && _sections.isNotEmpty ? _hoverGap : null;
    final hoverId = _hover == null || hoverGap != null ? null : (_sectionAt(_hover!) ?? _nearestSection(_hover!));
    final hoverRect = _sectionRect(hoverId);
    final orbSel = c.selectedOrb;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _down = e.localPosition,
      child: DragTarget<Object>(
        onWillAcceptWithDetails: (d) => _accepts(d.data),
        onMove: (d) {
          final me = context.findRenderObject() as RenderBox?;
          if (me == null) return;
          final p = me.globalToLocal(d.offset);
          final side = d.data is SectionDrop ? _dropSide(p) : null;
          final gap = d.data is SectionDrop && side == null ? _gapAt(p) : null;
          if (gap != _hoverGap) tapFeel();
          setState(() {
            _hover = p;
            _hoverGap = gap;
            _hoverSide = side;
          });
          _autoScrollFor(p);
        },
        onLeave: (_) => setState(() {
          _hover = null;
          _hoverGap = null;
          _hoverSide = null;
        }),
        onAcceptWithDetails: _onDrop,
        builder: (context, _, __) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          onScaleStart: _onStart,
          onScaleUpdate: _onUpdate,
          onScaleEnd: _onEnd,
          onLongPressStart: _onLongStart,
          onLongPressMoveUpdate: _onLongMove,
          onLongPressEnd: _onLongEnd,
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
              // Glides from section to section; follows the finger exactly.
              AnimatedPositioned.fromRect(
                key: const ValueKey('section-outline'),
                duration: ordering ? Duration.zero : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                rect: ordering
                    ? (_shrunkRect(c.current?.id)?.shift(_finger - _start) ?? cur.shift(Offset(0, _finger.dy - _start.dy)))
                    : cur,
                // A subtle highlight on the one picked section, nothing else.
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kGold.withValues(alpha: 0.35), width: 1),
                    ),
                  ),
                ),
              ),
            ],
            if (_pickedPicture case final pic?)
              if (_slotRect(pic) case final r?)
                Positioned.fromRect(
                  key: const ValueKey('picture-frame'),
                  rect: r,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGold, width: 2),
                      ),
                    ),
                  ),
                ),
            if (target != null)
              Builder(builder: (_) {
                final r = _sections[target].$2;
                final from = _sections.indexWhere((s) => s.$1 == c.current?.id);
                final y = target > from ? r.bottom : r.top;
                return AnimatedPositioned(
                  key: const ValueKey('order-line'),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
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
            if (sideNow != null)
              Builder(builder: (_) {
                final r = _sectionRect(sideNow.$1);
                if (r == null) return const SizedBox.shrink();
                return Positioned(
                  key: const ValueKey('side-line'),
                  left: sideNow.$2 ? r.right - 10 : r.left + 4,
                  top: r.top + 10,
                  width: 6,
                  height: (r.height - 20).clamp(24, 2000),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                );
              }),
            if (_hoverSide != null)
              Builder(builder: (_) {
                final r = _sectionRect(_hoverSide!.$1);
                if (r == null) return const SizedBox.shrink();
                final onRight = _hoverSide!.$2;
                return Positioned(
                  key: const ValueKey('side-line'),
                  left: onRight ? r.right - 10 : r.left + 4,
                  top: r.top + 10,
                  width: 6,
                  height: (r.height - 20).clamp(24, 2000),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                );
              })
            else if (hoverRect != null)
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
            if (hoverGap != null && _hoverSide == null) InsertLine(y: _gapY(hoverGap)),
          ]),
        ),
      ),
    );
  }
}

/// Where a carried section will land: a bright line across the page with
/// a dot at each end.
class InsertLine extends StatelessWidget {
  const InsertLine({super.key, required this.y});
  final double y;

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
        key: const ValueKey('insert-line'),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        left: 6,
        right: 6,
        top: y - 9,
        height: 18,
        child: IgnorePointer(
          child: Row(children: [
            _dot(),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.7), blurRadius: 12)],
                ),
              ),
            ),
            _dot(),
          ]),
        ),
      );

  static Widget _dot() => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: kGold,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
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
