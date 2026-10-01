/// Today's coupon. Scratch the foil, then the coins fly.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import 'scratch_card.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final int _coins = 12 + DateTime.now().day % 18;
  var _cleared = false;
  String? _error;

  Future<void> _clearedNow() async {
    if (_cleared) return;
    setState(() => _cleared = true);
    final from = EconomyMirror.instance.coins;
    var gained = 0;
    try {
      final result = await EconomyApi.call('scratchCoupon');
      gained = (result['coins'] as num?)?.toInt() ?? 0;
    } on EconomyException catch (e) {
      if (!EconomyApi.isMissing(e)) {
        if (mounted) setState(() => _error = e.message);
        return;
      }
      gained = await EconomyMirror.instance.grantOnce('scratch', _coins);
    }
    if (!mounted || gained <= 0) return;
    await NwsbCoinFly.show(context, coins: gained, from: from, to: from + gained);
  }

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Coupon',
      mark: NwsbMarks.coupon,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const FourBanners(
            splitTitle: 'Coupon',
            splitCta: 'Scratch',
            blackTitle: 'One a day',
            blackSub: 'Scratch the foil. The coins fly when it clears.',
          ),
          const SizedBox(height: 12),
          const GlassLine(
            text: 'Scratch the gold. The prize stays hidden until the foil comes off.',
            mark: NwsbMarks.coupon,
          ),
          const SizedBox(height: 16),
          NwsbScratchCard(
            onCleared: _clearedNow,
            prize: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(NwsbCoinFly.disc, width: 64, height: 64, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(
                  '+$_coins',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const Text('NOWSSB COINS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: NwsbColors.goldLight)),
          ],
          if (_cleared) ...[
            const SizedBox(height: 12),
            const Text('Collected.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}