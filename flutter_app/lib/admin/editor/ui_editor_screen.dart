/// Admin → UI Editor: the real page, full screen, edge to edge.
///
/// Nothing sits on the page permanently except a small handle at the top
/// and the + button. The handle opens a floating pill (back · page ·
/// undo/redo · publish · more); the pill also opens for a few seconds
/// after each change, so undo is right there, then folds away again. Everything else appears only when needed:
///   +            opens a drawer from the bottom with tabs inside it — Add
///                (ready-made sections), Effects and Orbs (drag them onto
///                the page) and Sections (a map of the page);
///   touch        tap to select, drag to move, pinch to resize, drag onto
///                the trash to delete, long-press for the rest (preview.dart);
///   selection    a small strip for whatever is touched, which opens its
///                own sheet (style, words, picture) — there is no Style tab.
///
/// A one-time hint explains the touches (any touch dismisses it).
///
/// Edits wait on this phone until Publish.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin_state.dart';
import '../layout/anims/anim_library.dart';
import '../layout/app_pages.dart';
import '../layout/placed_orbs.dart';
import '../template/all_slots_screen.dart';
import '../template/slot_keys.dart';
import 'bin_page.dart';
import 'editor_controller.dart';
import 'movable.dart';
import 'tab_look.dart';
import 'glass.dart';
import 'preview.dart';
import 'tab_animation.dart';
import 'tab_content.dart';
import 'tab_layout.dart';
import 'tab_publish.dart';
import 'tab_style.dart';

void openUiEditor(BuildContext context, {String page = 'home.normal'}) {
  if (!AdminState.instance.isAdmin) return;
  Navigator.of(context).push(PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => UiEditorScreen(initialPage: page),
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  ));
}

class UiEditorScreen extends StatefulWidget {
  const UiEditorScreen({super.key, this.initialPage = 'home.normal', this.controller});
  final String initialPage;

  /// For tests: drive and inspect the editor. The screen disposes it.
  @visibleForTesting
  final EditorController? controller;

  @override
  State<UiEditorScreen> createState() => _UiEditorScreenState();
}

/// How long the pill stays open after a change or a tap.
const kPillOpenFor = Duration(seconds: 4);

/// The tabs inside the + drawer.
const kDrawerTabs = <(String, IconData)>[
  ('Sections', Icons.dashboard_customize_rounded),
  ('Effects', Icons.animation_rounded),
  ('Orbs', Icons.blur_circular_rounded),
  ('Loaders', Icons.autorenew_rounded),
  ('Backgrounds', Icons.gradient_rounded),
  ('Particles', Icons.grain_rounded),
  ('Celebrate', Icons.celebration_rounded),
  ('Map', Icons.view_agenda_outlined),
];

class _UiEditorScreenState extends State<UiEditorScreen> {
  late final EditorController c = widget.controller ?? EditorController();

  /// One instance: rebuilding this screen (every edit does) then skips the
  /// page, which listens to [c] itself and rebuilds only what changed.
  late final Widget _preview = EditorPreview(c: c);
  bool _full = false;

  /// The + drawer: null = closed, else the tab showing.
  int? _drawer;
  int _drops = 0;

  /// The one-time "tap / drag / pinch / +" hint.
  bool _hint = false;

  @override
  void initState() {
    super.initState();
    c.openPage(widget.initialPage);
    _drops = c.fxDrops;
    _pillSig = _sig();
    c.addListener(_on);
    c.carrying.addListener(_onCarry);
    c.openWords = _wordsSheet;
    _pillLater();
    _loadHint();
    _loadSpots();
  }

  /// Where the + and the folded pill were left (null: their usual place).
  Offset? _addSpot;
  Offset? _handleSpot;

  Future<void> _loadSpots() async {
    final add = await loadSpot(kAddSpotKey);
    final handle = await loadSpot(kHandleSpotKey);
    if (!mounted) return;
    setState(() {
      _addSpot = add;
      _handleSpot = handle;
    });
  }

  /// The open pill sits where its handle was left.
  double _pillTop(MediaQueryData mq) {
    final f = _handleSpot;
    final top = mq.padding.top + 8;
    if (f == null) return top;
    return (f.dy * mq.size.height).clamp(top, (mq.size.height - 140).clamp(top, double.infinity));
  }

