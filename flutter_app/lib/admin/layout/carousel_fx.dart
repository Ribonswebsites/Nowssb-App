/// Page-turn transitions for sideways carousels, chosen per section in the
/// UI Editor's Animation tab.
///
/// In a PageView.builder's itemBuilder:
///   itemBuilder: (context, i) => carouselFxItem(context, _controller, i, card),
/// With no transition chosen it returns [child] itself (pixel-identical).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'layout_sections.dart';

/// id → plain-words name, in the order the Animation tab shows them.
const kCarouselTransitions = <String, String>{
  '': 'As designed',
  'slide': 'Slide',
  'fade': 'Fade',
  'depth': 'Scale / depth',
  'coverflow': '3D carousel',
  'cube': 'Cube',
  'stack': 'Stack',
  'parallax': 'Parallax',
  'flip': 'Flip',
};

Widget carouselFxItem(BuildContext context, PageController controller, int index, Widget child) {
  final fx = SectionCarouselScope.of(context)?.transition ?? '';
  if (fx.isEmpty || fx == 'slide') return child;
  return AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) {
      double page = index.toDouble();
      if (controller.hasClients && controller.position.haveDimensions) {
        page = controller.page ?? index.toDouble();
      } else {
        page = controller.initialPage.toDouble();
      }
      return carouselFxFrame(fx, index - page, child!);
    },
  );
}

/// One card of transition [fx] at offset [d] from the centre (−1 left, 0
/// centred, 1 right). Shared with the editor's live thumbnails.
Widget carouselFxFrame(String fx, double d, Widget child) {
  final a = d.abs().clamp(0.0, 1.0);
  switch (fx) {
    case 'fade':
      return Opacity(opacity: (1 - a).clamp(0.0, 1.0), child: child);
    case 'depth':
      return Transform.scale(scale: 1 - 0.18 * a, child: Opacity(opacity: 1 - 0.4 * a, child: child));
    case 'coverflow':
      return Transform(
        alignment: d < 0 ? Alignment.centerRight : Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(-d.clamp(-1.0, 1.0) * 0.75)
          ..scaleByDouble(1 - 0.12 * a, 1 - 0.12 * a, 1, 1),
        child: child,
      );
    case 'cube':
      return Transform(
        alignment: d < 0 ? Alignment.centerRight : Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(-d.clamp(-1.0, 1.0) * math.pi / 2),
        child: child,
      );
    case 'stack':
      if (d <= 0) return child;
      return Transform.translate(
        offset: Offset(-d * 240 * 0.85, 0),
        child: Transform.scale(scale: 1 - 0.1 * a, child: Opacity(opacity: 1 - 0.3 * a, child: child)),
      );
    case 'parallax':
      return ClipRect(
        child: Transform.translate(offset: Offset(d * 80, 0), child: child),
      );
    case 'flip':
      if (a > 0.5) return const SizedBox.shrink();
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateY(d.clamp(-1.0, 1.0) * math.pi),
        child: child,
      );
  }
  return child;
}

/// [carouselFxItem] for a `PageView(children: …)`. Returns [children]
/// itself when no transition is chosen.
List<Widget> carouselFxChildren(BuildContext context, PageController controller, List<Widget> children) {
  final fx = SectionCarouselScope.of(context)?.transition ?? '';
  if (fx.isEmpty || fx == 'slide') return children;
  return [for (var i = 0; i < children.length; i++) carouselFxItem(context, controller, i, children[i])];
}
