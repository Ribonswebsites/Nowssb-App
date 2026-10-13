/// NowssB Coupons (Plan B 5): My Coupons · Scratch · Coupon Shop · History ·
/// Rules and Odds. Cards are sealed by the server when issued; scratching
/// only uncovers what the server drew.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../economy/economy_api.dart';
import '../economy/play_billing.dart';
import '../economy/reward_fx.dart';
import '../economy/scratch_card.dart';
import 'program_kit.dart';
import 'program_heroes.dart';
import '../economy/coupon_screen.dart';
import '../../admin/template/editable.dart';

const kCouponsDisclaimer =
    'Coupon prizes are random. The odds for every coupon are shown before you buy. Paid coupons are for users aged 18 '
    'and over, may not be available in your country, and always return at least the price paid in coins or discounts. Prizes '
    'have no cash value and cannot be transferred. Set a monthly limit any time in Settings.';

const kCouponsSpec = ProgramSpec(
  pageId: 'coupons.program',
  title: 'NowssB Coupons',
  mark: NwsbMarks.coupon,
  disclaimer: kCouponsDisclaimer,
  accent: ProgramAccent.coupons,
  tabs: [
    ProgramTab('mine', 'My Coupons', _mine),
    ProgramTab('scratch', 'Scratch', _scratch),
    ProgramTab('shop', 'Coupon Shop', _shop),
    ProgramTab('history', 'History', _history),
    ProgramTab('odds', 'Rules and Odds', _odds),
  ],
);

/// Kept for every existing entry point: opens the one Coupons page
/// (CouponScreen), at tab [initialTab] when given.
class CouponsProgramPage extends StatelessWidget {
  const CouponsProgramPage({super.key, this.initialTab});
  final int? initialTab;

  @override
  Widget build(BuildContext context) => CouponScreen(
        initialTab: initialTab == null ? null : kCouponsSpec.tabs[initialTab!.clamp(0, kCouponsSpec.tabs.length - 1)].id,
      );
}

List<Widget> _mine(BuildContext context, Map<String, dynamic> s) {
  final coupons = sList(s['coupons']);
  final tokens = sList(s['tokens']);
  final cards = sList(s['scratchCards']);
  final soon = DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
  // Hero figure: the sum of the server's capINR on every active discount,
  // only when every discount has a cap (an uncapped one has no honest
  // ceiling). Otherwise the hero shows the real count instead.
  final capped = coupons.isNotEmpty && coupons.every((c) => sNum(c['capINR']) > 0);
  final capSum = capped ? coupons.fold<num>(0, (a, c) => a + sNum(c['capINR'])) : 0;
  return [
    LSection('hero', 'Coupons for you', _MineHero(discounts: coupons.length, sealed: cards.length, tokens: tokens.length, capSumINR: capSum)),
    const SizedBox(height: 28),
    const LSection('code', 'Enter a code', _CodeBox()),
    const SizedBox(height: 44),
    LSection('coupons', 'Discounts', _World(seed: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _CalmLabel('DISCOUNTS', slot: 'coupons_program.mine'),
      const SizedBox(height: 16),
      if (coupons.isEmpty)
        const _CalmEmpty(icon: Icons.local_offer_outlined, text: 'No discounts yet')
      else
        for (final c in coupons)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _Tilt(child: _CouponTicket(coupon: c, expiringSoon: sInt(c['expiresAt']) > 0 && sInt(c['expiresAt']) < soon)),
          ),
    ]))),
    const SizedBox(height: 40),
    LSection('cards', 'Sealed cards', _World(seed: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _CalmLabel('SCRATCH', slot: 'coupons_program.mine'),
      const SizedBox(height: 16),
      if (cards.isEmpty)
        const _CalmEmpty(icon: Icons.style_outlined, text: 'No sealed cards')
      else
        for (final c in cards)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: CouponScratchTicket(key: ValueKey('ticket_${c['id']}'), card: c),
          ),
    ]))),
    const SizedBox(height: 40),
    LSection('tokens', 'Tokens', _World(seed: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _CalmLabel('TOKENS', slot: 'coupons_program.mine'),
      const SizedBox(height: 16),
      if (tokens.isEmpty)
        const _CalmEmpty(icon: Icons.key_outlined, text: 'No tokens yet')
      else
        for (final t in tokens)
          Padding(padding: const EdgeInsets.only(bottom: 14), child: _Tilt(child: _TokenBanner(token: t))),
    ]))),
  ];
}

/// The one calm accent shared with the Rewards page.
const Color _kMineAccent = NwsbColors.gold;

class _CalmLabel extends StatelessWidget {
  const _CalmLabel(this.text, {required this.slot});
  final String text;
  final String slot;
  @override
  Widget build(BuildContext context) => EditableLabel(slot, text,
      style: const TextStyle(color: _kMineAccent, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w500));
}

