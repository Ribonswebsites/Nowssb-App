/// Admin → UI Editor.
///
///   top     Normal home | Fashion home switch, and a picker for every
///           other page and sub-page
///   middle  the live preview — the real page, one section at a time,
///           swiped sideways, with the section's name and dots
///   bottom  five pills — Content · Style · Animation · Layout · Publish —
///           each opening its own compact tab
///
/// Edits wait on this phone (shown on the preview) until Publish.
library;

import 'package:flutter/material.dart';

import '../admin_state.dart';
import '../layout/app_pages.dart';
import '../template/all_slots_screen.dart';
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
  const UiEditorScreen({super.key, this.initialPage = 'home.normal'});
  final String initialPage;

  @override
  State<UiEditorScreen> createState() => _UiEditorScreenState();
}

const _tabs = <(String, IconData, String)>[
  ('Content', Icons.photo_library_outlined, 'Pictures, clips and words in this section'),
  ('Style', Icons.palette_outlined, 'Colours, fonts and button shapes'),
  ('Animation', Icons.animation_rounded, 'Page turns, entrances and thinking orbs'),
  ('Layout', Icons.view_agenda_outlined, 'Order, hide, duplicate, delete, add sections'),
  ('Publish', Icons.rocket_launch_outlined, 'Make it live, schedule, history'),
];

class _UiEditorScreenState extends State<UiEditorScreen> {
  final EditorController c = EditorController();
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

  @override
  void initState() {
    super.initState();
    c.openPage(widget.initialPage);
    c.addListener(_on);
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

  void _openTab(int i) => setState(() => _tab = _tab == i ? null : i);

  Future<bool> _confirmLeave() async {
    if (c.pendingCount == 0) return true;
    return confirmAction(context, 'Leave without publishing?',
        '${c.pendingCount} change(s) are only on this phone. They will be lost.',
        yes: 'Leave');
  }

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
          body: AdminBackdrop(
            dim: 0.55,
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                _TopBar(c: c, onFull: _openFull, onBack: () async {
                  if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
                }),
                _PageRow(c: c),
                _SectionHeader(c: c),
                Expanded(child: _full ? const SizedBox.shrink() : EditorPreview(c: c)),
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
          ),
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
          child: Text('UI Editor', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
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

class _PageRow extends StatelessWidget {
  const _PageRow({required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final page = appPage(c.pageId);
    final homeIndex = c.pageId == 'home.fashion' ? 1 : (c.pageId == 'home.normal' ? 0 : -1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Row(children: [
        Flexible(
          flex: 6,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: homeIndex < 0 ? 0.55 : 1,
              child: PillSwitch(
                labels: const ['Normal home', 'Fashion home'],
                index: homeIndex < 0 ? -1 : homeIndex,
                onChanged: (i) => c.openPage(i == 0 ? 'home.normal' : 'home.fashion'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Glass(
            radius: 99,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            onTap: () => _pickPage(context),
            child: Row(children: [
              Icon(page?.icon ?? Icons.layers_rounded, color: kGold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.isHome ? 'Other pages' : (page?.title ?? c.pageId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: kDim, size: 18),
            ]),
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
