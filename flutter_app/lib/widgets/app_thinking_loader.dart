/// Shared thinking-orb loader for NowssB.
///
/// Picks one of [OrbState.composing], [OrbState.listening], or
/// [OrbState.solving] once per mount so the animation does not flicker.
/// Use size 64 for full-screen centers and 20–24 for inline/button busy.
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
    this.size = 64,
    this.state,
    this.theme = OrbTheme.auto,
    this.axis = Axis.vertical,
    this.labelStyle,
  });

  /// Optional plain text beside/below the orb (e.g. "Thinking…", "Preparing…").
  final String? label;

  /// 64 for full-screen/center; 20–24 for inline buttons.
  final double size;

  /// Force one of the three allowed states. When null, one is chosen at random
  /// in [initState] and kept for the lifetime of this State.
  final OrbState? state;

  final OrbTheme theme;
  final Axis axis;
  final TextStyle? labelStyle;

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
    final label = widget.label;
    if (label == null || label.isEmpty) return orb;

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
          orb,
          const SizedBox(width: 12),
          Flexible(child: text),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orb,
        const SizedBox(height: 14),
        text,
      ],
    );
  }
}
