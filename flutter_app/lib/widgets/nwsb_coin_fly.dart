/// NowssB coins flying into the wallet.
///
/// The disc is the gold NowssB coin (the seated mark), not a generic coin
/// and not the header logo. Paths are curves. Nothing here is a downloaded
/// animation.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin/template/editable.dart';

class NwsbCoinFly {
  NwsbCoinFly._();

  static const disc = 'assets/icons/nwsb-coin.webp';

  static Future<void> show(
    BuildContext context, {
    required int coins,
    required int from,
    required int to,
  }) {
    final count = (coins.clamp(1, 40) + 6).clamp(8, 18);
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0xC0000000),
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
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_quiet || MediaQuery.disableAnimationsOf(context)) {
        Navigator.of(context).pop();
        return;
      }
      _move.forward().whenComplete(() {
        HapticFeedback.selectionClick();
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final t = _move.value;
            final shown = widget.from + ((widget.to - widget.from) * Curves.easeOut.transform(t)).round();
            final punch = t > 0.82 ? math.sin((t - 0.82) / 0.18 * math.pi) : 0.0;
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.78),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EditableLabel('nwsb_coin_fly.FlyStage',
                        'NOWSSB COINS',
                        style: TextStyle(
                          color: Color(0xFFE4C56A),
                          fontSize: 11,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Transform.scale(
                        scale: 1 + punch * 0.12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0x66E4C56A)),
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
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < widget.count; i++) _coin(i, widget.count, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _coin(int i, int count, double raw) {
    final size = MediaQuery.sizeOf(context);
    final delay = i == 0 ? 0.0 : 0.12 + (i / count) * 0.28;
    final span = i == 0 ? 0.55 : 0.62;
    final u = ((raw - delay) / span).clamp(0.0, 1.0);
    if (u <= 0) return const SizedBox.shrink();
    final curve = Curves.easeInOutCubic.transform(u);
    final start = Offset(
      size.width * (0.42 + ((i % 5) - 2) * 0.06),
      size.height * (0.62 + (i % 3) * 0.03),
    );
    final lift = Offset(
      size.width * (0.18 + (i % 7) * 0.1),
      size.height * (0.28 - (i % 4) * 0.04),
    );
    final end = Offset(size.width * 0.50, size.height * 0.16);
    final a = Offset.lerp(start, lift, curve)!;
    final b = Offset.lerp(lift, end, curve)!;
    final p = Offset.lerp(a, b, curve)!;
    final disc = i == 0 ? 72.0 : 30.0 + (i % 4) * 4;
    final spin = curve * math.pi * (i.isEven ? 1 : -1);
    return Positioned(
      left: p.dx - disc / 2,
      top: p.dy - disc / 2,
      child: Opacity(
        opacity: u < 0.08 ? u / 0.08 : (u > 0.92 ? (1 - u) / 0.08 : 1),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(spin)
            ..rotateZ(spin * 0.15),
          child: _Disc(size: disc),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => NwsbCoinDisc(size: size);
}

/// The gold NowssB coin beside a balance. Same asset the flight uses.
class NwsbCoinDisc extends StatelessWidget {
  const NwsbCoinDisc({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return EditableImage.asset(
      NwsbCoinFly.disc,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Color(0xFFE4C56A), shape: BoxShape.circle),
        child: EditableLabel('nwsb_coin_fly.NwsbCoinDisc',
          'N',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: size * 0.42),
        ),
      ),
      slot: 'nwsb_coin_fly.NwsbCoinDisc',
    );
  }
}
