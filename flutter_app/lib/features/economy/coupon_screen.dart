/// Coupons from the plan: a free scratch, standing codes, and three paid
/// cards whose odds are on the card before the draw.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/tokens.dart';
import '../../widgets/four_banners.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/program_shelf.dart';
import 'economy_api.dart';
import 'economy_theme.dart';
import 'scratch_card.dart';

class _Prize {
  const _Prize(this.label, this.weight, this.coins);
  final String label;
  final int weight;
  final int coins;
}

class _DrawCard {
  const _DrawCard(this.tier, this.price, this.ev, this.rare, this.odds, this.prizes);
  final String tier;
  final String price;
  final String ev;
  final String rare;
  final String odds;
  final List<_Prize> prizes;
}

const _draws = <_DrawCard>[
  _DrawCard('Common', '₹49', 'about ₹19', 'Signature word', '0.2%', [
    _Prize('Coins, small', 550, 12),
    _Prize('10% off, cap ₹35', 250, 0),
    _Prize('Stage token', 120, 0),
    _Prize('7-day Basic or ebook', 60, 0),
    _Prize('30-day Standard', 18, 0),
    _Prize('Signature word', 2, 0),
  ]),
  _DrawCard('Rare', '₹149', 'about ₹55', '10-word bundle', '1.0%', [
    _Prize('Coins, small', 300, 20),
    _Prize('15% off, cap ₹80', 280, 0),
    _Prize('Stage token', 180, 0),
    _Prize('7-day Basic or ebook', 120, 0),
    _Prize('30-day Standard', 80, 0),
    _Prize('10-word bundle', 10, 0),
    _Prize('Signature word', 25, 0),
    _Prize('2-month Signature', 5, 0),
  ]),
  _DrawCard('Epic', '₹399', 'about ₹150', '2-month Signature', '0.4%', [
    _Prize('Coins, small', 200, 40),
    _Prize('20% off, cap ₹150', 240, 0),
    _Prize('Stage token', 180, 0),
    _Prize('7-day Basic or ebook', 140, 0),
    _Prize('30-day Standard', 120, 0),
    _Prize('10-word bundle', 60, 0),
    _Prize('Signature word', 56, 0),
    _Prize('2-month Signature', 4, 0),
  ]),
];

class _Held {
  const _Held(this.code, this.title, this.line);
  final String code;
  final String title;
  final String line;
}

