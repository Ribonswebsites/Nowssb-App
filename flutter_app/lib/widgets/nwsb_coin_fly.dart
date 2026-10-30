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
import '../features/economy/economy_api.dart' show EconomyMirror;
import '../features/economy/reward_overlay.dart' show CoinPillAnchor;

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
      barrierColor: const Color(0x40000000),
      pageBuilder: (context, _, __) => _FlyStage(count: count, from: from, to: to, target: CoinPillAnchor.target()),
    );
  }
}

class _FlyStage extends StatefulWidget {
  const _FlyStage({required this.count, required this.from, required this.to, this.target});
  final int count;
  final int from;
  final int to;

  /// The balance pill on screen (global), or null → top centre.
  final Offset? target;

  @override
  State<_FlyStage> createState() => _FlyStageState();
}

class _FlyStageState extends State<_FlyStage> with SingleTickerProviderStateMixin {
  late final AnimationController _move;
  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
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

  double get _pillTop => MediaQuery.paddingOf(context).top + 10;
  double get _pillWidth => math.min(MediaQuery.sizeOf(context).width - 32, 360);

  /// Centre of the glass wallet circle on the right of the pill: the coins land here.
  Offset get _walletCentre {
    final w = MediaQuery.sizeOf(context).width;
    return Offset((w + _pillWidth) / 2 - CoinWalletPill.pad - CoinWalletPill.circle / 2, _pillTop + CoinWalletPill.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final t = _move.value;
            final shown = widget.from + ((widget.to - widget.from) * Curves.easeOut.transform(t)).round();
            final punch = t > 0.82 ? math.sin((t - 0.82) / 0.18 * math.pi) : 0.0;
            final fade = t < 0.08 ? t / 0.08 : (t > 0.94 ? (1 - t) / 0.06 : 1.0);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: _pillTop,
                  child: Center(
                    child: Opacity(
                      opacity: fade.clamp(0.0, 1.0),
                      child: CoinWalletPill(total: shown, punch: punch, width: _pillWidth),
                    ),
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
    final end = _walletCentre;
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


/// The pill that drops in at the top after a coin collect: the new total,
/// today's free-coin progress on the app's gold progress bar, and on the
/// right a round glass wallet the coins fly into.
class CoinWalletPill extends StatelessWidget {
  const CoinWalletPill({super.key, required this.total, this.punch = 0, this.width = 340});

  static const height = 56.0;
  static const circle = 44.0;
  static const pad = 6.0;

  final int total;
  final double punch;
  final double width;

  @override
  Widget build(BuildContext context) {
    final today = (EconomyMirror.instance.summary['today'] as Map?) ?? const {};
    final earned = (today['freeCoins'] as num?)?.toInt();
    final cap = ((today['ceilingNow'] ?? today['ceiling']) as num?)?.toInt();
    final hasCap = earned != null && cap != null && cap > 0;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(10, pad, pad, pad),
      decoration: BoxDecoration(
        color: const Color(0xCC0B0B10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x66E4C56A)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Row(children: [
        const NwsbCoinDisc(size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('$total',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(hasCap ? 'today $earned / $cap' : 'coins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              if (hasCap) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (earned / cap).clamp(0.0, 1.0),
                    minHeight: 4,
                    color: const Color(0xFFE4C56A),
                    backgroundColor: const Color(0x33FFFFFF),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Transform.scale(
          scale: 1 + punch * 0.14,
          child: Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x40FFFFFF), Color(0x14FFFFFF)],
              ),
              border: Border.all(color: const Color(0x66FFFFFF)),
              boxShadow: [BoxShadow(color: const Color(0xFFE4C56A).withValues(alpha: 0.25 + 0.4 * punch), blurRadius: 14)],
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE4C56A), size: 22),
          ),
        ),
      ]),
    );
  }
}
