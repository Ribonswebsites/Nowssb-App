/// A section's saved zoom (an older per-section size), drawn for everyone.
/// Editing happens only in the admin UI Editor; there is no pinch surface
/// or chip on the user app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../admin_state.dart';
import '../section_editor/section_editor_shell.dart';
import '../template/ui_overrides.dart';

class SectionPinch extends StatelessWidget {
  const SectionPinch({
    super.key,
    required this.pageId,
    required this.sectionId,
    required this.child,
  });

  final String pageId;
  final String sectionId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context);
    final z = UiOverrides.instance.sectionZoomOf(pageId, sectionId);
    if ((z - 1).abs() < 0.015) return child;
    return SectionZoom(scale: z, child: child);
  }
}

/// Scales [child] uniformly and changes the space it takes, so the next
/// section moves with it instead of being covered.
class SectionZoom extends SingleChildRenderObjectWidget {
  const SectionZoom({super.key, required this.scale, required super.child});

  final double scale;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSectionZoom(scale);

  @override
  void updateRenderObject(BuildContext context, _RenderSectionZoom renderObject) {
    renderObject.scale = scale;
  }
}

class _RenderSectionZoom extends RenderProxyBox {
  _RenderSectionZoom(this._scale);

  double _scale;
  set scale(double v) {
    if ((v - _scale).abs() < 0.001) return;
    _scale = v;
    markNeedsLayout();
  }

  Matrix4 get _transform {
    final c = child;
    final dx = c == null ? 0.0 : (size.width - c.size.width * _scale) / 2;
    return Matrix4.identity()
      ..translate(dx, 0.0)
      ..scale(_scale, _scale, 1.0);
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    final h = c.size.height * _scale;
    size = constraints.constrain(Size(constraints.maxWidth, h));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) => c.hitTest(result, position: position),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (ctx, off) {
        ctx.pushTransform(
          needsCompositing,
          off,
          _transform,
          (c2, o2) => c2.paintChild(c, o2),
        );
      },
    );
  }
}

/// Draws [child] exactly [height] tall by scaling it uniformly, up as well
/// as down. A section pinched bigger than its natural height grows (the
/// sides that no longer fit are clipped, centred) instead of sitting on top
/// of blank space; pinched smaller, it shrinks as before.
///
/// [width] is used only when the parent gives no width (the child is laid
/// out at the screen width, like the page it came from).
class SectionFitHeight extends SingleChildRenderObjectWidget {
  const SectionFitHeight({super.key, required this.height, required this.width, this.align = 0, this.fraction, required super.child});

  /// Instead of [height]: this part of its own height (and width) — a
  /// banner or template pinched narrower than the page.
  final double? fraction;

  final double height;
  final double width;

  /// Made smaller, where it sits across its row: −1 left, 0 middle, 1 right.
  final double align;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSectionFitHeight(height, width, align, fraction);

  @override
  void updateRenderObject(BuildContext context, RenderSectionFitHeight renderObject) {
    renderObject
      ..height = height
      ..width = width
      ..align = align
      ..fraction = fraction;
  }
}

class RenderSectionFitHeight extends RenderProxyBox {
  RenderSectionFitHeight(this._height, this._width, [this._align = 0, this._fraction]);

  double? _fraction;
  set fraction(double? v) {
    if (v == _fraction) return;
    _fraction = v;
    markNeedsLayout();
  }

  double _align;
  set align(double v) {
    if (v == _align) return;
    _align = v;
    markNeedsPaint();
  }

  /// Where the section itself is drawn in this row's box.
  Rect get contentRect {
    final c = child;
    if (c == null || !c.hasSize) return Offset.zero & size;
    return Rect.fromLTWH(_left, 0, _childW * _scale, c.size.height * _scale);
  }

  double get _left => (size.width - _childW * _scale) * (_scale < 1 ? (_align + 1) / 2 : 0.5);

  double _height;
  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  double _width;
  set width(double v) {
    if (v == _width) return;
    _width = v;
    markNeedsLayout();
  }

  double _scale = 1;

  /// How much the child is scaled to fill [height] (1 = natural size).
  double get scale => _scale;

  double _childW = 0;

  Matrix4 get _transform {
    return Matrix4.identity()
      ..translateByDouble(_left, 0, 0, 1)
      ..scaleByDouble(_scale, _scale, 1, 1);
  }

  @override
  void performLayout() {
    final c = child;
    final w = constraints.hasBoundedWidth ? constraints.maxWidth : _width;
    if (c == null) {
      size = constraints.constrain(Size(w, _height));
      return;
    }
    c.layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
    _childW = c.size.width;
    final f = _fraction;
    final screen = _width > 1 ? _width : w;
    final cell = f == null ? w : screen * f;
    // Already given its share of the row: scale from the full page width
    // into that share, instead of scaling a second time.
    final packed = f != null && (w - cell).abs() < 28;
    if (packed) {
      // Share the row at this width. Reflow into the cell — do not scale,
      // or the picture zooms just because something sits beside it.
      c.layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
      _childW = c.size.width;
      _scale = 1;
      size = constraints.constrain(Size(w, c.size.height));
      return;
    }
    size = constraints.constrain(Size(w, f == null ? _height : c.size.height * f));
    final ch = c.size.height;
    _scale = ch > 0 ? size.height / ch : 1;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) => c.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    void inner(PaintingContext ctx, Offset off) =>
        ctx.pushTransform(needsCompositing, off, _transform, (c2, o2) => c2.paintChild(c, o2));
    if (_scale > 1.0005) {
      // Scaled up: the sides spill past the screen; keep them off the
      // neighbours' margins.
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, inner);
    } else {
      inner(context, offset);
    }
  }
}

/// Shows the top [height] of [child] and clips the rest. The child is not
/// scaled, so a taller window reveals more of the video and a shorter one
/// crops it. The video's own size stays put.
class SectionWindow extends SingleChildRenderObjectWidget {
  const SectionWindow({super.key, required this.height, required super.child});
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSectionWindow(height);

  @override
  void updateRenderObject(BuildContext context, RenderSectionWindow renderObject) {
    renderObject.height = height;
  }
}

class RenderSectionWindow extends RenderProxyBox {
  RenderSectionWindow(this._height);
  double _height;
  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    final w = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
    if (c == null) {
      size = constraints.constrain(Size(w, _height));
      return;
    }
    c.layout(BoxConstraints(minWidth: w, maxWidth: w), parentUsesSize: true);
    size = constraints.constrain(Size(w, _height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    context.pushClipRect(needsCompositing, offset, Offset.zero & size, (ctx, off) {
      ctx.paintChild(c, off);
    });
  }
}
