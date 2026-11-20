/// Your day on both homes: one black banner holding three glass buttons —
/// Quick, Today and Your Earnings. Quick and Today open the very same sheets
/// as the greeting's Quick and the Begin banner's Today (the host passes its
/// own Quick opener; Today is ProgressPanel.open).
///
/// Your Earnings opens the Your Earnings tab: a deep-blur glass sheet with a
/// black Cash earned hero, Coins and Sold, then the Your position and Target
/// cards. Each figure is shown once and each card opens its own page. It
/// opens part way and expands to full screen (button, or drag the handle up)
/// and collapses back.
///
/// Every number is the server's: EconomyMirror (users/{uid}/wallet/main,
/// payout/main, sellerStats/main incl. teamCount, the summary's rank ladder)
/// and the monthly sellers board (leaderboards/sellers_{month}). Coins are
/// only shown here, never collected.
library;

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
import 'earnings_screen.dart';

// Same tokens as NewReleasesCard / PickedForYouCard.
const _radius = 28.0;
const _tile = 78.0;
const _gap = 8.0;
const _tileRadius = 16.0;
const _grey = Color(0xFF9A9A9A);
const _seeAll = Color(0xFFB3B3B3);
const _gold = NwsbColors.goldLight;

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
                    glow: const Color(0xFF8B6CF0),
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
                    glow: const Color(0xFF4FD1B5),
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
                    sub: live ? '${_cents(m.lifetimeCents)} earned' : 'Sign in to earn',
                    glow: const Color(0xFFE8C46A),
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
/// coloured glow in its corner, a white disc mark, label and live line.
class _TrioButton extends StatelessWidget {
  const _TrioButton({super.key, required this.label, required this.sub, required this.glow, required this.icon, required this.onTap, this.progress});
  final String label;
  final String sub;
  final Color glow;
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(minHeight: 112),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x2EFFFFFF), Color(0x0DFFFFFF)]),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Stack(children: [
                Positioned(
                  right: -26,
                  top: -26,
                  child: IgnorePointer(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [glow.withValues(alpha: .55), glow.withValues(alpha: 0)]),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 11, 10, 11),
                  child: ExcludeSemantics(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: glow.withValues(alpha: .45), blurRadius: 14)],
                        ),
                        child: icon,
                      ),
                      const Spacer(),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(label, maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -0.2)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(sub, maxLines: 1, softWrap: false, style: const TextStyle(color: _grey, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.15)),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: LinearProgressIndicator(
                            value: progress!.clamp(0, 1).toDouble(),
                            minHeight: 3,
                            backgroundColor: const Color(0x26FFFFFF),
                            valueColor: AlwaysStoppedAnimation(glow),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ]),
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
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.2)),
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

// ─── featured hero: Cash earned ─────────────────────────────────────────────

class _CashHero extends StatelessWidget {
  const _CashHero({required this.s, required this.onTap, this.tall = false});
  final EarnSnapshot s;
  final VoidCallback onTap;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final sub = !s.live || (s.lifetimeCents == 0 && s.availableCents == 0)
        ? 'Sales through your links show up here'
        : '${_cents(s.availableCents)} available${s.availableCents > 0 ? ' · tap to request' : ''}';
    return Semantics(
      button: true,
      label: 'Cash earned, ${_cents(s.lifetimeCents)}, $sub',
      child: _Press(
        key: const ValueKey('earn-hero-cash'),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: tall ? 168 : 146,
            child: Stack(fit: StackFit.expand, children: [
              const _Glow(),
              // Fine grain of sound-wave dots, the NowssB mark of the hero art.
              const CustomPaint(painter: _DotWave()),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: ExcludeSemantics(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0x26E8D5A3), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x55E8D5A3))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          NwsbIcon(NwsbMarks.earn, size: 12, color: _gold, strokeWidth: 2),
                          SizedBox(width: 5),
                          Text('CASH EARNED', style: TextStyle(color: _gold, fontSize: 9.5, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.north_east_rounded, size: 16, color: Colors.black),
                      ),
                    ]),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EarnCount(
                        s.lifetimeCents,
                        format: _cents,
                        style: TextStyle(color: Colors.white, fontSize: tall ? 40 : 34, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Slow drifting gold/violet glow (still under reduced motion).
class _Glow extends StatefulWidget {
  const _Glow();
  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0E0B14), Color(0xFF000000)]),
            ),
            child: Stack(fit: StackFit.expand, children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.75 + 0.18 * math.cos(t), -0.35 + 0.25 * math.sin(t)),
                    radius: 0.95,
                    colors: const [Color(0x99D9B970), Color(0x33D9B970), Color(0x00D9B970)],
                    stops: const [0, .45, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.9 + 0.15 * math.sin(t), 1.1 + 0.1 * math.cos(t)),
                    radius: 1.0,
                    colors: const [Color(0x667A5BE0), Color(0x007A5BE0)],
                  ),
                ),
              ),
            ]),
          );
        },
      );
}

/// Dot-matrix sound wave across the right of the hero.
class _DotWave extends CustomPainter {
  const _DotWave();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x40FFFFFF);
    const step = 7.0;
    final startX = size.width * 0.42;
    for (var x = startX; x < size.width - 6; x += step) {
      final k = (x - startX) / (size.width - startX);
      final amp = (math.sin(k * math.pi * 3.2) * 0.5 + 0.5) * size.height * 0.22 * (0.4 + k);
      final cy = size.height * 0.62;
      for (var y = cy - amp; y <= cy + amp; y += step) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotWave old) => false;
}

