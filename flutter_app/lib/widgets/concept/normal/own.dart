/// Everything You Own — "The shelf": one long shelf with three bays. Each
/// bay stands up the real product thumbnails you hold there (fanned like
/// books), and the live count under it is the hero. No icon tiles.
///
/// Data (runtime, never invented):
/// * [cartThumbs] / [cartCount] — `CartBag.instance` cart lines (`BagItem.image`).
/// * [wishlistThumbs] / [wishlistCount] — the wishlist's saved items' images.
/// * [orderThumbs] / [orderCount] — `BagOrder` items' images and order count.
/// A null count shows "—"; an empty bay shows a dashed outline.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NOwn extends StatefulWidget {
  const NOwn({super.key, required this.onCart, required this.onWishlist, required this.onOrders,
      this.cartCount, this.wishlistCount, this.orderCount,
      this.cartThumbs = const [], this.wishlistThumbs = const [], this.orderThumbs = const []});
  final VoidCallback onCart, onWishlist, onOrders;
  final int? cartCount, wishlistCount, orderCount;
  final List<ImageProvider> cartThumbs, wishlistThumbs, orderThumbs;
  @override
  State<NOwn> createState() => _NOwnState();
}

class _NOwnState extends State<NOwn> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(seconds: 5);
  @override
  Widget build(BuildContext context) {
    final bays = [
      (widget.cartCount == 1 ? 'item' : 'items', 'Cart', widget.cartCount, widget.cartThumbs, widget.onCart),
      ('saved', 'Wishlist', widget.wishlistCount, widget.wishlistThumbs, widget.onWishlist),
      ('placed', widget.orderCount == 1 ? 'Order' : 'Orders', widget.orderCount, widget.orderThumbs, widget.onOrders),
    ];
    return Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Everything you own', style: nHello),
      const Text('On one shelf', style: nTitle),
      const SizedBox(height: 14),
      Container(decoration: neu(r: 26), padding: const EdgeInsets.fromLTRB(8, 16, 8, 14), child: Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(child: NPress(label: bays[i].$2, onTap: bays[i].$5, child: Column(children: [
            AnimatedBuilder(animation: loop, builder: (_, __) => _Bay(thumbs: bays[i].$4, t: (loop.value + i / 3) % 1)),
            // shelf board segment
            Container(height: 9, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFD3D8E3)]),
              boxShadow: const [BoxShadow(color: Color(0x338E97B5), offset: Offset(0, 4), blurRadius: 6)])),
            const SizedBox(height: 10),
            Text(bays[i].$3 == null ? '—' : '${bays[i].$3}', style: nTitle),
            Text(bays[i].$2, style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700)),
            Text(bays[i].$1, style: nSub),
          ]))),
      ])),
    ]));
  }
}

/// Up to three thumbnails fanned on the shelf; the front one sways a few
/// degrees (every bay the same size, nothing scales).
class _Bay extends StatelessWidget {
  const _Bay({required this.thumbs, required this.t});
  final List<ImageProvider> thumbs;
  final double t;
  @override
  Widget build(BuildContext context) {
    const w = 44.0, h = 60.0;
    final shown = thumbs.take(3).toList();
    final n = shown.length;
    return SizedBox(height: 72, child: Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
      if (shown.isEmpty)
        Container(width: w, height: h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB9BFCC), width: 1.4))),
      for (var i = n - 1; i >= 0; i--)
        Transform.translate(
          offset: Offset((i - (n - 1) / 2) * 13, 0),
          child: Transform.rotate(
            alignment: Alignment.bottomCenter,
            angle: (i - (n - 1) / 2) * .16 + (i == 0 ? math.sin(t * math.pi * 2) * .05 : 0),
            child: Container(width: w, height: h, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Color(0x408E97B5), offset: Offset(2, 3), blurRadius: 5)],
                image: DecorationImage(image: shown[i], fit: BoxFit.cover))))),
    ]));
  }
}
