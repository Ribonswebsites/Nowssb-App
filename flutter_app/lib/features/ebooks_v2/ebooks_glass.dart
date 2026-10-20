import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Page-local glass matching the approved cards (approved-1/2): frosted,
/// see-through over the original background video, soft white border,
/// large radius. (This main has no shared nowssb_ui kit.)
class EbTok {
  static const textHi = Colors.white;
  static const textLo = Color(0xB3FFFFFF);
  static const mint = Color(0xFF7FE7D6);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFE879F9);
  static const gold = Color(0xFFF5C451);
  static const rare = Color(0xFF4FD8F0);
  static const accents = [violet, rare, gold, pink];
  static const label = TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6);
}

class EbGlass extends StatelessWidget {
  const EbGlass({super.key, required this.child, this.radius = 24, this.padding = const EdgeInsets.all(16), this.tint, this.onTap});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? tint;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = tint;
    Widget box = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (t ?? Colors.white).withValues(alpha: t == null ? .22 : .30),
                (t ?? Colors.white).withValues(alpha: t == null ? .06 : .10),
              ],
            ),
            border: Border.all(color: const Color(0x45FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) box = GestureDetector(onTap: onTap, child: box);
    return box;
  }
}

/// White rounded pill ("Next" in the approved card) or outlined variant.
class EbPill extends StatelessWidget {
  const EbPill(this.label, {super.key, this.onTap, this.white = true, this.icon});
  final String label;
  final VoidCallback? onTap;
  final bool white;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final fg = white ? const Color(0xFF120B3A) : Colors.white;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: white ? Colors.white : Colors.transparent,
            border: Border.all(color: white ? Colors.white : Colors.white70, width: 1.3),
            boxShadow: white ? const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))] : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13))),
          ]),
        ),
      ),
    );
  }
}

class EbDots extends StatelessWidget {
  const EbDots({super.key, required this.count, required this.index});
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

/// Round photo with soft ring; network cover falls back to a gradient.
class EbCircle extends StatelessWidget {
  const EbCircle({super.key, required this.url, this.size = 140, this.ring = EbTok.violet, this.icon});
  final String url;
  final double size;
  final Color ring;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
          boxShadow: [BoxShadow(color: ring.withValues(alpha: .5), blurRadius: 26)],
          gradient: LinearGradient(colors: [ring, EbTok.pink]),
        ),
        child: ClipOval(
          child: url.startsWith('http') ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()) : _fallback(),
        ),
      );
  Widget _fallback() => Center(child: Icon(icon ?? Icons.auto_stories_rounded, color: Colors.white, size: size * .38));
}

/// The approved MeditationCard: frosted card, top row with a heart, round
/// photo, inner frosted panel (bold title, small grey body, Skip-style text
/// link left, white pill right) and page dots.
class EbMedCard extends StatelessWidget {
  const EbMedCard(
      {super.key,
      required this.photo,
      required this.title,
      this.body,
      this.link,
      this.onLink,
      required this.cta,
      this.onCta,
      this.dots,
      this.dotIndex = 0,
      this.liked,
      this.onLike,
      this.bodyLines = 4});
  final Widget photo;
  final String title, cta;
  final String? body, link;
  final VoidCallback? onLink, onCta, onLike;
  final int? dots;
  final int dotIndex, bodyLines;
  final bool? liked;
  @override
  Widget build(BuildContext context) => EbGlass(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (liked != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: liked! ? 'Saved' : 'Save',
                onPressed: onLike,
                icon: Icon(liked! ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: Colors.white, size: 20),
              ),
            )
          else
            const SizedBox(height: 8),
          photo,
          const SizedBox(height: 20),
          EbGlass(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!, maxLines: bodyLines, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EbTok.textLo, fontSize: 12, height: 1.4)),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: link == null
                      ? const SizedBox.shrink()
                      : GestureDetector(onTap: onLink, child: Text(link!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EbTok.textLo, fontSize: 12))),
                ),
                const SizedBox(width: 8),
                EbPill(cta, onTap: onCta),
              ]),
              if (dots != null) ...[const SizedBox(height: 10), Center(child: EbDots(count: dots!, index: dotIndex))],
            ]),
          ),
        ]),
      );
}

/// Frosted coupon-ticket row (approved-2): notched glass, round photo,
/// dashed divider, rarity-style pill + badge, label, bold value, mint link.
class EbTicket extends StatelessWidget {
  const EbTicket({super.key, required this.photo, required this.accent, required this.tag, this.badge, required this.label, required this.value, required this.action, this.onTap});
  final Widget photo;
  final Color accent;
  final String tag, label, value, action;
  final String? badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: const _Notch(),
        child: EbGlass(
          radius: 22,
          tint: accent,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            photo,
            const SizedBox(width: 12),
            SizedBox(height: 64, child: CustomPaint(painter: _Dash(), size: const Size(1, 64))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, runSpacing: 4, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: accent.withValues(alpha: .25), border: Border.all(color: accent.withValues(alpha: .7))),
                    child: Text(tag, style: TextStyle(color: Color.lerp(accent, Colors.white, .5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: const LinearGradient(colors: [EbTok.pink, EbTok.violet])),
                      child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ]),
                const SizedBox(height: 6),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EbTok.textLo, fontSize: 12)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(action, style: const TextStyle(color: EbTok.mint, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      );
}

class _Notch extends CustomClipper<Path> {
  const _Notch();
  @override
  Path getClip(Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22));
    final p = Path()..addRRect(r);
    final y = s.height / 2;
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: 10))
      ..addOval(Rect.fromCircle(center: Offset(s.width, y), radius: 10));
    return Path.combine(PathOperation.difference, p, holes);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;
    for (double y = 0; y < s.height; y += 6) {
      c.drawLine(Offset(0, y), Offset(0, y + 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Black card inside a frosted wrapper (spec section 6 pop-up).
Future<T?> showEbPopup<T>(BuildContext context, WidgetBuilder builder) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (c, _, __) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              type: MaterialType.transparency,
              child: EbGlass(
                radius: 34,
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: const Color(0xF20B0B12)),
                  child: Material(type: MaterialType.transparency, child: SingleChildScrollView(child: builder(c))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