class _CalmGlass extends StatelessWidget {
  const _CalmGlass({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        decoration: BoxDecoration(
          color: const Color(0xCC0A0A0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _CalmEmpty extends StatelessWidget {
  const _CalmEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0x990A0A0A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(children: [
          Icon(icon, color: _kMineAccent, size: 22),
          const SizedBox(width: 14),
          Expanded(child: EditableLabel('coupons_program.CalmEmpty', text, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13, height: 1.45))),
        ]),
      );
}

bool _still(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// "Coupons for you": deep glass, a huge figure and a slow gold glow. The
/// figure is the sum of the server's discount caps when every discount is
/// capped, otherwise the real count of what is waiting.
class _MineHero extends StatefulWidget {
  const _MineHero({required this.discounts, required this.sealed, required this.tokens, required this.capSumINR});
  final int discounts;
  final int sealed;
  final int tokens;
  final num capSumINR;
  @override
  State<_MineHero> createState() => _MineHeroState();
}

class _MineHeroState extends State<_MineHero> with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _glow
        ..stop()
        ..value = 0.5;
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final ready = w.discounts + w.sealed + w.tokens;
    // No currency on screen (no-INR rule): always the count of what's ready.
    final big = '$ready';
    final caption = ready == 1 ? 'coupon ready' : 'coupons ready';
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_glow.value);
          return _Glass(
            radius: 32,
            border: Color.lerp(const Color(0x26FFFFFF), NwsbColors.gold.withValues(alpha: 0.6), t)!,
            glow: NwsbColors.gold.withValues(alpha: 0.05 + 0.12 * t),
            child: child!,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 20, 30),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const EditableLabel('coupons_program.mine', 'Coupons for you',
                    style: TextStyle(color: NwsbColors.goldLight, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFFFFF), NwsbColors.goldLight, NwsbColors.gold]).createShader(r),
                    child: Text(big, key: const ValueKey('hero_figure'),
                        style: const TextStyle(color: Colors.white, fontSize: 68, height: 1, fontWeight: FontWeight.w200, letterSpacing: -2)),
                  ),
                ),
                const SizedBox(height: 6),
                EditableLabel('coupons_program.MineHero', caption, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14)),
              ]),
            ),
            EditableImage.asset(NwsbCoinFly.disc, width: 64, height: 64, fit: BoxFit.contain, slot: 'coupons_program.mine.hero',
                errorBuilder: (_, __, ___) => const SizedBox(width: 64)),
          ]),
        ),
      ),
    );
  }
}

/// Frosted glass in the app's own palette (Store-home cards).
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 30, this.border = const Color(0x1FFFFFFF), this.glow});
  final Widget child;
  final double radius;
  final Color border;
  final Color? glow;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: glow == null ? null : [BoxShadow(color: glow!, blurRadius: 36, spreadRadius: -6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x1AFFFFFF), Color(0x08FFFFFF)]),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// Section wrapper: one frosted glass panel.
class _World extends StatelessWidget {
  const _World({required this.seed, required this.child});
  final int seed;
  final Widget child;
  @override
  Widget build(BuildContext context) => _Glass(child: Padding(padding: const EdgeInsets.fromLTRB(14, 18, 14, 4), child: child));
}

/// A subtle 3D tilt toward the finger (perspective transform). Listener does
/// not join the gesture arena, so taps and scrolls behave as before. Off when
/// the system asks for reduced motion.
class _Tilt extends StatefulWidget {
  const _Tilt({required this.child});
  final Widget child;
  @override
  State<_Tilt> createState() => _TiltState();
}

class _TiltState extends State<_Tilt> {
  Offset _a = Offset.zero;

  void _at(Offset p) {
    final s = context.size;
    if (s == null || s.isEmpty) return;
    setState(() => _a = Offset(((p.dy / s.height) - 0.5) * -0.10, ((p.dx / s.width) - 0.5) * 0.10));
  }

  void _rest([PointerEvent? _]) => setState(() => _a = Offset.zero);

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return widget.child;
    return Listener(
      onPointerDown: (e) => _at(e.localPosition),
      onPointerMove: (e) => _at(e.localPosition),
      onPointerUp: _rest,
      onPointerCancel: _rest,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _a),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, a, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(a.dx)
            ..rotateY(a.dy),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Every coupon type has its own silhouette (from the reference sheet).
enum _Shape {
  /// "Special Discount" list ticket: notched stub on the left.
  stub,

  /// "Coin Terminal" pass: tall, side notches at the tear line.
  terminal,

  /// "My Rewards" brand tile: scalloped stamp edge.
  stamp,

  /// Gift scratch tile: notched stub with bevelled right corners.
  gift,

