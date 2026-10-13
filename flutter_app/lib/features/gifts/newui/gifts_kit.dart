import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

/// Gifts colours on the shared kit tokens (approved design: neutral frosted
/// glass, white type, mint section labels, rarity-style status pills).
class GiftsPalette {
  static const text = Colors.white;
  static const soft = NTokens.textLo;
  static const muted = Color(0x99FFFFFF);
  static const label = NTokens.mint;
  static const ink = Color(0xFF1B1B24);
  static const cta = NTokens.violet;
  static const bgBottom = Color(0xFF08090B);
}

/// Thin alias so every Gifts surface is the kit's [NGlass] (UI Design's
/// approved card glass). [inner] = the lighter inner panel.
class GiftsFrost extends StatelessWidget {
  const GiftsFrost({super.key, required this.child, this.radius = NTokens.rCard, this.padding = const EdgeInsets.all(16), this.inner = false, this.onTap});
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool inner;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => NGlass(radius: radius, padding: padding, elevation: inner ? .3 : 1, onTap: onTap, child: child);
}

/// Mint caps section label ("COUPON LIST" in the approved design).
class GiftsSectionLabel extends StatelessWidget {
  const GiftsSectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(text.toUpperCase(), style: const TextStyle(color: GiftsPalette.label, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
      );
}

/// Status pill in the approved rarity-pill style (glass, tinted text).
class GiftsStatusPill extends StatelessWidget {
  const GiftsStatusPill(this.text, {super.key, this.color = NTokens.common});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rPill,
        accent: color,
        tint: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(color: Color.lerp(color, Colors.white, .5), fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
      );
}

/// Gift ticket: the approved frosted coupon ticket (notched glass, circle
/// photo, dashed divider, status pill + optional NEW, small label, bold
/// headline, mint link). Same structure as the kit's CouponListCard, but
/// with honest gift wording instead of its fixed rarity / "View products".
class GiftTicketCard extends StatelessWidget {
  const GiftTicketCard(
      {super.key,
      required this.label,
      required this.headline,
      required this.status,
      required this.link,
      this.image,
      this.statusColor = NTokens.common,
      this.isNew = false,
      this.expired = false,
      this.onTap});
  final String label, headline, status, link;
  final ImageProvider? image;
  final Color statusColor;
  final bool isNew, expired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Semantics(
      button: onTap != null,
      label: '$headline. $label. $status${expired ? '. Expired' : ''}',
      child: ClipPath(
        clipper: const NotchClipper(radius: 22, notch: 10),
        child: NGlass(
          radius: 22,
          accent: statusColor,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            CircleImage(image: image, size: 64, ring: statusColor),
            const SizedBox(width: 12),
            const SizedBox(height: 64, child: DashedLine(vertical: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GiftsStatusPill(status, color: statusColor),
                  if (isNew) ...[const SizedBox(width: 6), const GlassBadge('NEW')]
                ]),
                const SizedBox(height: 6),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
                Text(headline,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(link, style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
    if (expired) card = ExpiredOverlay(child: card);
    return card;
  }
}

/// Empty / error / offline: kit GlassStateCard.
class GiftsStateCard extends StatelessWidget {
  const GiftsStateCard({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => GlassStateCard(icon: icon, title: title, message: message, action: action, onAction: onAction);
}

/// Four frosted shortcut tiles (kit glass, white icons).
class GiftsShortcuts extends StatelessWidget {
  const GiftsShortcuts({super.key, required this.items, required this.onTap});
  final List<(IconData, String)> items;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Semantics(
                button: true,
                label: items[i].$2,
                excludeSemantics: true,
                child: NGlass(
                  radius: 20,
                  onTap: () => onTap(i),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(children: [
                    Icon(items[i].$1, color: Colors.white, size: 24),
                    const SizedBox(height: 6),
                    Text(items[i].$2,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
      ]);
}

/// Page root on the app's ORIGINAL background (kit NAppBackdrop = AppBackdrop
/// video; still colour under flutter test).
class GiftsPageShell extends StatelessWidget {
  const GiftsPageShell({super.key, required this.title, required this.body, this.actions = const [], this.backdrop = true});
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool backdrop;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GiftsPalette.bgBottom,
        body: NAppBackdrop(
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
                child: Row(children: [
                  IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                  ...actions,
                ]),
              ),
              Expanded(child: body),
            ]),
          ),
        ),
      );
}

/// Fades and lifts a section in, staggered by [index]. Calm, 500 ms.
class GiftsReveal extends StatelessWidget {
  const GiftsReveal({super.key, required this.index, required this.child, this.animate = true});
  final int index;
  final Widget child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate || (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + 90 * index),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c)),
      child: child,
    );
  }
}