// ─── Coins and Sold: the two figures no other card shows ───────────────────

class _TileRow extends StatelessWidget {
  const _TileRow({required this.s});
  final EarnSnapshot s;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _StatCard(
              id: 'coins',
              label: 'Coins',
              sub: s.live ? 'In your wallet' : 'Sign in to see',
              value: s.coins,
              icon: const Icon(Icons.toll_rounded, size: 19, color: Colors.black),
              onTap: () => _Go.coins(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              id: 'sold',
              label: 'Sold',
              sub: !s.live ? 'Sign in to see' : s.sold == 0 ? 'No sales yet' : 'Words and meanings',
              value: s.sold,
              icon: const NwsbIcon(NwsbMarks.wordBag, size: 18, color: Colors.black, strokeWidth: 1.9),
              onTap: () => _Go.sales(context),
            ),
          ),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.id, required this.label, required this.sub, required this.value, required this.icon, required this.onTap});
  final String id;
  final String label;
  final String sub;
  final int value;
  final Widget icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label, $value, $sub',
        child: _Press(
          key: ValueKey('earn-tile-$id'),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: _surface(),
            child: ExcludeSemantics(
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: EarnCount(value, format: (v) => '$v', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.5)),
                    ),
                    const SizedBox(height: 3),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _grey, fontSize: 10.5, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

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
    // Light scrim: the glass does the frosting, so the home shows through.
    barrierColor: const Color(0x59000000),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (ctx, _, __) => const YourEarningsSheet(),
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
    final r = BorderRadius.circular(_expanded ? 30 : _radius);
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
                        colors: [Color(0x4D3A3550), Color(0x33201C2C), Color(0x40302A44)],
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
            Row(children: [
              const Expanded(
                child: Text('Your Earnings', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3)),
              ),
              const SizedBox(width: 8),
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
            ]),
          ]),
        ),
      );

  Widget _body(EarnSnapshot s) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
        children: [
          _CashHero(s: s, tall: true, onTap: () => _Go.cash(context)),
          const SizedBox(height: 12),
          _TileRow(s: s),
          const SizedBox(height: 18),
          const _RowHead('Your position'),
          _PositionCard(s: s),
          const SizedBox(height: 18),
          const _RowHead('Target'),
          _TargetCard(s: s),
        ],
      );
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
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x26FFFFFF), border: Border.all(color: const Color(0x33FFFFFF))),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      );
}

class _RowHead extends StatelessWidget {
  const _RowHead(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
      );
}

/// Glass surface used by the sheet's cards.
BoxDecoration _surface({bool gold = false}) => BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x26FFFFFF), Color(0x0FFFFFFF)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: gold ? const Color(0x77E8D5A3) : const Color(0x33FFFFFF)),
    );

class _PositionCard extends StatelessWidget {
  const _PositionCard({required this.s});
  final EarnSnapshot s;
  @override
  Widget build(BuildContext context) {
    Widget stat(String k, String v) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _grey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .6)),
              const SizedBox(height: 3),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(v, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
            ]),
          ),
        );
    return Semantics(
      button: true,
      label: 'Your position, ${s.rank}',
      child: _Press(
        key: const ValueKey('earn-position-card'),
        onTap: () => _Go.team(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _surface(gold: true),
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFF3E6BF), Color(0xFFB8914A)]),
                    boxShadow: [BoxShadow(color: Color(0x66D9B970), blurRadius: 18, offset: Offset(0, 4))],
                  ),
                  child: const NwsbIcon(NwsbMarks.crown, size: 22, color: Colors.black, strokeWidth: 1.9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Rank', style: TextStyle(color: _grey, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(s.live ? s.rank : 'Not ranked yet',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.15)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: _seeAll),
              ]),
              const SizedBox(height: 12),
              if (!s.live)
                const Text('Sign in to see your rank, your place and your team', style: TextStyle(color: _grey, fontSize: 11.5, fontWeight: FontWeight.w500))
              else
                Row(children: [
                  stat('THIS MONTH', s.place == null ? 'Not on board' : '#${s.place!.$1} of ${s.place!.$2}'),
                  const SizedBox(width: 8),
                  stat('UNDER YOU', s.under == 1 ? '1 person' : '${s.under} people'),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.s});
  final EarnSnapshot s;
  @override
  Widget build(BuildContext context) {
    final line = !s.live
        ? 'Sign in to see your target'
        : s.topRank
            ? 'Top rank reached'
            : '${math.max(0, s.target - s.sold)} more words to ${s.nextRank ?? 'the next rank'}';
    Widget bar(double v) => LayoutBuilder(
          builder: (context, c) => Stack(children: [
            Container(height: 8, decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(9))),
            Container(
              height: 8,
              width: c.maxWidth * v,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(colors: [Color(0xFFF3E6BF), Color(0xFF7FE0D0)]),
                boxShadow: const [BoxShadow(color: Color(0x667FE0D0), blurRadius: 10)],
              ),
            ),
          ]),
        );
    return Semantics(
      button: true,
      label: 'Target, $line',
      child: _Press(
        key: const ValueKey('earn-target-card'),
        onTap: () => _Go.targets(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _surface(),
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.live ? '${s.sold}' : '0', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1)),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(s.live ? '/ ${s.target} words' : 'words', style: const TextStyle(color: _grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: _seeAll),
              ]),
              const SizedBox(height: 10),
              if (_still(context))
                bar(s.progress)
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: s.progress),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => bar(v),
                ),
              const SizedBox(height: 8),
              Text(line, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
