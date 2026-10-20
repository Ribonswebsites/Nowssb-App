// Earn UI pieces in Ribon's approved design: frosted meditation card and
// frosted ticket card, on the app's original background video.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../nowssb_ui/app_video_backdrop.dart';

const kEarnPoster = 'assets/video/7e4d709136dc254a_grok_video_2026-07-18-15-53-02_ubjx5b-poster.webp';

/// Round photos: the app's own video posters (no new art).
const kEarnPhotos = [
  'assets/video/28eb0c85b5fd748e_grok_video_2026-07-24-15-42-55_lknomr-poster.webp',
  'assets/video/415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk-poster.webp',
  'assets/video/beaf11ea10561d43_grok_video_2026-07-30-15-35-40_xwm1ei-poster.webp',
  kEarnPoster,
];

/// Tests have no video plugin; they set this to true.
bool earnNoVideo = false;

const kInk = Colors.white;
const kGrey = Color(0xB3FFFFFF);
const kMint = Color(0xFF7FE7D6);

/// The app's original background (shared kit [NAppBackdrop], the same video
/// as every page). The old Earn-only video had a warm sunset on its right
/// side that the cards' backdrop blur smeared into a yellow-red blob.
class EarnBackground extends StatelessWidget {
  const EarnBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const NAppBackdrop(),
        const ColoredBox(color: Color(0x40000000)),
        child,
      ]);
}

/// Frosted translucent glass with a soft white border and large radius.
class Frost extends StatelessWidget {
  const Frost({super.key, required this.child, this.radius = 30, this.padding = const EdgeInsets.all(18), this.onTap, this.tint});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final t = tint ?? Colors.white;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: const Color(0x4DFFFFFF)),
          // Even, cool frost with a dark base so text reads over any frame.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.alphaBlend(t.withValues(alpha: .18), const Color(0x8C1A1530)), Color.alphaBlend(t.withValues(alpha: .06), const Color(0x991A1530))],
          ),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: child,
      ),
    );
  }
}

/// Scales down a touch on press; plain when reduced motion is on.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: AnimatedScale(scale: _down && !still ? .97 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
      ),
    );
  }
}

/// Fade + rise in, staggered by [index]. Instant under reduced motion.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + 60 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c)),
      child: child,
    );
  }
}

/// Progress ring with a value in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.color, required this.center, this.size = 60});
  final double value;
  final Color color;
  final Widget center;
  final double size;
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? value : 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 5, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(color))),
          center,
        ]),
      ),
    );
  }
}

/// Money in the balance's own currency, formatted for the user's locale.
/// Empty currency means the server sent none: show the number only.
String earnMoney(BuildContext context, num amount, String currency) {
  final locale = Localizations.maybeLocaleOf(context)?.toString();
  if (currency.isEmpty) return NumberFormat.decimalPattern(locale).format(amount);
  return NumberFormat.simpleCurrency(locale: locale, name: currency).format(amount);
}

class WhitePill extends StatelessWidget {
  const WhitePill(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: Material(
          color: Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF1B1433), fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ),
        ),
      );
}

class Dots extends StatelessWidget {
  const Dots({super.key, required this.count, required this.index});
  final int count, index;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == index ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(3)),
          ),
      ]);
}

/// The approved meditation card: round top, inner frosted panel with bold
/// title, grey body, text link bottom-left, white pill bottom-right, dots.
class MeditationCard extends StatelessWidget {
  const MeditationCard({
    super.key,
    this.photo,
    this.top,
    required this.title,
    this.body,
    this.extra,
    this.link,
    this.onLink,
    required this.cta,
    this.onCta,
    this.dots,
    this.dotIndex = 0,
  });
  final String? photo;
  final Widget? top;
  final String title;
  final String? body;
  final Widget? extra;
  final String? link;
  final VoidCallback? onLink;
  final String cta;
  final VoidCallback? onCta;
  final int? dots;
  final int dotIndex;

  @override
  Widget build(BuildContext context) => Frost(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: const [Spacer(), Icon(Icons.favorite_rounded, color: Colors.white, size: 18)]),
          top ??
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                  image: photo == null ? null : DecorationImage(image: AssetImage(photo!), fit: BoxFit.cover),
                  color: const Color(0x22FFFFFF),
                ),
              ),
          const SizedBox(height: 18),
          Frost(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: kInk, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              if (body != null) ...[const SizedBox(height: 8), Text(body!, style: const TextStyle(color: kGrey, fontSize: 12.5, height: 1.4))],
              if (extra != null) ...[const SizedBox(height: 10), extra!],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: link == null
                      ? const SizedBox()
                      : GestureDetector(onTap: onLink, child: Text(link!, style: const TextStyle(color: kGrey, fontSize: 12.5))),
                ),
                WhitePill(cta, onTap: onCta),
              ]),
              if (dots != null) ...[const SizedBox(height: 10), Center(child: Dots(count: dots!, index: dotIndex))],
            ]),
          ),
        ]),
      );
}

/// Frosted ticket card (approved coupon list card layout).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.leading, required this.pill, required this.label, required this.headline, required this.link, this.accent = kMint, this.onTap, this.badge});
  final Widget leading;
  final String pill, label, headline, link;
  final String? badge;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Frost(
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(children: [
          SizedBox.square(dimension: 60, child: leading),
          const SizedBox(width: 12),
          Container(width: 1, height: 60, color: Colors.white24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: accent.withValues(alpha: .25), border: Border.all(color: accent.withValues(alpha: .6))),
                  child: Text(pill.toUpperCase(), style: TextStyle(color: Color.lerp(accent, Colors.white, .5), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color(0xFFE879F9)),
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: kGrey, fontSize: 12)),
              Text(headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kInk, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('$link >', style: const TextStyle(color: kMint, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

class RoundPhoto extends StatelessWidget {
  const RoundPhoto(this.asset, {super.key});
  final String asset;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66FFFFFF), width: 2),
          image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
        ),
      );
}

class RoundIcon extends StatelessWidget {
  const RoundIcon(this.icon, {super.key, this.color = kMint, this.text});
  final IconData icon;
  final Color color;
  final String? text;
  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2), color: color.withValues(alpha: .15)),
        child: text != null
            ? FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: Text(text!, style: const TextStyle(color: kInk, fontWeight: FontWeight.w800, fontSize: 18))))
            : Icon(icon, color: kInk),
      );
}

/// Pop-up in the approved card style.
Future<T?> showEarnCard<T>(BuildContext context, Widget Function(BuildContext) builder) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, __) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            child: Material(type: MaterialType.transparency, child: builder(ctx)),
          ),
        ),
      ),
    );

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Text(text.toUpperCase(), style: const TextStyle(color: kMint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
      );
}
