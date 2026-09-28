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
import '../admin/layout/scopes.dart';
import '../admin/template/editable.dart';
import '../admin/template/slot_keys.dart';
import '../admin/template/ui_overrides.dart';

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
    this.slot,
  });

  /// Pins this loader's orb choice (UI Editor → Animation → Thinking orb)
  /// to a name. Without one, the section it sits in is used, then the
  /// app-wide choice (`orb.all`).
  final String? slot;

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
    UiScope.watch(context);
    final section = SectionScope.maybeOf(context);
    final key = widget.slot ??
        (section != null ? 'orb.${section.pageId}.${section.sectionId}' : 'orb.all');
    slotSeen(context, key, SlotType.orb, _state.name);
    var look = effectiveOverride(context, key)?.style;
    if ((look == null || look.isEmpty) && key != 'orb.all') {
      look = effectiveOverride(context, 'orb.all')?.style;
    }
    look ??= const {};
    var state = _state;
    final pick = look['orb'];
    if (pick is String) {
      for (final s in OrbState.values) {
        if (s.name == pick) state = s;
      }
    }
    final size = look['orbSize'] is num ? (look['orbSize'] as num).toDouble() : widget.size;
    final blackCircle = look['orbCircle'] is bool ? look['orbCircle'] as bool : widget.blackCircle;

    final orb = ThinkingOrb(
      state: state,
      size: size,
      theme: widget.theme,
    );

    final Widget orbWidget;
    if (blackCircle) {
      final circle = size + widget.circlePad * 2;
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

    final text = EditableLabel('app_thinking_loader.AppThinkingLoader', label, style: style, textAlign: TextAlign.center);

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
