/// NowssB Earn (Ribon, Nov 23, redesign 6): the sports-betting reference
/// layout, in NowssB black glass and white. No yellow, gold, blue, purple
/// or violet. White cards with black text; black glass where the reference
/// fills a surface yellow. The same contrast, the real coin, no emoji.
///
///  * [EarnHey]          the top row: avatar, "Hey," over the bold name,
///                       how-it-works and the bell.
///  * [EarnBalanceCard]  one white card, two balances side by side, a
///                       wallet badge on the top centre (cash · coins).
///  * [EarnActions]      Payout (solid white, a black icon square) ·
///                       Invite (outline, a black icon square).
///  * [EarnSectionTitle] "Top programmes" with a small See all.
///  * [EarnStatCard]     the match card: title + status chip, a side mark
///                       each side of a big centre score, three odds boxes.
///  * [EarnStatGrid]     the Statistics card: a white card of cells, one
///                       dark highlighted box.
///  * [showEarnHowItWorks] the how-it-works pop-up.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../account/account_kit.dart' show TileRow, TileBadge, accountFieldStyle;

import '../../data/app_haptics.dart';
import '../../data/firebase.dart';
import '../../screens/notifications_sheet.dart' show showNotificationsSheet;
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import '../../widgets/nwsb_icon.dart';

// ─── tokens (lifted from GlassWrap / HeroGlassRecipe / restyle_kit) ────────

const kEarnMuted = Color(0x8CFFFFFF);
const kEarnSoft = Color(0xCCFFFFFF);
const kEarnInk = Color(0xFF111118);
const kEarnGlass = Color(0x14FFFFFF);
const kEarnLine = Color(0x26FFFFFF);
const kEarnDark = Color(0xF0111114);
/// The one accent: white.
const kEarnAccent = Colors.white;
const kEarnRadius = 22.0;
const kEarnTileRadius = 16.0;

/// The grey of small labels on white.
const kEarnGrey = Color(0xFF6E6E76);

/// The soft black drop under glass (GlassWrap: 0 16 40 rgba(0,0,0,.34)).
const kEarnShadow = Color(0x57000000);

/// Small caps eyebrow (CurrentlyPlayingHero / StoreNowCard).
const kEarnEyebrow = TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700, height: 1.25);

/// The NowssB photograph on the balance hero.
const kEarnHeroArt = 'assets/banners/earn/man-dark.png';

/// Tests: the name the header greets.
String? debugEarnName;

/// Tests: the avatar photo URL ('' for none).
String? debugEarnPhoto;

/// The account's first name, or null when there is none.
String? earnFirstName() {
  if (debugEarnName != null) return debugEarnName!.isEmpty ? null : debugEarnName;
  if (!NwsbFirebase.ready) return null;
  final n = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
  if (n.isEmpty) return null;
  return n.split(RegExp(r'\s+')).first;
}

String earnHey() {
  final n = earnFirstName();
  return n == null ? 'Hey there' : 'Hey, $n';
}

String? _photo() {
  if (debugEarnPhoto != null) return debugEarnPhoto!.isEmpty ? null : debugEarnPhoto;
  if (!NwsbFirebase.ready) return null;
  final p = FirebaseAuth.instance.currentUser?.photoURL ?? '';
  return p.isEmpty ? null : p;
}

// ─── circles and the top bar ───────────────────────────────────────────────

/// A WHITE CIRCLE badge holding a dark mark, icon or [child].
class EarnCircle extends StatelessWidget {
  const EarnCircle({super.key, this.mark, this.icon, this.size = 40, this.child, this.outlined = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;

  /// A hairline ring so the circle reads on a white surface.
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: const Color(0x26000000)) : null,
        ),
        child: child ??
            (mark != null
                ? NwsbIcon(mark!, size: size * 0.46, color: kEarnInk, strokeWidth: 1.9)
                : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.5, color: kEarnInk)),
      );
}

/// A BLACK circle with a white glyph, for use on white surfaces.
class EarnInkCircle extends StatelessWidget {
  const EarnInkCircle({super.key, this.mark, this.icon, this.size = 34});
  final String? mark;
  final IconData? icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: kEarnInk, shape: BoxShape.circle),
        child: mark != null
            ? NwsbIcon(mark!, size: size * 0.46, color: Colors.white, strokeWidth: 1.9)
            : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.5, color: Colors.white),
      );
}

