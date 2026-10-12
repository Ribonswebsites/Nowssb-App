/// Coinback (Flipkart "Coinback store" ref: hero banner, rail of tiles,
/// strips). Rates come from the server's `config.rewards.buying` and the
/// wallet's partner bonus; the server credits coinback on verified orders.
library;

import 'package:flutter/material.dart';

import '../../screens/subscription.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../programs/program_router.dart';
import '../programs/program_kit.dart';
import 'coin_glass.dart';

import '../economy/shop_faces.dart' as shop;

const kPromo = 'assets/banners/programs/earn.png';
const _accent = NwsbColors.goldLight;

class CoinbackPage extends StatelessWidget {
  const CoinbackPage({super.key, this.preset});
  final Map<String, dynamic>? preset;

  @override
  Widget build(BuildContext context) {
    if (preset != null) {
      return CoinSummaryScaffold(
        title: 'COINBACK',
        accent: _accent,
        preset: preset,
        info: 'NowssB credits coinback after each verified order. Coins have no cash value.',
        builder: _body,
      );
    }
    return const shop.CoinbackPage(title: 'Coinback store', art: 'assets/store/intro-store.webp');
  }
}

List<Widget> _body(BuildContext context, Map<String, dynamic> s) {
  final b = sMap(sMap(sMap(s['config'])['rewards'])['buying']);
  final base = sInt(b['coinsBackPct']);
  final bonus = sInt(sMap(s['wallet'])['coinsBackBonusPct']);
  final bundle = sInt(b['bundleBonusPct']);
  final first = sInt(sMap(b['firstPurchase'])['coins']);
  final renew = sMap(b['renewalBonus']).entries.toList()..sort((x, y) => sInt(x.key).compareTo(sInt(y.key)));
  if (base <= 0 && bonus <= 0 && bundle <= 0 && first <= 0 && renew.isEmpty) {
    return const [SizedBox(height: 80), PEmpty('Not live yet', slot: 'coinback.empty')];
  }
  return [
    GlassHero(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${base + bonus}', style: const TextStyle(color: _accent, fontSize: 96, fontWeight: FontWeight.w200, height: 1)),
        const Padding(padding: EdgeInsets.only(top: 10, left: 4), child: Text('% back', style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 20, fontWeight: FontWeight.w300))),
      ]),
    ),
    if (first > 0) PromoCard(image: kPromo, title: 'First purchase', value: '+${coinNum(first)} coins', onTap: () => _store(context)),
    if (renew.isNotEmpty) ...[
      const GlassEyebrow('Renewals'),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: renew.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (c, i) => _tile(c, '${renew[i].key} mo', '+${coinNum(sInt(renew[i].value))}'),
        ),
      ),
    ],
    const GlassEyebrow('Coinback'),
    if (base > 0) OfferStrip(accent: _accent, title: 'Every purchase', value: '$base%', onTap: () => _store(context)),
    if (bonus > 0) OfferStrip(accent: _accent, title: 'Partner bonus', value: '+$bonus%', onTap: () => Programmes.open(context, Programme.partner)),
    if (bundle > 0) OfferStrip(accent: _accent, title: 'Bundles', value: '+$bundle%', onTap: () => _store(context)),
    if (first > 0) OfferStrip(accent: _accent, title: 'First purchase', value: '+${coinNum(first)}', onTap: () => _store(context)),
  ];
}

void _store(BuildContext c) {
  NavScope.goTo(c, 3);
}

Widget _tile(BuildContext context, String top, String big) => GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0x8C000000),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(top, style: const TextStyle(color: Color(0xFFBFBFBF), fontSize: 13)),
          FittedBox(child: Text(big, style: const TextStyle(color: _accent, fontSize: 30, fontWeight: FontWeight.w300))),
        ]),
      ),
    );
