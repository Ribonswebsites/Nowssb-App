/// Free coins (Flipkart "Free Coins" ref: spin-wheel hero, then wide earn
/// rows). Every row is a real server action from the economy summary; the
/// server grants and caps every coin.
library;

import 'package:flutter/material.dart';

import '../../screens/quotes_live.dart';
import '../../shell/nav_shell.dart';
import '../../theme/tokens.dart';
import '../social/echo_wall_screen.dart';
import '../gifts/spin_wheel.dart';
import '../programs/program_kit.dart';
import 'coin_glass.dart';

const kPromo = 'assets/banners/programs/rewards.png';
const _accent = NwsbColors.goldLight;

class FreeCoinsPage extends StatelessWidget {
  const FreeCoinsPage({super.key, this.preset, this.showWheel = true});
  final Map<String, dynamic>? preset;
  final bool showWheel;

  @override
  Widget build(BuildContext context) => CoinSummaryScaffold(
        title: 'FREE COINS',
        accent: _accent,
        preset: preset,
        info: 'Free coins count toward a daily limit set by NowssB. Coins have no cash value.',
        builder: (c, s) => _body(c, s, showWheel),
      );
}

List<Widget> _body(BuildContext context, Map<String, dynamic> s, bool showWheel) {
  final t = sMap(s['today']);
  final free = sInt(t['freeCoins']);
  final ceiling = sInt(t['ceiling']);
  final actions = sList(t['actions']);
  final open = actions.where((a) => !_done(a)).toList();
  final done = actions.where(_done).toList();
  return [
    GlassHero(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(coinNum(free), style: const TextStyle(color: _accent, fontSize: 80, fontWeight: FontWeight.w200, height: 1)),
          Padding(padding: const EdgeInsets.only(bottom: 10, left: 8), child: Text('/ ${coinNum(ceiling)}', style: const TextStyle(color: Color(0xFFBFBFBF), fontSize: 18))),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ceiling <= 0 ? 0 : (free / ceiling).clamp(0, 1), minHeight: 3, color: _accent, backgroundColor: Colors.white12),
        ),
      ]),
    ),
    PromoCard(
        image: kPromo,
        title: sInt(sMap(t['spin'])['freeLeft']) > 0 ? 'Free spin ready' : 'Spin used today',
        value: sInt(sMap(t['spin'])['freeLeft']) > 0 ? '1 left' : 'Tomorrow',
        onTap: () => _toWheel(context)),
    if (showWheel) ...[const SizedBox(height: 28), GiftWheel(key: _wheelKey)],
    if (open.isNotEmpty) ...[const GlassEyebrow('Earn'), for (final a in open) _row(context, a)],
    if (done.isNotEmpty) ...[const GlassEyebrow('Done'), for (final a in done) _row(context, a)],
    if (actions.isEmpty) const PEmpty('Nothing live', slot: 'free_coins.empty'),
  ];
}

bool _done(Map<String, dynamic> a) {
  final per = '${a['per']}';
  final d = sInt(a['done']);
  if (per == 'once' || per == 'month') return d > 0;
  if (per == 'key') return false;
  return d >= sInt(a['limit']);
}

Widget _row(BuildContext context, Map<String, dynamic> a) {
  final go = _done(a) ? null : _dest('${a['id']}');
  return OfferStrip(accent: _accent, title: '${a['title']}', value: '+${sInt(a['coins'])}', dim: _done(a), onTap: go == null ? null : () => go(context));
}

final _wheelKey = GlobalKey();

/// The wheel on this page when it's shown; otherwise the same wheel in a sheet.
void _toWheel(BuildContext context) {
  final c = _wheelKey.currentContext;
  if (c != null) {
    Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12081F),
    builder: (_) => const Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 32), child: GiftWheel()),
  );
}

/// Where each server action actually happens. Null = no single screen (row stays plain).
void Function(BuildContext)? _dest(String id) {
  void tab(BuildContext c, int i) {
    NavScope.goTo(c, i);
  }

  void push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));
  if (id == 'word_of_day') return (c) => tab(c, 0); // Connect home carries the word of the day
  if (id.startsWith('ring') || id == 'pronounce80' || id == 'close_stage' || id == 'read_meaning' || id == 'first_share') return (c) => tab(c, 1);
  if (id == 'sound_bath') return (c) => tab(c, 2);
  if (id == 'profile_complete') return (c) => tab(c, 4);
  if (id == 'quote') return (c) => push(c, const QuotesWeekScreen());
  if (id == 'echo_first_post') return (c) => push(c, const EchoWallScreen());
  return null;
}
