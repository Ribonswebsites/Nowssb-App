/// Today's coupon. The prize is chosen on the server, then the foil comes off.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import 'scratch_card.dart';
import '../../widgets/nwsb_coin_fly.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  String? _rarity;
  int _coins = 0;
  var _busy = false;
  var _cleared = false;
  String? _error;

  Future<void> _open() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await EconomyApi.call('scratchCoupon');
      if (!mounted) return;
      setState(() {
        _coins = (result['coins'] as num?)?.toInt() ?? 0;
        _rarity = '${result['rarity'] ?? 'common'}';
        _busy = false;
      });
    } on EconomyException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _clearedNow() async {
    if (_cleared) return;
    setState(() => _cleared = true);
    final from = EconomyMirror.instance.coins;
    await NwsbCoinFly.show(
      context,
      coins: _coins,
      from: from,
      to: from + _coins,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _rarity != null;
    return EconomyPage(
      title: 'Coupon',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const ProgramShelf(),
          const SizedBox(height: 12),
          const GlassLine(
            text: 'One coupon a day. The server picks the prize. Scratch the gold.',
          ),
          const SizedBox(height: 16),
          if (!ready)
            GoldButton(
              label: _busy ? 'Opening…' : 'Open today’s coupon',
              onTap: _busy ? null : _open,
            )
          else
            NwsbScratchCard(
              onCleared: _clearedNow,
              prize: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _rarity!.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFE4C56A),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_coins coins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: NwsbColors.goldLight)),
          ],
          if (_cleared) ...[
            const SizedBox(height: 12),
            Text(
              '$_coins coins are on the wallet.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
