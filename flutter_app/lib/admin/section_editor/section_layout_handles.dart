/// Drag handles for [SectionLayout] fields (CS-4 / CS-5).
///
/// Vertical / horizontal drag strips update height, card size, spacing,
/// radius and wrapper live. Values are clamped to sensible ranges.
library;

import 'package:flutter/material.dart';

import '../../widgets/sections/section_config.dart';
import '../editor/glass.dart';

class SectionLayoutHandles extends StatelessWidget {
  const SectionLayoutHandles({
    super.key,
    required this.layout,
    required this.onChanged,
  });

  final SectionLayout layout;
  final ValueChanged<SectionLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Layout handles',
            style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Drag each strip · live preview updates',
            style: TextStyle(color: kDim.withValues(alpha: 0.9), fontSize: 11),
          ),
          const SizedBox(height: 10),
          _Handle(
            label: 'Height',
            value: layout.height ?? 160,
            min: 72,
            max: 480,
            unit: 'px',
            axis: Axis.vertical,
            onChanged: (v) => onChanged(layout.copyWith(height: v)),
          ),
          _Handle(
            label: 'Card width',
            value: layout.cardWidth ?? 140,
            min: 64,
            max: 360,
            unit: 'px',
            onChanged: (v) => onChanged(layout.copyWith(cardWidth: v)),
          ),
          _Handle(
            label: 'Card height',
            value: layout.cardHeight ?? 180,
            min: 64,
            max: 420,
            unit: 'px',
            axis: Axis.vertical,
            onChanged: (v) => onChanged(layout.copyWith(cardHeight: v)),
          ),
          _Handle(
            label: 'Spacing',
            value: layout.spacing ?? 12,
            min: 0,
            max: 48,
            unit: 'px',
            onChanged: (v) => onChanged(layout.copyWith(spacing: v)),
          ),
          _Handle(
            label: 'Corner radius',
            value: layout.radius ?? 16,
            min: 0,
            max: 48,
            unit: 'px',
            onChanged: (v) => onChanged(layout.copyWith(radius: v)),
          ),
          _Handle(
            label: 'Wrapper width',
            value: layout.wrapperWidth ?? 360,
            min: 120,
            max: 480,
            unit: 'px',
            onChanged: (v) => onChanged(layout.copyWith(wrapperWidth: v)),
          ),
          _Handle(
            label: 'Wrapper height',
            value: layout.wrapperHeight ?? 220,
            min: 80,
            max: 480,
            unit: 'px',
            axis: Axis.vertical,
            onChanged: (v) => onChanged(layout.copyWith(wrapperHeight: v)),
          ),
        ],
      ),
    );
  }
}

class _Handle extends StatefulWidget {
  const _Handle({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = '',
    this.axis = Axis.horizontal,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Axis axis;
  final ValueChanged<double> onChanged;

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  late double _v = widget.value;
  double? _start;
  double? _startV;

  @override
  void didUpdateWidget(_Handle old) {
    super.didUpdateWidget(old);
    if ((old.value - widget.value).abs() > 0.01 && _start == null) {
      _v = widget.value;
    }
  }

  void _onDragStart(DragStartDetails d) {
    _start = widget.axis == Axis.horizontal ? d.globalPosition.dx : d.globalPosition.dy;
    _startV = _v;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final start = _start;
    final startV = _startV;
    if (start == null || startV == null) return;
    final now = widget.axis == Axis.horizontal ? d.globalPosition.dx : d.globalPosition.dy;
    // ~2px drag = 1 unit.
    final delta = (now - start) / 2.0;
    // Vertical grow downward feels natural for height; invert Y so drag down increases.
    final signed = widget.axis == Axis.vertical ? delta : delta;
    final next = (startV + signed).clamp(widget.min, widget.max);
    if ((next - _v).abs() < 0.05) return;
    setState(() => _v = next);
    widget.onChanged(double.parse(next.toStringAsFixed(1)));
  }

  void _onDragEnd(DragEndDetails _) {
    _start = null;
    _startV = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = ((_v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_v.toStringAsFixed(_v == _v.roundToDouble() ? 0 : 1)}${widget.unit}',
                style: const TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.axis == Axis.horizontal ? _onDragStart : null,
            onHorizontalDragUpdate: widget.axis == Axis.horizontal ? _onDragUpdate : null,
            onHorizontalDragEnd: widget.axis == Axis.horizontal ? _onDragEnd : null,
            onVerticalDragStart: widget.axis == Axis.vertical ? _onDragStart : null,
            onVerticalDragUpdate: widget.axis == Axis.vertical ? _onDragUpdate : null,
            onVerticalDragEnd: widget.axis == Axis.vertical ? _onDragEnd : null,
            child: Container(
              height: widget.axis == Axis.vertical ? 28 : 22,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1A),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x44E8D5A3)),
              ),
              child: Align(
                alignment: Alignment(-1 + 2 * t, 0),
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: kGold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kGold.withValues(alpha: 0.35), blurRadius: 8),
                    ],
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
