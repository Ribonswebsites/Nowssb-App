/// Twenty more prebuilt banners for the Sections drawer.
///
/// Layout ideas only: offer twins, a ribbon, a code band, a gift that opens,
/// a stay card, deal steps, a metal pass, a rank track. NowssB colours.
/// Every word is a template field, and each one moves.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'template_more.dart';

const _earn = 'assets/banners/programs/earn.png';
const _rewards = 'assets/banners/programs/rewards.png';
const _coupon = 'assets/gifts/coupon-hero.png';
const _gift = 'assets/gifts/gift-hero.png';
const _library = 'assets/hero-curve/banner-library.webp';
const _store = 'assets/hero-curve/banner-store.webp';

const kMotionTemplates = <String, (String, String, String)>{
  'offerTwins': ('Twin offer cards', 'Two gold-edged offer cards, side by side', 'Top banners'),
  'savedShelf': ('Saved for you', 'Chips and cards of things you saved', 'Cards'),
  'goldRibbon': ('Gold ribbon', 'A shining gold ribbon with doors under it', 'Top banners'),
  'doorChips': ('Door chips', 'A row of doors you can tap', 'Cards'),
  'codeBand': ('Code band', 'A slim band with an offer code', 'Offers & coupons'),
  'giftOpen': ('Opening gift', 'A gift card whose flap lifts', 'Offers & coupons'),
  'stayCard': ('Stay card', 'A curved card that asks you to stay', 'Buttons & banners'),
  'threeDeals': ('Three deals', 'Three steps, then the deals they unlock', 'Offers & coupons'),
  'savingLine': ('Saving line', 'A bar that fills with what you saved', 'Numbers'),
  'bagItem': ('Bag item', 'One item in the bag, with its price', 'Cards'),
  'coinPicks': ('Coin amounts', 'Five coin amounts in a row', 'Offers & coupons'),
  'metalPass': ('Metal membership', 'A metal card with a slow shine', 'Cards'),
  'rankTrack': ('Rank track', 'Dots for each rank and how far you are', 'Numbers'),
  'benefitSplit': ('This rank, next rank', 'What you have, and what the next rank adds', 'Features'),
  'dropShelf': ('Dropped prices', 'Cards with the old price and the new one', 'Cards'),
  'peekShelf': ('Peeking posters', 'Posters in a row, the next one peeking in', 'Top banners'),
  'lovedRow': ('Loved row', 'Cards you marked, with a heart', 'Cards'),
  'shineLine': ('Moving offer line', 'One line of an offer that travels', 'Top banners'),
  'pulseCta': ('Pulsing button', 'A banner whose button breathes', 'Buttons & banners'),
  'litSteps': ('Lit steps', 'Steps that light up one after another', 'Features'),
};

const kMotionKinds = <String>[
  'offerTwins', 'savedShelf', 'goldRibbon', 'doorChips', 'codeBand',
  'giftOpen', 'stayCard', 'threeDeals', 'savingLine', 'bagItem',
  'coinPicks', 'metalPass', 'rankTrack', 'benefitSplit', 'dropShelf',
  'peekShelf', 'lovedRow', 'shineLine', 'pulseCta', 'litSteps',
];