/// Kept for callers: the white circle badge.
class EarnSquare extends StatelessWidget {
  const EarnSquare({super.key, this.mark, this.icon, this.size = 36, this.child, this.dark = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;
  final bool dark;
  @override
  Widget build(BuildContext context) => EarnCircle(mark: mark, icon: icon, size: size, outlined: !dark, child: child);
}

/// A tappable round button (back, expand, close): white, or black glass
/// with a white glyph when [glass].
class EarnCircleButton extends StatelessWidget {
  const EarnCircleButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 42, this.glass = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool glass;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: EarnPress(
          onTap: onTap,
          child: glass
              ? EarnGlassCircle(icon: icon, size: size)
              : DecoratedBox(
                  decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))]),
                  child: EarnCircle(icon: icon, size: size),
                ),
        ),
      );
}

/// The back button as a white circle.
class EarnBackSquare extends StatelessWidget {
  const EarnBackSquare({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => EarnCircleButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: onTap);
}

/// The round avatar: the account photo, else the initial, on white.
class EarnAvatar extends StatelessWidget {
  const EarnAvatar({super.key, this.size = 42, this.name});
  final double size;
  final String? name;
  @override
  Widget build(BuildContext context) {
    final n = (name ?? earnFirstName() ?? '').trim();
    final initial = Text(n.isEmpty ? 'N' : n.characters.first.toUpperCase(),
        style: TextStyle(color: kEarnInk, fontSize: size * 0.42, fontWeight: FontWeight.w800, height: 1));
    final url = _photo();
    return Container(
      key: const ValueKey('earn-avatar'),
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66FFFFFF), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: url == null
          ? initial
          : Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initial),
    );
  }
}

/// The reference header: [onBack], the round avatar, "Hey," small with the
/// name bold under it, how-it-works ([onHelp]), and the bell (or [trailing])
/// at the far right.
class EarnHey extends StatelessWidget {
  const EarnHey({super.key, this.eyebrow, this.onBack, this.trailing, this.title, this.bell = true, this.name, this.onHelp, this.avatar = true});

  /// Kept for callers; the reference has no eyebrow.
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Overrides the greeting's name line.
  final String? title;

  /// Overrides the account's first name.
  final String? name;

  /// Shows the bell when there is no [trailing].
  final bool bell;

  /// Shows the how-it-works button.
  final VoidCallback? onHelp;

  /// Shows the avatar at the left of the greeting.
  final bool avatar;

  @override
  Widget build(BuildContext context) {
    final n = name ?? earnFirstName();
    final spoken = title ?? earnHey();
    var line = title ?? n ?? 'there';
    final lower = line.toLowerCase();
    if (lower.startsWith('hey, ')) {
      line = line.substring(5).trim();
      if (line.isEmpty) line = n ?? 'there';
    } else if (lower == 'hey,' || lower == 'hey') {
      line = n ?? 'there';
    }
    return Row(children: [
      if (onBack != null) ...[EarnBackSquare(onTap: onBack!), const SizedBox(width: 10)],
      if (avatar) ...[EarnAvatar(name: n, size: 44), const SizedBox(width: 12)],
      Expanded(
        child: Semantics(
          label: spoken,
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Hey,', maxLines: 1, style: TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
            Text(line,
                key: const ValueKey('earn-hey'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3)),
          ]),
        ),
      ),
      if (onHelp != null) ...[
        const SizedBox(width: 8),
        EarnCircleButton(key: const ValueKey('earn-help'), icon: Icons.question_mark_rounded, label: 'How Earn works', onTap: onHelp!, glass: true, size: 40),
      ],
      if (trailing != null) ...[const SizedBox(width: 8), trailing!]
      else if (bell) ...[
        const SizedBox(width: 8),
        EarnCircleButton(key: const ValueKey('earn-bell'), icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => showNotificationsSheet(context), glass: true, size: 40),
      ],
    ]);
  }
}

// ─── the glass ──────────────────────────────────────────────────────────────

enum EarnTone {
  /// The everyday pane: black translucent glass over the background.
  pane,

  /// The plate: the near-black Store / Subscription card.
  hero,

  /// A cell inside a pane.
  cell,

  /// White (the one key figure, the picked tab).
  light,
}

