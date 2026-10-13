/// Page-local GlassWrapper (spec 0.5) for the Store rebuild.
///
/// Swap for Bug Hunter's shared `GlassWrapper` once the kit lands on main;
/// the parameters match the spec so the swap is mechanical.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Spec 0.5 radius presets.
class StoreRadius {
  StoreRadius._();
  static const hero = 30.0;
  static const card = 22.0;
  static const row = 16.0;
  static const pill = 999.0;
}

/// Store palette (spec 20.6 fixed colour meanings).
class StorePalette {
  StorePalette._();
  static const bgTop = Color(0xFF1B1238);
  static const bgBottom = Color(0xFF0B0820);
  static const violet = Color(0xFF9B7BFF);
  static const lilac = Color(0xFFC9B8FF);
  static const coinGold = Color(0xFFE8C46A);
  static const teal = Color(0xFF5ED6C4);
  static const pink = Color(0xFFFF8FC7);
  static const text = Color(0xFFFFFFFF);
  static const textSoft = Color(0xD9FFFFFF);
}

class StoreGlass extends StatefulWidget {
  const StoreGlass({
    super.key,
    required this.child,
    this.radius = StoreRadius.card,
    this.accent = StorePalette.violet,
    this.blur = 0,
    this.padding = const EdgeInsets.all(14),
    this.elevation = 0.5,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final double radius;
  final Color accent;

  /// 0 = lite mode (no BackdropFilter). Use blur only on large surfaces.
  final double blur;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<StoreGlass> createState() => _StoreGlassState();
}

class _StoreGlassState extends State<StoreGlass> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);
    final lite = widget.blur <= 0;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.white, widget.accent, .25)!.withValues(alpha: lite ? .26 : .22),
            Colors.white.withValues(alpha: lite ? .09 : .06),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .27)),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: .28 * widget.elevation),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        // inner top highlight
        Positioned(
          left: 12, right: 12, top: 0, height: 1,
          child: ColoredBox(color: Colors.white.withValues(alpha: .45)),
        ),
        Padding(padding: widget.padding, child: widget.child),
      ]),
    );
    if (!lite) {
      body = RepaintBoundary(
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
            child: body,
          ),
        ),
      );
    }
    if (widget.onTap == null) return body;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 110),
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: body),
        ),
      ),
    );
  }
}
