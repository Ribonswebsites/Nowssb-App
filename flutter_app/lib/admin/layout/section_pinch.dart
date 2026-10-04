/// Pinch a section while edit mode is on. The whole section — layout, pictures
/// and clips — scales together, and the size is saved for every phone.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../admin_state.dart';
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
    final edit = EditMode.instance.on;
    if (!edit && (z - 1).abs() < 0.015) return child;
    if (!edit) return SectionZoom(scale: z, child: child);
    return _PinchSurface(pageId: pageId, sectionId: sectionId, scale: z, child: child);
  }
}

class _PinchSurface extends StatefulWidget {
  const _PinchSurface({
    required this.pageId,
    required this.sectionId,
    required this.scale,
    required this.child,
  });

  final String pageId;
  final String sectionId;
  final double scale;
  final Widget child;

  @override
  State<_PinchSurface> createState() => _PinchSurfaceState();
}

class _PinchSurfaceState extends State<_PinchSurface> {
  final Map<int, Offset> _pts = {};
  double? _startDist;
  double _startScale = 1;
  late double _scale = widget.scale;
  ScrollHoldController? _hold;
  var _pinching = false;

  @override
  void didUpdateWidget(_PinchSurface old) {
    super.didUpdateWidget(old);
    if (!_pinching && (widget.scale - _scale).abs() > 0.001) {
      _scale = widget.scale;
    }
  }

  double? _dist() {
    if (_pts.length < 2) return null;
    final a = _pts.values.elementAt(0);
    final b = _pts.values.elementAt(1);
    return (a - b).distance;
  }

  void _down(PointerDownEvent e) {
    _pts[e.pointer] = e.position;
    if (_pts.length == 2) {
      _startDist = _dist();
      _startScale = _scale;
      _pinching = true;
      final scroll = Scrollable.maybeOf(context);
      _hold ??= scroll?.position.hold(() {});
      setState(() {});
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pts.containsKey(e.pointer)) return;
    _pts[e.pointer] = e.position;
    final start = _startDist;
    final now = _dist();
    if (start == null || now == null || start < 12) return;
    final next = (_startScale * now / start).clamp(0.55, 1.85);
    if ((next - _scale).abs() < 0.004) return;
    setState(() => _scale = next);
  }

  void _up(PointerEvent e) {
    _pts.remove(e.pointer);
    if (_pts.length >= 2) return;
    _startDist = null;
    _hold?.cancel();
    _hold = null;
    final was = _pinching;
    if (was) {
      // Save before clearing the pinch flag, so a rebuild from the save
      // does not snap the scale back to the old value.
      UiOverrides.instance.setSectionZoom(widget.pageId, widget.sectionId, _scale);
    }
    _pinching = false;
    if (was && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SectionZoom(scale: _scale, child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _pinching ? const Color(0xFFE8D5A3) : const Color(0x55E8D5A3),
                  ),
                ),
              ),
            ),
          ),
          if (_pinching)
            Positioned(
              top: 6,
              right: 6,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE0060C18),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFE8D5A3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text(
                      '${_scale.toStringAsFixed(2)}×',
                      style: const TextStyle(
                        color: Color(0xFFE8D5A3),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) return;
    final dx = (size.width - c.size.width * _scale) / 2;
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (ctx, off) {
        ctx.pushTransform(
          needsCompositing,
          off + Offset(dx, 0),
          Matrix4.diagonal3Values(_scale, _scale, 1),
          (c2, o2) => c2.paintChild(c, o2),
        );
      },
    );
  }
}
