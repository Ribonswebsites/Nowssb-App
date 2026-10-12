/// Multiplier (Flipkart "Multiplier" ref: a hero banner, then themed strips
/// of boosted moments). The multiplier and its events come from the server's
/// `config.rewards.eventMultiplier` and `events`; the server applies it to
/// every earned coin. This page only shows it.
library;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../programs/program_kit.dart';
import 'coin_glass.dart';
import 'free_coins_page.dart';

class MultiplierPage extends StatelessWidget {
  const MultiplierPage({super.key, this.preset});
  final Map<String, dynamic>? preset;

  @override
  Widget build(BuildContext context) => CoinSummaryScaffold(
      title: 'MULTIPLIER', preset: preset, accent: _accent, info: 'NowssB applies multipliers on its servers to free coins you earn. Spin and scratch prizes aren\u2019t multiplied.', builder: _body);
}

const kPromo = 'assets/banners/programs/rewards-live.png';
const _accent = NwsbColors.goldLight;

bool _live(Map<String, dynamic> e, DateTime now) {
  final s = DateTime.tryParse('${e['startsAt'] ?? ''}');
  final t = DateTime.tryParse('${e['endsAt'] ?? ''}');
  if (s != null && now.isBefore(s)) return false;
  if (t != null && now.isAfter(t)) return false;
  final wd = (e['weekdays'] as List?)?.whereType<num>().map((n) => n.toInt()).toList() ?? const <int>[];
  return wd.isEmpty || wd.contains(now.weekday % 7);
}

String _x(num m) => m == m.roundToDouble() ? '${m.toInt()}' : m.toStringAsFixed(1);

List<Widget> _body(BuildContext context, Map<String, dynamic> s) {
  final r = sMap(sMap(s['config'])['rewards']);
  final base = (r['eventMultiplier'] is num ? r['eventMultiplier'] as num : 1);
  final events = sList(r['events']);
  final nowMs = sInt(s['now']);
  final now = nowMs > 0 ? DateTime.fromMillisecondsSinceEpoch(nowMs) : DateTime.now();
  final live = events.where((e) => _live(e, now)).toList();
  num cur = base;
  for (final e in live) {
    final m = e['multiplier'] is num ? e['multiplier'] as num : 1;
    if (m > cur) cur = m;
  }
  final upcoming = events.where((e) => !_live(e, now)).toList();
  return [
    GlassHero(
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('\u00d7', style: TextStyle(color: Color(0xFFBFBFBF), fontSize: 40, fontWeight: FontWeight.w200))),
        Text(_x(cur), style: const TextStyle(color: _accent, fontSize: 112, fontWeight: FontWeight.w100, height: 1)),
      ]),
    ),
    if (upcoming.isNotEmpty)
      PromoCard(
          image: kPromo, title: '${upcoming.first['title']}', value: '\u00d7${_x(upcoming.first['multiplier'] is num ? upcoming.first['multiplier'] as num : 1)} soon', onTap: () => _earn(context)),
    if (live.isNotEmpty) ...[const GlassEyebrow('Live'), for (final e in live) _strip(context, e, true)],
    if (upcoming.isNotEmpty) ...[const GlassEyebrow('Soon'), for (final e in upcoming) _strip(context, e, false)],
    if (events.isEmpty) ...[const SizedBox(height: 32), const PEmpty('No events yet', slot: 'multiplier.empty')],
  ];
}

/// A multiplier boosts free coins, so every row leads to where they're earned.
void _earn(BuildContext c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const FreeCoinsPage()));

Widget _strip(BuildContext context, Map<String, dynamic> e, bool live) => OfferStrip(
      onTap: () => _earn(context),
      accent: _accent,
      title: '${e['title'] ?? 'Coin event'}',
      value: '\u00d7${_x(e['multiplier'] is num ? e['multiplier'] as num : 1)}',
      dim: !live,
    );
