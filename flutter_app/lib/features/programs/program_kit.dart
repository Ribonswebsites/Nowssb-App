/// Shared building blocks for the six program pages (Plan B 9.2): a tabbed
/// page whose every tab is a list of editor sections, glass cards, claim
/// buttons that run a server action and play its reward, loaders (thinking
/// orbs), and the disclaimer each program must show on every screen.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../admin/template/editable.dart';
import '../../screens/nwsb_sign_in_sheet.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_thinking_loader.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/money.dart';
import '../economy/economy_theme.dart';
import '../economy/reward_fx.dart';
import '../earn/earn_kit.dart';

class ProgramTab {
  const ProgramTab(this.id, this.title, this.build);
  final String id;
  final String title;
  final List<Widget> Function(BuildContext context, Map<String, dynamic> s) build;
}

/// Shortcuts into the summary map.
Map<String, dynamic> sMap(Object? v) => v is Map ? v.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
List<Map<String, dynamic>> sList(Object? v) => v is List ? v.whereType<Map>().map(sMap).toList() : <Map<String, dynamic>>[];
int sInt(Object? v) => v is num ? v.toInt() : v is Timestamp ? v.millisecondsSinceEpoch : v is DateTime ? v.millisecondsSinceEpoch : int.tryParse('${v ?? ''}') ?? 0;
num sNum(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;
String money(num v) => FxBook.instance.formatPrice(v);
String shortDate(Object? ms) {
  final n = sInt(ms);
  if (n <= 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(n);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// One programme's tab set (Rules · History · Odds …). Every programme
/// has ONE page: its play area on top, these tabs below it
/// ([ProgramTabsBlock]).
class ProgramSpec {
  const ProgramSpec({
    required this.pageId,
    required this.title,
    required this.mark,
    required this.tabs,
    required this.disclaimer,
    this.accent = Colors.white,
  });
  final String pageId;
  final String title;
  final String mark;
  final List<ProgramTab> tabs;
  final String disclaimer;
  final Color accent;

  int indexOf(String? id) {
    if (id == null) return -1;
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id == id) return i;
    }
    return -1;
  }
}

/// Lets content inside a programme page switch the tab below it
/// (e.g. "Open them in Scratch") without opening a second page.
class ProgramTabsScope extends InheritedWidget {
  const ProgramTabsScope({super.key, required this.go, required super.child, this.tabs = const [], this.current = 0});
  final void Function(String tabId) go;

  /// The programme's tabs and the picked one, for [ProgramTabPills].
  final List<ProgramTab> tabs;
  final int current;

  static void goTo(BuildContext context, String tabId) =>
      context.getInheritedWidgetOfExactType<ProgramTabsScope>()?.go(tabId);

  @override
  bool updateShouldNotify(ProgramTabsScope old) => old.current != current || old.tabs != tabs;
}

/// Kept for callers: the old second tab row. Draws nothing now.
class ProgramTabPills extends StatelessWidget {
  const ProgramTabPills({super.key});
  // Redesign 5: the one tab bar above the content is the only switcher;
  // this row is kept for callers and draws nothing.
  @override
  Widget build(BuildContext context) => const SizedBox(key: ValueKey('program-tab-pills'), height: 14);
}

/// "Report one visit a day" for a programme page.
final _explored = <String>{};
void reportExploreOnce(String page) {
  final now = DateTime.now().toUtc().add(const Duration(minutes: 330));
  final k = '${now.year}-${now.month}-${now.day}:$page';
  if (!_explored.add(k)) return;
  // Offered, not credited: the user collects it from the Collect card.
  reportEarn('explore', key: page);
}

/// The tab chips + the selected tab's sections + the disclaimer, as a
/// block inside a programme page's own scroll (no inner scrollable).
/// Only this block listens to the economy, so the play area above it
/// isn't rebuilt when a number changes.
class ProgramTabsBlock extends StatefulWidget {
  const ProgramTabsBlock({
    super.key,
    required this.spec,
    this.initialTab,
    this.scrollTo = false,
    this.goRef,
    this.showDisclaimer = true,
    this.marks = const {},
    this.hPad = 0,
    this.sectionTitle,
  });

  /// Each tab's mark in its pill (tab id → [NwsbMarks]).
  final Map<String, String> marks;

  /// Side air of the content; the pill row runs edge to edge and starts
  /// at this inset, so no pill is cut at the page margin.
  final double hPad;

  /// A section title with See all above the pills (See all lists every tab).
  final String? sectionTitle;
  /// Off when the page already shows the same text in its Good to know bar.
  final bool showDisclaimer;
  final ProgramSpec spec;
  final String? initialTab;

  /// Scroll the chips into view on open (an entry point asked for a tab).
  final bool scrollTo;

  /// Filled with this block's tab switcher so a page can wrap its whole
  /// scroll in a [ProgramTabsScope].
  final ValueNotifier<void Function(String)?>? goRef;

  @override
  State<ProgramTabsBlock> createState() => _ProgramTabsBlockState();
}

class _ProgramTabsBlockState extends State<ProgramTabsBlock> {
  late int _tab = widget.spec.indexOf(widget.initialTab).clamp(0, widget.spec.tabs.length - 1);
  final _anchor = GlobalKey();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    if (EconomyMirror.instance.summary.isEmpty) _refresh();
    reportExploreOnce(widget.spec.pageId);
    widget.goRef?.value = go;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPill();
      if (widget.scrollTo) _reveal();
    });
  }

  void go(String id) {
    final i = widget.spec.indexOf(id);
    if (i < 0 || !mounted) return;
    setState(() => _tab = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  final _pillKeys = <int, GlobalKey>{};
  GlobalKey _pillKey(int i) => _pillKeys.putIfAbsent(i, GlobalKey.new);

  /// Brings the picked pill fully on screen in the pill row.
  void _showPill() {
    final c = _pillKey(_tab).currentContext;
    if (c == null) return;
    final ro = c.findRenderObject();
    final sc = Scrollable.maybeOf(c);
    if (ro == null || sc == null) return;
    sc.position.ensureVisible(ro, alignment: 0.5, duration: Duration.zero);
  }

  void _pick(int i) {
    RewardHaptics.tick();
    setState(() => _tab = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPill());
  }

  void _seeAll() {
    final spec = widget.spec;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: EarnPane(
            dark: true,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              Text(widget.sectionTitle ?? spec.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (var i = 0; i < spec.tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: i == _tab ? Colors.white : const Color(0x14FFFFFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('see-all-${spec.tabs[i].id}'),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _pick(i);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        child: Row(children: [
                          EarnSquare(mark: widget.marks[spec.tabs[i].id] ?? NwsbMarks.arrow, size: 34, dark: i != _tab),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(spec.tabs[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: i == _tab ? kEarnInk : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: i == _tab ? kEarnInk : kEarnMuted),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  void _reveal() {
    final c = _anchor.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic, alignment: 0.02);
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await EconomyMirror.instance.refresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final tab = spec.tabs[_tab];
    return ProgramTabsScope(
      go: go,
      tabs: spec.tabs,
      current: _tab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.sectionTitle != null)
            Padding(
              padding: EdgeInsets.fromLTRB(widget.hPad, 4, widget.hPad, 4),
              child: EarnSectionTitle(widget.sectionTitle!, onSeeAll: _seeAll),
            ),
          Padding(
            key: _anchor,
            padding: const EdgeInsets.only(top: 6, bottom: 14),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.hPad),
              child: EarnGlass(
                key: const ValueKey('program-tab-bar'),
                radius: 30,
                padding: const EdgeInsets.all(5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (var i = 0; i < spec.tabs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      _tabCard(spec.tabs[i].title, i),
                    ],
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.hPad),
            child: ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) {
              final m = EconomyMirror.instance;
              final s = m.summary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SwitchingOnCard(),
                  if (m.uid == null)
                    PCard(children: [
                      const EditableLabel('program_kit.ProgramPage', 'Sign in to see your coins, cards, gifts and links. Everything is kept on your account.',
                          style: TextStyle(color: kEarnSoft, height: 1.4)),
                      const SizedBox(height: 10),
                      TextButton(onPressed: () => NwsbSignInPage.open(context), style: earnButtonStyle(), child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w800))),
                    ])
                  else if (s.isEmpty && _loading)
                    const Center(child: EarnLoading(label: 'Opening your account…'))
                  else
                    ...layoutChildren(context, '${spec.pageId}.${tab.id}', tab.build(context, s)),
                ],
              );
            },
          ),
          ),
          if (widget.showDisclaimer) ...[
            const SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.hPad),
              child: PDisclaimer(spec.disclaimer, slot: 'program_kit.${spec.pageId}'),
            ),
          ],
        ],
      ),
    );
  }

  /// The reference category chips: the picked tab a white pill (its icon
  /// in a white circle, its name), every other tab a round white icon
  /// circle. Tapping one switches the tab.
  Widget _tabCard(String label, int i) {
    final on = i == _tab;
    final mark = widget.marks[widget.spec.tabs[i].id] ?? NwsbMarks.arrow;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: EarnPress(
        key: _pillKey(i),
        haptic: false,
        onTap: () {
          if (!on) _pick(i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.fromLTRB(5, 0, 16, 0),
          alignment: Alignment.center,
          decoration: on ? earnGlossyWhite(shadow: false) : const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(999))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            on ? EarnInkCircle(mark: mark, size: 34) : SizedBox(width: 34, height: 34, child: Center(child: NwsbIcon(mark, size: 17, color: kEarnSoft, strokeWidth: 1.9))),
            const SizedBox(width: 6),
            Text(label, maxLines: 1, style: TextStyle(color: on ? kEarnInk : kEarnSoft, fontWeight: on ? FontWeight.w800 : FontWeight.w700, fontSize: 13.5)),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, int i) {
    final on = i == _tab;
    final accent = widget.spec.accent;
    return GestureDetector(
      onTap: () {
        RewardHaptics.tick();
        setState(() => _tab = i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? accent : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? accent : const Color(0x33FFFFFF)),
          boxShadow: null,
        ),
        child: EditableLabel('program_kit.ProgramPage', label, style: TextStyle(color: on ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}

/// Glass card holding a column (the Earn pane: rounded 22, kit glass).
class PCard extends StatelessWidget {
  const PCard({super.key, required this.children, this.glow});
  final List<Widget> children;

  /// Kept for callers; the kit look has no coloured glow.
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EarnPane(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// Section heading: small caps eyebrow over a bold title, an optional white
/// rounded-square mark.
class PHeading extends StatelessWidget {
  const PHeading(this.eyebrow, this.title, {super.key, this.slot = 'program_kit.PHeading', this.mark});
  final String eyebrow;
  final String title;
  final String slot;
  final String? mark;

  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      EditableLabel(slot, eyebrow.toUpperCase(), style: const TextStyle(color: Color(0xB3FFFFFF), letterSpacing: 1.4, fontSize: 10.5, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      EditableLabel(slot, title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, height: 1.2)),
    ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: mark == null
          ? text
          : Row(children: [EarnSquare(mark: mark, size: 40), const SizedBox(width: 12), Expanded(child: text)]),
    );
  }
}

/// A line item: mark, title, subtitle, trailing widget.
class PRow extends StatelessWidget {
  const PRow({super.key, required this.title, this.sub, this.trailing, this.mark, this.coin = false, this.color});
  final String title;
  final String? sub;
  final Widget? trailing;
  final String? mark;
  final bool coin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        if (coin)
          const Padding(padding: EdgeInsets.only(right: 10), child: _MiniCoin())
        else if (mark != null)
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 12),
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: NwsbIcon(mark!, size: 16, color: color == null ? kEarnInk : Color.lerp(color, kEarnInk, 0.35)!, strokeWidth: 1.9),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EditableLabel('program_kit.PRow', title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
            if (sub != null && sub!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub!, style: const TextStyle(color: kEarnMuted, fontSize: 12.5, height: 1.3)),
            ],
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

class _MiniCoin extends StatelessWidget {
  const _MiniCoin();
  @override
  Widget build(BuildContext context) => EditableImage.asset('assets/icons/nwsb-coin.webp', width: 30, height: 30, errorBuilder: (_, __, ___) => const SizedBox(width: 30), slot: 'program_kit.MiniCoin');
}

/// Progress bar with "value / goal".
class PProgress extends StatelessWidget {
  const PProgress({super.key, required this.value, required this.goal, this.label});
  final num value;
  final num goal;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final v = goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, x, _) => EarnBar(x),
        ),
        const SizedBox(height: 6),
        Text(label ?? '${value.toInt()} / ${goal.toInt()}', style: const TextStyle(color: kEarnSoft, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// A small pill button that runs a server action and plays its reward.
class PClaim extends StatefulWidget {
  const PClaim({super.key, required this.label, required this.action, this.data = const {}, this.title, this.enabled = true, this.filled = true, this.onDone});
  final String label;
  final String action;
  final Map<String, dynamic> data;
  final String? title;
  final bool enabled;
  final bool filled;
  final void Function(Map<String, dynamic> r)? onDone;

  @override
  State<PClaim> createState() => _PClaimState();
}

class _PClaimState extends State<PClaim> {
  var _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    RewardHaptics.tick();
    final r = await runReward(context, () => EconomyApi.call(widget.action, widget.data), title: widget.title);
    if (r != null) {
      widget.onDone?.call(r);
      if (r['already'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: EditableLabel('program_kit.PClaim', 'Already on your account.')));
      }
      await EconomyMirror.instance.refresh();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !_busy;
    return TextButton(
      onPressed: on ? _go : null,
      style: earnButtonStyle(filled: widget.filled, enabled: on),
      child: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kEarnInk))
          : EditableLabel('program_kit.PClaim', widget.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}

/// The Earn button look for a [TextButton]: white with ink when filled,
/// glass with white when not. Off stays readable: glass fill, a hairline and
/// 70% white, never a faded ghost.
ButtonStyle earnButtonStyle({bool filled = true, bool enabled = true}) => ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(!enabled ? const Color(0x1FFFFFFF) : (filled ? Colors.white : const Color(0x24FFFFFF))),
      foregroundColor: WidgetStatePropertyAll(!enabled ? const Color(0xB3FFFFFF) : (filled ? kEarnInk : Colors.white)),
      overlayColor: const WidgetStatePropertyAll(Color(0x14000000)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: !enabled || !filled ? const Color(0x40FFFFFF) : Colors.transparent),
      )),
    );

/// A status pill ("Done", "Locked", "3 left").
class PPill extends StatelessWidget {
  const PPill(this.text, {super.key, this.color = Colors.white});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: color.withValues(alpha: 0.14), border: Border.all(color: color.withValues(alpha: 0.6))),
        child: EditableLabel('program_kit.PPill', text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class PEmpty extends StatelessWidget {
  const PEmpty(this.text, {super.key, this.slot = 'program_kit.PEmpty'});
  final String text;
  final String slot;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: EditableLabel(slot, text, style: const TextStyle(color: kEarnSoft, fontSize: 13, height: 1.45)),
      );
}

/// Bullet list of rules (copy is editable per line).
class PRules extends StatelessWidget {
  const PRules(this.lines, {super.key, this.slot = 'program_kit.PRules'});
  final List<String> lines;
  final String slot;
  @override
  Widget build(BuildContext context) => PCard(children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, right: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5)),
              ),
              Expanded(child: EditableLabel(slot, l, style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 13.5))),
            ]),
          ),
      ]);
}

