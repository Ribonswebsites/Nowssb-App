// Earn in NowssB Home's style (Oct 21 order): Home's top bar, dark-glass
// sections with a white icon button + pill caption, Home's 3D banner art with
// the Enter pill, a gold Shop pill, SBI-style huge % stat rows, and bottom
// sheets with a hero, two split stats and Close / Resume buttons.
import 'package:flutter/material.dart';

import '../../../widgets/home_parts.dart' show EnterPill;
import 'earn_ui.dart';

const kNearBlack = Color(0xF20C0C10);
const kGold = Color(0xFFE9C987);

/// Home's top row: round NowssB logo disc + title left, a glass cluster of
/// round buttons with thin dividers right. Sub-pages show a back arrow.
class EarnHomeBar extends StatelessWidget {
  const EarnHomeBar({super.key, required this.title, required this.onHelp, required this.onMenu});
  final String title;
  final VoidCallback onHelp, onMenu;
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    Widget btn(Key k, String tip, IconData i, VoidCallback f) => IconButton(key: k, tooltip: tip, onPressed: f, icon: Icon(i, color: kInk, size: 21));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: [
        if (canPop)
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x33FFFFFF), border: Border.all(color: const Color(0x55FFFFFF))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: kInk, size: 18, semanticLabel: 'Back'),
            ),
          )
        else
          ClipOval(child: Image.asset('assets/icons/logo-disc.webp', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, color: kInk))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kInk, fontSize: 20, fontWeight: FontWeight.w800))),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: const Color(0x2EFFFFFF), border: Border.all(color: const Color(0x40FFFFFF))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            btn(const Key('earn-help'), 'How Earn works', Icons.help_outline_rounded, onHelp),
            Container(width: 1, height: 20, color: const Color(0x40FFFFFF)),
            btn(const Key('earn-menu'), 'Menu', Icons.menu_rounded, onMenu),
          ]),
        ),
      ]),
    );
  }
}

/// Home's section: ~24px translucent dark glass with a thin light border,
/// headed by a round white icon button and a small pill caption.
class DarkSection extends StatelessWidget {
  const DarkSection({super.key, this.icon, this.caption, this.eyebrow, required this.child, this.onHeader});
  final IconData? icon;
  final String? caption, eyebrow;
  final Widget child;
  final VoidCallback? onHeader;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0x99101016),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (caption != null) ...[
            GestureDetector(
              onTap: onHeader,
              child: Row(children: [
                Container(width: 34, height: 34, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Icon(icon ?? Icons.auto_awesome_rounded, size: 18, color: const Color(0xFF111111))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0x55FFFFFF))),
                  child: Text(caption!, style: const TextStyle(color: kInk, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                if (eyebrow != null) ...[const Spacer(), Text(eyebrow!.toUpperCase(), style: const TextStyle(color: kGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4))],
              ]),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ]),
      );
}

/// Solid near-black inner box.
class InnerBox extends StatelessWidget {
  const InnerBox({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(padding: padding, decoration: BoxDecoration(color: kNearBlack, borderRadius: BorderRadius.circular(16)), child: child),
      );
}

/// SBI-style row: a huge bold number, a label under it, a round icon right.
class PctRow extends StatelessWidget {
  const PctRow({super.key, required this.value, required this.label, required this.icon, this.color = Colors.white, this.divider = true, this.onTap});
  final String value, label;
  final IconData icon;
  final Color color;
  final bool divider;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: divider ? const Border(bottom: BorderSide(color: Color(0x26FFFFFF))) : null),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(color: kInk, fontSize: 44, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1))),
                const SizedBox(height: 4),
                Text(label, maxLines: 2, style: const TextStyle(color: kGrey, fontSize: 13)),
              ]),
            ),
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: .18), border: Border.all(color: color.withValues(alpha: .6))),
              child: Icon(icon, color: color, size: 22),
            ),
          ]),
        ),
      );
}

/// Home's wide 3D banner (Home's own render) with a bold white title and
/// the white round-arrow Enter pill.
class EarnBanner extends StatelessWidget {
  const EarnBanner({super.key, required this.art, required this.title, required this.sub, required this.onEnter, this.label = 'Enter'});
  final String art, title, sub, label;
  final VoidCallback onEnter;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onEnter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(art, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1B1433))),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]))),
              Positioned(
                left: 16, right: 16, bottom: 14,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(title, style: const TextStyle(color: kInk, fontSize: 22, fontWeight: FontWeight.w900)),
                      Text(sub, maxLines: 2, style: const TextStyle(color: kGrey, fontSize: 12)),
                    ]),
                  ),
                  EnterPill(label: label, onTap: onEnter),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// Home's cream/gold "Shop Now" pill.
class ShopPill extends StatelessWidget {
  const ShopPill({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: const LinearGradient(colors: [Color(0xFFF6E7C1), kGold])),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(color: Color(0xFF2A1E05), fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF2A1E05)),
          ]),
        ),
      );
}

/// Full-width white call-to-action pinned under the content.
class FixedCta extends StatelessWidget {
  const FixedCta({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF111111), shape: const StadiumBorder(), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            onPressed: onTap,
            child: Text(label),
          ),
        ),
      );
}

/// SBI "Complete your application" sheet: hero, title, body, two huge stats
/// split by a vertical divider, Close (outline) and Resume (white).
Future<void> showEarnSheet(
  BuildContext context, {
  Key? key,
  required Widget hero,
  required String title,
  required String body,
  required (String, String) left,
  required (String, String) right,
  String? note,
  String resume = 'Resume',
  VoidCallback? onResume,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget stat((String, String) s) => Expanded(
              child: Column(children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(s.$1, style: const TextStyle(color: kInk, fontSize: 40, fontWeight: FontWeight.w900, height: 1))),
                const SizedBox(height: 4),
                Text(s.$2, textAlign: TextAlign.center, style: const TextStyle(color: kGrey, fontSize: 12)),
              ]),
            );
        return Container(
          key: key,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          decoration: BoxDecoration(color: const Color(0xF0121218), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x33FFFFFF))),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              // Content scrolls on short screens; Close / Resume always show.
              Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              hero,
              const SizedBox(height: 14),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: kInk, fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: kGrey, fontSize: 13.5, height: 1.35)),
              const SizedBox(height: 18),
              IntrinsicHeight(child: Row(children: [stat(left), const VerticalDivider(color: Color(0x40FFFFFF), width: 24, thickness: 1), stat(right)])),
              if (note != null) ...[const SizedBox(height: 12), Text(note, textAlign: TextAlign.center, style: const TextStyle(color: kMint, fontSize: 12.5, fontWeight: FontWeight.w700))],
              ]))),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: kInk, side: const BorderSide(color: Color(0x99FFFFFF)), shape: const StadiumBorder(), minimumSize: const Size.fromHeight(50)),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF111111), shape: const StadiumBorder(), minimumSize: const Size.fromHeight(50)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onResume?.call();
                    },
                    child: Text(resume, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
