/// The big live preview: the real page, in a phone frame, drawing only one
/// section at a time (with every pending edit), swiped sideways section by
/// section. In "Tap to edit" mode the page takes no taps — instead every
/// editable element on it gets a hotspot that picks it.
library;

import 'dart:async';

import 'package:flutter/material.dart';

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

  void _sync() {
    if (!mounted) return;
    if (c.pageId != _page) {
      _page = c.pageId;
      _pages.dispose();
      _pages = PageController(initialPage: 0);
      setState(() {});
      return;
    }
    final n = c.sections.length;
    if (n != _count) {
      _count = n;
      c.onReported();
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
    return EditorPreviewScope(
      controller: c.preview,
      child: secs.isEmpty
          // First paint (and pages not split into sections yet): the page
          // as a whole. A sectioned page reports its sections from here.
          ? _Frame(key: ValueKey('whole-${page.id}'), c: c, page: page, sectionId: kProbe, active: true)
          : PageView.builder(
              key: ValueKey('pv-${page.id}'),
              controller: _pages,
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
                if (active && c.pickMode && !c.arrange)
                  Positioned.fill(
                    child: _Hotspots(c: c, section: sectionId == kProbe ? null : '$pageId/$sectionId'),
                  ),
                if (active && c.arrange && sectionId != kProbe)
                  Positioned.fill(child: _ArrangeHand(c: c, sectionId: sectionId)),
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
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // Elements move (carousels, entrance animations): re-measure a few
    // times a second while the preview is on screen.
    _t = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.findRenderObject() as RenderBox?;
    final spots = <Widget>[];
    if (me != null && me.hasSize) {
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
    }
    return Stack(children: spots);
  }
}

/// Drag the section on the phone to place it. Pinch to resize. No sliders.
class _ArrangeHand extends StatefulWidget {
  const _ArrangeHand({required this.c, required this.sectionId});
  final EditorController c;
  final String sectionId;

  @override
  State<_ArrangeHand> createState() => _ArrangeHandState();
}

class _ArrangeHandState extends State<_ArrangeHand> {
  double _dx = 0;
  double _dy = 0;
  double _h = 0;
  var _pinch = false;

  Map<String, dynamic> get _props => widget.c.current?.entry.props ?? const {};

  double _num(String k) {
    final v = _props[k];
    return v is num ? v.toDouble() : 0;
  }

  void _place(double dx, double dy) {
    final id = widget.c.current?.id;
    if (id == null || id != widget.sectionId) return;
    widget.c.patchProps(id, {
      'dx': dx.abs() < 1 ? null : dx,
      'dy': dy.abs() < 1 ? null : dy,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (d) {
        _dx = _num('dx');
        _dy = _num('dy');
        _h = _num('height');
        _pinch = d.pointerCount >= 2;
      },
      onScaleUpdate: (d) {
        final id = widget.c.current?.id;
        if (id == null || id != widget.sectionId) return;
        if (d.pointerCount >= 2) {
          _pinch = true;
          final base = _h < 1 ? 200.0 : _h;
          final next = (base * d.scale).clamp(70.0, 720.0);
          widget.c.patchProps(id, {'height': next.roundToDouble()});
          return;
        }
        if (_pinch) return;
        final box = context.findRenderObject() as RenderBox?;
        var scale = 1.0;
        if (box != null && box.hasSize) {
          final a = box.localToGlobal(Offset.zero);
          final b = box.localToGlobal(const Offset(100, 0));
          final painted = (b.dx - a.dx).abs();
          if (painted > 1) scale = painted / 100;
        }
        _dx = (_dx + d.focalPointDelta.dx / scale).clamp(-220.0, 220.0);
        _dy = (_dy + d.focalPointDelta.dy / scale).clamp(-240.0, 420.0);
        _place(_dx, _dy);
      },
      child: const IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: Color(0xCCE8D5A3), width: 1.5)),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xE0060C18),
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Drag to place  ·  pinch to resize',
                    style: TextStyle(color: Color(0xFFE8D5A3), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