Map<String, dynamic> motionStarter(String kind) => switch (kind) {
      'offerTwins' => {'title': 'NowssB picks', 't1': 'Signature', 'off1': 'Rare words', 't2': 'Sounds', 'off2': 'Hear a word', 'image': _store, 'image2': _library},
      'savedShelf' => {'title': 'Saved for you', 'c1': 'Your list', 'c2': 'Opened', 'c3': 'Still here', 't1': 'Meaning pack', 'p1': '₹499', 's1': 'Was ₹899', 'image': _library, 't2': 'Sound week', 'p2': '₹299', 's2': 'Was ₹599', 'image2': _earn},
      'goldRibbon' => {'title': 'NowssB nights', 'subtitle': 'Words, sounds and the store', 'd1': 'Words', 'd2': 'Sounds', 'd3': 'Store', 'd4': 'Gifts', 'd5': 'Earn'},
      'doorChips' => {'title': 'Where to', 'c1': 'Words', 'c2': 'Sounds', 'c3': 'Store', 'c4': 'Practice', 'c5': 'Earn'},
      'codeBand' => {'kicker': 'Extra', 'title': '10% off', 'subtitle': 'On your first order', 'code': 'NOWSSB10'},
      'giftOpen' => {'title': 'A gift is waiting', 'subtitle': 'Catalogue prize, not cash', 'cta': 'Open it', 'route': 'page:gifts.program', 'image': _gift},
      'stayCard' => {'title': 'Before you go', 'subtitle': 'Your rank and coins stay on this account', 'b1': 'Your words', 'b2': 'Your coins', 'b3': 'Your code', 'cta': 'Keep going', 'cta2': 'Not now', 'route': 'tab:1'},
      'threeDeals' => {'title': 'Items unlocked', 'd1': 'Deal 1', 'd2': 'Deal 2', 'd3': 'Deal 3', 't1': 'Word card', 'p1': '₹199', 'image': _coupon, 't2': 'Sound card', 'p2': '₹149', 'image2': _library},
      'savingLine' => {'title': 'You are saving', 'amount': '₹340', 'subtitle': 'Catalogue value, not cash out'},
      'bagItem' => {'title': 'Your bag', 'name': 'Signature set', 'line': 'The rarest words', 'price': '₹1,499', 'old': '₹1,999', 'note': 'Coupon sits on the catalogue', 'image': _store},
      'coinPicks' => {'title': 'Spend coins', 'a1': '10', 'a2': '20', 'a3': '50', 'a4': '80', 'a5': '100', 'subtitle': '10 coins = ₹1 in the catalogue'},
      'metalPass' => {'hello': 'Hello', 'title': 'You are on this rank', 'rank': 'Officer', 'since': 'NowssB Earn'},
      'rankTrack' => {'title': 'Your rank', 'a1': 'Start', 'a2': 'Officer', 'a3': 'Exec I', 'a4': 'Exec II', 'a5': 'Diamond', 'now': 'You are here', 'next': 'Next: Officer at 100 words'},
      'benefitSplit' => {'left': 'This rank', 'right': 'Next rank', 'l1': '15% of Net on your sales', 'l2': 'Coins stay in the catalogue', 'r1': '22% of Net after 100 words', 'r2': 'One team level, real sales only'},
      'dropShelf' => {'title': 'Lower on your list', 't1': 'Meaning pack', 'old1': '₹899', 'p1': '₹499', 'drop1': 'Down ₹400', 'image': _rewards, 't2': 'Sound week', 'old2': '₹599', 'p2': '₹299', 'drop2': 'Down ₹300', 'image2': _earn},
      'peekShelf' => {'title': 'New on NowssB', 't1': 'Sound Library', 't2': 'Signature', 't3': 'Coupons', 'image': _library, 'image2': _store, 'image3': _coupon},
      'lovedRow' => {'title': 'You marked these', 't1': 'Morning line', 't2': 'Night sound', 'image': _library, 'image2': _earn},
      'shineLine' => {'title': 'Scratch today · catalogue only · not cash · '},
      'pulseCta' => {'title': 'Start from your rank', 'subtitle': 'Words sold move it. Money does not buy it.', 'cta': 'See ranks', 'route': 'page:earn.program'},
      'litSteps' => {'title': 'How a rank moves', 's1': 'Someone buys', 's2': 'The sale clears', 's3': 'Words count', 's4': 'The rate can rise'},
      _ => const {},
    };

class MotionLoop extends StatefulWidget {
  const MotionLoop({super.key, required this.builder, this.milliseconds = 2800});
  final Widget Function(double t) builder;
  final int milliseconds;

  @override
  State<MotionLoop> createState() => _MotionLoopState();
}

class _MotionLoopState extends State<MotionLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.milliseconds),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => widget.builder(_c.value),
      );
}