bool earnStill(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

List<Color> _fill(EarnTone t) => switch (t) {
      EarnTone.pane => const [Color(0x8C0C0C0E), Color(0x99080809), Color(0xA6050506)],
      EarnTone.hero => const [Color(0xF51C1C20), Color(0xF5101013), Color(0xF7070708)],
      EarnTone.cell => const [Color(0x1AFFFFFF), Color(0x0DFFFFFF), Color(0x08FFFFFF)],
      EarnTone.light => const [Color(0xFFFFFFFF), Color(0xFFF7F7F8), Color(0xFFEDEDEF)],
    };

/// The fine white edge: bright at the top left, fading round the shape.
class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.radius, {this.strong = 1});
  final double radius;
  final double strong;
  @override
  void paint(Canvas canvas, Size size) {
    if (strong <= 0) return;
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(math.max(0, math.min(radius, size.shortestSide / 2) - 0.5)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.42 * strong),
          Color.fromRGBO(255, 255, 255, 0.16 * strong),
          Color.fromRGBO(255, 255, 255, 0.07 * strong),
          Color.fromRGBO(255, 255, 255, 0.14 * strong),
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.radius != radius || old.strong != strong;
}

/// Box shadows painted only outside the rounded shape, so translucent glass
/// never shows its own shadow through itself.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter(this.shadows, this.radius);
  final List<BoxShadow> shadows;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(math.min(radius, size.shortestSide / 2)));
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect((Offset.zero & size).inflate(90)), Path()..addRRect(rr)));
    for (final s in shadows) {
      canvas.drawRRect(rr.shift(s.offset).inflate(s.spreadRadius), s.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) => old.radius != radius || old.shadows != shadows;
}

/// Static film grain for the plate.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final p = Paint()..color = const Color(0x0DFFFFFF);
    final n = (size.width * size.height / 300).clamp(0, 1400).toInt();
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), rnd.nextDouble() * 0.6 + 0.2, p);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// One sweep of white light across the plate on entrance.
class _Shimmer extends StatelessWidget {
  const _Shimmer();
  @override
  Widget build(BuildContext context) {
    if (earnStill(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -1.2, end: 2.2),
        duration: const Duration(milliseconds: 2200),
        curve: const Interval(0.25, 1, curve: Curves.easeInOutCubic),
        builder: (context, v, _) => v >= 2.2
            ? const SizedBox.shrink()
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(v - 1, -1),
                    end: Alignment(v, 1),
                    colors: const [Color(0x00FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
      ),
    );
  }
}

/// The glass surface: a real backdrop blur (GlassWrap's sigma), the black
/// fill of [tone], a sheen from the top left, the white edge and a soft
/// black shadow outside the shape. [glow] is kept for callers and only
/// deepens the black shadow.
class EarnGlass extends StatelessWidget {
  const EarnGlass({
    super.key,
    required this.child,
    this.tone = EarnTone.pane,
    this.radius = kEarnRadius,
    this.padding = EdgeInsets.zero,
    this.glow = kEarnShadow,
    this.blur = true,
    this.circle = false,
  });
  final Widget child;
  final EarnTone tone;
  final double radius;
  final EdgeInsets padding;
  final Color? glow;
  final bool blur;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(circle ? 999 : radius);
    final plate = tone == EarnTone.hero;
    final light = tone == EarnTone.light;
    final cell = tone == EarnTone.cell;
    Widget body = Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _fill(tone), stops: const [0, 0.5, 1]),
          ),
        ),
      ),
      if (plate) const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _GrainPainter()))),
      // Sheen from the top.
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, 0.2),
              colors: [Color(light ? 0x00FFFFFF : (plate ? 0x1AFFFFFF : 0x14FFFFFF)), const Color(0x00FFFFFF)],
            ),
          ),
        ),
      ),
      if (plate) const Positioned.fill(child: _Shimmer()),
      Padding(padding: padding, child: child),
      Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _EdgePainter(circle ? 999 : radius, strong: light ? 0.0 : (cell ? 0.6 : (plate ? 1.15 : 1))))),
      ),
    ]);
    body = ClipRRect(
      borderRadius: br,
      child: blur && !light && !plate && !cell
          ? BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: body)
          : body,
    );
    final shadows = <BoxShadow>[
      if (!cell) BoxShadow(color: plate ? const Color(0x80000000) : kEarnShadow, blurRadius: plate ? 40 : 30, offset: Offset(0, plate ? 18 : 12)),
      if (light) const BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
    ];
    return CustomPaint(painter: _OuterShadowPainter(glow == null ? const [] : shadows, circle ? 9999 : radius), child: body);
  }
}

