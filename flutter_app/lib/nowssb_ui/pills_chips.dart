// Pills, buttons, chips, badges, countdown, rarity chip, page dots.
import 'package:flutter/material.dart';
import '../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import 'glass_core.dart';
import 'tokens.dart';

enum PillStyle { glass, solid, outlined, white }

/// Small light glass pill button (meditation "Next").
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.label, this.onTap, this.style = PillStyle.glass,
    this.icon, this.trailing, this.accent = NTokens.violet, this.dense = false});
  final String label; final VoidCallback? onTap; final PillStyle style;
  final IconData? icon, trailing; final Color accent; final bool dense;
  @override
  Widget build(BuildContext context) {
    final fg = style == PillStyle.white ? NTokens.bgBottom : Colors.white;
    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
      Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: dense ? 12 : 14))),
      if (trailing != null) ...[const SizedBox(width: 4), Icon(trailing, size: 16, color: fg)],
    ]);
    final pad = EdgeInsets.symmetric(horizontal: dense ? 12 : 18, vertical: dense ? 6 : 10);
    final inner = switch (style) {
      PillStyle.glass => content,
      PillStyle.solid => DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [accent, NTokens.indigoBtn])), child: Padding(padding: pad, child: content)),
      PillStyle.white => DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFE6E0FF)])), child: Padding(padding: pad, child: content)),
      PillStyle.outlined => DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white70, width: 1.4)), child: Padding(padding: pad, child: content)),
    };
    return NGlass(radius: NTokens.rPill, accent: accent, elevation: .5, onTap: onTap,
        padding: style == PillStyle.glass ? pad : const EdgeInsets.all(2), child: inner);
  }
}

/// Filter chip: outlined (default) or selected (filled glass) + optional dropdown caret.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.selected = false, this.dropdown = false, this.onTap});
  final String label; final bool selected, dropdown; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rPill, elevation: selected ? .8 : .2, onTap: onTap,
        tint: selected ? NTokens.violet : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check, size: 14, color: Colors.white)),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          if (dropdown) const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
        ]));
}

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.labels, required this.selected, required this.onSelect, this.dropdowns = const {}});
  final List<String> labels; final Set<int> selected; final ValueChanged<int> onSelect; final Set<int> dropdowns;
  @override
  Widget build(BuildContext context) => SizedBox(height: 44, child: ListView.separated(
      scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: labels.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Center(child: GlassChip(label: labels[i], selected: selected.contains(i),
          dropdown: dropdowns.contains(i), onTap: () => onSelect(i)))));
}

class RarityChip extends StatelessWidget {
  const RarityChip(this.rarity, {super.key, this.label, this.color});
  final Rarity rarity;
  /// Optional overrides; default to the rarity's own name and colour.
  final String? label; final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? rarity.color;
    return NGlass(radius: NTokens.rPill, accent: c, tint: c,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text((label ?? rarity.name).toUpperCase(), style: TextStyle(color: Color.lerp(c, Colors.white, .5),
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)));
  }
}

/// "New", "100% CoinBack", "Best saving" etc.
class GlassBadge extends StatelessWidget {
  const GlassBadge(this.text, {super.key, this.color = NTokens.pink});
  final String text; final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [color, Color.lerp(color, NTokens.violet, .5)!]),
          border: Border.all(color: NTokens.border), boxShadow: [BoxShadow(color: color.withValues(alpha: .5), blurRadius: 10)]),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))));
}

class CountdownPill extends StatelessWidget {
  const CountdownPill({super.key, required this.remaining});
  final Duration remaining;
  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final t = '${two(remaining.inHours)}:${two(remaining.inMinutes % 60)}:${two(remaining.inSeconds % 60)}';
    return GlassPill(label: t, icon: Icons.hourglass_bottom_rounded, dense: true, accent: NTokens.coral);
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.balance, this.onTap});
  final String balance; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rPill, accent: NTokens.gold, onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CoinDot(size: 18), const SizedBox(width: 6),
        Text(balance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ]));
}

/// Original golden lotus coin, gradient-only (no artwork).
/// The app's own coin (assets/icons/nwsb-coin.webp via NwsbCoinDisc). No new coin art.
class CoinDot extends StatelessWidget {
  const CoinDot({super.key, this.size = 24});
  final double size;
  @override
  Widget build(BuildContext context) => NwsbCoinDisc(size: size);
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});
  final int count, index;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 18 : 6, height: 6,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),
                  color: Colors.white.withValues(alpha: i == index ? .95 : .35))),
      ]);
}