  Future<void> _loadHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(kTouchHintSeen) ?? false) return;
      if (mounted) setState(() => _hint = true);
    } catch (_) {
      // No preferences (tests, odd platforms): skip the hint.
    }
  }

  Future<void> _dismissHint() async {
    setState(() => _hint = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kTouchHintSeen, true);
    } catch (_) {}
  }

  void _onCarry() {
    if (mounted) setState(() {});
  }

  // ── The pill: open for a few seconds, then just a small handle ─────

  bool _pillOpen = true;
  Timer? _pillTimer;
  String _pillSig = '';

  /// Undo/redo/publish state: when it changes the pill opens briefly.
  String _sig() => '${c.canUndo}|${c.canRedo}|${c.pendingCount}|${c.pickMode}';

  /// Collapse after a while (never while one of its sheets or menus is up).
  void _pillLater() {
    _pillTimer?.cancel();
    _pillTimer = Timer(kPillOpenFor, () {
      if (mounted) setState(() => _pillOpen = false);
    });
  }

  void _pillHold() => _pillTimer?.cancel();

  void _showPill() {
    if (!_pillOpen) setState(() => _pillOpen = true);
    _pillLater();
  }

  void _on() {
    if (!mounted) return;
    final sig = _sig();
    if (sig != _pillSig) {
      _pillSig = sig;
      _pillOpen = true;
      _pillLater();
    }
    // Something from the drawer landed on the page: the drawer is done.
    if (c.fxDrops != _drops) {
      _drops = c.fxDrops;
      _drawer = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pillTimer?.cancel();
    c.carrying.removeListener(_onCarry);
    c.removeListener(_on);
    c.dispose();
    super.dispose();
  }

  Future<void> _openFull() async {
    bigFeel();
    // The page holds GlobalKeys: drop the editing copy while the big one is up.
    setState(() => _full = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => FullPagePreview(c: c),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child),
      ),
    ));
    if (mounted) setState(() => _full = false);
  }

  Future<bool> _confirmLeave() async {
    if (c.pendingCount == 0) return true;
    return confirmAction(context, 'Leave without publishing?',
        '${c.pendingCount} change(s) are only on this phone. They will be lost.',
        yes: 'Leave');
  }

  void _openDrawer([int tab = 0]) {
    tapFeel();
    setState(() => _drawer = tab);
  }

  /// A sheet for the touched thing; it follows the editor live.
  Future<void> _sheet(String title, WidgetBuilder body, {double size = 0.5, Color barrier = Colors.black26}) {
    final h = MediaQuery.of(context).size.height;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xF20B1120),
      barrierColor: barrier,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: (h * size).clamp(280.0, 560.0),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [
            const _Handle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
            Expanded(child: ListenableBuilder(listenable: c, builder: (ctx, _) => body(ctx))),
          ]),
        ),
      ),
    );
  }

  /// The look of what's touched: small chips, one panel at a time.
  /// No dimming, a lower sheet: the change shows on the page above.
  void _styleSheet() => _sheet('Look', (_) => LookSheet(c: c, onReplace: _wordsSheet, onMore: _moreStyle),
      size: 0.42, barrier: Colors.transparent);

  /// Every text style knob, for when the chips are not enough.
  void _moreStyle() => _sheet('More style', (_) => StyleTab(c: c));

  void _wordsSheet() {
    final key = c.selectedSlot;
    final type = c.selectedType;
    if (key == null || type == null) return;
    final ref = SlotRef(key, type, c.selectedDefault);
    _sheet(slotFriendly(key, type, c.selectedDefault), (_) => ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [SlotRow(c: c, slot: ref, expanded: true, onStyle: _styleSheet)],
    ));
  }

  void _sectionSheet() {
    final title = c.current?.title ?? 'This section';
    _sheet(title, (_) => ContentTab(c: c, openTab: (i) {
      if (i == 1) _styleSheet();
      if (i == 2) _openDrawer(1);
    }));
  }

  Future<void> _publishSheet() => _sheet('Publish', (_) => PublishTab(c: c));

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final drawerH = (mq.size.height * 0.44).clamp(280.0, 480.0) + mq.padding.bottom;
    final open = _drawer != null;
    final selected = c.selectedSlot != null || c.selectedOrb != null || (c.sectionPicked && c.current != null);
    return PopScope(
      canPop: c.pendingCount == 0 && !open,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (open) {
          setState(() => _drawer = null);
          return;
        }
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGold, secondary: kGold, surface: Color(0xFF0F1828)),
          scaffoldBackgroundColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          body: Stack(children: [
            // The real page, edge to edge.
            Positioned.fill(child: _full ? const SizedBox.shrink() : _preview),
            // The one small pill: pages, undo/redo, publish, more. Folded,
            // its handle can be dragged anywhere; the pill opens there.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: child),
                ),
                child: _pillOpen
                    ? Stack(key: const ValueKey('pill-open'), children: [
                        Positioned(
                          top: _pillTop(mq),
                          left: 0,
                          right: 0,
                          child: Center(
                            child: EditorPill(
                          c: c,
                          onBack: () async {
                            _pillHold();
                            if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                            _pillLater();
                          },
                          onPages: () async {
                            _pillHold();
                            await _pickPage(context, c);
                            _pillLater();
                          },
                          onPublish: () async {
                            _pillHold();
                            await _publishSheet();
                            _pillLater();
                          },
                          onFull: _openFull,
                          onBin: () => openBin(context, c),
                          onMenu: (open) => open ? _pillHold() : _pillLater(),
                            ),
                          ),
                        ),
                      ])
                    : DraggableSpot(
                        key: const ValueKey('pill-folded'),
                        frac: _handleSpot,
                        size: const Size(58, 38),
                        initial: (a) => Offset((a.width - 58) / 2, mq.padding.top + 8),
                        onMoved: (f) {
                          setState(() => _handleSpot = f);
                          saveSpot(kHandleSpotKey, f);
                        },
                        child: _PillHandle(c: c, onTap: _showPill),
                      ),
              ),
            ),
            if (c.pickMode && !open && selected && !c.carrying.value)
              Positioned(
                left: 10,
                right: 10,
                // Above the + (bottom right), so nothing covers a tool.
                bottom: mq.padding.bottom + 16 + 56 + 10,
                child: Align(
                  alignment: Alignment.center,
                  child: ContextStrip(
                    c: c,
                    onStyle: _styleSheet,
                    onWords: _wordsSheet,
                    onSection: _sectionSheet,
                    onEffects: () => _openDrawer(1),
                  ),
                ),
              ),
            // The +: drag it anywhere out of the way; it stays there.
            if (c.pickMode && !c.carrying.value)
              Positioned.fill(
                child: DraggableSpot(
                  frac: _addSpot,
                  size: const Size(56, 56),
                  initial: (a) => Offset(a.width - 16 - 56, a.height - mq.padding.bottom - 16 - 56),
                  onMoved: (f) {
                    setState(() => _addSpot = f);
                    saveSpot(kAddSpotKey, f);
                  },
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: open ? 0 : 1,
                    child: _RoundButton(
                      key: const ValueKey('editor-add'),
                      icon: Icons.add_rounded,
                      tooltip: 'Add',
                      big: true,
                      onTap: open ? null : () => _openDrawer(),
                    ),
                  ),
                ),
              ),
            // The + drawer. It slides away while something from it is carried.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: drawerH,
              child: IgnorePointer(
                ignoring: !open,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  offset: open && !c.fxDragging ? Offset.zero : const Offset(0, 1.05),
                  // Thumbnails stop while it is closed or slid away.
                  child: open || c.fxDragging
                      ? TickerMode(
                          enabled: open && !c.fxDragging,
                          child: EditorDrawer(
                            key: const ValueKey('editor-drawer'),
                            c: c,
                            tab: _drawer ?? 1,
                            bottom: mq.padding.bottom,
                            onTab: (i) => setState(() => _drawer = i),
                            onClose: () => setState(() => _drawer = null),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            if (_hint) Positioned.fill(child: TouchHint(onDismiss: _dismissHint)),
          ]),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 10),
    decoration: BoxDecoration(color: const Color(0x55FFFFFF), borderRadius: BorderRadius.circular(99)),
  );
}