/// A gentle fade and rise on first build; still under reduced motion.
class EarnEnter extends StatelessWidget {
  const EarnEnter({super.key, required this.child, this.order = 0});
  final Widget child;
  final int order;
  @override
  Widget build(BuildContext context) {
    if (earnStill(context)) return child;
    final start = (order * 0.12).clamp(0.0, 0.6);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + (order * 70).clamp(0, 420)),
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
    );
  }
}

/// Press-in scale for a tappable; the haptic and [onTap] fire on the tap.
class EarnPress extends StatefulWidget {
  const EarnPress({super.key, required this.onTap, required this.child, this.haptic = true});
  final VoidCallback? onTap;
  final Widget child;
  final bool haptic;
  @override
  State<EarnPress> createState() => _EarnPressState();
}

class _EarnPressState extends State<EarnPress> {
  var _down = false;
  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        if (widget.haptic) AppHaptics.selection();
        widget.onTap!();
      },
      child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
    );
  }
}

/// The white pill face (Payout, the picked tab, chips): white with a soft
/// black drop.
BoxDecoration earnGlossyWhite({double radius = 999, bool shadow = true}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFF1F1F3)]),
      boxShadow: shadow
          ? const [
              BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
              BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
            ]
          : null,
    );

/// A round black-glass button with a white glyph and the white edge.
class EarnGlassCircle extends StatelessWidget {
  const EarnGlassCircle({super.key, this.mark, this.icon, this.size = 48});
  final String? mark;
  final IconData? icon;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: EarnGlass(
          circle: true,
          radius: size / 2,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: mark != null
                  ? NwsbIcon(mark!, size: size * 0.42, color: Colors.white, strokeWidth: 1.9)
                  : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.46, color: Colors.white),
            ),
          ),
        ),
      );
}

/// A card in the Earn shape: black glass ([dark] the near-black plate).
class EarnPane extends StatelessWidget {
  const EarnPane({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.dark = false, this.tone = EarnTone.pane, this.glow = kEarnShadow});
  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  final EarnTone tone;
  final Color? glow;
  @override
  Widget build(BuildContext context) => EarnGlass(tone: dark ? EarnTone.hero : tone, padding: padding, glow: glow, child: child);
}

// ─── the balance hero ───────────────────────────────────────────────────────

/// One figure of [EarnBalanceCard].
class EarnBalance {
  const EarnBalance({required this.label, required this.value, this.sub, this.coin = false, this.mark, this.onTap, this.key});
  final String label;
  final Widget value;
  final String? sub;
  final bool coin;
  final String? mark;
  final VoidCallback? onTap;
  final Key? key;
}

/// Kept for callers; figures carry no glow.
const kEarnNumberGlow = <Shadow>[Shadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 4))];

/// The big number style of balances and focus cards.
const kEarnBig = TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8);

/// The same figure, in black, for white cards.
const kEarnInkBig = TextStyle(color: kEarnInk, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8);

/// One white card, two balances side by side, a wallet-icon badge centred
/// on its top edge (the reference's Current / Bonus balance card). [art]
/// is kept for callers and is not drawn: the reference card has no photo.
class EarnBalanceCard extends StatelessWidget {
  const EarnBalanceCard({super.key, required this.left, required this.right, this.badge = Icons.account_balance_wallet_rounded, this.art});
  final EarnBalance left;
  final EarnBalance right;
  final IconData badge;

  /// Kept for callers.
  final String? art;

  Widget _side(EarnBalance b) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(b.label, maxLines: 1, style: const TextStyle(color: kEarnGrey, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
          if (b.onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kEarnGrey),
          ],
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle.merge(
            style: kEarnInkBig,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (b.coin) ...[const NwsbCoinDisc(size: 26), const SizedBox(width: 7)],
              b.value,
            ]),
          ),
        ),
        if (b.sub != null) ...[
          const SizedBox(height: 4),
          Text(b.sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnGrey, fontSize: 11.5, height: 1.3)),
        ],
      ]),
    );
    if (b.onTap == null) return KeyedSubtree(key: b.key, child: body);
    return Semantics(
      button: true,
      label: b.label,
      child: EarnPress(key: b.key, onTap: b.onTap, child: body),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            key: const ValueKey('earn-balance-card'),
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            decoration: earnGlossyWhite(radius: 22),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: _side(left)),
                Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), color: const Color(0x1A000000)),
                Expanded(child: _side(right)),
              ]),
            ),
          ),
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: EarnIconSquare(icon: badge, size: 32, dark: true),
              ),
            ),
          ),
        ]),
      );
}

