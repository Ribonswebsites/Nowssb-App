/// Full control of one picture, set in the UI Editor and drawn the same in
/// the published app (override style keys):
///   imgZoom          zoom inside the frame, in and out (0.25–6; 1 = as laid out)
///   imgX, imgY       where the picture sits in the frame: a pan, in frame
///                    widths / heights (0 = centred) — what a drag sets
///   frameL/T/R/B     how far each edge of the frame moved out (+) or in
///                    (−), as a fraction of the picture's own size — what
///                    the side and corner handles set
/// The frame is painted over its neighbours (the page around it does not
/// move), and only what is inside the frame shows.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The picture framing saved in [look], or null when there is none.
ImageFraming? framingOf(Map<String, dynamic> look) {
  double n(String k, double d) => look[k] is num ? (look[k] as num).toDouble() : d;
  final f = ImageFraming(
    zoom: n('imgZoom', 1).clamp(ImageFraming.kMinZoom, ImageFraming.kMaxZoom),
    x: n('imgX', 0).clamp(-2.0, 2.0),
    y: n('imgY', 0).clamp(-2.0, 2.0),
    left: n('frameL', 0).clamp(-0.9, 4.0),
    top: n('frameT', 0).clamp(-0.9, 4.0),
    right: n('frameR', 0).clamp(-0.9, 4.0),
    bottom: n('frameB', 0).clamp(-0.9, 4.0),
  );
  return f.isIdentity ? null : f;
}

class ImageFraming {
  const ImageFraming({
    this.zoom = 1,
    this.x = 0,
    this.y = 0,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  static const kMinZoom = 0.25;
  static const kMaxZoom = 6.0;

  final double zoom, x, y, left, top, right, bottom;

  bool get isIdentity =>
      (zoom - 1).abs() < 0.005 &&
      x.abs() < 0.001 &&
      y.abs() < 0.001 &&
      left.abs() < 0.001 &&
      top.abs() < 0.001 &&
      right.abs() < 0.001 &&
      bottom.abs() < 0.001;

  /// The frame, in the picture's own box of [base] size.
  Rect frameIn(Size base) => Rect.fromLTRB(
        0.0 - left * base.width,
        0.0 - top * base.height,
        base.width * (1 + right),
        base.height * (1 + bottom),
      );

  @override
  bool operator ==(Object other) =>
      other is ImageFraming &&
      other.zoom == zoom &&
      other.x == x &&
      other.y == y &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(zoom, x, y, left, top, right, bottom);
}

/// Draws [child] framed by [framing]. Takes the same room as [child].
class ImageFrame extends SingleChildRenderObjectWidget {
  const ImageFrame({super.key, required this.framing, required super.child});
  final ImageFraming framing;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderImageFrame(framing);

  @override
  void updateRenderObject(BuildContext context, RenderImageFrame renderObject) => renderObject.framing = framing;
}

class RenderImageFrame extends RenderProxyBox {
  RenderImageFrame(this._f);

  ImageFraming _f;
  ImageFraming get framing => _f;
  set framing(ImageFraming v) {
    if (v == _f) return;
    _f = v;
    markNeedsLayout();
  }

  /// The frame in this box's coordinates.
  Rect frame = Rect.zero;

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    // Its own size first (as laid out without framing)…
    c.layout(constraints, parentUsesSize: true);
    size = c.size;
    frame = _f.frameIn(size);
    // …then the picture fills the frame.
    final fs = Size(frame.width.clamp(1.0, 100000.0), frame.height.clamp(1.0, 100000.0));
    if ((fs.width - size.width).abs() > 0.01 || (fs.height - size.height).abs() > 0.01) {
      c.layout(BoxConstraints.tight(fs), parentUsesSize: true);
    }
  }

  Matrix4 get _m {
    final c = child!;
    final w = c.size.width, h = c.size.height;
    return Matrix4.identity()
      ..translateByDouble(frame.left + w / 2 + _f.x * w, frame.top + h / 2 + _f.y * h, 0, 1)
      ..scaleByDouble(_f.zoom, _f.zoom, 1, 1)
      ..translateByDouble(-w / 2, -h / 2, 0, 1);
  }

  @override
  bool get alwaysNeedsCompositing => false;

  final _clip = LayerHandle<ClipRectLayer>();
  final _transform = LayerHandle<TransformLayer>();

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    _clip.layer = context.pushClipRect(needsCompositing, offset, frame, (ctx, o) {
      _transform.layer = ctx.pushTransform(needsCompositing, o, _m, (ctx2, o2) => ctx2.paintChild(c, o2),
          oldLayer: _transform.layer);
    }, oldLayer: _clip.layer);
  }

  @override
  void dispose() {
    _clip.layer = null;
    _transform.layer = null;
    super.dispose();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!frame.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    return result.addWithPaintTransform(
      transform: _m,
      position: position,
      hitTest: (r, p) => c.hitTest(r, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_m);

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => frame;

  @override
  Rect get paintBounds => frame.expandToInclude(Offset.zero & size);
}