  /// "Free coins" offer banner: wide, a notch pair near the right end.
  banner,
}

Path _shapePath(_Shape s, Size z, {double stub = 92, double tear = 0.6}) {
  Path notch(Offset a, Offset b, double r) => Path()
    ..addOval(Rect.fromCircle(center: a, radius: r))
    ..addOval(Rect.fromCircle(center: b, radius: r));
  switch (s) {
    case _Shape.stub:
      final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & z, const Radius.circular(20)));
      return Path.combine(PathOperation.difference, base, notch(Offset(stub, 0), Offset(stub, z.height), 9));
    case _Shape.gift:
      const b = 16.0;
      final base = Path()
        ..moveTo(10, 0)
        ..lineTo(z.width - b, 0)
        ..lineTo(z.width, b)
        ..lineTo(z.width, z.height - b)
        ..lineTo(z.width - b, z.height)
        ..lineTo(10, z.height)
        ..arcToPoint(Offset(0, z.height - 10), radius: const Radius.circular(10))
        ..lineTo(0, 10)
        ..arcToPoint(const Offset(10, 0), radius: const Radius.circular(10))
        ..close();
      return Path.combine(PathOperation.difference, base, notch(Offset(stub, 0), Offset(stub, z.height), 10));
    case _Shape.terminal:
      final y = z.height * tear;
      final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & z, const Radius.circular(26)));
      return Path.combine(PathOperation.difference, base, notch(Offset(0, y), Offset(z.width, y), 13));
    case _Shape.stamp:
      const r = 4.5, step = 15.0;
      final holes = Path();
      for (var x = step / 2 + 6; x < z.width - 6; x += step) {
        holes
          ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: r))
          ..addOval(Rect.fromCircle(center: Offset(x, z.height), radius: r));
      }
      for (var y = step / 2 + 6; y < z.height - 6; y += step) {
        holes
          ..addOval(Rect.fromCircle(center: Offset(0, y), radius: r))
          ..addOval(Rect.fromCircle(center: Offset(z.width, y), radius: r));
      }
      final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & z, const Radius.circular(8)));
      return Path.combine(PathOperation.difference, base, holes);
    case _Shape.banner:
      final x = z.width - stub;
      final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & z, const Radius.circular(18)));
      return Path.combine(PathOperation.difference, base, notch(Offset(x, 0), Offset(x, z.height), 8));
  }
}

class _ShapeClipper extends CustomClipper<Path> {
  const _ShapeClipper(this.shape, {this.stub = 92, this.tear = 0.6});
  final _Shape shape;
  final double stub;
  final double tear;
  @override
  Path getClip(Size size) => _shapePath(shape, size, stub: stub, tear: tear);
  @override
  bool shouldReclip(_ShapeClipper old) => old.shape != shape || old.stub != stub || old.tear != tear;
}

/// The foil edge: a sweep-gradient stroke along the ticket's own outline.
class _FoilEdge extends CustomPainter {
  const _FoilEdge(this.shape, this.colors, {this.stub = 92, this.tear = 0.6, this.width = 1.6});
  final _Shape shape;
  final List<Color> colors;
  final double stub;
  final double tear;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(shape, size, stub: stub, tear: tear);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = SweepGradient(colors: [...colors, colors.first], transform: const GradientRotation(-0.6)).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_FoilEdge old) => old.shape != shape || old.colors != colors || old.stub != stub;
}

/// A shaped, foil-edged glass ticket.
class _ShapedTicket extends StatelessWidget {
  const _ShapedTicket({required this.shape, required this.accent, required this.child, this.stub = 92, this.tear = 0.6, this.fill});
  final _Shape shape;
  final Color accent;
  final Widget child;
  final double stub;
  final double tear;
  final Gradient? fill;
  @override
  Widget build(BuildContext context) {
    final foil = [accent, const Color(0xEEFFFFFF), Color.lerp(accent, Colors.black, 0.45)!, accent.withValues(alpha: 0.7), const Color(0x99FFFFFF)];
    return CustomPaint(
      foregroundPainter: _FoilEdge(shape, foil, stub: stub, tear: tear),
      child: ClipPath(
        clipper: _ShapeClipper(shape, stub: stub, tear: tear),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: fill ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(const Color(0xFF0B0B0B), accent, 0.10)!, const Color(0xF0080808)],
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Art tile: a glowing gradient square with the type's mark.
class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.icon, required this.accent, this.size = 56});
  final IconData icon;
  final Color accent;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.42), accent.withValues(alpha: 0.08)],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 18, spreadRadius: -4)],
        ),
        child: Icon(icon, color: Color.lerp(accent, Colors.white, 0.35), size: size * 0.5),
      );
}

/// Accent and art per discount scope (server field `scope`).
const Color _kWordAccent = NwsbColors.goldLight;
const Color _kSubAccent = NwsbColors.gold;
const Color _kAnyAccent = Color(0xFFB8975C); // deeper NowssB gold
const Color _kTokenAccent = NwsbColors.mist;

/// A discount from the server (label, pct, capINR, scope, source,
/// expiresAt). Each scope gets its own ticket.
class _CouponTicket extends StatelessWidget {
  const _CouponTicket({required this.coupon, required this.expiringSoon});
  final Map<String, dynamic> coupon;
  final bool expiringSoon;

  @override
  Widget build(BuildContext context) {
    final c = coupon;
    final pct = sInt(c['pct']);
    final cap = sNum(c['capINR']);
    final scope = '${c['scope'] ?? 'any'}';
    final until = sInt(c['expiresAt']) > 0 ? 'Till ${shortDate(c['expiresAt'])}' : 'No expiry';
    return switch (scope) {
      'word' => _wordTicket(pct, cap, until),
      'subscription' => _subscriptionPass(pct, cap, until),
      _ => _anyStamp(pct, cap, scope, until),
    };
  }

  Widget _soonPill() => const PPill('Expiring', color: _kWordAccent);

