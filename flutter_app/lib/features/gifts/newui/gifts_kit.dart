import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart' show NCircles, ExpiredOverlay;
import '../../../widgets/app_backdrop.dart';
import '../../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;

/// Gifts colours. Text is white / grey-white like the reference card.
/// The only accent is the reference's solid violet CTA pill.
class GiftsPalette {
  static const text = Colors.white;
  static const soft = Color(0xB3FFFFFF);
  static const muted = Color(0x99FFFFFF);
  static const cta = Color(0xFF7C4DFF); // solid violet "Get Started" pill
  static const ink = Color(0xFF1B1B24); // dark text on the white pill
  // Kept for call sites; all map to the neutral frosted look now.
  static const pink = Colors.white;
  static const violet = Colors.white;
  static const amber = Colors.white;
  static const teal = Colors.white;
  static const bgBottom = Color(0xFF05070D);
}

/// Frosted glass from card-reference-exact.png: lightly white-tinted, blurred,
/// radius ~26, 1px faint light border, soft shadow. Page-local until UI
/// Design's updated NGlass lands on main; swap this one class then.
class GiftsFrost extends StatelessWidget {
  const GiftsFrost({super.key, required this.child, this.radius = 26, this.padding = const EdgeInsets.all(16), this.inner = false, this.onTap});
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// The lighter inner sub-card (holds the text in the reference).
  final bool inner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: Colors.white.withValues(alpha: inner ? .16 : .10),
        border: Border.all(color: Colors.white.withValues(alpha: inner ? .22 : .28), width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap != null) {
      body = Material(type: MaterialType.transparency, child: InkWell(borderRadius: r, onTap: onTap, child: body));
    } else {
      body = Material(type: MaterialType.transparency, child: body);
    }
    final glass = ClipRRect(
      borderRadius: r,
      child: inner ? body : BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: body),
    );
    if (inner) return glass;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))]),
      child: glass,
    );
  }
}

/// Small white pill with dark text ("Next"), or the solid violet CTA.
class GiftsPill extends StatelessWidget {
  const GiftsPill({super.key, required this.label, required this.onTap, this.primary = false, this.icon});
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: primary ? GiftsPalette.cta : Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: primary ? 22 : 14, vertical: primary ? 11 : 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 16, color: primary ? Colors.white : GiftsPalette.ink), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: primary ? Colors.white : GiftsPalette.ink, fontWeight: FontWeight.w700, fontSize: primary ? 14 : 12)),
            ]),
          ),
        ),
      );
}

class GiftsDots extends StatelessWidget {
  const GiftsDots({super.key, required this.count, required this.index});
  final int count, index;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == index ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: i == index ? .9 : .4), borderRadius: BorderRadius.circular(3)),
          ),
      ]);
}

/// One step of the reference card: circle photo on top, inner frosted panel
/// with bold title, muted body, Skip (left), Next pill (right) and dots.
class GiftsRefCard extends StatelessWidget {
  const GiftsRefCard(
      {super.key, required this.image, required this.title, required this.body, required this.index, required this.count, this.onNext, this.onSkip, this.cta});
  final ImageProvider image;
  final String title, body;
  final int index, count;
  final VoidCallback? onNext, onSkip;

  /// When set, the last step shows the solid violet CTA pill instead of Next.
  final String? cta;

  @override
  Widget build(BuildContext context) {
    final last = index == count - 1;
    return GiftsFrost(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: image, fit: BoxFit.cover),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
        ),
        const SizedBox(height: 16),
        GiftsFrost(
          inner: true,
          radius: 20,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: GiftsPalette.text, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: GiftsPalette.muted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 14),
            Row(children: [
              if (onSkip != null && !last)
                GestureDetector(onTap: onSkip, child: const Text('Skip', style: TextStyle(color: GiftsPalette.soft, fontSize: 12)))
              else
                const SizedBox(),
              const Spacer(),
              if (last && cta != null) GiftsPill(label: cta!, primary: true, onTap: onNext) else GiftsPill(label: 'Next', onTap: onNext),
            ]),
            const SizedBox(height: 10),
            Center(child: GiftsDots(count: count, index: index)),
          ]),
        ),
      ]),
    );
  }
}

/// Coin balance with the app's existing gold coin (NwsbCoinDisc).
class GiftsCoinPill extends StatelessWidget {
  const GiftsCoinPill({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$coins coins',
        excludeSemantics: true,
        child: GiftsFrost(
          key: const Key('gifts.coins'),
          radius: 20,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const NwsbCoinDisc(size: 18),
            const SizedBox(width: 6),
            Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

/// Empty / error / offline card in the same frosted style.
class GiftsStateCard extends StatelessWidget {
  const GiftsStateCard({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => GiftsFrost(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: GiftsPalette.muted, fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 16), GiftsPill(label: action!, onTap: onAction)],
        ]),
      );
}

/// Four frosted shortcut tiles with the existing circle photos.
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
                child: GiftsFrost(
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

/// Gift card tile (catalog rails and My gifts): frosted card, circle photo,
/// bold white title, muted caption, small footer line. Expired is greyed.
class GiftsCardTile extends StatelessWidget {
  const GiftsCardTile({super.key, required this.title, required this.caption, this.footer = '', this.color, this.expired = false, this.onTap, this.photo = 0});
  final String title, caption, footer;
  final Color? color; // unused: neutral glass everywhere
  final bool expired;
  final VoidCallback? onTap;
  final int photo;

  @override
  Widget build(BuildContext context) {
    final t = Semantics(
      button: onTap != null,
      label: '$title. $caption${expired ? '. Expired' : ''}',
      child: GiftsFrost(
        radius: 24,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NCircles.at(photo), fit: BoxFit.cover))),
          const SizedBox(height: 10),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.muted, fontSize: 11.5, height: 1.3)),
          if (footer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(footer, style: const TextStyle(color: GiftsPalette.soft, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
    return expired ? ExpiredOverlay(child: t) : t;
  }
}

/// The page root: the app's ORIGINAL background (AppBackdrop: the saved
/// Fashion Plus film, or its still / black) with content on top.
class GiftsPageShell extends StatelessWidget {
  const GiftsPageShell({super.key, required this.title, required this.body, this.actions = const [], this.backdrop = true});
  final String title;
  final Widget body;
  final List<Widget> actions;

  /// Tests switch the video off; the fallback is the app's own deep colour.
  final bool backdrop;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: GiftsPalette.bgBottom,
        body: Stack(fit: StackFit.expand, children: [
          if (backdrop) const Positioned.fill(child: AppBackdrop()) else const ColoredBox(color: GiftsPalette.bgBottom),
          SafeArea(
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
        ]),
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
