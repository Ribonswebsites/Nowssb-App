/// Shared thinking-orb loader for NowssB.
///
/// Picks one of [OrbState.composing], [OrbState.listening], or
/// [OrbState.solving] once per mount so the animation does not flicker.
/// Every orb sits inside a **larger black circle** for consistent placement
/// across hero chips, search fields, practice pills, and loaders.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

/// Alias kept for call sites that prefer the product name.
typedef NwsbThinkingOrb = AppThinkingLoader;

/// The only three states this app mounts for loading surfaces.
const List<OrbState> kNwsbThinkingOrbStates = <OrbState>[
  OrbState.composing,
  OrbState.listening,
  OrbState.solving,
];

class AppThinkingLoader extends StatefulWidget {
  const AppThinkingLoader({
    super.key,
    this.label,
    this.size = 72,
    this.state,
    this.theme = OrbTheme.auto,
    this.axis = Axis.vertical,
    this.labelStyle,
    this.blackCircle = true,
    this.circlePad = 7,
  });

  /// Optional plain text beside/below the orb (e.g. "Thinking…", "Preparing…").
  final String? label;

  /// Orb diameter. Prefer 28–36 inline, 72 for full-screen centers.
  final double size;

  /// Force one of the three allowed states. When null, one is chosen at random
  /// in [initState] and kept for the lifetime of this State.
  final OrbState? state;

  final OrbTheme theme;
  final Axis axis;
  final TextStyle? labelStyle;

  /// When true (default), the orb sits inside a larger black circle wrapper.
  final bool blackCircle;

  /// Extra radius beyond [size] on each side of the black circle.
  final double circlePad;

  @override
  State<AppThinkingLoader> createState() => _AppThinkingLoaderState();
}

class _AppThinkingLoaderState extends State<AppThinkingLoader> {
  late final OrbState _state;

  @override
  void initState() {
    super.initState();
    final forced = widget.state;
    if (forced != null) {
      assert(
        kNwsbThinkingOrbStates.contains(forced),
        'AppThinkingLoader only mounts composing / listening / solving',
      );
      _state = forced;
    } else {
      _state = kNwsbThinkingOrbStates[
          math.Random().nextInt(kNwsbThinkingOrbStates.length)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final orb = ThinkingOrb(
      state: _state,
      size: widget.size,
      theme: widget.theme,
    );

    final Widget orbWidget;
    if (widget.blackCircle) {
      final circle = widget.size + widget.circlePad * 2;
      orbWidget = Container(
        width: circle,
        height: circle,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: orb,
      );
    } else {
      orbWidget = orb;
    }

    final label = widget.label;
    if (label == null || label.isEmpty) return orbWidget;

    final brightness = Theme.of(context).brightness;
    final style = widget.labelStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.72),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ) ??
        TextStyle(
          color: brightness == Brightness.dark
              ? const Color(0xB8FFFFFF)
              : const Color(0xB8000000),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );

    final text = Text(label, style: style, textAlign: TextAlign.center);

    if (widget.axis == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          orbWidget,
          const SizedBox(width: 12),
          Flexible(child: text),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orbWidget,
        const SizedBox(height: 14),
        text,
      ],
    );
  }
}