  /// Word: the "Special Discount" list ticket (art left, title, offer).
  Widget _wordTicket(int pct, num cap, String until) => _ShapedTicket(
        shape: _Shape.stub,
        stub: 96,
        accent: _kWordAccent,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(width: 96, child: Center(child: _ArtTile(icon: Icons.auto_stories_outlined, accent: _kWordAccent))),
            const _DashedDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Expanded(
                      child: EditableLabel('coupons_program.mine', 'WORD', style: TextStyle(color: _kWordAccent, fontSize: 10.5, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                    ),
                    if (expiringSoon) _soonPill(),
                  ]),
                  const SizedBox(height: 8),
                  Text('$pct% off', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 24, fontWeight: FontWeight.w300, height: 1.1)),
                  const SizedBox(height: 6),
                  Text([if (cap > 0) 'capped', until].join(' · '), style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11.5)),
                ]),
              ),
            ),
          ]),
        ),
      );

  /// Subscription: the tall "Coin Terminal" pass with side notches.
  Widget _subscriptionPass(int pct, num cap, String until) => SizedBox(
        height: 196,
        child: _ShapedTicket(
          shape: _Shape.terminal,
          tear: 0.62,
          accent: _kSubAccent,
          fill: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF241F14), Color(0xFF0E0D0A), Color(0xF0080808)], stops: [0, 0.6, 0.6]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              flex: 62,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
                child: Row(children: [
                  Expanded(
                    // Scales the stack down only when the 62% band is too short
                    // (it overflowed by 28px with the soon pill); 1:1 otherwise.
                    child: LayoutBuilder(builder: (_, box) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: box.maxWidth, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(children: [
                        const EditableLabel('coupons_program.mine', 'PASS', style: TextStyle(color: _kSubAccent, fontSize: 10.5, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (expiringSoon) _soonPill(),
                      ]),
                      const SizedBox(height: 8),
                      Text('$pct% OFF', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 38, fontWeight: FontWeight.w200, height: 1)),
                      if (cap > 0) const Text('Discount is capped', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5)),
                    ])),
                    )),
                  ),
                  const _ArtTile(icon: Icons.workspace_premium_outlined, accent: _kSubAccent, size: 60),
                ]),
              ),
            ),
            const SizedBox(height: 1, child: _DashedRule()),
            Expanded(
              flex: 38,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 18, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(until, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: _kSubAccent.withValues(alpha: 0.5))),
                    child: const EditableLabel('coupons_program.mine', 'Subscription', style: TextStyle(color: _kSubAccent, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );

  /// Any item: the "My Rewards" brand tile, a scalloped stamp.
  Widget _anyStamp(int pct, num cap, String scope, String until) => _ShapedTicket(
        shape: _Shape.stamp,
        accent: _kAnyAccent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(children: [
            Row(children: [
              const _ArtTile(icon: Icons.sell_outlined, accent: _kAnyAccent, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(scope == 'any' ? 'ANY ITEM' : scope.toUpperCase(),
                      style: const TextStyle(color: _kAnyAccent, fontSize: 10.5, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$pct% off${cap > 0 ? ' · capped' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
                ]),
              ),
              if (expiringSoon) _soonPill(),
            ]),
            const SizedBox(height: 12),
            const SizedBox(height: 1, child: _DashedRule()),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text(until, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11.5))),
          ]),
        ),
      );
}

/// A token as a wide "Free coins" offer banner, art on the right stub.
class _TokenBanner extends StatelessWidget {
  const _TokenBanner({required this.token});
  final Map<String, dynamic> token;
  @override
  Widget build(BuildContext context) {
    final t = token;
    return _ShapedTicket(
      shape: _Shape.banner,
      stub: 84,
      accent: _kTokenAccent,
      fill: LinearGradient(colors: [_kTokenAccent.withValues(alpha: 0.16), const Color(0xF0080808)], stops: const [0, 0.7]),
      child: SizedBox(
        height: 86,
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                const EditableLabel('coupons_program.mine', 'TOKEN', style: TextStyle(color: _kTokenAccent, fontSize: 10.5, letterSpacing: 1.8, fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text('${t['label'] ?? t['item']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400)),
              ]),
            ),
          ),
          const SizedBox(width: 84, child: Center(child: _ArtTile(icon: Icons.vpn_key_outlined, accent: _kTokenAccent, size: 48))),
        ]),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 1, child: CustomPaint(painter: _DashPainter()));
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();
  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _DashPainter(horizontal: true));
}

