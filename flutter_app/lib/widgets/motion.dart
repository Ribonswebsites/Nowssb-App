/// Shared motion primitives for the Flutter app.
///
/// Motion is intentionally short and transform/opacity based so the UI feels
/// quick on Android while remaining calm enough for a daily practice app.
library;

import 'package:flutter/material.dart';

class NwsbMotion {
  NwsbMotion._();

  static const curve = Cubic(.16, 1, .3, 1);
  static const softCurve = Cubic(.22, 1, .36, 1);
  static const pageDuration = Duration(milliseconds: 300);
  static const tabDuration = Duration(milliseconds: 280);
}

class NwsbPageTransitionsBuilder extends PageTransitionsBuilder {
  const NwsbPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: NwsbMotion.curve,
      reverseCurve: NwsbMotion.softCurve,
    );
    final offset = Tween<Offset>(
      begin: const Offset(.035, 0),
      end: Offset.zero,
    ).animate(curved);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class NwsbScrollBehavior extends MaterialScrollBehavior {
  const NwsbScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class NwsbSmoothScrollPhysics extends BouncingScrollPhysics {
  const NwsbSmoothScrollPhysics({super.parent});

  @override
  NwsbSmoothScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      NwsbSmoothScrollPhysics(parent: buildParent(ancestor));
}

class NwsbTabMotion extends StatefulWidget {
  const NwsbTabMotion({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<NwsbTabMotion> createState() => _NwsbTabMotionState();
}

class _NwsbTabMotionState extends State<NwsbTabMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NwsbMotion.tabDuration,
    reverseDuration: const Duration(milliseconds: 220),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant NwsbTabMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled) return IgnorePointer(ignoring: !widget.active, child: widget.child);
    final curved = CurvedAnimation(parent: _controller, curve: NwsbMotion.curve);
    return IgnorePointer(
      ignoring: !widget.active,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.025, 0),
            end: Offset.zero,
          ).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

class NwsbMotionReveal extends StatefulWidget {
  const NwsbMotionReveal({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<NwsbMotionReveal> createState() => _NwsbMotionRevealState();
}

class _NwsbMotionRevealState extends State<NwsbMotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = 1;
        return;
      }
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: NwsbMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .018),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