const _held = <_Held>[
  _Held('NWSB-OPEN5', 'Open the app', '5 coins · once a day'),
  _Held('NWSB-READ8', 'Read one meaning', '8 coins · three a day'),
  _Held('NWSB-WORD10', '10% off a word', 'Cap ₹35 · 30 days · does not stack'),
  _Held('NWSB-STAGE', 'Stage token', 'One locked stage of a named word'),
  _Held('NWSB-EBOOK7', '7-day ebook pass', 'After the trial has ended'),
  _Held('NWSB-BASIC7', '7-day Basic', 'A gifted pass does not unlock a rank'),
  _Held('NWSB-STD30', '30-day Standard', 'Catalogue prize, not cash'),
  _Held('NWSB-HELLO', 'Welcome set', '50 coins and one scratch on a first purchase'),
];

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
      title: 'NowssB Coupons',
      mark: NwsbMarks.coupon,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const FourBanners(
            splitTitle: 'Coupons',
            splitCta: 'Scratch',
            blackTitle: 'Odds on the card',
            blackSub: 'A free scratch, and three paid cards. Nothing is cash.',
          ),
          const SizedBox(height: 12),
          const GlassLine(
            text: 'Free scratch after a purchase. Paid cards show every prize before you draw. Expected value stays under the price.',
            mark: NwsbMarks.coupon,
          ),
          const SizedBox(height: 16),
          const Text('FREE SCRATCH', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          NwsbScratchCard(
            onCleared: _clearedNow,
            prize: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(NwsbCoinFly.disc, width: 36, height: 36, fit: BoxFit.contain),
                const SizedBox(height: 6),
                Text('+$_coins', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const Text('NOWSSB COINS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: NwsbColors.goldLight)),
          ],
          const SizedBox(height: 18),
          const Text('YOUR CODES', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GlassWrap(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var r = 0; r < _held.length; r += 2) ...[
                  if (r > 0) const Divider(height: 1, thickness: 1, color: Color(0x33FFFFFF)),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _Ticket(held: _held[r])),
                        const VerticalDivider(width: 1, thickness: 1, color: Color(0x33FFFFFF)),
                        Expanded(
                          child: r + 1 < _held.length ? _Ticket(held: _held[r + 1]) : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('PAID CARDS', style: TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Odds are fixed until a published change. A Signature prize does not unlock a rank rate.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          for (final d in _draws) ...[
            _PaidCard(card: d),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Ticket extends StatefulWidget {
  const _Ticket({required this.held});
  final _Held held;

  @override
  State<_Ticket> createState() => _TicketState();
}

class _TicketState extends State<_Ticket> with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  var _open = false;
  var _busy = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _take() async {
    if (_busy || _open) return;
    setState(() => _busy = true);
    await _flip.forward(from: 0);
    final h = widget.held;
    final coins = h.code == 'NWSB-OPEN5'
        ? 5
        : h.code == 'NWSB-READ8'
            ? 8
            : h.code == 'NWSB-HELLO'
                ? 50
                : 0;
    var gained = 0;
    if (coins > 0) {
      final before = EconomyMirror.instance.coins;
      gained = await EconomyMirror.instance.grantOnce('coupon_${h.code}', coins);
      if (gained > 0 && mounted) {
        await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
      }
    }
    if (!mounted) return;
    setState(() {
      _open = true;
      _busy = false;
      _note = gained > 0 ? '+$gained coins' : 'Code ${h.code}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.held;
    return GestureDetector(
      onTap: () async {
        if (_open) {
          await Clipboard.setData(ClipboardData(text: widget.held.code));
          HapticFeedback.selectionClick();
          if (mounted) setState(() => _note = 'Copied');
          return;
        }
        await _take();
      },
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = _flip.value;
          final torn = t > 0.55 || _open;
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              children: [
                NwsbIcon(NwsbMarks.coupon, size: 18, color: const Color(0xFFE4C56A)),
                const SizedBox(height: 6),
                Text(h.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 8,
                  width: double.infinity,
                  child: CustomPaint(painter: _Dash()),
                ),
                const SizedBox(height: 6),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: torn ? 1 : 0.0,
                    child: Transform.translate(
                      offset: Offset((1 - t) * 18, 0),
                      child: Opacity(
                        opacity: t,
                        child: Text(
                          _note ?? h.code,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!torn)
                  const Text('Tear open', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Dash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66E4C56A)
      ..strokeWidth = 1;
    const dash = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 4), Offset(min(x + dash, size.width), 4), paint);
      x += dash * 2;
    }
  }

  @override
  bool shouldRepaint(_Dash old) => false;
}

class _PaidCard extends StatefulWidget {
  const _PaidCard({required this.card});
  final _DrawCard card;

  @override
  State<_PaidCard> createState() => _PaidCardState();
}

class _PaidCardState extends State<_PaidCard> {
  var _busy = false;
  String? _landed;
  String? _code;
  int _tick = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _day {
    final n = DateTime.now();
    return '${n.year}${n.month}${n.day}';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('nwsb_cdraw_${widget.card.tier}_$_day');
    if (saved != null && mounted) {
      final parts = saved.split('|');
      setState(() {
        _landed = parts.first;
        _code = parts.length > 1 ? parts[1] : null;
      });
    }
  }

  _Prize _pick() {
    final prizes = widget.card.prizes;
    final total = prizes.fold<int>(0, (s, p) => s + p.weight);
    var roll = Random().nextInt(total);
    for (final p in prizes) {
      if (roll < p.weight) return p;
      roll -= p.weight;
    }
    return prizes.first;
  }

  Future<void> _draw() async {
    if (_busy || _landed != null) return;
    setState(() => _busy = true);
    final prize = _pick();
    final code = 'NWSB-${widget.card.tier.substring(0, 1)}${Random().nextInt(9000) + 1000}';
    var i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _tick = i);
      i++;
      if (i > 16) t.cancel();
    });
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nwsb_cdraw_${widget.card.tier}_$_day', '${prize.label}|$code');
    var gained = 0;
    final before = EconomyMirror.instance.coins;
    if (prize.coins > 0) {
      gained = await EconomyMirror.instance.grantOnce('draw_${widget.card.tier}', prize.coins);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _landed = prize.label;
      _code = code;
    });
    HapticFeedback.mediumImpact();
    if (gained > 0 && mounted) {
      await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final flashing = _busy ? card.prizes[_tick % card.prizes.length].label : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x66E4C56A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(card.tier.toUpperCase(), style: const TextStyle(color: Color(0xFFE4C56A), fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const Spacer(),
              Text(card.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Expected value ${card.ev} · rarest ${card.rare} · ${card.odds}', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
          const SizedBox(height: 10),
          for (final p in card.prizes)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(child: Text(p.label, style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Text('${(p.weight / 10).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFE4C56A), fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            flashing ?? _landed ?? 'Odds stay on this card. Draw once today.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          if (_code != null)
            Text(_code!, style: const TextStyle(color: Color(0xFFE4C56A), letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          GoldButton(
            label: _landed != null ? 'Drawn today' : (_busy ? 'Drawing…' : 'Draw ${card.tier}'),
            onTap: (_landed != null || _busy) ? null : _draw,
          ),
        ],
      ),
    );
  }
}
