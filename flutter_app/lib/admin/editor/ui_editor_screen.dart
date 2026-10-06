/// Admin → UI Editor.
///
///   top     a strip of every page and sub-page (tap to open), and the
///           full picker
///   middle  the live preview — the real page, one section at a time,
///           swiped sideways. Everything is done by touching it: tap to
///           select, drag to move, pinch to resize, drag onto the trash to
///           delete, long-press for the rest; + adds a section; undo/redo
///           sit beside it; a small strip of colours shows for whatever is
///           selected.
///   bottom  five pills — Content · Style · Animation · Layout · Publish —
///           each opening its own compact tab
///
/// A one-time hint explains the four touches (any touch dismisses it).
///
/// Edits wait on this phone (shown on the preview) until Publish.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin_state.dart';
import '../layout/app_pages.dart';
import '../template/all_slots_screen.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
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

const _tabs = <(String, IconData, String)>[
  ('Content', Icons.photo_library_outlined, 'Pictures, clips and words in this section'),
  ('Style', Icons.palette_outlined, 'Colours, fonts and button shapes'),
  ('Animation', Icons.animation_rounded, 'Effects to drag onto the phone'),
  ('Layout', Icons.view_agenda_outlined, 'Every section of the page: reorder, hide, delete'),
  ('Publish', Icons.rocket_launch_outlined, 'Make it live, schedule, history'),
];

class _UiEditorScreenState extends State<UiEditorScreen> {
  late final EditorController c = widget.controller ?? EditorController();

  /// One instance: rebuilding this screen (every edit does) then skips the
  /// preview, which listens to [c] itself and rebuilds only what changed.
  late final Widget _preview = EditorPreview(c: c);
  int? _tab;
  bool _full = false;

  Future<void> _openFull() async {
    bigFeel();
    // The page holds GlobalKeys: drop the small preview while the big one is up.
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

  /// The one-time "tap / drag / pinch / +" hint.
  bool _hint = false;

  @override
  void initState() {
    super.initState();
    c.openPage(widget.initialPage);
    c.addListener(_on);
    _loadHint();
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

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_on);
    c.dispose();
    super.dispose();
  }

  void _openTab(int i) {
    setState(() => _tab = _tab == i ? null : i);
  }

  Future<bool> _confirmLeave() async {
    if (c.pendingCount == 0) return true;
    return confirmAction(context, 'Leave without publishing?',
        '${c.pendingCount} change(s) are only on this phone. They will be lost.',
        yes: 'Leave');
  }

  /// The one-time hint goes over the whole editor.
  Widget _withHint(Widget editor) => Stack(
    children: [
      Positioned.fill(child: editor),
      if (_hint) Positioned.fill(child: TouchHint(onDismiss: _dismissHint)),
    ],
  );

  /// Over the phone: undo/redo (left), + to add (right), and the small
  /// strip for whatever is selected (middle).
  Widget _overPreview(Widget preview) => Stack(
    children: [
      Positioned.fill(child: preview),
      if (c.pickMode) ...[
        Positioned(left: 10, bottom: 6, child: _UndoRedo(c: c)),
        Positioned(
          right: 10,
          bottom: 6,
          child: _RoundButton(
            icon: Icons.add_rounded,
            tooltip: 'Add',
            big: true,
            onTap: () => openAddSection(context, c),
          ),
        ),
        if (_tab == null && c.selectedSlot != null)
          Positioned(
            left: 66,
            right: 76,
            bottom: 6,
            child: Center(
              child: ContextStrip(c: c, openTab: (i) => setState(() => _tab = i)),
            ),
          ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final panelH = (mq.size.height * 0.42).clamp(260.0, 460.0);
    return PopScope(
      canPop: c.pendingCount == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
          body: _withHint(AdminBackdrop(
            dim: 0.55,
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                _TopBar(c: c, onFull: _openFull, onBack: () async {
                  if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                }),
                _PageRow(c: c),
                _SectionHeader(c: c),
                Expanded(child: _overPreview(_full ? const SizedBox.shrink() : _preview)),
                _Dots(c: c),
                _TabPills(index: _tab, pending: c.pendingCount, onTap: _openTab),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  height: _tab == null ? mq.padding.bottom + 6 : panelH + mq.padding.bottom,
                  child: _tab == null
                      ? const SizedBox.shrink()
                      : ClipRect(
                          child: Glass(
                            radius: 26,
                            padding: EdgeInsets.only(top: 6, bottom: mq.padding.bottom),
                            fill: const Color(0xCC070B14),
                            child: Material(
                              type: MaterialType.transparency,
                              child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                                  child: child,
                                ),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey('tab-$_tab-${c.pageId}-${c.current?.id}'),
                                child: switch (_tab) {
                                  0 => ContentTab(c: c, openTab: (i) => setState(() => _tab = i)),
                                  1 => StyleTab(c: c),
                                  2 => AnimationTab(c: c),
                                  3 => LayoutTab(c: c),
                                  _ => PublishTab(c: c),
                                },
                              ),
                            ),
                            ),
                          ),
                        ),
                ),
              ]),
            ),
          )),
        ),
      ),
    );
  }
}

