/// Free coins (Flipkart "Free Coins" ref: spin-wheel hero, then wide earn
/// rows). Every row is a real server action from the economy summary; the
/// server grants and caps every coin.
library;

import 'package:flutter/material.dart';

import '../../screens/quotes_live.dart';
import '../../shell/nav_shell.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
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
  Widget build(BuildContext context) {
    if (preset != null) {
      return CoinSummaryScaffold(
        title: 'FREE COINS',
        accent: _accent,
        preset: preset,
        info: 'Free coins count toward a daily limit set by NowssB. Coins have no cash value.',
        builder: (c, s) => _body(c, s, showWheel),
      );
    }
    return const _LiveFreeCoins();
  }
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

class _LiveFreeCoins extends StatelessWidget {
  const _LiveFreeCoins();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final s = EconomyMirror.instance.summary;
        final t = sMap(s['today']);
        final actions = sList(t['actions']);
        final ceiling = sInt(t['ceiling']);
        final cap = ceiling > 0 ? ceiling : 1500;
        final rows = actions.isEmpty
            ? const [
                {'title': 'Open the app', 'coins': 5, 'id': 'open'},
                {'title': 'Word of the day', 'coins': 10, 'id': 'word_of_day'},
                {'title': 'Sound Bath', 'coins': 10, 'id': 'sound_bath'},
                {'title': 'Read one meaning', 'coins': 8, 'id': 'read_meaning'},
              ]
            : actions;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF6A1B9A),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Free Coins', style: TextStyle(fontWeight: FontWeight.w600)),
            actions: [
              IconButton(onPressed: () => NwsbLinks.cart(context), icon: const Icon(Icons.search)),
              IconButton(onPressed: () => NwsbLinks.cart(context), icon: const Icon(Icons.shopping_cart_outlined)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              Container(
                height: 180,
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)])),
                child: Row(
                  children: [
                    Expanded(child: Text('Earn\nUp to $cap\ncoins\nto shop', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.02))),
                    Container(
                      width: 128,
                      height: 128,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Color(0xFFE53935), Color(0xFFFFC107), Color(0xFF6A1B9A), Color(0xFFE53935)])),
                      alignment: Alignment.center,
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
                        child: const Text('N', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < rows.length; i++)
                _EarnBanner(
                  title: '${rows[i]['title']}',
                  coins: sInt(rows[i]['coins']),
                  flip: i.isOdd,
                  onTap: () {
                    final go = _dest('${rows[i]['id']}');
                    if (go != null) go(context);
                  },
                ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, color: Color(0xFFFFC107)),
                  Text('  Explore more with coins  ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Icon(Icons.bolt, color: Color(0xFFFFC107)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EarnBanner extends StatelessWidget {
  const _EarnBanner({required this.title, required this.coins, required this.flip, required this.onTap});
  final String title;
  final int coins;
  final bool flip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const arts = [
      'assets/store/intro-words.webp',
      'assets/store/intro-meanings.webp',
      'assets/store/picker-words.png',
      'assets/store/intro-ebooks.webp',
    ];
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(arts[title.hashCode.abs() % arts.length], width: 132, height: 84, fit: BoxFit.cover),
    );
    final copy = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Earn up to $coins coins', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Color(0xFF717171), fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Earn now  ›', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: flip ? [copy, const SizedBox(width: 8), photo] : [photo, const SizedBox(width: 10), copy]),
          ),
        ),
      ),
    );
  }
}