Widget buildMotionBanner(String kind, TplKit k) {
  final l = k.label;
  switch (kind) {
    case 'offerTwins':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(20)),
        const SizedBox(height: 10),
        SizedBox(
        height: 196,
        child: MotionLoop(builder: (t) {
          final glow = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
          return Row(children: [
            Expanded(child: _offerCard(k, 'image', 't1', 'off1', glow)),
            const SizedBox(width: 10),
            Expanded(child: _offerCard(k, 'image2', 't2', 'off2', glow)),
          ]);
        }),
      ),
      ]));
    case 'savedShelf':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(20)),
        const SizedBox(height: 10),
        SizedBox(height: 34, child: ListView(scrollDirection: Axis.horizontal, children: [
          _pill(l('c1', _dark(12)), true),
          _pill(l('c2', _white(12)), false),
          _pill(l('c3', _white(12)), false),
        ])),
        const SizedBox(height: 10),
        SizedBox(height: 210, child: ListView(scrollDirection: Axis.horizontal, children: [
          _saveCard(k, 'image', 't1', 'p1', 's1'),
          _saveCard(k, 'image2', 't2', 'p2', 's2'),
        ])),
      ]));
    case 'goldRibbon':
      return _hpad(MotionLoop(
        milliseconds: 2200,
        builder: (t) => Column(children: [
          _shineBox(
            t,
            height: 92,
            radius: 18,
            colors: const [Color(0xFF8A6A32), Color(0xFFF3E2B0), Color(0xFFC8A96E), Color(0xFF6E5424)],
            child: Center(child: l('title', const TextStyle(color: Color(0xFF2A1C08), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.4))),
          ),
          const SizedBox(height: 8),
          l('subtitle', _dim(12), align: TextAlign.center),
          const SizedBox(height: 12),
          Row(children: [
            for (final id in ['d1', 'd2', 'd3', 'd4', 'd5'])
              Expanded(child: Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE8D5A3))),
                  child: const Icon(Icons.circle, size: 8, color: Color(0xFFE8D5A3)),
                ),
                const SizedBox(height: 4),
                l(id, _dim(10), maxLines: 1, align: TextAlign.center),
              ])),
          ]),
        ]),
      ));
    case 'doorChips':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xFFE8D5A3) : const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: l('c${i + 1}', TextStyle(color: i == 0 ? const Color(0xFF121212) : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ),
          ]),
        ),
      ]));
    case 'codeBand':
      return _hpad(MotionLoop(builder: (t) => _shineBox(
            t,
            height: 84,
            radius: 16,
            colors: const [Color(0xFF3A3018), Color(0xFF1A160E)],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                l('kicker', _gold(12)),
                const SizedBox(width: 10),
                l('title', _white(22)),
                const Spacer(),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  l('subtitle', _dim(11)),
                  const SizedBox(height: 4),
                  DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: l('code', _white(12))),
                  ),
                ]),
              ]),
            ),
          )));
    case 'giftOpen':
      return _hpad(MotionLoop(
        milliseconds: 3200,
        builder: (t) {
          final lift = math.sin(t * math.pi);
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: ColoredBox(
              color: const Color(0xFF14161C),
              child: SizedBox(
                height: 230,
                child: Stack(children: [
                  Positioned(left: 16, right: 16, top: 16, child: l('title', _white(20))),
                  Positioned(left: 16, right: 16, top: 46, child: l('subtitle', _dim(13))),
                  Positioned(
                    left: 0, right: 0, bottom: 54,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, -18 * lift),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(width: 120, height: 90, child: k.picture('image')),
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: 16, right: 16, bottom: 14, child: Center(child: k.button(light: true))),
                ]),
              ),
            ),
          );
        },
      ));
    case 'stayCard':
      return _hpad(ClipPath(
        clipper: const _CurveTop(),
        child: ColoredBox(
          color: const Color(0xFF1A140C),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
            child: Column(children: [
              l('title', _white(22), align: TextAlign.center),
              const SizedBox(height: 8),
              l('subtitle', const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14), align: TextAlign.center, maxLines: 2),
              const SizedBox(height: 16),
              Row(children: [
                for (final id in ['b1', 'b2', 'b3'])
                  Expanded(child: l(id, _white(12), align: TextAlign.center, maxLines: 2)),
              ]),
              const SizedBox(height: 16),
              k.button(light: true),
              const SizedBox(height: 8),
              l('cta2', const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), align: TextAlign.center),
            ]),
          ),
        ),
      ));
    case 'threeDeals':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 8),
        MotionLoop(builder: (t) {
          final on = (t * 3).floor() % 3;
          return Row(children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == on ? const Color(0xFFE8D5A3) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: l('d${i + 1}', TextStyle(color: i == on ? const Color(0xFF121212) : Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ),
          ]);
        }),
        const SizedBox(height: 10),
        SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, children: [
          _miniDeal(k, 'image', 't1', 'p1'),
          _miniDeal(k, 'image2', 't2', 'p2'),
        ])),
      ]));
    case 'savingLine':
      return _hpad(MotionLoop(builder: (t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1E3A28), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              l('title', const TextStyle(color: Color(0xFFB6F0C8), fontWeight: FontWeight.w800, fontSize: 16)),
              l('amount', const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: 0.25 + 0.7 * t, minHeight: 6, color: const Color(0xFF7DDEA0), backgroundColor: const Color(0x33FFFFFF)),
              ),
              const SizedBox(height: 6),
              l('subtitle', _dim(12)),
            ]),
          )));
    case 'bagItem':
      return _hpad(Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF16181E), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x22FFFFFF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          l('title', _dim(12)),
          const SizedBox(height: 8),
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 72, height: 84, child: k.picture('image'))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              l('name', _white(16)),
              l('line', _dim(12), maxLines: 1),
              const SizedBox(height: 4),
              Row(children: [
                l('price', _white(15)),
                const SizedBox(width: 8),
                l('old', const TextStyle(color: Color(0x88FFFFFF), fontSize: 12, decoration: TextDecoration.lineThrough)),
              ]),
              l('note', const TextStyle(color: Color(0xFFB6F0C8), fontSize: 12)),
            ])),
          ]),
        ]),
      ));
    case 'coinPicks':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 10),
        Row(children: [
          for (final id in ['a1', 'a2', 'a3', 'a4', 'a5'])
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x55E8D5A3))),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: l(id, _gold(13)))),
              ),
            )),
        ]),
        const SizedBox(height: 8),
        l('subtitle', _dim(12)),
      ]));
    case 'metalPass':
      return _hpad(MotionLoop(
        milliseconds: 2600,
        builder: (t) => _shineBox(
          t,
          height: 168,
          radius: 18,
          colors: const [Color(0xFFBFC6D0), Color(0xFFF7F8FA), Color(0xFF8E97A3), Color(0xFFE4E7EC)],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              l('since', const TextStyle(color: Color(0xFF2C3138), fontWeight: FontWeight.w800, fontSize: 14)),
              const Spacer(),
              l('hello', const TextStyle(color: Color(0xFF3A4048), fontSize: 13)),
              l('rank', const TextStyle(color: Color(0xFF1A1D22), fontSize: 28, fontWeight: FontWeight.w900)),
              l('title', const TextStyle(color: Color(0xFF3A4048), fontSize: 12)),
            ]),
          ),
        ),
      ));
    case 'rankTrack':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 14),
        MotionLoop(builder: (t) {
          final at = (t * 4).floor() % 5;
          return Row(children: [
            for (var i = 0; i < 5; i++)
              Expanded(child: Column(children: [
                Container(
                  width: i == at ? 16 : 10,
                  height: i == at ? 16 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= at ? const Color(0xFFE8D5A3) : Colors.transparent,
                    border: Border.all(color: const Color(0xFFE8D5A3)),
                  ),
                ),
                const SizedBox(height: 6),
                l('a${i + 1}', _dim(10), maxLines: 1, align: TextAlign.center),
              ])),
          ]);
        }),
        const SizedBox(height: 8),
        l('now', _gold(12)),
        l('next', _dim(12)),
      ]));
    case 'benefitSplit':
      return _hpad(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _benefitCol(k, 'left', const ['l1', 'l2'], const Color(0xFF1C1C1C))),
        const SizedBox(width: 10),
        Expanded(child: _benefitCol(k, 'right', const ['r1', 'r2'], const Color(0xFF2A2418))),
      ]));
    case 'dropShelf':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 10),
        SizedBox(height: 196, child: ListView(scrollDirection: Axis.horizontal, children: [
          _dropCard(k, 'image', 't1', 'old1', 'p1', 'drop1'),
          _dropCard(k, 'image2', 't2', 'old2', 'p2', 'drop2'),
        ])),
      ]));
    case 'peekShelf':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _peek(k, 'image', 't1'),
            _peek(k, 'image2', 't2'),
            _peek(k, 'image3', 't3'),
          ]),
        ),
      ]));
    case 'lovedRow':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 10),
        SizedBox(height: 160, child: ListView(scrollDirection: Axis.horizontal, children: [
          _loved(k, 'image', 't1'),
          _loved(k, 'image2', 't2'),
        ])),
      ]));
    case 'shineLine':
      return _hpad(ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: const Color(0xFF1A1408),
          child: SizedBox(
            height: 48,
            child: MotionLoop(builder: (t) => Transform.translate(
                  offset: Offset(-180 + 360 * t, 0),
                  child: Align(alignment: Alignment.centerLeft, child: l('title', _gold(16))),
                )),
          ),
        ),
      ));
    case 'pulseCta':
      return _hpad(Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0xFF2A2418), Color(0xFF121212)]),
        ),
        child: Column(children: [
          l('title', _white(20), align: TextAlign.center),
          const SizedBox(height: 6),
          l('subtitle', _dim(13), align: TextAlign.center, maxLines: 2),
          const SizedBox(height: 12),
          MotionLoop(builder: (t) {
            final s = 1 + 0.04 * math.sin(t * math.pi * 2);
            return Transform.scale(scale: s, child: k.button());
          }),
        ]),
      ));
    case 'litSteps':
      return _hpad(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        l('title', _white(18)),
        const SizedBox(height: 12),
        MotionLoop(milliseconds: 3200, builder: (t) {
          final lit = (t * 4).floor() % 4;
          return Column(children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= lit ? const Color(0xFFE8D5A3) : const Color(0xFF2A2A2A),
                    ),
                    child: Text('${i + 1}', style: TextStyle(color: i <= lit ? const Color(0xFF121212) : Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: l('s${i + 1}', i <= lit ? _white(14) : _dim(14))),
                ]),
              ),
          ]);
        }),
      ]));
    default:
      return const SizedBox.shrink();
  }
}

