import 'package:flutter/material.dart';

/// Static brand mark used in the fixed headers.
///
/// The header logo is intentionally not animated. The launch/splash animation
/// remains separate, while this widget is a quiet, reusable image mark.
class LoopingLogoMark extends StatelessWidget {
  const LoopingLogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          'assets/profile_source/img-ring.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.16),
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF14141C),
            child: Icon(Icons.auto_awesome, color: Color(0xFFFFA21A), size: 22),
          ),
        ),
      ),
    );
  }
}