class _DashPainter extends CustomPainter {
  const _DashPainter({this.horizontal = false});
  final bool horizontal;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    if (horizontal) {
      for (var x = 18.0; x < size.width - 18; x += 8) {
        canvas.drawLine(Offset(x, 0.5), Offset(x + 4, 0.5), p);
      }
      return;
    }
    for (var y = 12.0; y < size.height - 12; y += 8) {
      canvas.drawLine(Offset(0.5, y), Offset(0.5, y + 4), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.horizontal != horizontal;
}

/// Tone per rarity in NowssB gold tones.
Color _goldFor(String rarity) => switch (rarity.toLowerCase()) {
      'common' || '' => const Color(0xFFB8975C),
      'rare' => NwsbColors.gold,
      _ => NwsbColors.goldLight,
    };

/// Sealed-card look per rarity: shape, art and foil.
({_Shape shape, IconData icon}) _sealedLook(String rarity) => switch (rarity.toLowerCase()) {
      'common' || '' => (shape: _Shape.gift, icon: Icons.redeem_outlined),
      'rare' => (shape: _Shape.stub, icon: Icons.card_giftcard_outlined),
      _ => (shape: _Shape.stamp, icon: Icons.diamond_outlined),
    };

/// Asks the server to open one sealed card (the existing revealScratch
/// endpoint). The server alone draws the prize.
Future<Map<String, dynamic>> _serverReveal(Map<String, dynamic> card) =>
    EconomyApi.call('revealScratch', {'id': card['id']});

/// A sealed card as a real ticket: shaped by rarity, a dashed tear line, and
/// a finger-scratch panel. The first scratch asks the server to open the
/// seal; what shows underneath is only what the server returned. When the
/// scratch clears and the server has answered, the prize lands with a burst
/// and a shimmer (skipped under reduced motion). If the call fails the
/// panel re-seals with a calm note.
class CouponScratchTicket extends StatefulWidget {
  const CouponScratchTicket({super.key, required this.card, this.reveal = _serverReveal});
  final Map<String, dynamic> card;

  /// The server call. Tests pass their own future; the app never does.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> card) reveal;

  @override
  State<CouponScratchTicket> createState() => _CouponScratchTicketState();
}

class _CouponScratchTicketState extends State<CouponScratchTicket> with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? _pending;
  Map<String, dynamic>? _result;
  String? _error;
  var _seal = 0; // bumps to re-seal the scratch panel after a failed call
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  String get _id => '${widget.card['id']}';

  @override
  void initState() {
    super.initState();
    final kept = _revealedThisSession[_id];
    if (kept != null && kept['_result'] is Map<String, dynamic>) {
      _result = kept['_result'] as Map<String, dynamic>;
      _burst.value = 1;
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _open() {
    if (_pending != null || _result != null) return;
    setState(() => _error = null);
    _pending = widget.reveal(widget.card).then((r) {
      if (r.isEmpty) throw const FormatException('empty');
      _revealedThisSession[_id] = {...widget.card, '_result': r};
      if (mounted) setState(() => _result = r);
      return r;
    }).catchError((Object e) {
      if (mounted) {
        setState(() {
          _error = e is EconomyException ? e.message : 'Not opened, still sealed';
          _pending = null;
          _seal++;
        });
      }
      return <String, dynamic>{};
    });
  }

  Future<void> _cleared() async {
    _open();
    final p = _pending;
    if (p == null) return;
    final r = await p;
    if (!mounted || r.isEmpty) return;
    // The burst plays only once the server result is in hand.
    if (_still(context)) {
      _burst.value = 1;
    } else {
      unawaited(_burst.forward(from: 0));
    }
    if (r['already'] == true) return;
    unawaited(celebrate(context, r, title: '${rarityTitle('${r['rarity'] ?? widget.card['rarity'] ?? ''}')} card'));
  }

  @override
  Widget build(BuildContext context) {
    final rarity = '${widget.card['rarity'] ?? 'common'}';
    final color = _goldFor(rarity);
    final look = _sealedLook(rarity);
    final r = _result;
    final Widget prize = r != null
        ? _BurstReveal(
            anim: _burst,
            color: NwsbColors.goldLight,
            child: Text('${r['label'] ?? 'Prize'}', textAlign: TextAlign.center, maxLines: 2,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w400, fontSize: 18, height: 1.25)),
          )
        : _pending != null
            ? const Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 1.6, color: _kMineAccent)),
                SizedBox(height: 10),
                EditableLabel('coupons_program.mine', 'Opening…', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              ])
            : const EditableLabel('coupons_program.mine', 'Scratch to open', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 222,
        child: _ShapedTicket(
          shape: look.shape,
          stub: 88,
          accent: color,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 88,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _ArtTile(icon: look.icon, accent: color, size: 50),
                  const SizedBox(height: 12),
                  Text(rarityTitle(rarity).toUpperCase(), textAlign: TextAlign.center,
                      style: TextStyle(color: color, fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const _DashedDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: NwsbScratchCard(
                      key: ValueKey('seal_${_id}_$_seal'),
                      height: 190,
                      rarity: rarity,
                      glowColor: color,
                      onFirstTouch: _open,
                      onCleared: _cleared,
                      prize: prize,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.4)),
      ],
    ]);
  }
}

