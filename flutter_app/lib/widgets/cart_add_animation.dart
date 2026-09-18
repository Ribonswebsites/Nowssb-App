import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../data/cart_bag.dart';
import '../theme/tokens.dart';

/// Recreates the reference micro-interaction: the product pops out of the
/// pressed button, the cart rolls in to catch it, then exits toward the cart
/// chip. It is an overlay so the product page does not re-layout during flight.
class CartAddAnimation {
  CartAddAnimation._();

  static Future<void> addAndPlay(
    BuildContext context, {
    required BagItem item,
    GlobalKey? targetKey,
  }) async {
    await CartBag.instance.addCart(item);
    play(context, fromContext: context, targetKey: targetKey, item: item);
    await Future<void>.delayed(const Duration(milliseconds: 960));
  }

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
    final target = targetKey == null
        ? _fallbackTarget(context)
        : _rectFor(targetKey);
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
    duration: const Duration(milliseconds: 920),
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
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final itemT = Curves.easeOutBack.transform(
            (_controller.value / .58).clamp(0.0, 1.0).toDouble(),
          );
          final cartT = Curves.easeInOutCubic.transform(
            ((_controller.value - .18) / .62).clamp(0.0, 1.0).toDouble(),
          );
          final itemCenter = Offset.lerp(
            widget.from.center,
            widget.target.center,
            t,
          )!;
          final cartStart = Offset(
            widget.from.center.dx - 70,
            widget.from.center.dy + 8,
          );
          final cartEnd = Offset(
            widget.target.center.dx,
            widget.target.center.dy,
          );
          final cartCenter = Offset.lerp(cartStart, cartEnd, cartT)!;
          final itemOpacity = _controller.value < .72
              ? 1.0
              : (1 - ((_controller.value - .72) / .28))
                  .clamp(0.0, 1.0)
                  .toDouble();
          final cartOpacity =
              (_controller.value / .12).clamp(0.0, 1.0).toDouble();
          final itemSize = math.max(26.0, math.min(widget.from.width, 72.0));
          return Stack(
            children: [
              Positioned(
                left: itemCenter.dx - itemSize / 2,
                top: itemCenter.dy - itemSize / 2 - (1 - itemT) * 18,
                child: Opacity(
                  opacity: itemOpacity,
                  child: Transform.scale(
                    scale: .58 + itemT * .42,
                    child: _FlyingItem(item: widget.item, size: itemSize),
                  ),
                ),
              ),
              Positioned(
                left: cartCenter.dx - 27,
                top: cartCenter.dy - 21,
                child: Opacity(
                  opacity: cartOpacity,
                  child: Transform.rotate(
                    angle: (1 - cartT) * -.12 + cartT * .16,
                    child: _RollingCart(size: 54),
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
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: NwsbColors.deep,
                  ),
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
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0xB3000000), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: Icon(Icons.shopping_cart_rounded, color: NwsbColors.ink, size: 25),
    );
  }
}
