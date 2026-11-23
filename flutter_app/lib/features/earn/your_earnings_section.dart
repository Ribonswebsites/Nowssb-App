/// Your day on both homes: one black banner holding three glass buttons —
/// Quick, Today and Your Earnings. Quick and Today open the very same sheets
/// as the greeting's Quick and the Begin banner's Today (the host passes its
/// own Quick opener; Today is ProgressPanel.open).
///
/// Your Earnings opens the Your Earnings tab in the Earn layout: "Hey, name",
/// one card with cash earned and coins side by side, Payout and Invite, then
/// Your position (a statistics grid, rank as the dark tile) and Target (a
/// stat card: big number, status pill, three chips). Each figure is shown
/// once and each card opens its own page. It
/// opens part way and expands to full screen (button, or drag the handle up)
/// and collapses back.
///
/// Every number is the server's: EconomyMirror (users/{uid}/wallet/main,
/// payout/main, sellerStats/main incl. teamCount, the summary's rank ladder)
/// and the monthly sellers board (leaderboards/sellers_{month}). Coins are
/// only shown here, never collected.
library;

import '../../shell/tablet.dart';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot, FirebaseFirestore;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../circle/circle_screen.dart' show EarnTabsPage;
import '../coins/coins_screen.dart';
import '../economy/economy_api.dart';
import '../economy/money.dart';
import '../programs/reference_program.dart' show monthKeyIst;
import '../progress/progress_center.dart';
import '../progress/progress_popup.dart' show ProgressPanel;
import 'earn_kit.dart';
import 'earnings_screen.dart';

// Same tokens as NewReleasesCard / PickedForYouCard.
const _radius = 28.0;
const _gap = 8.0;
const _grey = Color(0xFF9A9A9A);

bool _still(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// ─── data ───────────────────────────────────────────────────────────────────

/// One reading of everything the section shows.
class EarnSnapshot {
  EarnSnapshot(this.m, this.place);
  final EconomyMirror m;

  /// (place, sellers on this month's board), null when not on it.
  final (int, int)? place;

  bool get live => m.live;
  int get coins => m.coins;
  int get lifetimeCents => m.lifetimeCents;
  int get availableCents => m.cash;
  int get sold => m.wordsSold;
  int get target => m.nextSellerTarget;
  int get under => m.teamCount;
  String get rank => live ? m.sellerTier : 'Not ranked';
  bool get topRank => live && sold > 0 && target <= sold;
  double get progress => !live || target <= 0 ? 0 : (sold / target).clamp(0.0, 1.0);

  /// The rank whose word mark is [target], from the server's ladder.
  String? get nextRank {
    final earn = m.summary['earn'];
    final ranks = earn is Map ? earn['ranks'] : null;
    if (ranks is! List) return null;
    for (final r in ranks) {
      if (r is Map && (r['minWords'] as num?)?.toInt() == target) {
        final t = '${r['title'] ?? ''}';
        return t.isEmpty ? null : t;
      }
    }
    return null;
  }

}

final _boards = <String, Stream<DocumentSnapshot<Map<String, dynamic>>>>{};
Stream<DocumentSnapshot<Map<String, dynamic>>> _board(String month) =>
    _boards.putIfAbsent(month, () => FirebaseFirestore.instance.doc('leaderboards/sellers_$month').snapshots().asBroadcastStream());

(int, int)? _placeOf(Map<String, dynamic>? doc, String uid) {
  final raw = doc?['entries'];
  if (raw is! Map) return null;
  int words(Object? v) => v is Map ? ((v['words'] as num?)?.toInt() ?? 0) : 0;
  final ids = raw.keys.map((e) => '$e').toList()..sort((a, b) => words(raw[b]).compareTo(words(raw[a])));
  final i = ids.indexOf(uid);
  return i < 0 ? null : (i + 1, ids.length);
}

/// Rebuilds with a fresh [EarnSnapshot] whenever the mirror, currency or
/// this month's board changes.
class EarnBuilder extends StatelessWidget {
  const EarnBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, EarnSnapshot s) builder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([EconomyMirror.instance, FxBook.instance]),
        builder: (context, _) {
          final m = EconomyMirror.instance;
          final uid = m.uid;
          if (!NwsbFirebase.ready || uid == null) return builder(context, EarnSnapshot(m, null));
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _board(monthKeyIst()),
            builder: (context, snap) => builder(context, EarnSnapshot(m, _placeOf(snap.data?.data(), uid))),
          );
        },
      );
}

