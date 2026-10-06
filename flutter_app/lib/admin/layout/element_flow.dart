/// How a moved or resized element takes up room (template/editable.dart
/// `elementPlacement`): a pinch to [scale] and a vertical move of [dy]
/// change the space it holds, so the content under it reflows instead of
/// being painted over. Its width stays (the row or column around it keeps
/// its shape); the bigger element is centred on it. Where the parent fixes
/// the height, it keeps that height and simply paints larger.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ElementFlow extends SingleChildRenderObjectWidget {
  const ElementFlow({super.key, required this.scale, required this.dy, super.child});
  final double scale;
  final double dy;

  @override
  RenderElementFlow createRenderObject(BuildContext context) => RenderElementFlow(scale, dy);

  @override
  void updateRenderObject(BuildContext context, RenderElementFlow renderObject) => renderObject
    ..scale = scale
    ..dy = dy;
}

class RenderElementFlow extends RenderProxyBox {
  RenderElementFlow(this._scale, this._dy);

  double _scale;
  double get scale => _scale;
  set scale(double v) {
    if (v == _scale) return;
    _scale = v;
    markNeedsLayout();
  }

  double _dy;
  double get dy => _dy;
  set dy(double v) {
    if (v == _dy) return;
    _dy = v;
    markNeedsLayout();
  }

  Offset _offset = Offset.zero;

  Size _sizeFor(BoxConstraints c, Size child) =>
      c.constrain(Size(child.width, math.max(0, child.height * _scale + _dy)));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    return _sizeFor(constraints, c.getDryLayout(constraints));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    size = _sizeFor(constraints, c.size);
    final wantH = math.max(0.0, c.size.height * _scale + _dy);
    _offset = Offset((size.width - c.size.width * _scale) / 2, _dy + (size.height - wantH) / 2);
  }

  Matrix4 get _transform => Matrix4.identity()
    ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
    ..scaleByDouble(_scale, _scale, 1, 1);

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    layer = context.pushTransform(needsCompositing, offset, _transform, (ctx, o) => ctx.paintChild(c, o),
        oldLayer: layer is TransformLayer ? layer as TransformLayer : null);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, p) => c.hitTest(result, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);
}