/// The prize landing: rays and a ring burst out, sparks drift, a light band
/// sweeps over the text, and the text settles from a slight scale. Fully
/// deterministic (no randomness), and static when [anim] is at 1.
class _BurstReveal extends StatelessWidget {
  const _BurstReveal({required this.anim, required this.color, required this.child});
  final Animation<double> anim;
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        child: child,
        builder: (context, child) {
          final t = anim.value;
          final pop = t >= 1 ? 1.0 : 0.82 + 0.18 * Curves.easeOutBack.transform((t * 1.6).clamp(0.0, 1.0));
          Widget text = Transform.scale(scale: pop, child: child);
          if (t > 0 && t < 1) {
            final x = -1.5 + 3.0 * Curves.easeInOut.transform(((t - 0.15) / 0.7).clamp(0.0, 1.0));
            text = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment(x - 0.5, -0.4),
                end: Alignment(x + 0.5, 0.4),
                colors: const [Color(0x00FFFFFF), Color(0xCCFFF6DA), Color(0x00FFFFFF)],
              ).createShader(r),
              child: text,
            );
          }
          return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            if (t > 0 && t < 1) Positioned.fill(child: IgnorePointer(child: CustomPaint(key: const ValueKey('coupon_burst'), painter: _BurstPainter(t, color)))),
            text,
          ]);
        },
      );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final reach = size.longestSide * 0.75;
    final e = Curves.easeOutCubic.transform(t);
    final fade = Curves.easeIn.transform((1 - t).clamp(0.0, 1.0)).clamp(0.0, 1.0) * 0.4 + (1 - t).clamp(0.0, 1.0) * 0.6;
    canvas.drawCircle(c, reach * 0.55, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: 0.55 * fade), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: reach * 0.55)));
    final ray = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = i * 6.2831853 / n + 0.2;
      final long = i.isEven ? 1.0 : 0.7;
      final d = Offset(math.cos(a), math.sin(a));
      ray.color = Color.lerp(color, Colors.white, i.isEven ? 0.5 : 0)!.withValues(alpha: 0.85 * fade);
      canvas.drawLine(c + d * (reach * 0.18 * e + 12), c + d * (reach * 0.5 * e * long + 16), ray);
    }
    canvas.drawCircle(c, 14 + reach * 0.5 * e, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * fade + 0.5
      ..color = Colors.white.withValues(alpha: 0.55 * fade));
    final spark = Paint()..color = const Color(0xFFFFF1CF).withValues(alpha: fade);
    for (var i = 0; i < 10; i++) {
      final a = i * 0.628 + 0.5;
      final d = Offset(math.cos(a), math.sin(a)) * (reach * (0.25 + 0.04 * (i % 4)) * e + 20);
      canvas.drawCircle(c + d + Offset(0, 18 * t * t), 1.6 + (i % 3), spark);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t || old.color != color;
}

/// Cards opened this session stay on screen (the summary lists only sealed
/// cards, so without this a just-scratched card would vanish mid-reveal).
final _revealedThisSession = <String, Map<String, dynamic>>{};

List<Widget> _scratch(BuildContext context, Map<String, dynamic> s) {
  final t = sMap(s['today']);
  final sealed = sList(s['scratchCards']);
  final ids = {for (final c in sealed) '${c['id']}'};
  final cards = [...sealed, for (final e in _revealedThisSession.entries) if (!ids.contains(e.key)) e.value];
  return [
    LSection('daily', 'Daily scratch', PCard(children: [
      PRow(
        title: 'Today\u2019s free scratch',
        sub: t['scratch'] == true ? 'Scratched today. A new card comes tomorrow.' : 'One free card every day.',
        mark: NwsbMarks.coupon,
        trailing: PClaim(label: t['scratch'] == true ? 'Done' : 'Get card', action: 'dailyScratch', enabled: t['scratch'] != true, title: 'Daily scratch'),
      ),
    ])),
    if (cards.isEmpty) const LSection('empty', 'No cards', PEmpty('No sealed cards right now.')),
    for (final c in cards) LSection('card_${c['id']}', 'Scratch card', Padding(padding: const EdgeInsets.only(bottom: 14), child: SealedScratch(key: ValueKey('scratch_${c['id']}'), card: c))),
  ];
}

/// One sealed card: scratch → server reveal → prize + celebration.
class SealedScratch extends StatefulWidget {
  const SealedScratch({super.key, required this.card});
  final Map<String, dynamic> card;
  @override
  State<SealedScratch> createState() => _SealedScratchState();
}

