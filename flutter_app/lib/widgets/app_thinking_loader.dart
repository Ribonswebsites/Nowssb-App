/// Shared thinking-orb loader for NowssB.
///
/// When a per-slot (or app-wide `orb.all`) choice is saved server-side in
/// `ui_overrides`, that animation plays for every user — no random pick.
/// Random is used only while the slot (and `orb.all`) are still unset.
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

/// Fallback pool while no server choice is set for the slot / `orb.all`.
const List<OrbState> kNwsbThinkingOrbStates = <OrbState>[
  OrbState.composing,
  OrbState.listening,
  OrbState.solving,
];

/// Resolve a saved OrbState name from [style], or null if unset / unknown.
OrbState? orbStateFromStyle(Map<String, dynamic>? style) {
  final pick = style == null ? null : style['orb'];
  if (pick is! String || pick.isEmpty || pick == 'random') return null;
  for (final s in OrbState.values) {
    if (s.name == pick) return s;
  }
  return null;
}

/// The effective server choice for a loader slot: slot → `orb.all` → null.
OrbState? resolvedOrbChoice(String key) {
  final local = orbStateFromStyle(UiOverrides.instance.get(key)?.style);
  if (local != null) return local;
  if (key != 'orb.all') {
    return orbStateFromStyle(UiOverrides.instance.get('orb.all')?.style);
  }
  return null;
}

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

  /// Force one OrbState. When null, the server choice for [slot] / `orb.all`
  /// is used; only if that is also unset does the loader pick at random once
  /// per mount from [kNwsbThinkingOrbStates].
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
  /// Random fallback kept for the lifetime of this State when no server
  /// choice (and no [widget.state]) is set. Cleared conceptually once a
  /// choice appears — build always prefers the server pick.
  OrbState? _randomFallback;

  OrbState _fallbackRandom() {
    return kNwsbThinkingOrbStates[
        math.Random().nextInt(kNwsbThinkingOrbStates.length)];
  }

  @override
  void initState() {
    super.initState();
    // Prefer an already-cached server choice so the first frame is stable.
    if (widget.state == null) {
      final key = widget.slot ?? 'orb.all';
      if (resolvedOrbChoice(key) == null) {
        _randomFallback = _fallbackRandom();
      }
    }
  }

  String _slotKey(BuildContext context) {
    final section = SectionScope.maybeOf(context);
    return widget.slot ??
        (section != null ? 'orb.${section.pageId}.${section.sectionId}' : 'orb.all');
  }

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final key = _slotKey(context);
    final forced = widget.state;
    final saved = resolvedOrbChoice(key);
    // Once a server choice exists, never use random for this mount.
    final OrbState state;
    if (forced != null) {
      state = forced;
    } else if (saved != null) {
      state = saved;
      _randomFallback = null;
    } else {
      _randomFallback ??= _fallbackRandom();
      state = _randomFallback!;
    }

    slotSeen(context, key, SlotType.orb, state.name);
    var look = effectiveOverride(context, key)?.style;
    if ((look == null || look.isEmpty) && key != 'orb.all') {
      look = effectiveOverride(context, 'orb.all')?.style;
    }
    look ??= const {};

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
