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
import '../economy/economy_theme.dart';
import '../economy/reward_fx.dart';

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
String inr(num v) => '\u20b9${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';
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
    this.accent = NwsbColors.goldLight,
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
  const ProgramTabsScope({super.key, required this.go, required super.child});
  final void Function(String tabId) go;

  static void goTo(BuildContext context, String tabId) =>
      context.getInheritedWidgetOfExactType<ProgramTabsScope>()?.go(tabId);

  @override
  bool updateShouldNotify(ProgramTabsScope old) => false;
}

/// "Report one visit a day" for a programme page.
final _explored = <String>{};
void reportExploreOnce(String page) {
  final now = DateTime.now().toUtc().add(const Duration(minutes: 330));
  final k = '${now.year}-${now.month}-${now.day}:$page';
  if (!_explored.add(k)) return;
  EconomyApi.call('reportAction', {'action': 'explore', 'key': page}).then((r) {
    final gained = coinsIn(r);
    if (gained > 0) unawaited(playCoins(null, gained, balanceAfter: balanceIn(r), title: 'Explorer coins'));
  }).catchError((_) {});
}

/// The tab chips + the selected tab's sections + the disclaimer, as a
/// block inside a programme page's own scroll (no inner scrollable).
/// Only this block listens to the economy, so the play area above it
/// isn't rebuilt when a number changes.
class ProgramTabsBlock extends StatefulWidget {
  const ProgramTabsBlock({super.key, required this.spec, this.initialTab, this.scrollTo = false, this.goRef, this.showDisclaimer = true});
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
    if (widget.scrollTo) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void go(String id) {
    final i = widget.spec.indexOf(id);
    if (i < 0 || !mounted) return;
    setState(() => _tab = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: _anchor,
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (var i = 0; i < spec.tabs.length; i++) _chip(spec.tabs[i].title, i)],
            ),
          ),
          ListenableBuilder(
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
                          style: TextStyle(color: NwsbColors.mist, height: 1.4)),
                      const SizedBox(height: 10),
                      GoldButton(label: 'Sign in', onTap: () => NwsbSignInPage.open(context)),
                    ])
                  else if (s.isEmpty && _loading)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: AppThinkingLoader(label: 'Opening your account…')))
                  else
                    ...layoutChildren(context, '${spec.pageId}.${tab.id}', tab.build(context, s)),
                ],
              );
            },
          ),
          if (widget.showDisclaimer) ...[
            const SizedBox(height: 18),
            PDisclaimer(spec.disclaimer, slot: 'program_kit.${spec.pageId}'),
          ],
        ],
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
          boxShadow: on ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 14)] : null,
        ),
        child: EditableLabel('program_kit.ProgramPage', label, style: TextStyle(color: on ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ),
    );
  }
}

/// A programme page: the shared shell (back button, coin pill, Good to
/// know), the programme's own [hero] and play area ([top]), then its tabs.
class ProgramPage extends StatefulWidget {
  const ProgramPage({
    super.key,
    required this.pageId,
    required this.title,
    required this.mark,
    required this.tabs,
    required this.disclaimer,
    this.initialTab = 0,
    this.header,
  });

  final String pageId;
  final String title;
  final String mark;
  final List<ProgramTab> tabs;
  final String disclaimer;
  final int initialTab;
  final Widget? header;

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  Future<void> _refresh() => EconomyMirror.instance.refresh();

  @override
  Widget build(BuildContext context) {
    final spec = ProgramSpec(pageId: widget.pageId, title: widget.title, mark: widget.mark, tabs: widget.tabs, disclaimer: widget.disclaimer);
    return EconomyPage(
      title: widget.title,
      mark: widget.mark,
      child: RefreshIndicator(
        color: NwsbColors.gold,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            if (widget.header != null) widget.header!,
            ProgramTabsBlock(spec: spec, initialTab: widget.tabs[widget.initialTab.clamp(0, widget.tabs.length - 1)].id),
          ],
        ),
      ),
    );
  }
}

