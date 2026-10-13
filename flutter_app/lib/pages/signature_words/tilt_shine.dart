import 'package:flutter/material.dart';

/// Gentle 3D tilt toward the finger plus a slow gold shine sweep.
/// Both are off when [enabled] is false (Reduce effects).
class TiltShine extends StatefulWidget {
  const TiltShine({super.key, required this.child, this.enabled = true, this.radius = 24});
  final Widget child;
  final bool enabled;
  final double radius;
  @override
  State<TiltShine> createState() => _TiltShineState();
}

class _TiltShineState extends State<TiltShine> with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  late final AnimationController _shine = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _shine.repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  void _move(Offset local, Size size) {
    if (!widget.enabled) return;
    setState(() => _tilt = Offset(
          (local.dx / size.width - 0.5).clamp(-0.5, 0.5),
          (local.dy / size.height - 0.5).clamp(-0.5, 0.5),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      return Listener(
        onPointerMove: (e) => _move(e.localPosition, size),
        onPointerUp: (_) => setState(() => _tilt = Offset.zero),
        onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(end: _tilt),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (_, v, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-v.dy * 0.22)
              ..rotateY(v.dx * 0.22),
            child: child,
          ),
          child: Stack(fit: StackFit.passthrough, children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (_, __) {
                      final p = _shine.value * 3 - 1; // sweep, then rest
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1 + p * 2, -1),
                            end: Alignment(p * 2, 1),
                            colors: const [Color(0x00FFFFFF), Color(0x26FFE6A8), Color(0x00FFFFFF)],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}