// ─── actions and headings ───────────────────────────────────────────────────

/// A rounded-square icon badge: black with a white mark, or white with a
/// black mark ([dark] off).
class EarnIconSquare extends StatelessWidget {
  const EarnIconSquare({super.key, this.mark, this.icon, this.size = 36, this.dark = true, this.child});
  final String? mark;
  final IconData? icon;
  final double size;
  final bool dark;
  final Widget? child;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? kEarnInk : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: dark ? null : Border.all(color: const Color(0x26000000)),
        ),
        child: child ??
            (mark != null
                ? NwsbIcon(mark!, size: size * 0.48, color: dark ? Colors.white : kEarnInk, strokeWidth: 1.9)
                : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.52, color: dark ? Colors.white : kEarnInk)),
      );
}

/// A pill button: solid white with a black icon square when [primary]
/// (Payout), else an outline with a black icon square (Invite).
class EarnActionButton extends StatelessWidget {
  const EarnActionButton({super.key, required this.label, required this.icon, required this.onTap, this.primary = true});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        child: Row(children: [
          EarnIconSquare(icon: icon, size: 36, dark: true),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1, style: TextStyle(color: primary ? kEarnInk : Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: -0.1)),
            ),
          ),
        ]),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: EarnPress(
        onTap: onTap,
        child: primary
            ? DecoratedBox(decoration: earnGlossyWhite(radius: 26), child: content)
            : DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: const Color(0x14000000),
                  border: Border.all(color: const Color(0x66FFFFFF), width: 1.4),
                ),
                child: content,
              ),
      ),
    );
  }
}

/// Two equal buttons side by side: Payout (solid) and Invite (outline).
class EarnActions extends StatelessWidget {
  const EarnActions({super.key, required this.onPayout, required this.onInvite});
  final VoidCallback onPayout;
  final VoidCallback onInvite;
  @override
  Widget build(BuildContext context) => EarnEnter(
        order: 1,
        child: Row(children: [
          Expanded(child: EarnActionButton(key: const ValueKey('earn-action-payout'), label: 'Payout', icon: Icons.south_rounded, onTap: onPayout)),
          const SizedBox(width: 10),
          Expanded(child: EarnActionButton(key: const ValueKey('earn-action-invite'), label: 'Invite', icon: Icons.north_rounded, onTap: onInvite, primary: false)),
        ]),
      );
}

/// A section heading: bold title at the left, small See all at the right.
class EarnSectionTitle extends StatelessWidget {
  const EarnSectionTitle(this.title, {super.key, this.onSeeAll, this.action = 'See all', this.eyebrow});
  final String title;
  final VoidCallback? onSeeAll;
  final String action;
  final String? eyebrow;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (eyebrow != null) ...[Text(eyebrow!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: kEarnEyebrow), const SizedBox(height: 2)],
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.2)),
            ]),
          ),
          if (onSeeAll != null)
            Semantics(
              button: true,
              label: '$action, $title',
              excludeSemantics: true,
              child: EarnPress(
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(action, style: const TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ]),
      );
}

// ─── status, chips, bar ─────────────────────────────────────────────────────

enum EarnStatus { ongoing, upcoming, reached, off }

/// The status pill: Ongoing white with a black dot, Reached white with a
/// tick, Upcoming and off a glass pill.
class EarnStatusPill extends StatelessWidget {
  const EarnStatusPill(this.status, {super.key, this.text});
  final EarnStatus status;
  final String? text;
  @override
  Widget build(BuildContext context) {
    final label = text ??
        switch (status) {
          EarnStatus.ongoing => 'Ongoing',
          EarnStatus.upcoming => 'Upcoming',
          EarnStatus.reached => 'Reached',
          EarnStatus.off => 'Not yet',
        };
    final white = status == EarnStatus.ongoing || status == EarnStatus.reached;
    final row = Row(mainAxisSize: MainAxisSize.min, children: [
      if (status == EarnStatus.ongoing) ...[
        Container(width: 6, height: 6, decoration: const BoxDecoration(color: kEarnInk, shape: BoxShape.circle)),
        const SizedBox(width: 6),
      ],
      if (status == EarnStatus.reached) ...[const Icon(Icons.check_rounded, size: 13, color: kEarnInk), const SizedBox(width: 4)],
      Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: TextStyle(color: white ? kEarnInk : Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2)))),
    ]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: white
          ? earnGlossyWhite(shadow: false)
          : BoxDecoration(borderRadius: BorderRadius.circular(999), color: const Color(0x1FFFFFFF), border: Border.all(color: const Color(0x40FFFFFF))),
      child: row,
    );
  }
}