class PDisclaimer extends StatelessWidget {
  const PDisclaimer(this.text, {super.key, required this.slot});
  final String text;
  final String slot;
  @override
  Widget build(BuildContext context) => EarnPane(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const EditableLabel('program_kit.GoodToKnow', 'GOOD TO KNOW', style: TextStyle(color: Color(0xB3FFFFFF), letterSpacing: 1.6, fontWeight: FontWeight.w800, fontSize: 10.5)),
          const SizedBox(height: 6),
          EditableLabel(slot, text, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5, height: 1.45)),
        ]),
      );
}

/// Loads a server view (earnSummary, linkHub, partnerSummary, league…) with
/// an orb loader and a calm error.
class ServerView extends StatefulWidget {
  const ServerView({super.key, required this.action, this.data = const {}, required this.builder, this.reloadKey});
  final String action;
  final Map<String, dynamic> data;
  final Widget Function(BuildContext context, Map<String, dynamic> r, VoidCallback reload) builder;
  final Object? reloadKey;

  @override
  State<ServerView> createState() => _ServerViewState();
}

class _ServerViewState extends State<ServerView> {
  late Future<Map<String, dynamic>> _f = _load();
  Future<Map<String, dynamic>> _load() => EconomyApi.call(widget.action, widget.data);

  @override
  void didUpdateWidget(ServerView old) {
    super.didUpdateWidget(old);
    if (old.reloadKey != widget.reloadKey || old.action != widget.action) _f = _load();
  }