void _push(BuildContext context, Widget page) {
  AppHaptics.medium();
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Real destinations, shared by the home section and the sheet.
class _Go {
  static void coins(BuildContext c) => _push(c, const CoinsScreen());
  static void cash(BuildContext c) => _push(c, const EarningsScreen());
  static void sales(BuildContext c) => _push(c, const EarnTabsPage(initialTab: 'sales'));
  static void targets(BuildContext c) => _push(c, const EarnTabsPage(initialTab: 'targets'));
  static void team(BuildContext c) => _push(c, const EarnTabsPage(initialTab: 'team'));
  static void payouts(BuildContext c) => _push(c, const EarnTabsPage(initialTab: 'payouts'));
  static void invite(BuildContext c) => _push(c, const EarnTabsPage(initialTab: 'invite'));
}

String _cents(int v) => FxBook.instance.formatCents(v);

// ─── the home section: Quick · Today · Your Earnings ────────────────────────

class HomeTrioSection extends StatelessWidget {
  const HomeTrioSection({super.key, required this.onQuick, this.light = true, this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 14), this.center});

  /// The host home's own Quick opener — the same sheet its greeting Quick
  /// (Zen) or header Quick (Normal) opens.
  final VoidCallback onQuick;

  /// Outer air; the Zen home's panes sit 16 from the edge.
  final EdgeInsets padding;

  /// Normal home: the New releases neumorphic shadow pair. On the dark Zen
  /// home the white highlight would glow, so it gets a hairline instead.
  final bool light;

  /// Tests: Today's source (defaults to ProgressCenter.instance).
  final ProgressCenter? center;

  @override
  Widget build(BuildContext context) {
    final c = center ?? ProgressCenter.instance;
    return Padding(
      key: const ValueKey('home-trio-section'),
      padding: padding,
      child: _BlackBanner(
        light: light,
        title: 'Your day',
        child: ListenableBuilder(
          listenable: Listenable.merge([c, EconomyMirror.instance, FxBook.instance]),
          builder: (context, _) {
            final items = c.items;
            final done = items.where((e) => e.complete).length;
            final m = EconomyMirror.instance;
            final live = m.live && m.uid != null;
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: _TrioButton(
                    key: const ValueKey('trio-quick'),
                    label: 'Quick',
                    sub: 'Your shortcuts',
                                        icon: const NwsbIcon(NwsbMarks.features, size: 18, color: Colors.black, strokeWidth: 1.8),
                    onTap: onQuick,
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _TrioButton(
                    key: const ValueKey('trio-today'),
                    label: 'Today',
                    sub: '$done/${items.length} done',
                                        progress: items.isEmpty ? null : done / items.length,
                    icon: const Icon(Icons.check_rounded, size: 19, color: Colors.black),
                    onTap: () => ProgressPanel.open(context),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _TrioButton(
                    key: const ValueKey('trio-earnings'),
                    label: 'Your Earnings',
                    hero: true,
                    sub: live ? '${_cents(m.lifetimeCents)} earned' : 'Sign in to earn',
                                        icon: const NwsbIcon(NwsbMarks.earn, size: 18, color: Colors.black, strokeWidth: 1.9),
                    onTap: () => showYourEarningsSheet(context),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// One glass button on the black banner: frosted face, hairline, a soft
/// white circle mark, label and live line, all on dark glass.
class _TrioButton extends StatelessWidget {
  const _TrioButton({super.key, required this.label, required this.sub, required this.icon, required this.onTap, this.progress, this.hero = false});

  /// The vivid purple hero glass (Your Earnings).
  final bool hero;
  final String label;
  final String sub;
  final Widget icon;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label, $sub',
        child: _Press(
          onTap: () {
            AppHaptics.medium();
            onTap();
          },
          child: EarnGlass(
            tone: hero ? EarnTone.hero : EarnTone.pane,
            radius: 18,
            glow: hero ? const Color(0x998B5CF6) : const Color(0x557C4DFF),
            child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
              child: ExcludeSemantics(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  EarnCircle(size: 36, child: icon),
                  const Spacer(),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label, maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.2)),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(sub, maxLines: 1, softWrap: false, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.15)),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    EarnBar(progress!.clamp(0, 1).toDouble(), height: 3),
                  ],
                ]),
              ),
            ),
          ),
          ),
        ),
      );
}

