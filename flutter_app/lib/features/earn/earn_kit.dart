/// The NowssB Earn layout (Ribon, Nov 23): the sports-betting reference
/// one-to-one, coloured in NowssB's own glass, the way the Sound Library,
/// Subscription and player are: real frosted glass over the purple swirl,
/// layered violet → indigo → near-black gradients, a fine top-left highlight
/// edge, an inner sheen and soft violet glows beneath. White and black for
/// emphasis, violet for small accents. No yellow, gold, amber or orange.
/// Every icon sits in a WHITE CIRCLE badge.
///
///  * [EarnGlass]        the frosted glass surface every card is made of.
///  * [EarnHey]          round avatar, "Hey," over the bold name, a bell.
///  * [EarnBalanceCard]  one card, two balances, a round badge on its top
///                       edge (cash earned · coins with the real coin).
///  * [EarnActions]      Payout (glossy white pill) · Invite (glass pill).
///  * [EarnSectionTitle] "Programmes" bold with a small See all.
///  * [EarnStatCard]     the event card: a vivid purple → indigo hero glass,
///                       a glow behind the big figure, three odds chips.
///  * [EarnStatGrid]     the Statistics card: deep cells, one luminous
///                       white / lavender highlighted cell.
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

const kEarnMuted = Color(0x99FFFFFF);
const kEarnSoft = Color(0xCCFFFFFF);
const kEarnInk = Color(0xFF0B0B10);
const kEarnGlass = Color(0x17FFFFFF);
const kEarnLine = Color(0x26FFFFFF);
const kEarnDark = Color(0xF20B0B10);
/// The one accent: white (no gold anywhere in Earn).
const kEarnAccent = Colors.white;
const kEarnRadius = 22.0;
const kEarnTileRadius = 16.0;

/// The grey of the small labels on white chips.
const kEarnGrey = Color(0xFF8A8A93);

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

/// A WHITE CIRCLE badge holding a dark mark, icon or [child].
class EarnCircle extends StatelessWidget {
  const EarnCircle({super.key, this.mark, this.icon, this.size = 40, this.child, this.outlined = false});
  final String? mark;
  final IconData? icon;
  final Widget? child;
  final double size;

  /// A hairline ring so the circle reads on a white pill.
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: outlined ? Border.all(color: const Color(0x2E0B0B10)) : null,
        ),
        child: child ??
            (mark != null
                ? NwsbIcon(mark!, size: size * 0.46, color: kEarnInk, strokeWidth: 1.9)
                : Icon(icon ?? Icons.arrow_forward_rounded, size: size * 0.5, color: kEarnInk)),
      );
}

/// Kept for callers: now the white circle badge.
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

/// A tappable white circle (back, bell, expand, close), softly lit.
class EarnCircleButton extends StatelessWidget {
  const EarnCircleButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 42});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: EarnPress(
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Color(0x667C4DFF), blurRadius: 14, offset: Offset(0, 4)),
              BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
            ]),
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

/// The small round avatar: the account photo, else the initial.
class EarnAvatar extends StatelessWidget {
  const EarnAvatar({super.key, this.size = 44, this.name});
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
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Color(0x807C4DFF), blurRadius: 16, offset: Offset(0, 4))]),
      child: url == null
          ? initial
          : Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => initial),
    );
  }
}

/// The reference header: [back], the round avatar, "Hey," small with the
/// name bold under it, and the bell (or [trailing]) at the far right.
class EarnHey extends StatelessWidget {
  const EarnHey({super.key, this.eyebrow, this.onBack, this.trailing, this.title, this.bell = true, this.name});

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

  @override
  Widget build(BuildContext context) {
    final n = name ?? earnFirstName();
    return Row(children: [
      if (onBack != null) ...[EarnBackSquare(onTap: onBack!), const SizedBox(width: 10)],
      EarnAvatar(name: n),
      const SizedBox(width: 12),
      Expanded(
        child: Semantics(
          label: title ?? earnHey(),
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Hey,', maxLines: 1, style: TextStyle(color: kEarnSoft, fontSize: 13, fontWeight: FontWeight.w500, height: 1.2)),
            Text(title ?? n ?? 'there',
                key: const ValueKey('earn-hey'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3)),
          ]),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 10), trailing!]
      else if (bell) ...[
        const SizedBox(width: 10),
        EarnCircleButton(key: const ValueKey('earn-bell'), icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => showNotificationsSheet(context)),
      ],
    ]);
  }
}

/// A glass pane in the Earn shape: NowssB dark glass.

// ─── the glass engine ──────────────────────────────────────────────────────

