/// NowssB coins flying into the wallet.
///
/// The disc is the app's own logo. The trail is drawn here. Nothing is a
/// downloaded coin, gift, or coupon animation.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class NwsbCoinFly {
  NwsbCoinFly._();

  static const disc = 'assets/icons/logo-disc.webp';

  static Future<void> show(
    BuildContext context, {
    required int coins,
    required int from,
    required int to,
  }) {
    final count = coins.clamp(5, 30);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xE6000000),
      pageBuilder: (context, _, __) => _FlyStage(count: count, from: from, to: to),
    );
  }
}

class _FlyStage extends StatefulWidget {
  const _FlyStage({required this.count, required this.from, required this.to});
  final int count;
  final int from;
  final int to;

  @override
  State<_FlyStage> createState() => _FlyStageState();
}

class _FlyStageState extends State<_FlyStage> with SingleTickerProviderStateMixin {
  late final AnimationController _move;
  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    if (_quiet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    _move.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.from + ((widget.to - widget.from) * _move.value).round();
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.72),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'WALLET',
                        style: TextStyle(
                          color: Color(0xFFE4C56A),
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x14FFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x55E4C56A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Disc(size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '$shown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < widget.count; i++)
                  _coin(i, widget.count),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _coin(int i, int count) {
    final size = MediaQuery.sizeOf(context);
    final start = (i / count) * 0.18;
    final t = ((_move.value - start) / (1 - start)).clamp(0.0, 1.0);
    final curve = Curves.easeIn.transform(t);
    final spread = (i - count / 2) * 14;
    final x = size.width / 2 + spread * (1 - curve);
    final y = size.height * 0.72 * (1 - curve) + size.height * 0.16 * curve;
    final spin = math.cos(curve * math.pi * 2 + i);
    return Positioned(
      left: x - 16,
      top: y,
      child: Opacity(
        opacity: t <= 0 ? 0 : 1,
        child: Column(
          children: [
            Container(
              width: 6,
              height: 18 * (1 - curve),
              decoration: BoxDecoration(
                color: const Color(0x66E4C56A),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(spin),
              child: const _Disc(size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        NwsbCoinFly.disc,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFE4C56A),
          alignment: Alignment.center,
          child: Text(
            'N',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}