/// Glass card holding a column.
class PCard extends StatelessWidget {
  const PCard({super.key, required this.children, this.glow});
  final List<Widget> children;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            boxShadow: glow == null ? null : [BoxShadow(color: glow!.withValues(alpha: 0.3), blurRadius: 22)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Section heading (gold eyebrow + white title).
class PHeading extends StatelessWidget {
  const PHeading(this.eyebrow, this.title, {super.key, this.slot = 'program_kit.PHeading'});
  final String eyebrow;
  final String title;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        EditableLabel(slot, eyebrow.toUpperCase(), style: const TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        EditableLabel(slot, title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
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
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color ?? const Color(0x55E4C56A))),
            child: NwsbIcon(mark!, size: 15, color: color ?? NwsbColors.goldLight),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EditableLabel('program_kit.PRow', title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            if (sub != null && sub!.isNotEmpty) Text(sub!, style: const TextStyle(color: NwsbColors.mist, fontSize: 12, height: 1.3)),
          ]),
        ),
        if (trailing != null) trailing!,
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
          builder: (context, x, _) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: x, minHeight: 7, color: NwsbColors.goldLight, backgroundColor: const Color(0x22FFFFFF)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label ?? '${value.toInt()} / ${goal.toInt()}', style: const TextStyle(color: NwsbColors.mist, fontSize: 11)),
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
      style: TextButton.styleFrom(
        backgroundColor: widget.filled ? (on ? NwsbColors.goldLight : const Color(0x33E8D5A3)) : Colors.transparent,
        foregroundColor: widget.filled ? Colors.black : NwsbColors.goldLight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: widget.filled ? Colors.transparent : const Color(0x66E8D5A3))),
      ),
      child: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : EditableLabel('program_kit.PClaim', widget.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// A status pill ("Done", "Locked", "3 left").
class PPill extends StatelessWidget {
  const PPill(this.text, {super.key, this.color = NwsbColors.mist});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.6))),
        child: EditableLabel('program_kit.PPill', text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class PEmpty extends StatelessWidget {
  const PEmpty(this.text, {super.key, this.slot = 'program_kit.PEmpty'});
  final String text;
  final String slot;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: EditableLabel(slot, text, style: const TextStyle(color: NwsbColors.mist, fontSize: 13, height: 1.4)),
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
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: CircleAvatar(radius: 2.5, backgroundColor: NwsbColors.gold)),
              Expanded(child: EditableLabel(slot, l, style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 13))),
            ]),
          ),
      ]);
}

class PDisclaimer extends StatelessWidget {
  const PDisclaimer(this.text, {super.key, required this.slot});
  final String text;
  final String slot;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x33FFFFFF)), color: const Color(0x0DFFFFFF)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const EditableLabel('program_kit.GoodToKnow', 'GOOD TO KNOW', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.6, fontWeight: FontWeight.w800, fontSize: 11)),
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
          return const Padding(padding: EdgeInsets.all(28), child: Center(child: AppThinkingLoader(size: 56)));
        }
        if (snap.hasError) {
          final e = snap.error;
          return PCard(children: [
            Text(e is EconomyException ? e.message : 'That did not load. Pull to try again.', style: const TextStyle(color: NwsbColors.mist, height: 1.4)),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: _reload, child: const EditableLabel('program_kit.ServerView', 'Try again', style: TextStyle(color: NwsbColors.goldLight)))),
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
  Widget build(BuildContext context) => PCard(glow: NwsbColors.gold, children: [
        Row(children: [
          EditableImage.asset('assets/icons/nwsb-coin.webp', width: 48, height: 48, errorBuilder: (_, __, ___) => const SizedBox(width: 48), slot: 'program_kit.PBalance'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CountUp(coins, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 30, fontWeight: FontWeight.w800)),
              Text(caption ?? 'NowssB coins', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
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
          PRow(title: title, sub: sub, mark: mark, trailing: const Icon(Icons.chevron_right, color: NwsbColors.goldLight)),
        ]),
      );
}