/// NowssB violet accents.
const kEarnViolet = Color(0xFF8B5CF6);
const kEarnVioletDeep = Color(0xFF6D28D9);
const kEarnLavender = Color(0xFFE9E2FF);
const kEarnGlowViolet = Color(0x667C4DFF);
const kEarnGlowBlue = Color(0x4D4F6BFF);

enum EarnTone {
  /// The everyday card: violet → indigo → near-black.
  pane,

  /// The event card: vivid deep purple → indigo.
  hero,

  /// A cell inside a card.
  cell,

  /// The luminous white / lavender highlighted cell.
  light,
}

bool earnStill(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

List<Color> _fill(EarnTone t) => switch (t) {
      EarnTone.pane => const [Color(0xB8301C5C), Color(0xB31A1446), Color(0xD00B0918)],
      EarnTone.hero => const [Color(0xF0592AC9), Color(0xEB34208F), Color(0xF5140C3A)],
      EarnTone.cell => const [Color(0x2EFFFFFF), Color(0x14FFFFFF), Color(0x0AFFFFFF)],
      EarnTone.light => const [Color(0xFFFFFFFF), Color(0xFFF1ECFF), Color(0xFFDCD0FF)],
    };

/// The fine highlight edge: bright at the top left, fading round the card,
/// a violet whisper at the bottom right.
class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.radius, {this.strong = 1});
  final double radius;
  final double strong;
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius((Offset.zero & size).deflate(0.6), Radius.circular(math.max(0, radius - 0.6)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromRGBO(255, 255, 255, 0.62 * strong),
          Color.fromRGBO(255, 255, 255, 0.14 * strong),
          Color.fromRGBO(255, 255, 255, 0.05 * strong),
          Color.fromRGBO(183, 156, 255, 0.30 * strong),
        ],
        stops: const [0, 0.32, 0.7, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter old) => old.radius != radius || old.strong != strong;
}

/// Box shadows painted only outside the rounded shape.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter(this.shadows, this.radius);
  final List<BoxShadow> shadows;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(math.min(radius, size.shortestSide / 2)));
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect((Offset.zero & size).inflate(80)), Path()..addRRect(rr)));
    for (final s in shadows) {
      canvas.drawRRect(rr.shift(s.offset).inflate(s.spreadRadius), s.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) => old.radius != radius || old.shadows != shadows;
}

/// Static film grain for the hero glass.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final p = Paint()..color = const Color(0x12FFFFFF);
    final n = (size.width * size.height / 260).clamp(0, 1600).toInt();
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), rnd.nextDouble() * 0.7 + 0.2, p);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}

/// One sweep of light across the hero glass on entrance.
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
                    colors: const [Color(0x00FFFFFF), Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
      ),
    );
  }
}

/// The frosted glass surface: a real backdrop blur, the layered gradient
/// of [tone], an inner sheen from the top left, the highlight edge and a
/// soft coloured glow beneath.
class EarnGlass extends StatelessWidget {
  const EarnGlass({
    super.key,
    required this.child,
    this.tone = EarnTone.pane,
    this.radius = kEarnRadius,
    this.padding = EdgeInsets.zero,
    this.glow = kEarnGlowViolet,
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
    final br = BorderRadius.circular(radius);
    final hero = tone == EarnTone.hero;
    final light = tone == EarnTone.light;
    Widget body = Stack(children: [
      // Layered fill.
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _fill(tone), stops: const [0, 0.5, 1]),
          ),
        ),
      ),
      if (hero) ...[
        // A second, cooler light from the bottom right.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment(1.1, 1.2), radius: 1.1, colors: [Color(0x664F6BFF), Color(0x004F6BFF)]),
            ),
          ),
        ),
        const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _GrainPainter()))),
      ],
      // Inner sheen.
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: const Alignment(0.4, 0.6),
              colors: [Color(light ? 0x00FFFFFF : (hero ? 0x2EFFFFFF : 0x1FFFFFFF)), const Color(0x00FFFFFF)],
            ),
          ),
        ),
      ),
      // Inner shadow at the foot, for depth.
      if (tone == EarnTone.cell)
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x33000000)], stops: [0.55, 1]),
            ),
          ),
        ),
      if (hero) const Positioned.fill(child: _Shimmer()),
      Padding(padding: padding, child: child),
      Positioned.fill(
        child: IgnorePointer(child: CustomPaint(painter: _EdgePainter(circle ? 999 : radius, strong: light ? 0.0 : (tone == EarnTone.cell ? 0.7 : 1)))),
      ),
    ]);
    body = ClipRRect(
      borderRadius: circle ? BorderRadius.circular(999) : br,
      child: blur && !light
          ? BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: body)
          : body,
    );
    final shadows = <BoxShadow>[
      if (glow != null) BoxShadow(color: glow!, blurRadius: hero ? 34 : 24, spreadRadius: -4, offset: Offset(0, hero ? 14 : 10)),
      if (tone != EarnTone.cell) const BoxShadow(color: Color(0x4D000000), blurRadius: 18, offset: Offset(0, 8)),
    ];
    // Drawn outside the shape only, so the glass never shows a dark lip
    // of its own shadow through itself.
    return CustomPaint(painter: _OuterShadowPainter(shadows, circle ? 9999 : radius), child: body);
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
      child: AnimatedScale(scale: _down ? 0.965 : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
    );
  }
}