/// The + drawer: tabs inside it, swipe it down (or tap ✕) to close.
class EditorDrawer extends StatelessWidget {
  const EditorDrawer({
    super.key,
    required this.c,
    required this.tab,
    required this.bottom,
    required this.onTab,
    required this.onClose,
  });
  final EditorController c;
  final int tab;
  final double bottom;
  final ValueChanged<int> onTab;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) onClose();
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          color: Color(0xF20B1120),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 24)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [
            const _Handle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 6, 8),
              child: Row(children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                for (var i = 0; i < kDrawerTabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Pill(
                      kDrawerTabs[i].$1,
                      key: ValueKey('drawer-tab-${kDrawerTabs[i].$1}'),
                      icon: kDrawerTabs[i].$2,
                      dense: true,
                      selected: tab == i,
                      onTap: () => onTab(i),
                    ),
                  ),
                    ]),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: kDim),
                ),
              ]),
            ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('drawer-$tab-${c.pageId}'),
                child: switch (tab) {
                  0 => AddSectionsTab(c: c, onAdded: onClose),
                  1 => EffectsTab(c: c),
                  2 => OrbsTab(c: c),
                  3 => AnimGridTab(c: c, category: AnimCategory.loaders),
                  4 => AnimGridTab(c: c, category: AnimCategory.backgrounds),
                  5 => AnimGridTab(c: c, category: AnimCategory.particles),
                  6 => AnimGridTab(c: c, category: AnimCategory.celebrations),
                  _ => LayoutTab(c: c),
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The only thing always over the page: a small floating pill. Undo and
/// redo appear in it only when there is something to undo or redo.
class EditorPill extends StatelessWidget {
  const EditorPill({
    super.key,
    required this.c,
    required this.onBack,
    required this.onPages,
    required this.onPublish,
    required this.onFull,
    required this.onMenu,
    required this.onBin,
  });
  final EditorController c;
  final VoidCallback onBack;
  final VoidCallback onPages;
  final VoidCallback onPublish;
  final VoidCallback onFull;
  final VoidCallback onBin;

  /// The ⋯ menu opened (true) or closed (false).
  final ValueChanged<bool> onMenu;

  @override
  Widget build(BuildContext context) {
    final n = c.pendingCount;
    Widget t(IconData i, String label, VoidCallback? onTap, {Key? key, Color color = Colors.white, String? badge}) =>
        StripTool(key: key, icon: i, label: label, onTap: onTap, color: color, minSize: 48, badge: badge);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: const ValueKey('editor-pill'),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xE60B1120),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 3))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            t(Icons.arrow_back_rounded, 'Back', onBack, key: const ValueKey('editor-back')),
            t(Icons.description_outlined, 'Pages', onPages, key: const ValueKey('editor-pages')),
            t(Icons.undo_rounded, 'Undo', c.canUndo ? c.undo : null, key: const ValueKey('editor-undo')),
            t(Icons.redo_rounded, 'Redo', c.canRedo ? c.redo : null, key: const ValueKey('editor-redo')),
            t(Icons.delete_outline_rounded, 'Bin', onBin, key: const ValueKey('editor-bin')),
            if (!c.pickMode) t(Icons.touch_app_rounded, 'Editing', () => c.setPickMode(true), color: kGold),
            t(n == 0 ? Icons.cloud_done_rounded : Icons.publish_rounded, 'Publish', onPublish,
                key: const ValueKey('editor-publish'), color: n == 0 ? kMint : kGold, badge: n == 0 ? null : '$n'),
            PopupMenuButton<String>(
              tooltip: 'More',
              color: const Color(0xFF111A2B),
              padding: EdgeInsets.zero,
              onOpened: () => onMenu(true),
              onCanceled: () => onMenu(false),
              onSelected: (v) {
                onMenu(false);
                switch (v) {
                  case 'try':
                    c.setPickMode(!c.pickMode);
                  case 'full':
                    onFull();
                  case 'all':
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AllSlotsScreen()));
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'try',
                  checked: !c.pickMode,
                  child: const Text('Try it like the app', style: TextStyle(color: Colors.white)),
                ),
                const PopupMenuItem(value: 'full', child: Text('Preview with my changes', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'all', child: Text('Every picture and text in the app', style: TextStyle(color: Colors.white))),
              ],
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: const Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                  SizedBox(height: 3),
                  Text('More', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.1)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The pill folded away: a small handle (with the number of changes
/// waiting). A tap opens the pill.
class _PillHandle extends StatelessWidget {
  const _PillHandle({required this.c, required this.onTap});
  final EditorController c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = c.pendingCount;
    return Tooltip(
      message: 'Pages, undo, publish',
      child: GestureDetector(
        key: const ValueKey('editor-pill-handle'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          tapFeel();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 46,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xB30B1120),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              backgroundColor: kMint,
              textColor: kInk,
              offset: const Offset(10, -8),
              child: const Center(child: Icon(Icons.expand_more_rounded, color: kGold, size: 20)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows while something is touched: a few colours for text and a way into
/// its own sheet (style, words, picture); for an orb its circle; for a
/// section its content and effects. Small on purpose.
class ContextStrip extends StatelessWidget {
  const ContextStrip({
    super.key,
    required this.c,
    required this.onStyle,
    required this.onWords,
    required this.onSection,
    required this.onEffects,
  });
  final EditorController c;
  final VoidCallback onStyle;
  final VoidCallback onWords;
  final VoidCallback onSection;
  final VoidCallback onEffects;

  /// Every button is at least this big (a thumb, not a fingertip).
  static const kTool = 56.0;

  @override
  Widget build(BuildContext context) {
    Widget tool(IconData i, String label, VoidCallback onTap, {Color color = Colors.white, Key? key}) =>
        StripTool(key: key, icon: i, label: label, color: color, onTap: onTap);
    final done = tool(Icons.check_rounded, 'Done', c.unpick, color: kDim, key: const ValueKey('strip-done'));
    // The only way to delete: a labelled button, with Undo and the bin.
    Widget delete(VoidCallback onTap) =>
        tool(Icons.delete_outline_rounded, 'Delete', onTap, color: const Color(0xFFFF8A8A), key: const ValueKey('strip-delete'));
    final children = <Widget>[];
    final orbSel = c.selectedOrb;
    final key = c.selectedSlot;
    final type = c.selectedType;
    if (orbSel != null) {
      final o = c.orbById(orbSel.$1, orbSel.$2);
      if (o == null) return const SizedBox.shrink();
      final spec = animById(o.anim) ?? animById(o.animId);
      final kin = spec == null ? <AnimSpec>[] : animsIn(spec.category);
      // Colour: automatic (from the background) → dark → light → automatic.
      const inks = <String?>[null, 'dark', 'light'];
      final inkNext = inks[(inks.indexOf(o.ink) + 1) % inks.length];
      children.addAll([
        tool(o.circle ? Icons.circle : Icons.circle_outlined, o.circle ? 'No circle' : 'Circle', () {
          c.endStep();
          c.updateOrb(orbSel.$1, o.id, (x) => x.copyWith(circle: !x.circle));
          c.endStep();
        }, color: kGold),
        tool(
          switch (o.ink) { 'dark' => Icons.dark_mode_rounded, 'light' => Icons.light_mode_rounded, _ => Icons.contrast_rounded },
          switch (o.ink) { 'dark' => 'Dark', 'light' => 'Light', _ => 'Auto colour' },
          () {
            c.endStep();
            c.updateOrb(orbSel.$1, o.id, (x) => x.copyWith(ink: inkNext ?? ''));
            c.endStep();
          },
          key: const ValueKey('orb-ink'),
        ),
        if (kin.length > 1)
          tool(Icons.animation_rounded, 'Animate', () {
            final next = kin[(kin.indexWhere((k) => k.id == spec!.id) + 1) % kin.length];
            c.endStep();
            c.setOrbAnim(orbSel.$1, o.id, next.id);
            c.endStep();
          }, key: const ValueKey('strip-animate')),
        delete(() => deleteOrbWithUndo(context, c, orbSel.$1, o.id)),
        done,
      ]);
    } else if (key != null && type != null) {
      final st = c.overrideOf(key)?.style ?? const <String, dynamic>{};
      if (st['hidden'] == true) {
        children.add(tool(Icons.visibility_rounded, 'Show', () {
          c.endStep();
          c.patchStyle(key, type, c.selectedDefault, {'hidden': null});
          c.endStep();
        }, color: kMint));
      }
      if (type == SlotType.text) {
        children.add(tool(Icons.text_fields_rounded, 'Edit text', onWords, color: kGold, key: const ValueKey('strip-text')));
      } else if (type == SlotType.image || type == SlotType.video) {
        children.add(tool(
          type == SlotType.video ? Icons.play_circle_outline : Icons.image_rounded,
          type == SlotType.video ? 'Video on' : 'Image on',
          onWords,
          color: kGold,
          key: const ValueKey('mode-media'),
        ));
        children.add(tool(Icons.crop_free_rounded, 'Section', () {
          final id = c.current?.id;
          c.clearSelection(notify: false);
          if (id != null) {
            c.pickSection(id);
          } else {
            c.changedSelection();
          }
        }, key: const ValueKey('mode-section')));
      } else if (type != SlotType.orb) {
        children.add(tool(Icons.image_rounded, 'Image', onWords, color: kGold, key: const ValueKey('strip-image')));
      }
      children.addAll([
        tool(Icons.palette_rounded, 'Style', onStyle, key: const ValueKey('strip-look')),
        tool(Icons.animation_rounded, 'Animate', onEffects, key: const ValueKey('strip-animate')),
        delete(() => deleteElementWithUndo(context, c, key, type, c.selectedDefault)),
        done,
      ]);
    } else if (c.sectionPicked && c.current != null) {
      children.addAll([
        tool(Icons.crop_free_rounded, 'Height · width', () {}, color: kGold, key: const ValueKey('mode-section')),
        tool(Icons.text_fields_rounded, 'Edit text', onSection, color: kGold, key: const ValueKey('strip-text')),
        tool(Icons.palette_rounded, 'Style', onStyle, key: const ValueKey('strip-look')),
        tool(Icons.animation_rounded, 'Animate', onEffects, key: const ValueKey('strip-animate')),
        delete(() => deleteWithUndo(context, c, c.current!.id, c.current!.title)),
        done,
      ]);
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('context-strip'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xF0111A2B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      // Every tool in plain sight: shared out across the width, scrolling
      // only on a phone too narrow for all of them.
      child: LayoutBuilder(builder: (context, box) {
        if (children.length * kTool <= box.maxWidth) {
          return Row(children: [for (final w in children) Expanded(child: w)]);
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        );
      }),
    );
  }
}

/// One button of the strip or the pill: an icon over a plain word, and a
/// touch target of at least [minSize] square.
class StripTool extends StatelessWidget {
  const StripTool({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.minSize = ContextStrip.kTool,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double minSize;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    Widget ic = Icon(icon, color: color, size: 24);
    if (badge != null) {
      ic = Badge(label: Text(badge!), backgroundColor: kMint, textColor: kInk, child: ic);
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: on
            ? () {
                tapFeel();
                onTap!();
              }
            : null,
        child: Opacity(
          opacity: on ? 1 : 0.35,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                ic,
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, height: 1.1)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preferences flag: the touch hint has been seen on this phone.
const kTouchHintSeen = 'ui_editor_touch_hint_seen';

/// Shown once: the touches, as they really work. Any touch dismisses it.
class TouchHint extends StatelessWidget {
  const TouchHint({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  static const _rows = <(IconData, String, String)>[
    (Icons.touch_app_rounded, 'Tap', 'to select, again to type'),
    (Icons.swipe_vertical_rounded, 'Drag', 'to scroll'),
    (Icons.pinch_rounded, 'Pinch', 'to resize'),
    (Icons.back_hand_rounded, 'Hold', 'to move, or for more'),
    (Icons.delete_outline_rounded, 'Delete', 'on its strip'),
    (Icons.add_circle_outline_rounded, '+', 'to add'),
  ];

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onDismiss(),
      child: Container(
        color: const Color(0xD9000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, verb, rest) in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGold.withValues(alpha: 0.16),
                        border: Border.all(color: kGold, width: 2),
                      ),
                      child: Icon(icon, color: kGold, size: 26),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 230,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$verb ',
                              style: const TextStyle(color: kGold, fontWeight: FontWeight.w900),
                            ),
                            TextSpan(text: rest),
                          ],
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            const Text('Touch anywhere to start', style: TextStyle(color: kDim, fontSize: 13)),
          ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.icon, required this.tooltip, required this.onTap, this.big = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: on
            ? () {
                tapFeel();
                onTap!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: on ? 1 : 0.35,
          child: Container(
            width: big ? 56 : 44,
            height: big ? 56 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: big ? kGold : const Color(0xCC111A2B),
              border: Border.all(color: big ? kGold : const Color(0x33FFFFFF)),
              boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Icon(icon, color: big ? kInk : Colors.white, size: big ? 30 : 22),
          ),
        ),
      ),
    );
  }
}

/// Every page and sub-page of the app, grouped. Nothing is home-page
/// specific: any page in kAppPages opens on the same canvas.
Future<void> _pickPage(BuildContext context, EditorController c) async {
  final groups = <String, List<AppPage>>{};
  for (final p in kAppPages) {
    (groups[p.group] ??= []).add(p);
  }
  final id = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xF2070B14),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.94,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          const Text('Which page?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Every page and sub-page of the app', style: TextStyle(color: kDim, fontSize: 12.5)),
          for (final g in groups.entries) ...[
            Eyebrow(g.key),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.9,
              children: [
                for (final p in g.value)
                  Glass(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    edge: p.id == c.pageId ? kGold : kGlassEdge,
                    onTap: () => Navigator.pop(ctx, p.id),
                    child: Row(children: [
                      Icon(p.icon, color: kGold, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ]),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
  if (id != null) c.openPage(id);
}
