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
                if (active && c.pickMode)
                  Positioned.fill(
                    child: _Hotspots(c: c, section: sectionId == kProbe ? null : '$pageId/$sectionId'),
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