/// The glossy white pill face (Payout, the active tab, odds chips).
BoxDecoration earnGlossyWhite({double radius = 999, bool shadow = true}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFF3EFFC), Color(0xFFE2DAF7)], stops: [0, 0.55, 1]),
      boxShadow: shadow
          ? const [
              BoxShadow(color: Color(0x557C4DFF), blurRadius: 18, spreadRadius: -4, offset: Offset(0, 8)),
              BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
            ]
          : null,
    );

/// The gloss band across the top half of a white pill.
const _gloss = Positioned(
  left: 0,
  right: 0,
  top: 0,
  height: 18,
  child: IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xB3FFFFFF), Color(0x00FFFFFF)]),
      ),
    ),
  ),
);

/// A frosted glass circle with a highlight edge holding a white icon
/// (the inactive tab chips).
class EarnGlassCircle extends StatelessWidget {
  const EarnGlassCircle({super.key, required this.mark, this.size = 48});
  final String mark;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: EarnGlass(
          circle: true,
          radius: size / 2,
          glow: const Color(0x337C4DFF),
          child: SizedBox(width: size, height: size, child: Center(child: NwsbIcon(mark, size: size * 0.42, color: Colors.white, strokeWidth: 1.9))),
        ),
      );
}

/// A card in the Earn shape: frosted NowssB glass.
class EarnPane extends StatelessWidget {
  const EarnPane({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.dark = false, this.tone = EarnTone.pane, this.glow = kEarnGlowViolet});
  final Widget child;
  final EdgeInsets padding;
  final bool dark;
  final EarnTone tone;
  final Color? glow;
  @override
  Widget build(BuildContext context) => EarnGlass(tone: tone, padding: padding, glow: dark ? kEarnGlowBlue : glow, child: child);
}

/// One side of [EarnBalanceCard].
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

/// One card, two balances side by side, a white circle badge centred on
/// its top edge (the reference's Current / Bonus balance card).
class EarnBalanceCard extends StatelessWidget {
  const EarnBalanceCard({super.key, required this.left, required this.right, this.badge = Icons.swap_horiz_rounded});
  final EarnBalance left;
  final EarnBalance right;
  final IconData badge;

  Widget _side(EarnBalance b) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Flexible(
            child: Text(b.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          if (b.onTap != null) ...[const SizedBox(width: 4), const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kEarnMuted)],
        ]),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (b.coin) ...[
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x667C4DFF), blurRadius: 14)]),
                child: const NwsbCoinDisc(size: 26),
              ),
              const SizedBox(width: 7),
            ],
            DefaultTextStyle.merge(style: const TextStyle(shadows: kEarnNumberGlow), child: b.value),
          ]),
        ),
        if (b.sub != null) ...[
          const SizedBox(height: 4),
          Text(b.sub!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnMuted, fontSize: 11.5, height: 1.3)),
        ],
      ]),
    );
    if (b.onTap == null) return body;
    return Semantics(
      button: true,
      label: b.label,
      child: EarnPress(key: b.key, onTap: b.onTap, child: body),
    );
  }

  @override
  Widget build(BuildContext context) => EarnEnter(
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Stack(clipBehavior: Clip.none, children: [
            EarnGlass(
              key: const ValueKey('earn-balance-card'),
              radius: 20,
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _side(left)),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)]),
                    ),
                  ),
                  Expanded(child: _side(right)),
                ]),
              ),
            ),
            Positioned(
              top: -15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: Color(0x887C4DFF), blurRadius: 16, offset: Offset(0, 4)),
                    BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 3)),
                  ]),
                  child: EarnCircle(icon: badge, size: 30),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// A soft glow under big white figures.
const kEarnNumberGlow = [Shadow(color: Color(0x99A78BFA), blurRadius: 18), Shadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))];