Widget _hpad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

TextStyle _white(double s) => TextStyle(color: Colors.white, fontSize: s, fontWeight: FontWeight.w800);
TextStyle _gold(double s) => TextStyle(color: const Color(0xFFE8D5A3), fontSize: s, fontWeight: FontWeight.w800);
TextStyle _dim(double s) => TextStyle(color: const Color(0xB3FFFFFF), fontSize: s, fontWeight: FontWeight.w600);
TextStyle _dark(double s) => TextStyle(color: const Color(0xFF121212), fontSize: s, fontWeight: FontWeight.w800);

Widget _pill(Widget child, bool on) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on ? Colors.white : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? Colors.white : const Color(0x33FFFFFF)),
        ),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), child: child),
      ),
    );

Widget _offerCard(TplKit k, String image, String title, String off, double glow) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.lerp(const Color(0xFF6E5424), const Color(0xFFF3E2B0), glow)!, width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(fit: StackFit.expand, children: [
          k.picture(image),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xCC000000)]))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
              k.label(title, _white(16), maxLines: 1),
              k.label(off, _gold(12), maxLines: 1),
            ]),
          ),
        ]),
      ),
    );

Widget _saveCard(TplKit k, String image, String title, String price, String was) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 120, width: 150, child: k.picture(image))),
          const SizedBox(height: 6),
          k.label(title, _white(13), maxLines: 1),
          k.label(price, _gold(13), maxLines: 1),
          k.label(was, const TextStyle(color: Color(0x88FFFFFF), fontSize: 11, decoration: TextDecoration.lineThrough), maxLines: 1),
        ]),
      ),
    );