/// Preferences flag: the touch hint has been seen on this phone.
const kTouchHintSeen = 'ui_editor_touch_hint_seen';

/// Shown once: the four touches. Any touch anywhere dismisses it.
class TouchHint extends StatelessWidget {
  const TouchHint({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  static const _rows = <(IconData, String, String)>[
    (Icons.touch_app_rounded, 'Tap', 'to select'),
    (Icons.open_with_rounded, 'Drag', 'to move'),
    (Icons.pinch_rounded, 'Pinch', 'to resize'),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (icon, verb, rest) in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kGold.withValues(alpha: 0.16),
                        border: Border.all(color: kGold, width: 2),
                      ),
                      child: Icon(icon, color: kGold, size: 28),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 170,
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
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
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
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap, this.big = false});
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

class _UndoRedo extends StatelessWidget {
  const _UndoRedo({required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _RoundButton(icon: Icons.redo_rounded, tooltip: 'Redo', onTap: c.canRedo ? c.redo : null),
      const SizedBox(height: 8),
      _RoundButton(icon: Icons.undo_rounded, tooltip: 'Undo', onTap: c.canUndo ? c.undo : null),
    ],
  );
}

/// Shows over the phone while something is selected: a few colours for
/// text, and a way into its words/picture and full style. Small on purpose
/// — the full Style tab is one tap away.
class ContextStrip extends StatelessWidget {
  const ContextStrip({super.key, required this.c, required this.openTab});
  final EditorController c;
  final ValueChanged<int> openTab;

  static const _quick = <int>[0xFFFFFFFF, 0xFF000000, 0xFFE8D5A3, 0xFF34D399, 0xFFFF4D8D, 0xFF2CB1FF];

  @override
  Widget build(BuildContext context) {
    final key = c.selectedSlot;
    final type = c.selectedType;
    if (key == null || type == null) return const SizedBox.shrink();
    final text = type == SlotType.text;
    final st = c.overrideOf(key)?.style ?? const <String, dynamic>{};
    Widget icon(IconData i, String tip, VoidCallback onTap, {Color color = Colors.white}) => IconButton(
      tooltip: tip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 40),
      onPressed: () {
        tapFeel();
        onTap();
      },
      icon: Icon(i, color: color, size: 20),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xEE111A2B),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text) ...[
              for (final col in _quick)
                GestureDetector(
                  onTap: () {
                    tapFeel();
                    c.endStep();
                    c.patchStyle(key, type, c.selectedDefault, {'color': col, 'gradient': null});
                    c.endStep();
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: Color(col),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: st['color'] == col ? kGold : const Color(0x55FFFFFF),
                        width: st['color'] == col ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              icon(Icons.text_fields_rounded, 'Font and more', () => openTab(1), color: kGold),
              icon(Icons.edit_rounded, 'Words', () => openTab(0)),
            ] else if (type != SlotType.orb)
              icon(Icons.photo_library_rounded, 'Replace', () => openTab(0), color: kGold)
            else
              icon(Icons.animation_rounded, 'Orb', () => openTab(2), color: kGold),
            icon(Icons.close_rounded, 'Done', c.clearSelection, color: kDim),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.c, required this.onBack, required this.onFull});
  final EditorController c;
  final VoidCallback onBack;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    final n = c.pendingCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 2),
      child: Row(children: [
        IconButton(
          tooltip: 'Back to Admin',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
        const Expanded(
          child: Text('UI Editor',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ),
        Pill(c.pickMode ? 'Tap to edit' : 'Try it',
            icon: c.pickMode ? Icons.touch_app_rounded : Icons.swipe_rounded,
            dense: true,
            tooltip: c.pickMode
                ? 'Taps pick what to edit. Switch to "Try it" to scroll and swipe the preview like the app.'
                : 'The preview behaves like the app. Switch back to pick things to edit.',
            onTap: () => c.setPickMode(!c.pickMode)),
        IconButton(
          tooltip: 'Full-screen live preview with your drafts',
          onPressed: onFull,
          icon: const Icon(Icons.fullscreen_rounded, color: kGold, size: 24),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: n == 0
              ? const Icon(Icons.cloud_done_rounded, key: ValueKey('ok'), color: kMint, size: 22)
              : Pill('Publish $n',
                  key: const ValueKey('pub'),
                  icon: Icons.rocket_launch_rounded,
                  selected: true,
                  dense: true,
                  tooltip: 'Make every change live for everyone',
                  onTap: c.busy
                      ? null
                      : () async {
                          bigFeel();
                          final err = await c.publish();
                          if (context.mounted) {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(err ?? 'Live — every open app shows it now.'),
                            ));
                          }
                        }),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          color: const Color(0xFF111A2B),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (v) {
            switch (v) {
              case 'edit':
                EditMode.instance.setOn(!EditMode.instance.on);
              case 'fab':
                EditMode.instance.setFab(!EditMode.instance.fabPreference);
              case 'all':
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AllSlotsScreen()));
            }
          },
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
              value: 'edit',
              checked: EditMode.instance.on,
              child: const Text('Pencils on the live app', style: TextStyle(color: Colors.white)),
            ),
            CheckedPopupMenuItem(
              value: 'fab',
              checked: EditMode.instance.fabPreference,
              child: const Text('Floating Edit button', style: TextStyle(color: Colors.white)),
            ),
            const PopupMenuItem(value: 'all', child: Text('Every slot in the app', style: TextStyle(color: Colors.white))),
          ],
        ),
      ]),
    );
  }
}

