/// UD-0: shared frosted-glass frame around a near-black card.
///
/// Brief 2026-10-12: "glassmorphism wrappers around black cards". Colours are
/// reused from [GlassWrap] (fill / line / blur) and [NwsbColors.plate]
/// (near-black inner card); nothing new is introduced.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/ui_tokens.dart';
import 'glass_wrap.dart';

export '../theme/ui_tokens.dart';

class GlassBlackCard extends StatelessWidget {
  const GlassBlackCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(UiSpace.lg),
    this.radius = UiRadii.card,
    this.title,
    this.header,
    this.onTap,
    this.intensity = defaultIntensity,
    this.frame = UiSpace.sm,
  });

  static const double defaultIntensity = 0.6;

  final Widget child;

  /// Padding inside the black card.
  final EdgeInsetsGeometry padding;

  /// Outer (glass) radius; the inner card follows it minus [frame].
  final double radius;

  /// Optional section header text (uses [UiType.sectionHeader]).
  final String? title;

  /// Optional custom header widget; wins over [title].
  final Widget? header;

  final VoidCallback? onTap;

  /// 0..1 — scales blur, glass fill and the edge highlight.
  final double intensity;

  /// Width of the glass rim between the outer edge and the black card.
  final double frame;

  @override
  Widget build(BuildContext context) {
    final k = intensity.clamp(0.0, 1.0);
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular((radius - frame).clamp(0, radius));
    final sigma = GlassWrap.blurSigma * (0.5 + k);
    final head = header ??
        (title == null || title!.trim().isEmpty
            ? null
            : Text(title!, style: UiType.sectionHeader));

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: NwsbColors.plate,
        borderRadius: inner,
        border: Border.all(color: GlassWrap.line.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: padding,
        child: head == null
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [head, const SizedBox(height: UiSpace.md), child],
              ),
      ),
    );
    if (onTap != null) {
      card = Material(
        type: MaterialType.transparency,
        child: InkWell(borderRadius: inner, onTap: onTap, child: card),
      );
    }

    return ClipRRect(
      borderRadius: outer,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: outer,
            // Soft top-left edge highlight fading into the glass fill.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GlassWrap.line.withValues(alpha: 0.10 + 0.12 * k),
                GlassWrap.fill.withValues(alpha: 0.03 + 0.05 * k),
                GlassWrap.fill.withValues(alpha: 0.02 + 0.03 * k),
              ],
              stops: const [0, 0.35, 1],
            ),
            border: Border.all(
              color: GlassWrap.line.withValues(alpha: 0.08 + 0.10 * k),
            ),
          ),
          child: Padding(padding: EdgeInsets.all(frame), child: card),
        ),
      ),
    );
  }
}
