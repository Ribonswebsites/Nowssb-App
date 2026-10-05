/// Fluid pinch-zoom + drag for one [SectionMediaItem] image (CS-4).
///
/// One finger pans focalX/focalY (−1…1). Two fingers pinch zoom (1…8).
/// Uses a [Listener] (same pattern as [SectionPinch]) so a scale recognizer
/// never steals the page scroll arena.
library;

import 'package:flutter/material.dart';

import '../../widgets/sections/section_config.dart';
import '../editor/glass.dart';

typedef SectionFocalChanged = void Function(double focalX, double focalY, double zoom);

class SectionFocalPad extends StatefulWidget {
  const SectionFocalPad({
    super.key,
    required this.item,
    required this.onChanged,
    this.height = 200,
  });

  final SectionMediaItem item;
  final SectionFocalChanged onChanged;
  final double height;

  @override
  State<SectionFocalPad> createState() => _SectionFocalPadState();
}

class _SectionFocalPadState extends State<SectionFocalPad> {
  late double _fx = widget.item.focalX;
  late double _fy = widget.item.focalY;
  late double _zoom = widget.item.zoom;

  final Map<int, Offset> _pts = {};
  double _startDist = 0;
  double _startZoom = 1;
  Offset? _lastPan;
  var _pinching = false;

  @override
  void didUpdateWidget(SectionFocalPad old) {
    super.didUpdateWidget(old);
    if (old.item.id != widget.item.id ||
        (!_pinching && _pts.isEmpty && (
          (old.item.focalX - widget.item.focalX).abs() > 0.001 ||
          (old.item.focalY - widget.item.focalY).abs() > 0.001 ||
          (old.item.zoom - widget.item.zoom).abs() > 0.001))) {
      _fx = widget.item.focalX;
      _fy = widget.item.focalY;
      _zoom = widget.item.zoom;
    }
  }

  void _emit() {
    widget.onChanged(
      _fx.clamp(-1.0, 1.0),
      _fy.clamp(-1.0, 1.0),
      _zoom.clamp(1.0, 8.0),
    );
  }

  void _down(PointerDownEvent e) {
    _pts[e.pointer] = e.position;
    if (_pts.length == 1) {
      _lastPan = e.position;
      _pinching = false;
    } else if (_pts.length >= 2) {
      _pinching = true;
      _startDist = _dist();
      _startZoom = _zoom;
      _lastPan = null;
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pts.containsKey(e.pointer)) return;
    _pts[e.pointer] = e.position;
    if (_pts.length >= 2) {
      final d = _dist();
      if (d < 8) return;
      if (_startDist < 8) {
        _startDist = d;
        _startZoom = _zoom;
        return;
      }
      final next = (_startZoom * d / _startDist).clamp(1.0, 8.0);
      if ((next - _zoom).abs() < 0.004) return;
      setState(() => _zoom = next);
      _emit();
      return;
    }
    // One-finger pan → focal
    final last = _lastPan;
    _lastPan = e.position;
    if (last == null || _pinching) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    if (size.shortestSide < 8) return;
    final dx = e.position.dx - last.dx;
    final dy = e.position.dy - last.dy;
    // Dragging the image right reveals the left → focalX decreases.
    final nextX = (_fx - dx / (size.width / 2)).clamp(-1.0, 1.0);
    final nextY = (_fy - dy / (size.height / 2)).clamp(-1.0, 1.0);
    if ((nextX - _fx).abs() < 0.001 && (nextY - _fy).abs() < 0.001) return;
    setState(() {
      _fx = nextX;
      _fy = nextY;
    });
    _emit();
  }

  void _up(PointerEvent e) {
    _pts.remove(e.pointer);
    if (_pts.length >= 2) return;
    if (_pts.length == 1) {
      _lastPan = _pts.values.first;
      _pinching = false;
      _startDist = 0;
      return;
    }
    _pinching = false;
    _startDist = 0;
    _lastPan = null;
  }

  double _dist() {
    final a = _pts.values.toList();
    if (a.length < 2) return 0;
    return (a[0] - a[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.item.imageUrl;
    const radius = 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Image · drag to pan · pinch to zoom',
          style: TextStyle(color: kDim.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.height,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF0A0F1A)),
                  if (url != null && url.isNotEmpty)
                    Transform.scale(
                      scale: _zoom,
                      alignment: Alignment(_fx, _fy),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        alignment: Alignment(_fx, _fy),
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
                    )
                  else
                    Transform.scale(
                      scale: _zoom,
                      alignment: Alignment(_fx, _fy),
                      child: _placeholder(),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xE0060C18),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: kGold.withValues(alpha: 0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Text(
                          'x${_fx.toStringAsFixed(2)}  y${_fy.toStringAsFixed(2)}  ${_zoom.toStringAsFixed(2)}×',
                          style: const TextStyle(
                            color: kGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_fx, _fy),
          end: Alignment(-_fx, -_fy),
          colors: const [Color(0xFF2A3348), Color(0xFFE8D5A3), Color(0xFF1A2233)],
        ),
      ),
      child: Center(
        child: Text(
          widget.item.title ?? widget.item.id,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Pure helper used by tests — map a pixel drag to a new focal.
(double, double) focalAfterPan({
  required double focalX,
  required double focalY,
  required double dx,
  required double dy,
  required Size size,
}) {
  if (size.width < 1 || size.height < 1) return (focalX, focalY);
  return (
    (focalX - dx / (size.width / 2)).clamp(-1.0, 1.0),
    (focalY - dy / (size.height / 2)).clamp(-1.0, 1.0),
  );
}

double zoomAfterPinch({
  required double startZoom,
  required double startDist,
  required double dist,
}) {
  if (startDist < 1 || dist < 1) return startZoom.clamp(1.0, 8.0);
  return (startZoom * dist / startDist).clamp(1.0, 8.0);
}