/// The black card of New releases / Picked for you, header included.
class _BlackBanner extends StatelessWidget {
  const _BlackBanner({required this.light, required this.title, this.subtitle, required this.child, this.trailing, this.onHead});
  final bool light;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final VoidCallback? onHead;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(_radius),
        border: light ? null : Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: light
            ? const [
                BoxShadow(color: Color(0x24000000), offset: Offset(7, 7), blurRadius: 18),
                BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-7, -7), blurRadius: 18),
              ]
            : const [BoxShadow(color: Color(0x80000000), offset: Offset(0, 16), blurRadius: 36)],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onHead,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _grey, fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.2)),
                    ],
                  ]),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ]),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      ),
    );
  }
}






// ─── shared ──────────────────────────────────────────────────────────────────



/// Counts up to [value] (from its last value on change); still under
/// reduced motion.
class EarnCount extends StatelessWidget {
  const EarnCount(this.value, {super.key, required this.format, this.style});
  final int value;
  final String Function(int v) format;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    if (_still(context)) return Text(format(value), maxLines: 1, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v.round()), maxLines: 1, style: style),
    );
  }
}

/// Press-in scale + haptic for every tappable surface here.
class _Press extends StatefulWidget {
  const _Press({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  var _down = false;
  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: _down ? 0.96 : 1, duration: const Duration(milliseconds: 110), curve: Curves.easeOut, child: widget.child),
      );
}

// ─── the sheet ──────────────────────────────────────────────────────────────

class _SpringCurve extends Curve {
  const _SpringCurve();
  static final _sim = SpringSimulation(const SpringDescription(mass: 1, stiffness: 170, damping: 19), 0, 1, 0);
  @override
  double transformInternal(double t) => t >= 1 ? 1 : _sim.x(t * 0.9);
}

Future<void> showYourEarningsSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Your Earnings',
    // Firm scrim: the home recedes so nothing behind reads through the sheet.
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (ctx, _, __) => const TabletSheet(child: YourEarningsSheet()),
    transitionBuilder: (ctx, a, _, child) {
      if (_still(ctx)) return FadeTransition(opacity: a, child: child);
      final fade = CurvedAnimation(parent: a, curve: const Interval(0, .45), reverseCurve: Curves.easeIn);
      final slide = CurvedAnimation(parent: a, curve: const _SpringCurve(), reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: Tween(begin: const Offset(0, .35), end: Offset.zero).animate(slide), child: child),
      );
    },
  );
}

/// The Your Earnings tab: deep-blur glass, black hero, glass tiles inside.
/// Opens part way; the expand button or dragging the handle up takes it
/// full screen, and the same (or dragging down) brings it back.
class YourEarningsSheet extends StatefulWidget {
  const YourEarningsSheet({super.key});
  @override
  State<YourEarningsSheet> createState() => _YourEarningsSheetState();
}

class _YourEarningsSheetState extends State<YourEarningsSheet> {
  bool _expanded = false;
  bool _dragging = false;

  /// Live height change while the handle is dragged (+ = taller).
  double _pull = 0;

  void _close() => Navigator.of(context).maybePop();

