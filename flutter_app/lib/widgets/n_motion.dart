/// Shared motion for every pop-up in the user app: one spring-like enter,
/// a matching quicker exit, swipe-down to close on sheets, and no motion at
/// all when the phone asks for reduced motion.
///
/// Drop-in for showDialog / showModalBottomSheet with the arguments the app
/// actually uses.
library;

import 'package:flutter/material.dart';

class NMotion {
  static const enter = Duration(milliseconds: 260);
  static const exit = Duration(milliseconds: 200);
  static const enterCurve = Curves.easeOutBack;
  static const exitCurve = Curves.easeInCubic;

  static bool still(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static AnimationStyle sheetStyle(BuildContext context) => still(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: enter,
          reverseDuration: exit,
          curve: Curves.easeOutCubic,
          reverseCurve: exitCurve,
        );

  /// Pop-in used by dialogs and the notification panel: fade + small scale
  /// with a light overshoot. The child sits in a RepaintBoundary so only the
  /// transform animates, not the content.
  static Widget popIn(Animation<double> a, Widget child) {
    final spring = CurvedAnimation(parent: a, curve: enterCurve, reverseCurve: exitCurve);
    final fade = CurvedAnimation(parent: a, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(spring),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}

/// [showDialog] with the shared pop-in (about 260ms in, 200ms out).
Future<T?> showNDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final still = NMotion.still(context);
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? Colors.black54,
    transitionDuration: still ? Duration.zero : NMotion.enter,
    pageBuilder: (ctx, _, __) => themes.wrap(SafeArea(child: Builder(builder: builder))),
    transitionBuilder: (ctx, a, _, child) => NMotion.popIn(a, child),
  );
}

/// [showModalBottomSheet] with the shared spring timing. Swipe down closes
/// it (enableDrag), tap outside closes it.
Future<T?> showNSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isScrollControlled = false,
  ShapeBorder? shape,
  Color? barrierColor,
  bool? showDragHandle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => RepaintBoundary(child: builder(ctx)),
    backgroundColor: backgroundColor,
    isScrollControlled: isScrollControlled,
    shape: shape,
    barrierColor: barrierColor,
    showDragHandle: showDragHandle,
    enableDrag: true,
    sheetAnimationStyle: NMotion.sheetStyle(context),
  );
}

/// Horizontal rail physics that settles on a card edge after a fling, so a
/// rail of fixed-width cards snaps like a real app carousel.
class SnapRailPhysics extends ScrollPhysics {
  const SnapRailPhysics({required this.itemExtent, super.parent});

  /// Card width plus the gap between cards.
  final double itemExtent;

  @override
  SnapRailPhysics applyTo(ScrollPhysics? ancestor) =>
      SnapRailPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _target(ScrollMetrics p, Tolerance t, double v) {
    var page = p.pixels / itemExtent;
    if (v < -t.velocity) {
      page -= 0.5;
    } else if (v > t.velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * itemExtent)
        .clamp(p.minScrollExtent, p.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final t = toleranceFor(position);
    final target = _target(position, t, velocity);
    if ((target - position.pixels).abs() < t.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: t);
  }

  @override
  bool get allowImplicitScrolling => false;
}