/// The big number style of balances and stat cards.
const kEarnBig = TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8);

/// A reference pill button: a glossy white pill when [primary] (the
/// Deposit), else a glass pill with a highlight edge (Withdraw); a white
/// circle icon at its left.
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
        padding: const EdgeInsets.fromLTRB(7, 7, 10, 7),
        child: Row(children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: primary ? const Color(0x337C4DFF) : const Color(0x557C4DFF), blurRadius: 10, offset: const Offset(0, 3))]),
            child: EarnCircle(icon: icon, size: 38, outlined: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: TextStyle(color: primary ? kEarnInk : Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: -0.1)),
            ),
          ),
          const SizedBox(width: 8),
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
            ? DecoratedBox(
                decoration: earnGlossyWhite(radius: 28),
                child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Stack(children: [content, _gloss])),
              )
            : EarnGlass(radius: 28, glow: const Color(0x557C4DFF), child: content),
      ),
    );
  }
}

/// Two equal pills side by side: Payout (glossy white) and Invite (glass).
class EarnActions extends StatelessWidget {
  const EarnActions({super.key, required this.onPayout, required this.onInvite});
  final VoidCallback onPayout;
  final VoidCallback onInvite;
  @override
  Widget build(BuildContext context) => EarnEnter(
        order: 1,
        child: Row(children: [
          Expanded(child: EarnActionButton(key: const ValueKey('earn-action-payout'), label: 'Payout', icon: Icons.arrow_downward_rounded, onTap: onPayout)),
          const SizedBox(width: 10),
          Expanded(child: EarnActionButton(key: const ValueKey('earn-action-invite'), label: 'Invite', icon: Icons.arrow_upward_rounded, onTap: onInvite, primary: false)),
        ]),
      );
}

/// A section header: bold title at the left, small See all at the right.
class EarnSectionTitle extends StatelessWidget {
  const EarnSectionTitle(this.title, {super.key, this.onSeeAll, this.action = 'See all'});
  final String title;
  final VoidCallback? onSeeAll;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
        child: Row(children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, shadows: [Shadow(color: Color(0x667C4DFF), blurRadius: 16)])),
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
                  child: Text(action, style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ]),
      );
}

enum EarnStatus { ongoing, upcoming, reached, off }

/// The status pill: Ongoing a glowing violet, Reached luminous white,
/// Upcoming and off a frosted glass pill.
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
    final (BoxDecoration deco, Color fg, bool dot) = switch (status) {
      EarnStatus.ongoing => (
          BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(colors: [Color(0xFFA78BFA), kEarnViolet, kEarnVioletDeep]),
            border: Border.all(color: const Color(0x66FFFFFF)),
            boxShadow: const [BoxShadow(color: Color(0x998B5CF6), blurRadius: 12, offset: Offset(0, 3))],
          ),
          Colors.white,
          true,
        ),
      EarnStatus.reached => (earnGlossyWhite(), kEarnInk, false),
      _ => (
          BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x38FFFFFF), Color(0x14FFFFFF)]),
            border: Border.all(color: const Color(0x4DFFFFFF)),
          ),
          Colors.white,
          false,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: deco,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white, blurRadius: 6)])),
          const SizedBox(width: 6),
        ],
        Text(label, maxLines: 1, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
      ]),
    );
  }
}

/// A small glossy white chip: a mark (or the real coin) and a short line.
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
            EarnCircle(mark: mark, icon: icon, size: 18, outlined: true),
          if (coin || mark != null || icon != null) const SizedBox(width: 5),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kEarnInk, fontSize: 11.5, fontWeight: FontWeight.w700))),
        ]),
      );
}

/// The reference odds chip: a glossy white pill, a small grey label and a
/// bold figure ("1x  1.8").
class EarnOdd {
  const EarnOdd(this.label, this.value, {this.coin = false, this.icon});
  final String label;
  final String value;
  final bool coin;
  final IconData? icon;
}

