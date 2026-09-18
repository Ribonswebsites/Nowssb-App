import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/cart_bag.dart';
import '../theme/tokens.dart';
import 'nwsb_icon.dart';

/// Recreates the reference micro-interaction: the product pops out of the
/// pressed button, the cart rolls in to catch it, then exits toward the cart
/// chip. It is an overlay so the product page does not re-layout during flight.
class CartAddAnimation {
  CartAddAnimation._();
  static bool _busy = false;

  /// Adds once, animates in the root overlay, and completes after the flight.
  static Future<void> playForContext(
    BuildContext context, {
    required BagItem item,
    GlobalKey? pressedKey,
    BuildContext? pressedContext,
    GlobalKey? cartTargetKey,
    VoidCallback? onComplete,
    bool openCartAfter = false,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      await CartBag.instance.addCart(item);
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        onComplete?.call();
        return;
      }
      play(
        context,
        fromKey: pressedKey,
        fromContext: pressedContext ?? context,
        targetKey: cartTargetKey,
        item: item,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1080));
      onComplete?.call();
    } finally {
      _busy = false;
    }
  }

  @Deprecated('Use playForContext')
  static Future<void> addAndPlay(
    BuildContext context, {
    required BagItem item,
    GlobalKey? fromKey,
    BuildContext? fromContext,
    GlobalKey? targetKey,
  }) =>
      playForContext(
        context,
        item: item,
        pressedKey: fromKey,
        pressedContext: fromContext,
        cartTargetKey: targetKey,
      );

  static void play(
    BuildContext context, {
    GlobalKey? fromKey,
    BuildContext? fromContext,
    GlobalKey? targetKey,
    required BagItem item,
  }) {
    final from = fromKey == null
        ? _rectForContext(fromContext ?? context)
        : _rectFor(fromKey);
    final target =
        targetKey == null ? _fallbackTarget(context) : _rectFor(targetKey);
    if (from == null || target == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CartFlight(
        from: from,
        target: target,
        item: item,
        onFinished: entry.remove,
      ),
    );
    overlay.insert(entry);
  }

  static Rect? _rectFor(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    final origin = render.localToGlobal(Offset.zero);
    return origin & render.size;
  }

  static Rect? _rectForContext(BuildContext context) {
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    return render.localToGlobal(Offset.zero) & render.size;
  }

  static Rect _fallbackTarget(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width - 38, MediaQuery.paddingOf(context).top + 34),
      width: 44,
      height: 44,
    );
  }
}

class _CartFlight extends StatefulWidget {
  const _CartFlight({
    required this.from,
    required this.target,
    required this.item,
    required this.onFinished,
  });

  final Rect from;
  final Rect target;
  final BagItem item;
  final VoidCallback onFinished;

  @override
  State<_CartFlight> createState() => _CartFlightState();
}

class _CartFlightState extends State<_CartFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1040),
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final value = _controller.value;
          final itemSize =
              math.max(28.0, math.min(widget.from.width * .72, 68.0));
          final button = widget.from.center;
          final target = widget.target.center;
          final catchPoint = Offset(button.dx, button.dy);
          final itemPop = Curves.easeOutBack.transform(
            (value / .18).clamp(0.0, 1.0).toDouble(),
          );
          final itemCenter = value < .22
              ? button + Offset(0, -10 * itemPop)
              : Offset.lerp(
                  catchPoint,
                  target,
                  Curves.easeInOutCubic.transform(
                    ((value - .22) / .78).clamp(0.0, 1.0).toDouble(),
                  ))!;
          final itemScale = value < .18 ? itemPop : .92;
          final itemOpacity = value < .70
              ? 1.0
              : (1 - ((value - .70) / .18)).clamp(0.0, 1.0).toDouble();
          final cartIn = Curves.easeOutCubic.transform(
            ((value - .16) / .30).clamp(0.0, 1.0).toDouble(),
          );
          final cartOut = Curves.easeInCubic.transform(
            ((value - .52) / .48).clamp(0.0, 1.0).toDouble(),
          );
          final cartStart = Offset(button.dx + 110, button.dy);
          final cartCenter = value < .52
              ? Offset.lerp(cartStart, catchPoint, cartIn)!
              : Offset.lerp(catchPoint, target, cartOut)!;
          final cartOpacity = ((value - .08) / .12).clamp(0.0, 1.0).toDouble();
          final cartRotation =
              -math.pi * 2.0 * (value < .52 ? cartIn : 1 + cartOut);
          final cartScale = .76 + (value < .52 ? cartIn * .24 : .24);
          return Stack(
            children: [
              Positioned(
                left: itemCenter.dx - itemSize / 2,
                top: itemCenter.dy - itemSize / 2,
                child: Opacity(
                  opacity: itemOpacity,
                  child: Transform.scale(
                    scale: itemScale,
                    child: _FlyingItem(item: widget.item, size: itemSize),
                  ),
                ),
              ),
              Positioned(
                left: cartCenter.dx - 28,
                top: cartCenter.dy - 28,
                child: Transform.rotate(
                  angle: cartRotation,
                  child: Transform.scale(
                    scale: cartScale,
                    child: Opacity(
                      opacity: cartOpacity,
                      child: _RollingCart(size: 56),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FlyingItem extends StatelessWidget {
  const _FlyingItem({required this.item, required this.size});
  final BagItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NwsbColors.deep,
        borderRadius: BorderRadius.circular(size * .22),
        border: Border.all(color: NwsbColors.goldLight, width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .2),
        child: SizedBox(
          width: size,
          height: size,
          child: item.image.startsWith('assets/')
              ? Image.asset(item.image, fit: BoxFit.cover)
              : CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: NwsbColors.deep),
                ),
        ),
      ),
    );
  }
}

class _RollingCart extends StatelessWidget {
  const _RollingCart({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: NwsbColors.goldLight, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: const NwsbIcon(NwsbMarks.cart, size: 24, color: NwsbColors.ink),
    );
  }
}