class _SealedScratchState extends State<SealedScratch> {
  Future<Map<String, dynamic>>? _reveal;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final kept = _revealedThisSession['${widget.card['id']}'];
    if (kept != null && kept['_result'] is Map<String, dynamic>) _result = kept['_result'] as Map<String, dynamic>;
  }

  void _open() {
    _reveal ??= EconomyApi.call('revealScratch', {'id': widget.card['id']}).then((r) {
      _revealedThisSession['${widget.card['id']}'] = {...widget.card, '_result': r};
      if (mounted) setState(() => _result = r);
      return r;
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e is EconomyException ? e.message : 'That did not open. Try again.');
      return <String, dynamic>{};
    });
  }

  Future<void> _cleared() async {
    _open();
    final r = await _reveal!;
    if (r.isEmpty || r['already'] == true) return;
    // "You won X" + coin fly on the root overlay: plays even if this card
    // scrolls away or the list reloads.
    unawaited(celebrate(context, r, title: '${rarityTitle('${r['rarity'] ?? widget.card['rarity'] ?? ''}')} card'));
  }

  @override
  Widget build(BuildContext context) {
    final rarity = '${widget.card['rarity'] ?? 'common'}';
    final paid = widget.card['paid'] == true;
    if (_result != null && _reveal == null) {
      // Opened earlier this session: show it open, not sealed again.
      return PCard(glow: rarityColor(rarity), children: [
        PRow(title: '${_result!['label'] ?? 'Prize'}', sub: '${rarityTitle(rarity)} · scratched · on your account', mark: NwsbMarks.coupon, color: rarityColor(rarity)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Text(rarityTitle(rarity).toUpperCase(), style: TextStyle(color: rarityColor(rarity), letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text('${paid ? 'Paid' : 'Free'} · from ${widget.card['source'] ?? 'a reward'}', style: const TextStyle(color: NwsbColors.mist, fontSize: 11)),
      ]),
      const SizedBox(height: 6),
      NwsbScratchCard(
        height: 170,
        rarity: rarity,
        onFirstTouch: _open,
        onCleared: _cleared,
        prize: _result == null
            ? (_error != null
                ? Padding(padding: const EdgeInsets.all(16), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)))
                : const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: NwsbColors.goldLight)))
            : Column(mainAxisSize: MainAxisSize.min, children: [
                EditableImage.asset('assets/icons/nwsb-coin.webp', width: 40, height: 40, errorBuilder: (_, __, ___) => const SizedBox(), slot: 'coupons_program.SealedScratch'),
                const SizedBox(height: 6),
                Text('${_result!['label'] ?? 'Prize'}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                Text('${rarityTitle('${_result!['rarity'] ?? rarity}')} · on your account', style: TextStyle(color: rarityColor('${_result!['rarity'] ?? rarity}'), fontSize: 12)),
              ]),
      ),
    ]);
  }
}

List<Widget> _shop(BuildContext context, Map<String, dynamic> s) {
  final odds = sMap(sMap(s['config'])['odds']);
  final paid = sList(odds['paid']);
  final coins = sInt(sMap(s['wallet'])['coins']);
  return [
    const LSection('note', 'Shop note', PEmpty('Every paid card returns at least its price in coins or discounts. Odds are listed on each card. 18+ only.', slot: 'coupons_program.shop')),
    for (final c in paid)
      LSection('card_${c['id']}', '${c['title']}', PCard(glow: rarityColor('${c['id']}'), children: [
        EditableLabel('coupons_program.shared', 'PAID CARD', style: TextStyle(color: rarityColor('${c['id']}').withValues(alpha: 0.8), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text('${c['title']}', style: TextStyle(color: rarityColor('${c['id']}'), fontSize: 18, fontWeight: FontWeight.w800))),
          if (sInt(c['coinPrice']) > 0) Text('${sInt(c['coinPrice'])} coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
        Text('Rarest prize: ${c['rarest'] ?? ''}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
        const SizedBox(height: 6),
        for (final o in sList(c['odds']))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text('${o['label']}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Text('${sNum(o['pct'])}%', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _PaidBuy(cardId: '${c['id']}'),
          if (sInt(c['coinPrice']) > 0)
            _PaidBuy(cardId: '${c['id']}', coinPrice: sInt(c['coinPrice']), enabled: coins >= sInt(c['coinPrice']), title: '${c['title']}'),
        ]),
      ])),
  ];
}

class _PaidBuy extends StatefulWidget {
  const _PaidBuy({required this.cardId, this.coinPrice = 0, this.enabled = true, this.title});
  final String cardId;

  /// > 0: buys the card with coins (same 18+ / country / monthly checks as
  /// Google Play) instead of opening the Play sheet.
  final int coinPrice;
  final bool enabled;
  final String? title;
  @override
  State<_PaidBuy> createState() => _PaidBuyState();
}

class _PaidBuyState extends State<_PaidBuy> {
  var _busy = false;

  Future<void> _buy({bool adult = false}) async {
    setState(() => _busy = true);
    try {
      if (widget.coinPrice > 0) {
        final r = await EconomyApi.call('buyScratchWithCoins', {'cardId': widget.cardId, if (adult) 'adult': true});
        if (mounted) await celebrate(context, r, title: widget.title ?? 'Your card is ready in Scratch');
        await EconomyMirror.instance.refresh();
        return;
      }
      final r = await PlayCheckout.purchase({'kind': 'scratch', 'cardId': widget.cardId, if (adult) 'adult': true});
      if (!mounted) return;
      unawaited(celebrate(context, r, title: 'Your card is ready in Scratch'));
      ProgramTabsScope.goTo(context, 'scratch');
      await EconomyMirror.instance.refresh();
    } on EconomyException catch (e) {
      if (e.extra['needsAdult'] == true && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const EditableLabel('coupons_program.PaidBuy', 'Are you 18 or over?', style: TextStyle(color: Colors.white)),
            content: const EditableLabel('coupons_program.PaidBuy', 'Paid scratch cards are for adults only. Free cards stay open to everyone.', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const EditableLabel('coupons_program.PaidBuy', 'No')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const EditableLabel('coupons_program.PaidBuy', 'I am 18+')),
            ],
          ),
        );
        if (ok == true && mounted) {
          setState(() => _busy = false);
          return _buy(adult: true);
        }
      } else if (mounted) {
        showEconomyError(context, e);
      }
    } catch (e) {
      if (mounted) showEconomyError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coinPrice > 0) {
      final on = widget.enabled && !_busy;
      return TextButton(
        onPressed: on ? _buy : null,
        style: TextButton.styleFrom(
          foregroundColor: NwsbColors.goldLight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: const BorderSide(color: Color(0x66E8D5A3))),
        ),
        child: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: NwsbColors.goldLight))
            : Text('${widget.coinPrice} coins', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
    }
    return TextButton(
        onPressed: _busy ? null : _buy,
        style: TextButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: Colors.black, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 14)),
        child: Text(_busy ? 'Waiting for Play…' : 'Buy on Play', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      );
  }
}