/// A small white chip: a mark (or the real coin) and a short line.
class EarnChip extends StatelessWidget {
  const EarnChip(this.text, {super.key, this.mark, this.icon, this.coin = false});
  final String text;
  final String? mark;
  final IconData? icon;
  final bool coin;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        decoration: earnGlossyWhite(shadow: false),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (coin)
            const NwsbCoinDisc(size: 18)
          else if (mark != null || icon != null)
            EarnInkCircle(mark: mark, icon: icon, size: 18),
          if (coin || mark != null || icon != null) const SizedBox(width: 5),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnInk, fontSize: 11.5, fontWeight: FontWeight.w700))),
        ]),
      );
}

/// One key fact of a match card: a small grey label and a bold figure
/// ("Rate  0%"), the reference's odds box.
class EarnOdd {
  const EarnOdd(this.label, this.value, {this.coin = false, this.icon});
  final String label;
  final String value;
  final bool coin;
  final IconData? icon;
}

/// A white odds box: the label in grey, the figure in black.
class EarnOddChip extends StatelessWidget {
  const EarnOddChip(this.odd, {super.key});
  final EarnOdd odd;
  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(odd.label, maxLines: 1, style: const TextStyle(color: kEarnGrey, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            if (odd.coin) ...[const NwsbCoinDisc(size: 15), const SizedBox(width: 3)],
            if (odd.icon != null) ...[Icon(odd.icon, size: 14, color: kEarnInk), const SizedBox(width: 2)],
            Text(odd.value, maxLines: 1, style: const TextStyle(color: kEarnInk, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

/// A row of up to three white odds boxes, equal widths.
class EarnOddsRow extends StatelessWidget {
  const EarnOddsRow(this.odds, {super.key});
  final List<EarnOdd> odds;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < odds.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: EarnOddChip(odds[i])),
        ],
      ]);
}

/// A progress line: white on a faint white track.
class EarnBar extends StatelessWidget {
  const EarnBar(this.value, {super.key, this.height = 6, this.color});
  final double value;
  final double height;
  final Color? color;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0x24FFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: color ?? Colors.white,
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─── the focus card ─────────────────────────────────────────────────────────

/// One end of a focus card's from → to line.
class EarnSide {
  const EarnSide(this.label, {this.mark, this.icon, this.coin = false});
  final String label;
  final String? mark;
  final IconData? icon;
  final bool coin;
}

/// "12 / 100" or "12 : 100" → 0.12; null when [s] is not a fraction.
double? earnFraction(String s) {
  final m = RegExp(r'^\s*([\d,.]+)\s*[/ :]\s*([\d,.]+)\s*$').firstMatch(s);
  if (m == null) return null;
  final a = double.tryParse(m.group(1)!.replaceAll(',', ''));
  final b = double.tryParse(m.group(2)!.replaceAll(',', ''));
  if (a == null || b == null || b <= 0) return null;
  return (a / b).clamp(0.0, 1.0);
}

/// The reference match card: title and status chip on top, a crest each
/// side of a big centre score (small line above, small line under), and
/// a row of three white odds boxes. Black glass (the reference's yellow
/// card). [hero] is kept for callers and no longer changes the face.
class EarnStatCard extends StatelessWidget {
  const EarnStatCard({
    super.key,
    required this.title,
    required this.number,
    this.eyebrow,
    this.under,
    this.left,
    this.right,
    this.status,
    this.odds = const [],
    this.onTap,
    this.hero = true,
  });
  final String title;
  final String number;
  final String? eyebrow;
  final String? under;
  final EarnSide? left;
  final EarnSide? right;
  final Widget? status;
  final List<EarnOdd> odds;
  final VoidCallback? onTap;
  final bool hero;