  void _setExpanded(bool v) {
    if (v == _expanded) return;
    AppHaptics.selection();
    setState(() => _expanded = v);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final full = size.height - pad.top - pad.bottom - 12;
    final part = math.min(full, math.min(size.height * 0.74, 640.0));
    final base = _expanded ? full : part;
    final height = (base + _pull).clamp(part * .55, full).toDouble();
    final still = _still(context);
    final r = BorderRadius.circular(_expanded ? 26 : kEarnRadius + 4);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_expanded ? 6 : 10, 0, _expanded ? 6 : 10, _expanded ? 6 : 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AnimatedContainer(
              key: const ValueKey('your-earnings-sheet'),
              duration: _dragging || still ? Duration.zero : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              height: height,
              decoration: BoxDecoration(
                borderRadius: r,
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 50, offset: Offset(0, 20))],
              ),
              child: ClipRRect(
                borderRadius: r,
                child: BackdropFilter(
                  // Deep blur: the home behind turns to soft colour.
                  filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: r,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xE61A1726), Color(0xE60F0D17), Color(0xE6151320)],
                      ),
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: EarnBuilder(builder: (context, s) => Column(children: [_head(s), Expanded(child: _body(s))])),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _head(EarnSnapshot s) => GestureDetector(
        key: const ValueKey('earn-sheet-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _dragging = true),
        onVerticalDragUpdate: (d) => setState(() => _pull -= d.delta.dy),
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          final pull = _pull;
          setState(() {
            _dragging = false;
            _pull = 0;
          });
          if (pull > 60 || v < -600) {
            _setExpanded(true);
          } else if (pull < -60 || v > 600) {
            if (_expanded) {
              _setExpanded(false);
            } else {
              _close();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
          child: Column(children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x80FFFFFF), borderRadius: BorderRadius.circular(9))),
            const SizedBox(height: 12),
            EarnHey(
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              _HeadButton(
                key: const ValueKey('earn-sheet-expand'),
                label: _expanded ? 'Collapse' : 'Expand',
                icon: _expanded ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded,
                onTap: () => _setExpanded(!_expanded),
              ),
              const SizedBox(width: 8),
              _HeadButton(
                key: const ValueKey('earn-sheet-close'),
                label: 'Close',
                icon: Icons.close_rounded,
                onTap: () {
                  AppHaptics.light();
                  _close();
                },
              ),
            ])),
          ]),
        ),
      );

  Widget _body(EarnSnapshot s) {
    final sub = !s.live || (s.lifetimeCents == 0 && s.availableCents == 0)
        ? 'Sales through your links show up here'
        : '${_cents(s.availableCents)} available${s.availableCents > 0 ? ' · tap to request' : ''}';
    final line = !s.live
        ? 'Sign in to see your target'
        : s.topRank
            ? 'Top rank reached'
            : '${math.max(0, s.target - s.sold)} more words to ${s.nextRank ?? 'the next rank'}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
      children: [
        EarnBalanceCard(
          left: EarnBalance(
            key: const ValueKey('earn-hero-cash'),
            label: 'Cash earned',
            mark: NwsbMarks.earn,
            value: EarnCount(s.lifetimeCents, format: _cents, style: kEarnBig),
            sub: sub,
            onTap: () => _Go.cash(context),
          ),
          right: EarnBalance(
            key: const ValueKey('earn-tile-coins'),
            label: 'Coins',
            coin: true,
            value: EarnCount(s.coins, format: (v) => '$v', style: kEarnBig),
            sub: s.live ? 'In your wallet' : 'Sign in to see',
            onTap: () => _Go.coins(context),
          ),
        ),
        const SizedBox(height: 12),
        EarnActions(onPayout: () => _Go.payouts(context), onInvite: () => _Go.invite(context)),
        const SizedBox(height: 20),
        EarnSectionTitle('Target', onSeeAll: () => _Go.targets(context)),
        const SizedBox(height: 8),
        Semantics(
          label: 'Target, $line',
          child: EarnStatCard(
            key: const ValueKey('earn-target-card'),
            title: s.live && !s.topRank ? 'Next: ${s.nextRank ?? 'the next rank'}' : 'Your target',
            status: EarnStatusPill(!s.live ? EarnStatus.off : s.topRank ? EarnStatus.reached : EarnStatus.ongoing),
            left: const EarnSide('You', mark: NwsbMarks.user),
            eyebrow: 'Words sold',
            number: s.live ? '${s.sold} / ${s.target}' : '0',
            under: line,
            right: EarnSide(s.live && !s.topRank ? (s.nextRank ?? 'Next rank') : 'Top rank', mark: NwsbMarks.rewards),
            odds: [
              if (s.live) EarnOdd('Goal', '${s.target}'),
              if (s.live && !s.topRank) EarnOdd('To go', '${math.max(0, s.target - s.sold)}'),
              if (s.live) EarnOdd('Done', '${(s.progress * 100).round()}%'),
            ],
            onTap: () => _Go.targets(context),
          ),
        ),
        const SizedBox(height: 20),
        EarnSectionTitle('Your position', onSeeAll: () => _Go.team(context)),
        const SizedBox(height: 8),
        EarnStatGrid([
          EarnStat('Rank', s.live ? s.rank : 'Not ranked yet', highlight: true, key: const ValueKey('earn-position-card'), onTap: () => _Go.team(context)),
          EarnStat('Sold', s.live ? '${s.sold}' : '0', sub: !s.live ? 'Sign in to see' : s.sold == 0 ? 'No sales yet' : 'Words and meanings', key: const ValueKey('earn-tile-sold'), onTap: () => _Go.sales(context)),
          if (s.live) ...[
            EarnStat('This month', s.place == null ? 'Not on board' : '#${s.place!.$1} of ${s.place!.$2}', onTap: () => _Go.team(context)),
            EarnStat('Under you', s.under == 1 ? '1 person' : '${s.under} people', onTap: () => _Go.team(context)),
          ],
        ]),
        if (!s.live)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text('Sign in to see your rank, your place and your team', style: TextStyle(color: kEarnSoft, fontSize: 12)),
          ),
      ],
    );
  }
}

class _HeadButton extends StatelessWidget {
  const _HeadButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: EarnCircle(icon: icon, size: 38),
        ),
      );
}




