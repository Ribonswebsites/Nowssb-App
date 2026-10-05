/// Pinch a section while edit mode is on. One finger still scrolls the page.
/// Two fingers scale the whole section — layout, pictures and clips — and
/// the size is saved for every phone.
///
/// This is a [Listener], not a gesture recognizer. A scale recognizer joins
/// the arena on the first finger and the page stops moving.
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
  late double _scale = widget.scale;
  double _startScale = 1;
  double _startDist = 0;
  var _pinching = false;
  final Map<int, Offset> _pts = {};
  ScrollHoldController? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PinchSurface old) {
    super.didUpdateWidget(old);
    if (!_pinching && (widget.scale - _scale).abs() > 0.001) {
      _scale = widget.scale;
    }
  }

  void _down(PointerDownEvent e) {
    _pts[e.pointer] = e.position;
    if (_pts.length < 2 || _pinching) return;
    _startDist = 0;
    _startScale = _scale;
    _pinching = true;
    final scroll = Scrollable.maybeOf(context);
    _hold ??= scroll?.position.hold(() {});
    setState(() {});
  }

  void _move(PointerMoveEvent e) {
    if (!_pts.containsKey(e.pointer)) return;
    _pts[e.pointer] = e.position;
    if (!_pinching || _pts.length < 2) return;
    final d = _dist();
    if (d < 8) return;
    if (_startDist < 8) {
      _startDist = d;
      _startScale = _scale;
      return;
    }
    final next = (_startScale * d / _startDist).clamp(0.55, 1.85);
    if ((next - _scale).abs() < 0.004) return;
    setState(() => _scale = next);
  }

  void _up(PointerEvent e) {
    _pts.remove(e.pointer);
    if (_pts.length >= 2 || !_pinching) return;
    // Save before clearing the flag, so a rebuild does not snap back.
    UiOverrides.instance.setSectionZoom(widget.pageId, widget.sectionId, _scale);
    _pinching = false;
    _startDist = 0;
    _hold?.cancel();
    _hold = null;
    if (mounted) setState(() {});
  }

  double _dist() {
    final a = _pts.values.toList();
    if (a.length < 2) return 0;
    return (a[0] - a[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: _pinching ? const Color(0xFFE8D5A3) : const Color(0x55E8D5A3),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SectionZoom(scale: _scale, child: widget.child),
            Positioned(
              top: 6,
              left: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => openSectionEditor(
                    context,
                    pageId: widget.pageId,
                    sectionId: widget.sectionId,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE0060C18),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFE8D5A3)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFFE8D5A3),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                      _pinching ? '${_scale.toStringAsFixed(2)}×' : 'Pinch ${_scale.toStringAsFixed(2)}×',
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