class EarnOddChip extends StatelessWidget {
  const EarnOddChip(this.odd, {super.key});
  final EarnOdd odd;
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: earnGlossyWhite().copyWith(boxShadow: const [BoxShadow(color: Color(0x4D1E0B4A), blurRadius: 10, offset: Offset(0, 4))]),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(odd.label, maxLines: 1, style: const TextStyle(color: kEarnGrey, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            if (odd.coin) ...[const NwsbCoinDisc(size: 15), const SizedBox(width: 3)],
            if (odd.icon != null) ...[Icon(odd.icon, size: 14, color: kEarnVioletDeep), const SizedBox(width: 2)],
            Text(odd.value, maxLines: 1, style: const TextStyle(color: kEarnInk, fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

/// A row of up to three odds chips, equal widths.
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

/// A progress bar: a violet → white gradient on a glass track, softly lit.
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
            const ColoredBox(color: Color(0x26FFFFFF)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: color == null ? const [kEarnViolet, Color(0xFFC4B5FD), Colors.white] : [color!, color!]),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// One side of [EarnStatCard]: the crest (a white circle badge) and its
/// name under it.
class EarnSide {
  const EarnSide(this.label, {this.mark, this.icon, this.coin = false});
  final String label;
  final String? mark;
  final IconData? icon;
  final bool coin;
}

/// The reference event card as a vivid hero: deep purple → indigo glass
/// with grain, a sweep of light on entrance and a glow behind the big
/// figure; a crest each side, three glossy odds chips under it.
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

  /// The vivid hero glass; off for the quieter list cards.
  final bool hero;

  Widget _side(EarnSide s) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: Color(0x80A78BFA), blurRadius: 18, spreadRadius: -2),
            BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 4)),
          ]),
          child: s.coin ? const NwsbCoinDisc(size: 46) : EarnCircle(mark: s.mark, icon: s.icon, size: 46),
        ),
        const SizedBox(height: 7),
        Text(s.label,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2)),
      ]);

  @override
  Widget build(BuildContext context) {
    final card = EarnGlass(
      tone: hero ? EarnTone.hero : EarnTone.pane,
      glow: hero ? const Color(0x998B5CF6) : kEarnGlowViolet,
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
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              // The soft light behind the figure.
              Positioned(
                left: -20,
                right: -20,
                top: -18,
                bottom: -18,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 0.62,
                        colors: hero ? const [Color(0x99B79CFF), Color(0x408B5CF6), Color(0x008B5CF6)] : const [Color(0x40A78BFA), Color(0x008B5CF6)],
                      ),
                    ),
                  ),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (eyebrow != null)
                  FittedBox(fit: BoxFit.scaleDown, child: Text(eyebrow!, maxLines: 1, style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 11.5, fontWeight: FontWeight.w600))),
                const SizedBox(height: 2),
                FittedBox(fit: BoxFit.scaleDown, child: Text(number, maxLines: 1, style: kEarnBig.copyWith(fontSize: 34, shadows: kEarnNumberGlow))),
                if (under != null) ...[
                  const SizedBox(height: 2),
                  Text(under!, maxLines: 3, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD9CCFF), fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.25)),
                ],
              ]),
            ]),
          ),
          Expanded(flex: 3, child: right == null ? const SizedBox() : _side(right!)),
        ]),
        if (odds.isNotEmpty) ...[const SizedBox(height: 16), EarnOddsRow(odds)],
      ]),
    );
    return EarnEnter(
      order: 2,
      child: onTap == null ? card : Semantics(button: true, child: EarnPress(onTap: onTap, child: card)),
    );
  }
}

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

/// The reference Statistics card: [title] over a grid of deep glass cells,
/// one luminous white / lavender highlighted cell with black text.
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
    final faint = hi ? const Color(0xFF5B5470) : kEarnSoft;
    final inner = Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text(s.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: faint, fontSize: 12, fontWeight: FontWeight.w600, height: 1.2))),
          if (s.onTap != null) Icon(Icons.arrow_forward_ios_rounded, size: 10, color: hi ? kEarnInk : kEarnSoft),
        ]),
        const Spacer(),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(s.value,
                  maxLines: 1,
                  style: TextStyle(
                      color: hi ? kEarnInk : Colors.white,
                      fontSize: hi ? 24 : 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.4,
                      shadows: hi ? null : const [Shadow(color: Color(0x66A78BFA), blurRadius: 12)])),
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
    return EarnGlass(
      tone: hi ? EarnTone.light : EarnTone.cell,
      radius: kEarnTileRadius,
      blur: false,
      glow: hi ? const Color(0x99A78BFA) : null,
      child: inner,
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
    if (title == null) return EarnEnter(order: 3, child: grid);
    return EarnEnter(
      order: 3,
      child: EarnPane(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        glow: kEarnGlowBlue,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Row(children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC4B5FD), kEarnViolet]), boxShadow: const [BoxShadow(color: Color(0x998B5CF6), blurRadius: 8)])),
              const SizedBox(width: 9),
              Expanded(child: Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3))),
            ]),
          ),
          grid,
        ]),
      ),
    );
  }
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
            hintStyle: const TextStyle(color: Color(0x73FFFFFF), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0),
          ),
        ),
      );
}