  void _reload() => setState(() => _f = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: EarnLoading());
        }
        if (snap.hasError) {
          final e = snap.error;
          return PCard(children: [
            Text(e is EconomyException ? e.message : 'That did not load. Pull to try again.', style: const TextStyle(color: kEarnSoft, height: 1.4)),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _reload, style: earnButtonStyle(filled: false), child: const EditableLabel('program_kit.ServerView', 'Try again', style: TextStyle(fontWeight: FontWeight.w800)))),
          ]);
        }
        return widget.builder(context, snap.data ?? const {}, _reload);
      },
    );
  }
}

/// Count-up number (coins / money).
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.prefix = '', this.suffix = ''});
  final num value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Text('$prefix${value % 1 == 0 ? v.round() : v.toStringAsFixed(2)}$suffix', style: style),
      );
}

/// Big balance header used by several tabs.
class PBalance extends StatelessWidget {
  const PBalance({super.key, required this.coins, this.caption});
  final int coins;
  final String? caption;
  @override
  Widget build(BuildContext context) => PCard(children: [
        Row(children: [
          EditableImage.asset('assets/icons/nwsb-coin.webp', width: 48, height: 48, errorBuilder: (_, __, ___) => const SizedBox(width: 48), slot: 'program_kit.PBalance'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CountUp(coins, style: kEarnBig),
              Text(caption ?? 'NowssB coins', style: const TextStyle(color: kEarnSoft, fontSize: 12)),
            ]),
          ),
        ]),
      ]);
}

/// Opens a program page.
void openProgram(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

/// Shared "Programs" link row for existing screens (adds, never replaces).
class ProgramLink extends StatelessWidget {
  const ProgramLink({super.key, required this.title, required this.sub, required this.page, this.mark = NwsbMarks.rewards});
  final String title;
  final String sub;
  final Widget Function() page;
  final String mark;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => openProgram(context, page()),
        child: PCard(children: [
          PRow(title: title, sub: sub, mark: mark, trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: kEarnMuted)),
        ]),
      );
}
