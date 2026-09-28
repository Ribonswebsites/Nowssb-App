import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'nwsb_icon.dart';
import '../admin/template/editable.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// Two portraits that turn over, the same flip the subscription cards use.
class FlipPortrait extends StatefulWidget {
  const FlipPortrait({
    super.key,
    required this.front,
    required this.back,
    this.mark,
    this.markAt = const Alignment(0, -0.62),
  });

  final String front;
  final String back;

  /// Optional mark drawn between the hands, in a white circle.
  final String? mark;
  final Alignment markAt;

  @override
  State<FlipPortrait> createState() => _FlipPortraitState();
}

class _FlipPortraitState extends State<FlipPortrait> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _auto;
  var _showBack = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    if (_flutterTest) return;
    _auto = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (!mounted) return;
      if (_showBack) {
        _c.reverse();
      } else {
        _c.forward();
      }
      _showBack = !_showBack;
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final ang = t * math.pi;
        final back = t > 0.5;
        final face = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(ang),
          child: back
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _face(widget.back),
                )
              : _face(widget.front),
        );
        return face;
      },
    );
  }

  Widget _face(String asset) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.black),
        EditableImage.asset(
          asset,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          slot: 'flip_portrait.FlipPortrait',
        ),
        if (widget.mark != null)
          Align(
            alignment: widget.markAt,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: NwsbIcon(widget.mark!, size: 18, color: Colors.black),
            ),
          ),
      ],
    );
  }
}