/// Every page, one tap away: a strip of page chips (swipe it sideways)
/// plus the full picker. Nothing here is home-page specific: any page in
/// kAppPages opens on the same canvas.
class _PageRow extends StatefulWidget {
  const _PageRow({required this.c});
  final EditorController c;

  @override
  State<_PageRow> createState() => _PageRowState();
}

class _PageRowState extends State<_PageRow> {
  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{};
  String? _shown;

  EditorController get c => widget.c;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Bring the open page's chip into view (e.g. after the picker).
  void _reveal() {
    if (_shown == c.pageId) return;
    _shown = c.pageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[c.pageId]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.4, duration: const Duration(milliseconds: 300));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _reveal();
    final pages = [
      for (final p in kAppPages)
        if (p.jumpTo == null) p,
    ];
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Every page',
            onPressed: () => _pickPage(context),
            icon: const Icon(Icons.grid_view_rounded, color: kGold, size: 20),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 14, top: 4, bottom: 6),
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final p = pages[i];
                final on = p.id == c.pageId;
                return GestureDetector(
                  key: _keys.putIfAbsent(p.id, GlobalKey.new),
                  onTap: () {
                    tapFeel();
                    c.openPage(p.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? kGold : const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: on ? kGold : const Color(0x2EFFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p.icon, size: 15, color: on ? kInk : kGold),
                        const SizedBox(width: 6),
                        Text(
                          p.title,
                          style: TextStyle(
                            color: on ? kInk : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ),
      ]),
    );
  }

  Future<void> _pickPage(BuildContext context) async {
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final cur = c.current;
    final n = c.sections.length;
    final hidden = cur != null && !cur.entry.showsNow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
      child: Row(children: [
        IconButton(
          tooltip: 'Previous section',
          onPressed: cur == null || c.index == 0 ? null : () => c.goTo(c.index - 1),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey('${c.pageId}-${cur?.id}'),
              children: [
                Text(
                  cur?.title ?? (appPage(c.pageId)?.title ?? '') + (n == 0 ? ' · whole page' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                Text(
                  cur == null
                      ? 'Tap an outlined element to edit it'
                      : 'Section ${c.index + 1} of $n${hidden ? ' · not showing to people' : ''}',
                  style: TextStyle(color: hidden ? kGold : kDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next section',
          onPressed: cur == null || c.index >= n - 1 ? null : () => c.goTo(c.index + 1),
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ),
      ]),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final n = c.sections.length;
    if (n < 2) return const SizedBox(height: 8);
    // A window of dots around the current one for long pages.
    const window = 13;
    final start = (c.index - window ~/ 2).clamp(0, (n - window).clamp(0, n));
    final end = (start + window).clamp(0, n);
    return SizedBox(
      height: 16,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (start > 0) const Text('‹', style: TextStyle(color: kFaint, fontSize: 11)),
        for (var i = start; i < end; i++)
          GestureDetector(
            onTap: () => c.goTo(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == c.index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == c.index
                    ? kGold
                    : (c.sections[i].entry.showsNow ? const Color(0x66FFFFFF) : const Color(0x33FFFFFF)),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        if (end < n) const Text('›', style: TextStyle(color: kFaint, fontSize: 11)),
      ]),
    );
  }
}

class _TabPills extends StatelessWidget {
  const _TabPills({required this.index, required this.pending, required this.onTap});
  final int? index;
  final int pending;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(children: [
        for (var i = 0; i < _tabs.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Tooltip(
                message: _tabs[i].$3,
                child: GestureDetector(
                  onTap: () {
                    tapFeel();
                    onTap(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: index == i ? kGold : const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: index == i ? kGold : const Color(0x33FFFFFF)),
                      boxShadow: index == i ? [BoxShadow(color: kGold.withValues(alpha: 0.35), blurRadius: 14)] : null,
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Badge(
                        isLabelVisible: i == 4 && pending > 0,
                        label: Text('$pending'),
                        backgroundColor: kMint,
                        textColor: kInk,
                        child: Icon(_tabs[i].$2, size: 17, color: index == i ? kInk : Colors.white),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: Text(_tabs[i].$1,
                            style: TextStyle(
                              color: index == i ? kInk : Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