Widget _shineBox(double t, {required double height, required double radius, required List<Color> colors, required Widget child}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment(-1.4 + t * 2.8, -0.6),
        end: Alignment(-0.2 + t * 2.8, 0.8),
        colors: colors,
      ),
    ),
    child: child,
  );
}

Widget _miniDeal(TplKit k, String image, String title, String price) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF16181E), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 64, height: 64, child: k.picture(image))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            k.label(title, _white(13), maxLines: 1),
            k.label(price, _gold(13), maxLines: 1),
          ])),
        ]),
      ),
    );

Widget _benefitCol(TplKit k, String head, List<String> lines, Color bg) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        k.label(head, _gold(13)),
        const SizedBox(height: 8),
        for (final id in lines) ...[
          k.label(id, _white(13), maxLines: 3),
          const SizedBox(height: 6),
        ],
      ]),
    );

Widget _dropCard(TplKit k, String image, String title, String old, String price, String drop) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 160,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 96, width: 160, child: k.picture(image))),
          const SizedBox(height: 6),
          k.label(title, _white(13), maxLines: 1),
          k.label(old, const TextStyle(color: Color(0x88FFFFFF), fontSize: 11, decoration: TextDecoration.lineThrough), maxLines: 1),
          k.label(price, _gold(14), maxLines: 1),
          k.label(drop, const TextStyle(color: Color(0xFFB6F0C8), fontSize: 11), maxLines: 1),
        ]),
      ),
    );

Widget _peek(TplKit k, String image, String title) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 220,
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            k.picture(image),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]))),
            Positioned(left: 10, right: 10, bottom: 10, child: k.label(title, _white(14), maxLines: 1)),
          ]),
        ),
      ),
    );

Widget _loved(TplKit k, String image, String title) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 140,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 110, width: 140, child: k.picture(image))),
            const Positioned(right: 8, top: 8, child: Icon(Icons.favorite, color: Color(0xFFE8D5A3), size: 16)),
          ]),
          const SizedBox(height: 6),
          k.label(title, _white(13), maxLines: 1),
        ]),
      ),
    );

class _CurveTop extends CustomClipper<Path> {
  const _CurveTop();
  @override
  Path getClip(Size size) {
    final p = Path()
      ..moveTo(0, 28)
      ..quadraticBezierTo(size.width / 2, -8, size.width, 28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
