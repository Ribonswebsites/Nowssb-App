/// Swipe-to-dismiss for pop-ups, toasts and banners: flick up, left or right
/// and it slides off in that direction with a light haptic — no waiting for
/// an auto-hide timer. A short drag springs back.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeAway extends StatefulWidget {
  const SwipeAway({
    super.key,
    required this.child,
    required this.onDismissed,
    this.onTap,
    this.up = true,
    this.sideways = true,
    this.distance = 28,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final HitTestBehavior behavior;

  final Widget child;
  final VoidCallback onDismissed;
  final VoidCallback? onTap;
  final bool up;
  final bool sideways;

  /// Drag (logical px) past which a release dismisses.
  final double distance;

  @override
  State<SwipeAway> createState() => _SwipeAwayState();
}

class _SwipeAwayState extends State<SwipeAway>
    with SingleTickerProviderStateMixin {
  late final AnimationController _out = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180));
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _gone = false;

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  Offset _clamp(Offset o) => Offset(
        widget.sideways ? o.dx : 0,
        widget.up ? math.min(0, o.dy) : 0,
      );

  void _update(DragUpdateDetails d) {
    if (_gone) return;
    setState(() => _drag = _clamp(_drag + d.delta));
  }

  Future<void> _end(DragEndDetails d) async {
    if (_gone) return;
    final v = _clamp(d.velocity.pixelsPerSecond);
    final far = _drag.distance >= widget.distance;
    final flick = v.distance >= 300;
    if (!far && !flick) {
      setState(() => _drag = Offset.zero);
      return;
    }
    _gone = true;
    final dir = (far ? _drag : v);
    final size = context.size ?? const Size(400, 100);
    final horizontal = dir.dx.abs() > dir.dy.abs();
    _from = _drag;
    _to = horizontal
        ? Offset(dir.dx.sign * (size.width + 40), _drag.dy)
        : Offset(_drag.dx, -(size.height + 80));
    HapticFeedback.lightImpact();
    await _out.forward(from: 0);
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onPanUpdate: _update,
      onPanEnd: _end,
      child: AnimatedBuilder(
        animation: _out,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_out.value);
          final off = _gone ? Offset.lerp(_from, _to, t)! : _drag;
          final fade =
              _gone ? 1 - t : (1 - _drag.distance / 400).clamp(0.4, 1.0);
          return Transform.translate(
              offset: off,
              child: Opacity(opacity: fade.toDouble(), child: child));
        },
        child: widget.child,
      ),
    );
  }
}