  Widget _side(EarnSide s) => Column(mainAxisSize: MainAxisSize.min, children: [
        s.coin ? const NwsbCoinDisc(size: 46) : EarnCircle(mark: s.mark, icon: s.icon, size: 46),
        const SizedBox(height: 7),
        Text(s.label,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
      ]);

  @override
  Widget build(BuildContext context) {
    final card = EarnPane(
      dark: hero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.2)),
          ),
          if (status != null) ...[const SizedBox(width: 8), status!],
          if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kEarnSoft)],
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(flex: 3, child: left == null ? const SizedBox() : _side(left!)),
          Expanded(
            flex: 4,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (eyebrow != null)
                FittedBox(fit: BoxFit.scaleDown, child: Text(eyebrow!, maxLines: 1, style: const TextStyle(color: kEarnSoft, fontSize: 11.5, fontWeight: FontWeight.w600))),
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, child: Text(number, maxLines: 1, style: kEarnBig.copyWith(fontSize: 34))),
              if (under != null) ...[
                const SizedBox(height: 2),
                Text(under!, maxLines: 3, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.25)),
              ],
            ]),
          ),
          Expanded(flex: 3, child: right == null ? const SizedBox() : _side(right!)),
        ]),
        if (odds.isNotEmpty) ...[const SizedBox(height: 14), EarnOddsRow(odds)],
      ]),
    );
    return EarnEnter(
      order: 2,
      child: onTap == null ? card : Semantics(button: true, child: EarnPress(onTap: onTap, child: card)),
    );
  }
}

// ─── the ledger ─────────────────────────────────────────────────────────────

/// One cell of [EarnStatGrid]: a label on top, the figure at the bottom
/// ([second] at the bottom right, the reference's home · away pair).
class EarnStat {
  const EarnStat(this.label, this.value, {this.sub, this.second, this.highlight = false, this.key, this.onTap});
  final VoidCallback? onTap;
  final String label;
  final String value;
  final String? second;
  final String? sub;
  final bool highlight;
  final Key? key;
}

/// The reference Statistics card: [title] over a grid of cells on a white
/// card, one DARK highlighted box. Without a [title] it is the bare grid.
class EarnStatGrid extends StatelessWidget {
  const EarnStatGrid(this.stats, {super.key, this.columns = 2, this.title = 'Statistics'});
  final List<EarnStat> stats;
  final int columns;
  final String? title;

  Widget _tile(EarnStat s) {
    final tile = _plain(s);
    if (s.onTap == null) return KeyedSubtree(key: s.key, child: tile);
    return Semantics(
      key: s.key,
      button: true,
      label: '${s.label}, ${s.value}',
      excludeSemantics: true,
      child: EarnPress(onTap: s.onTap, child: tile),
    );
  }

  Widget _plain(EarnStat s) {
    final hi = s.highlight;
    final ink = hi ? Colors.white : kEarnInk;
    final faint = hi ? kEarnSoft : kEarnGrey;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      decoration: BoxDecoration(
        color: hi ? kEarnInk : const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(kEarnTileRadius),
        border: Border.all(color: hi ? kEarnInk : const Color(0x14000000)),
        boxShadow: hi ? const [BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6))] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(s.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: faint, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)),
          ),
          if (s.onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 10, color: faint),
        ]),
        const Spacer(),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(s.value, maxLines: 1, style: TextStyle(color: ink, fontSize: hi ? 24 : 20, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.4)),
            ),
          ),
          if (s.second != null) ...[
            const SizedBox(width: 6),
            Text(s.second!, maxLines: 1, style: TextStyle(color: faint, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ]),
        if (s.sub != null) ...[
          const SizedBox(height: 3),
          Text(s.sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: faint, fontSize: 11, height: 1.3)),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += columns) {
      final row = stats.sublist(i, (i + columns).clamp(0, stats.length));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: 8),
            Expanded(child: j < row.length ? _tile(row[j]) : const SizedBox()),
          ],
        ]),
      ));
      if (i + columns < stats.length) rows.add(const SizedBox(height: 8));
    }
    final grid = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows);
    if (title == null) return grid;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: earnGlossyWhite(radius: kEarnRadius),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnInk, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        ),
        grid,
      ]),
    );
  }
}

// ─── how it works ───────────────────────────────────────────────────────────

/// The steps of NowssB Earn, plainly (no figures: those live in the tabs).
const kEarnHowSteps = <(String, String, String)>[
  (NwsbMarks.reference, 'Share your link', 'Make a link for a word, a meaning or a plan in Invite friends. Each link counts its opens, installs and buyers.'),
  (NwsbMarks.cart, 'A friend buys', 'When someone buys through your link, the words count toward your rank. Your own purchases never count.'),
  (NwsbMarks.hourglass, 'The sale clears', 'A sale waits out the refund window first. A refund or chargeback reverses it.'),
  (NwsbMarks.earn, 'You earn commission', 'Your rank\u2019s rate on each cleared sale after tax and store fees. It needs your own active paid plan.'),
  (NwsbMarks.piggy, 'Request a payout', 'Add your payout details in Payouts, then request what is available.'),
];