final _historyStreams = <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};

List<Widget> _history(BuildContext context, Map<String, dynamic> s) {
  final uid = EconomyMirror.instance.uid;
  return [
    LSection('revealed', 'Revealed cards', PCard(children: [
      const PHeading('Scratched', 'History', slot: 'coupons_program.history'),
      if (!NwsbFirebase.ready || uid == null)
        const PEmpty('Sign in to see your history.')
      else
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // One stream per account, so a rebuild never re-subscribes (no loader flash).
          stream: _historyStreams.putIfAbsent(uid, () => FirebaseFirestore.instance.collection('users/$uid/scratchCards').where('status', isEqualTo: 'revealed').limit(60).snapshots()),
          builder: (context, snap) {
            final docs = [...?snap.data?.docs]..sort((a, b) => sInt(b.data()['revealedAt'] ?? b.data()['at']).compareTo(sInt(a.data()['revealedAt'] ?? a.data()['at'])));
            if (docs.isEmpty) return const PEmpty('Nothing scratched yet.');
            return Column(children: [
              for (final d in docs)
                PRow(
                  title: '${d.data()['label'] ?? 'Prize'}',
                  sub: '${rarityTitle('${d.data()['rarity'] ?? ''}')} · ${shortDate(d.data()['revealedAt'] ?? d.data()['at'])}',
                  mark: NwsbMarks.coupon,
                  color: rarityColor('${d.data()['rarity'] ?? ''}'),
                ),
            ]);
          },
        ),
    ])),
  ];
}

List<Widget> _odds(BuildContext context, Map<String, dynamic> s) {
  final odds = sMap(sMap(s['config'])['odds']);
  final free = sMap(odds['free']);
  final daily = sList(odds['daily']);
  final after = sList(odds['afterPurchase']);
  final afterSub = sMap(odds['afterSubscription']);
  final spin = sList(odds['spin']);
  Widget table(String title, List<Map<String, dynamic>> rows) => PCard(children: [
        EditableLabel('coupons_program.shared', title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        for (final o in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text('${o['label']}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
              Text('${sNum(o['pct'])}%', style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]);
  return [
    const LSection('rules', 'Rules', PRules([
      'Every card is sealed by the server when it is issued. Scratching only shows what was drawn.',
      'Free cards expire after 30 days. Discounts expire after 30 days and apply before coins at checkout.',
      'Paid cards are 18+, have a monthly limit, and always return at least their price in coins or discounts.',
      'Prizes have no cash value and cannot be transferred or sold.',
    ], slot: 'coupons_program.odds')),
    LSection('daily', 'Daily scratch odds', table('Daily free scratch', daily)),
    for (final e in free.entries) LSection('free_${e.key}', '${rarityTitle(e.key)} odds', table('${rarityTitle(e.key)} free card', sList(e.value))),
    LSection('after', 'After a purchase', PCard(children: [
      const EditableLabel('coupons_program.shared', 'Rarity of the free card after a purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      for (final (i, b) in after.indexed)
        Text('${sNum(b['maxINR']) > 1e9 ? 'Largest purchases' : 'Purchase band ${i + 1}'}: ${sMap(b['odds']).entries.map((e) => '${rarityTitle(e.key)} ${e.value}%').join(' · ')}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
      Text('Subscriptions: ${afterSub.entries.map((e) => '${rarityTitle(e.key)} ${e.value}%').join(' · ')}', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
    ])),
    LSection('spin', 'Daily Spin odds', table('Daily Spin', spin)),
  ];
}

class _CodeBox extends StatefulWidget {
  const _CodeBox();
  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  final _c = TextEditingController();
  String? _note;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _CalmGlass(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: TextField(
              controller: _c,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, letterSpacing: 1.2),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Coupon code',
                hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          PClaim(
            label: 'Add',
            enabled: _c.text.trim().isNotEmpty,
            action: 'claimTicket',
            data: {'code': _c.text.trim()},
            title: 'Coupon',
            onDone: (r) => setState(() => _note = r['locked'] == true || r['action'] != null ? '${r['label']}: ${r['how']}' : r['win'] == false ? 'No win this time (${r['winPct']}% chance).' : '${r['label'] ?? 'Claimed'} is on your account.'),
          ),
        ]),
        if (_note != null) PEmpty(_note!),
      ]);
}