/// Opens the how-it-works pop-up. It closes on a tap outside, a swipe down
/// or back. [onRules] adds a "Read the rules" button.
Future<void> showEarnHowItWorks(BuildContext context, {VoidCallback? onRules}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xA6000000),
    builder: (ctx) => EarnHowItWorks(onRules: onRules == null ? null : () {
      Navigator.of(ctx).pop();
      onRules();
    }),
  );
}

/// The how-it-works pop-up's body.
class EarnHowItWorks extends StatelessWidget {
  const EarnHowItWorks({super.key, this.onRules});
  final VoidCallback? onRules;
  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH, maxWidth: 560),
          child: EarnGlass(
            key: const ValueKey('earn-how-sheet'),
            tone: EarnTone.hero,
            radius: 28,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('HOW IT WORKS', style: kEarnEyebrow),
                const SizedBox(height: 4),
                const Text('From a link to a payout', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
                const SizedBox(height: 18),
                for (var i = 0; i < kEarnHowSteps.length; i++) _step(i),
                const SizedBox(height: 8),
                const Text('Earnings depend on your own verified sales and are not guaranteed.', style: TextStyle(color: kEarnMuted, fontSize: 12, height: 1.35)),
                const SizedBox(height: 16),
                Row(children: [
                  if (onRules != null) ...[
                    Expanded(child: EarnActionButton(key: const ValueKey('earn-how-rules'), label: 'Read the rules', icon: Icons.gavel_rounded, onTap: onRules!, primary: false)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: EarnActionButton(key: const ValueKey('earn-how-done'), label: 'Got it', icon: Icons.check_rounded, onTap: () => Navigator.of(context).maybePop()),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int i) {
    final (mark, title, line) = kEarnHowSteps[i];
    final last = i == kEarnHowSteps.length - 1;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          EarnCircle(mark: mark, size: 40),
          if (!last) const Expanded(child: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: VerticalDivider(width: 1, thickness: 1, color: Color(0x33FFFFFF)))),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 4 : 18, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STEP ${i + 1}', style: kEarnEyebrow.copyWith(fontSize: 9.5, color: kEarnMuted)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 3),
              Text(line, style: const TextStyle(color: kEarnSoft, fontSize: 13, height: 1.4)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A glass row that opens the how-it-works pop-up.
class EarnHowItWorksRow extends StatelessWidget {
  const EarnHowItWorksRow({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'How Earn works',
        excludeSemantics: true,
        child: EarnPress(
          key: const ValueKey('earn-how-it-works'),
          onTap: onTap,
          child: EarnGlass(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(children: [
              const EarnCircle(icon: Icons.question_mark_rounded, size: 36),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('How Earn works', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800)),
                  Text('Five steps from a link to a payout', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: kEarnMuted, fontSize: 12, height: 1.3)),
                ]),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20, color: kEarnSoft),
            ]),
          ),
        ),
      );
}

/// A slim loading line in place of the old thinking orb.
class EarnLoading extends StatelessWidget {
  const EarnLoading({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const SizedBox(
              width: 140,
              child: LinearProgressIndicator(minHeight: 3, color: Colors.white, backgroundColor: Color(0x26FFFFFF)),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 10),
            Text(label!, style: const TextStyle(color: kEarnSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ]),
      );
}

/// A text field on the black tile row of the account pages: the small grey
/// label over white type, a square badge on the left.
class EarnField extends StatelessWidget {
  const EarnField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon = Icons.edit_outlined,
    this.fieldKey,
    this.keyboard,
    this.caps = TextCapitalization.none,
    this.action = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.spacing = 0,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Key? fieldKey;
  final TextInputType? keyboard;
  final TextCapitalization caps;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double spacing;

  @override
  Widget build(BuildContext context) => TileRow(
        leading: TileBadge(icon: icon),
        label: label,
        body: TextField(
          key: fieldKey,
          controller: controller,
          style: accountFieldStyle.copyWith(letterSpacing: spacing),
          cursorColor: Colors.white,
          keyboardType: keyboard,
          textCapitalization: caps,
          textInputAction: action,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 1),
            hintText: hint,
            hintMaxLines: 2,
            hintStyle: const TextStyle(color: Color(0x73FFFFFF), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
          ),
        ),
      );
}
