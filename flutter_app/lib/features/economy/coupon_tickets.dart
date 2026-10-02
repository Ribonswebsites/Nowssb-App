/// Two coupon faces, matching the black tickets: a wide cut-out strip,
/// and a portrait card that flips. Chance cards can win or lose.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/nwsb_coin_fly.dart';
import 'economy_api.dart';
import '../../admin/template/editable.dart';

class WideCouponData {
  const WideCouponData({
    required this.big,
    required this.mark,
    required this.side,
    required this.foot,
    required this.kicker,
    required this.banner,
    required this.line,
    required this.code,
    required this.copy,
    this.coins = 0,
  });

  final String big;
  final String mark;
  final String side;
  final String foot;
  final String kicker;
  final String banner;
  final String line;
  final String code;
  final String copy;
  final int coins;
}

class FlipCouponData {
  const FlipCouponData({
    required this.ribbon,
    required this.ribbonColor,
    required this.ribbonInk,
    required this.big,
    required this.mark,
    required this.side,
    required this.subtitle,
    required this.code,
    required this.copy,
    required this.codeColor,
    required this.fine,
    this.chance = false,
    this.winPercent = 0,
    this.winLabel = '',
    this.winCoins = 0,
  });

  final String ribbon;
  final Color ribbonColor;
  final Color ribbonInk;
  final String big;
  final String mark;
  final String side;
  final String subtitle;
  final String code;
  final String copy;
  final Color codeColor;
  final String fine;
  final bool chance;
  final int winPercent;
  final String winLabel;
  final int winCoins;
}

const _red = Color(0xFFD0122D);
const _gold = Color(0xFFF5C518);

const kWideCoupons = <WideCouponData>[
  WideCouponData(big: '20', mark: '%', side: 'OFF', foot: '', kicker: 'WORD COUPON', banner: '20% OFF A WORD', line: 'Cap ₹35. Does not stack.', code: 'SAVE20', copy: 'NWSB-SAVE20'),
  WideCouponData(big: '10', mark: '%', side: 'OFF', foot: 'ON A NAMED MEANING', kicker: 'MEANING COUPON', banner: '10% OFF A MEANING', line: 'Valid on one meaning.', code: 'MEAN10', copy: 'NWSB-MEAN10'),
  WideCouponData(big: '15', mark: '%', side: 'OFF', foot: 'ON THE MEANING STORE', kicker: 'MEANING COUPON', banner: '15% OFF MEANINGS', line: 'Cap ₹80. Catalogue, not cash.', code: 'MEAN15', copy: 'NWSB-MEAN15'),
  WideCouponData(big: '7', mark: '', side: 'DAYS', foot: 'BASIC SUBSCRIPTION', kicker: 'SUBSCRIPTION', banner: '7-DAY BASIC PASS', line: 'A gifted pass is not a rank.', code: 'BASIC7', copy: 'NWSB-BASIC7'),
  WideCouponData(big: '30', mark: '', side: 'DAYS', foot: 'STANDARD SUBSCRIPTION', kicker: 'SUBSCRIPTION', banner: '30-DAY STANDARD', line: 'Catalogue prize, not cash.', code: 'STD30', copy: 'NWSB-STD30'),
  WideCouponData(big: '7', mark: '', side: 'DAYS', foot: 'EBOOK PASS', kicker: 'SUBSCRIPTION', banner: '7-DAY EBOOK', line: 'After the trial has ended.', code: 'EBOOK7', copy: 'NWSB-EBOOK7'),
  WideCouponData(big: '7', mark: '', side: 'DAYS', foot: 'PREMIUM SUBSCRIPTION', kicker: 'SUBSCRIPTION', banner: '7-DAY PREMIUM', line: 'Higher tier. Not a rank key.', code: 'PREM7', copy: 'NWSB-PREM7'),
  WideCouponData(big: '3', mark: '', side: 'DAYS', foot: 'SIGNATURE PASS', kicker: 'EPIC COUPON', banner: '3-DAY SIGNATURE', line: 'Does not unlock Partner.', code: 'SIG3', copy: 'NWSB-SIG3'),
  WideCouponData(big: '1', mark: '', side: 'WORD', foot: 'A FULL WORD', kicker: 'WORD COUPON', banner: 'ONE FULL WORD', line: 'One named word. Not cash.', code: 'WORD1', copy: 'NWSB-WORD1'),
  WideCouponData(big: '1', mark: '', side: 'MEAN', foot: 'ONE NAMED WORD', kicker: 'MEANING COUPON', banner: 'ONE MEANING', line: 'One meaning of a named word.', code: 'MEAN1', copy: 'NWSB-MEAN1'),
  WideCouponData(big: '1', mark: '', side: 'STAGE', foot: 'A LOCKED STAGE', kicker: 'WORD COUPON', banner: 'ONE LOCKED STAGE', line: 'One stage of a named word.', code: 'STAGE', copy: 'NWSB-STAGE'),
  WideCouponData(big: '20', mark: '%', side: 'OFF', foot: 'AN EPIC WORD', kicker: 'EPIC COUPON', banner: '20% OFF EPIC', line: 'Cap ₹150. Does not stack.', code: 'EPIC20', copy: 'NWSB-EPIC20'),
  WideCouponData(big: '5', mark: '', side: 'COINS', foot: 'OPEN THE APP', kicker: 'DISCOUNT COUPON', banner: '5 COINS TODAY', line: 'Once a day. Not cash.', code: 'OPEN5', copy: 'NWSB-OPEN5', coins: 5),
  WideCouponData(big: '8', mark: '', side: 'COINS', foot: 'READ ONE MEANING', kicker: 'MEANING COUPON', banner: '8 COINS A READ', line: 'Three a day.', code: 'READ8', copy: 'NWSB-READ8', coins: 8),
  WideCouponData(big: '50', mark: '', side: 'COINS', foot: 'A FIRST PURCHASE', kicker: 'DISCOUNT COUPON', banner: 'WELCOME SET', line: '50 coins and one scratch.', code: 'HELLO', copy: 'NWSB-HELLO', coins: 50),
];

const kFlipCoupons = <FlipCouponData>[
  FlipCouponData(ribbon: 'LIMITED TIME OFFER!', ribbonColor: _red, ribbonInk: Colors.white, big: '20', mark: '%', side: 'OFF', subtitle: 'YOUR NEXT WORD', code: 'SAVE20', copy: 'NWSB-SAVE20', codeColor: _red, fine: 'Valid on a word. Not cash. See the code again on the back.'),
  FlipCouponData(ribbon: 'SPECIAL OFFER!', ribbonColor: _gold, ribbonInk: Colors.black, big: '10', mark: '%', side: 'OFF', subtitle: 'WHEN YOU OPEN A MEANING', code: 'SAVE10', copy: 'NWSB-SAVE10', codeColor: Color(0xFFC9A227), fine: 'Meaning coupon. Cap ₹35. Does not stack.'),
  FlipCouponData(ribbon: 'LIMITED TIME OFFER!', ribbonColor: _red, ribbonInk: Colors.white, big: '7', mark: '', side: 'DAY', subtitle: 'BASIC SUBSCRIPTION', code: 'SUB7', copy: 'NWSB-SUB7', codeColor: _red, fine: 'Subscription coupon. A gifted pass does not unlock a rank.'),
  FlipCouponData(ribbon: 'SPECIAL OFFER!', ribbonColor: _gold, ribbonInk: Colors.black, big: '30', mark: '', side: 'DAY', subtitle: 'STANDARD SUBSCRIPTION', code: 'SUB30', copy: 'NWSB-SUB30', codeColor: Color(0xFFC9A227), fine: '30-day Standard. Catalogue prize, not cash.'),
  FlipCouponData(ribbon: 'LIMITED TIME OFFER!', ribbonColor: _red, ribbonInk: Colors.white, big: '1', mark: '', side: 'WORD', subtitle: 'A FULL WORD', code: 'WORD1', copy: 'NWSB-FLIPWORD', codeColor: _red, fine: 'Word coupon. One named word on this account.'),
  FlipCouponData(ribbon: 'SPECIAL OFFER!', ribbonColor: _gold, ribbonInk: Colors.black, big: '1', mark: '', side: 'MEAN', subtitle: 'ONE NAMED MEANING', code: 'MEAN1', copy: 'NWSB-FLIPMEAN', codeColor: Color(0xFFC9A227), fine: 'Meaning coupon. One meaning. Not cash.'),
  FlipCouponData(ribbon: 'EPIC COUPON', ribbonColor: _red, ribbonInk: Colors.white, big: '7', mark: '', side: 'DAY', subtitle: 'PREMIUM SUBSCRIPTION', code: 'PREM7', copy: 'NWSB-PREM7F', codeColor: _red, fine: 'Premium days. Higher tier. Not a rank key.'),
  FlipCouponData(ribbon: 'SPECIAL OFFER!', ribbonColor: _gold, ribbonInk: Colors.black, big: '3', mark: '', side: 'DAY', subtitle: 'SIGNATURE PASS', code: 'SIG3', copy: 'NWSB-SIG3F', codeColor: Color(0xFFC9A227), fine: 'Does not unlock Partner. Not cash.'),
  FlipCouponData(ribbon: 'TAKE A CHANCE', ribbonColor: _red, ribbonInk: Colors.white, big: '1', mark: '', side: 'WORD', subtitle: 'WIN OR LOSE', code: '????', copy: 'NWSB-CHANCE-WORD', codeColor: _red, fine: 'Word chance. You can win or lose.', chance: true, winPercent: 35, winLabel: 'One full word'),
  FlipCouponData(ribbon: 'TAKE A CHANCE', ribbonColor: _gold, ribbonInk: Colors.black, big: '1', mark: '', side: 'MEAN', subtitle: 'WIN OR LOSE', code: '????', copy: 'NWSB-CHANCE-MEAN', codeColor: Color(0xFFC9A227), fine: 'Meaning chance. You can win or lose.', chance: true, winPercent: 40, winLabel: 'One meaning'),
  FlipCouponData(ribbon: 'TAKE A CHANCE', ribbonColor: _gold, ribbonInk: Colors.black, big: '7', mark: '', side: 'DAY', subtitle: 'SUBSCRIPTION', code: '????', copy: 'NWSB-CHANCE-SUB', codeColor: Color(0xFFC9A227), fine: 'Subscription chance. You can win or lose.', chance: true, winPercent: 18, winLabel: '7-day Premium'),
  FlipCouponData(ribbon: 'EPIC CHANCE', ribbonColor: _red, ribbonInk: Colors.white, big: '3', mark: '', side: 'DAY', subtitle: 'SIGNATURE OR NOTHING', code: '????', copy: 'NWSB-CHANCE-EPIC', codeColor: _red, fine: 'Epic chance. You can win or lose.', chance: true, winPercent: 8, winLabel: '3-day Signature'),
  FlipCouponData(ribbon: 'EPIC CHANCE', ribbonColor: _red, ribbonInk: Colors.white, big: '20', mark: '%', side: 'OFF', subtitle: 'AN EPIC WORD', code: '????', copy: 'NWSB-CHANCE-E20', codeColor: _red, fine: 'Epic word chance. You can win or lose.', chance: true, winPercent: 12, winLabel: '20% off an Epic word'),
  FlipCouponData(ribbon: 'TAKE A CHANCE', ribbonColor: _gold, ribbonInk: Colors.black, big: '20', mark: '', side: 'COIN', subtitle: 'WIN OR LOSE', code: '????', copy: 'NWSB-CHANCE-COIN', codeColor: Color(0xFFC9A227), fine: 'Coin chance. You can win or lose.', chance: true, winPercent: 25, winLabel: '20 coins', winCoins: 20),
];

String couponExpiry() {
  final d = DateTime.now().add(const Duration(days: 30));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$m/$day/${d.year}';
}

String couponDigits(String code) {
  final n = code.hashCode.abs().toString().padLeft(12, '0');
  return n.substring(n.length - 12);
}

/// Both rows. The first scrolls sideways. The second flips.
class CouponRails extends StatelessWidget {
  const CouponRails({super.key});

  @override
  Widget build(BuildContext context) {
    final expires = couponExpiry();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cardW = (maxW * 0.74).clamp(188.0, 250.0);
        final cardH = cardW * 1.9;
        return SizedBox(
          height: cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: kFlipCoupons.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    child: EditableImage.asset(
                      'assets/gifts/coupon-hero.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                      slot: 'coupon_tickets.CouponRails',
                    ),
                  ),
                );
              }
              return FlipCoupon(
                data: kFlipCoupons[i - 1],
                width: cardW,
                height: cardH,
                expires: expires,
              );
            },
          ),
        );
      },
    );
  }
}

class WideCoupon extends StatefulWidget {
  const WideCoupon({
    super.key,
    required this.data,
    required this.width,
    required this.expires,
    required this.scissorsLeft,
  });

  final WideCouponData data;
  final double width;
  final String expires;
  final bool scissorsLeft;

  @override
  State<WideCoupon> createState() => _WideCouponState();
}

class _WideCouponState extends State<WideCoupon> {
  var _copied = false;

  Future<void> _take() async {
    await Clipboard.setData(ClipboardData(text: widget.data.copy));
    HapticFeedback.selectionClick();
    if (widget.data.coins > 0) {
      final before = EconomyMirror.instance.coins;
      var gained = 0;
      try {
        gained = await EconomyMirror.instance.grantOnce('coupon_${widget.data.copy}', widget.data.coins);
      } catch (_) {
        gained = 0;
      }
      if (gained > 0 && mounted) {
        await NwsbCoinFly.show(context, coins: gained, from: before, to: before + gained);
      }
    }
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTap: _take,
      child: SizedBox(
        width: widget.width,
        height: 168,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _DashBorder())),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: widget.width * 0.36,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _OfferLockup(big: d.big, mark: d.mark, side: d.side, foot: d.foot, huge: 48),
                      ),
                    ),
                    Container(width: 1, height: 112, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(d.kicker, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8)),
                          const SizedBox(height: 4),
                          _Chevron(text: d.banner),
                          const SizedBox(height: 4),
                          Text(d.line, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.2)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.1)),
                            child: Text(
                              _copied ? 'COPIED' : 'CODE: ${d.code}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text('EXPIRES: ${widget.expires}', maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 8, letterSpacing: 0.6)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SideBarcode(code: d.copy),
                  ],
                ),
              ),
              Positioned(
                left: widget.scissorsLeft ? 4 : null,
                right: widget.scissorsLeft ? null : 4,
                top: widget.scissorsLeft ? 2 : null,
                bottom: widget.scissorsLeft ? null : 2,
                child: const CustomPaint(size: Size(22, 22), painter: _Scissors()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlipCoupon extends StatefulWidget {
  const FlipCoupon({
    super.key,
    required this.data,
    required this.width,
    required this.height,
    required this.expires,
  });

  final FlipCouponData data;
  final double width;
  final double height;
  final String expires;

  @override
  State<FlipCoupon> createState() => _FlipCouponState();
}

class _FlipCouponState extends State<FlipCoupon> with SingleTickerProviderStateMixin {
  late final AnimationController _turn;
  var _showBack = false;
  var _busy = false;
  var _touched = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _load();
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  String get _day {
    final n = DateTime.now();
    return '${n.year}${n.month}${n.day}';
  }

  String get _key => widget.data.chance ? 'nwsb_cflip_${widget.data.copy}_$_day' : 'nwsb_copen_${widget.data.copy}';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (!mounted || _touched || saved == null) return;
      setState(() {
        _result = saved;
        _showBack = true;
        _turn.value = 1;
      });
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_busy) return;
    _touched = true;
    setState(() => _busy = true);
    final d = widget.data;
    var fly = 0;
    var before = 0;
    if (!_showBack && d.chance && _result == null) {
      final win = Random().nextInt(100) < d.winPercent;
      _result = win ? 'win' : 'lose';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, _result!);
        if (win && d.winCoins > 0) {
          before = EconomyMirror.instance.coins;
          fly = await EconomyMirror.instance.grantOnce('coupon_${d.copy}', d.winCoins);
        }
      } catch (_) {}
    }
    if (_showBack) {
      await _turn.reverse();
      if (mounted) setState(() { _showBack = false; _busy = false; });
    } else {
      await _turn.forward();
      if (mounted) setState(() { _showBack = true; _busy = false; });
      if (fly > 0 && mounted) {
        await NwsbCoinFly.show(context, coins: fly, from: before, to: before + fly);
      }
    }
  }

  Future<void> _copy() async {
    final d = widget.data;
    if (d.chance && _result != 'win') return;
    await Clipboard.setData(ClipboardData(text: d.copy));
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _turn,
        builder: (context, _) {
          final angle = _turn.value * pi;
          final back = angle > pi / 2;
          final face = back
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _back(),
                )
              : _front();
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(angle),
            child: face,
          );
        },
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _DashBorder())),
            Padding(padding: const EdgeInsets.fromLTRB(12, 18, 12, 10), child: child),
            const Positioned(left: 6, top: 4, child: CustomPaint(size: Size(20, 20), painter: _Scissors())),
          ],
        ),
      ),
    );
  }

  Widget _front() {
    final d = widget.data;
    final shown = d.chance && _result == null ? '????' : (d.chance && _result == 'lose' ? 'LOSE' : d.code);
    final fine = d.chance ? 'Win ${d.winPercent}% or lose. Odds stay on this card.' : d.fine;
    return _shell(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: EditableImage.asset(
              'assets/gifts/coupon-banner.png',
              height: 52,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.2),
              errorBuilder: (_, __, ___) => const SizedBox(height: 52),
              slot: 'coupon_tickets.FlipCoupon',
            ),
          ),
          const SizedBox(height: 6),
          _Ribbon(text: d.ribbon, color: d.ribbonColor, ink: d.ribbonInk),
          const Spacer(),
          SizedBox(
            height: 78,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _OfferLockup(big: d.big, mark: d.mark, side: d.side, foot: '', huge: 58, center: true),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: ColoredBox(color: Colors.white, child: SizedBox(height: 1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(d.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              ),
              const Expanded(child: ColoredBox(color: Colors.white, child: SizedBox(height: 1))),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFFF4F4F4), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EditableLabel('coupon_tickets.FlipCoupon', 'COUPON CODE:  ', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w700)),
                Flexible(
                  child: Text(shown, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: d.codeColor, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(fine, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 8, height: 1.25)),
          const SizedBox(height: 6),
          _BarcodePill(code: d.copy),
          const SizedBox(height: 4),
          Text('EXPIRES: ${widget.expires}', style: const TextStyle(color: Colors.white, fontSize: 8, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _back() {
    final d = widget.data;
    final lose = d.chance && _result == 'lose';
    final win = d.chance && _result == 'win';
    final title = lose ? 'LOSE' : (win ? 'WIN' : d.code);
    final line = lose
        ? 'No prize. This card can lose.'
        : (win ? d.winLabel : 'On this account. Not cash.');
    return _shell(
      child: Column(
        children: [
          const EditableLabel('coupon_tickets.FlipCoupon', 'NOWSSB', style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w800)),
          const Spacer(),
          EditableLabel('coupon_tickets.FlipCoupon', title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 0.95)),
          const SizedBox(height: 8),
          Text(line, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
          if (!lose)
            GestureDetector(
              onTap: _copy,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Column(
                  children: [
                    Text(
                      d.chance ? d.copy : 'CODE: ${d.code}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF5C518), fontWeight: FontWeight.w800, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    const EditableLabel('coupon_tickets.FlipCoupon', 'TAP CODE TO COPY', style: TextStyle(color: Colors.white, fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          _BarcodePill(code: d.copy),
          const SizedBox(height: 4),
          const EditableLabel('coupon_tickets.FlipCoupon', 'Flip back. Not a rank key.', style: TextStyle(color: Colors.white70, fontSize: 8)),
        ],
      ),
    );
  }
}

class _OfferLockup extends StatelessWidget {
  const _OfferLockup({
    required this.big,
    required this.mark,
    required this.side,
    required this.foot,
    required this.huge,
    this.center = false,
  });

  final String big;
  final String mark;
  final String side;
  final String foot;
  final double huge;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(big, style: TextStyle(color: Colors.white, fontSize: huge, fontWeight: FontWeight.w800, height: 0.82, letterSpacing: -1.5)),
        const SizedBox(width: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mark.isNotEmpty)
              Text(mark, style: TextStyle(color: Colors.white, fontSize: huge * 0.42, fontWeight: FontWeight.w700, height: 1)),
            Text(side, style: TextStyle(color: Colors.white, fontSize: huge * 0.32, fontWeight: FontWeight.w800, height: 1, letterSpacing: 0.4)),
          ],
        ),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        row,
        if (foot.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(foot, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2, height: 1.15)),
        ],
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ChevronPaint(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
        child: EditableLabel('coupon_tickets.Chevron', text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      ),
    );
  }
}

class _ChevronPaint extends CustomPainter {
  const _ChevronPaint();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 6, size.height / 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(6, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ChevronPaint old) => false;
}

class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.text, required this.color, required this.ink});
  final String text;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonPaint(color),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: EditableLabel('coupon_tickets.Ribbon', text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      ),
    );
  }
}

class _RibbonPaint extends CustomPainter {
  const _RibbonPaint(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, 0)
      ..lineTo(size.width - 8, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 8, size.height)
      ..lineTo(8, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPaint old) => old.color != color;
}

class _SideBarcode extends StatelessWidget {
  const _SideBarcode({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 118,
      child: Row(
        children: [
          SizedBox(width: 22, height: 118, child: CustomPaint(painter: _Bars(code, Colors.white))),
          const SizedBox(width: 2),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(couponDigits(code), style: const TextStyle(color: Colors.white, fontSize: 8, letterSpacing: 0.6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePill extends StatelessWidget {
  const _BarcodePill({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Column(
        children: [
          SizedBox(height: 26, width: double.infinity, child: CustomPaint(painter: _Bars(code, Colors.black))),
          const SizedBox(height: 2),
          Text(couponDigits(code), style: const TextStyle(color: Colors.black, fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Bars extends CustomPainter {
  const _Bars(this.seed, this.color);
  final String seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed.hashCode);
    final paint = Paint()..color = color;
    var x = 0.0;
    while (x < size.width) {
      final w = 1.0 + rnd.nextInt(3);
      if (rnd.nextBool()) {
        canvas.drawRect(Rect.fromLTWH(x, 0, w.toDouble(), size.height), paint);
      }
      x += w + 1;
    }
  }

  @override
  bool shouldRepaint(_Bars old) => old.seed != seed || old.color != color;
}

class _DashBorder extends CustomPainter {
  const _DashBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, min(d + 6, metric.length)), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashBorder old) => false;
}

class _Scissors extends CustomPainter {
  const _Scissors();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.78), Offset(size.width * 0.88, size.height * 0.18), p);
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.22), Offset(size.width * 0.88, size.height * 0.82), p);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.26), 3.1, p);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.74), 3.1, p);
  }

  @override
  bool shouldRepaint(_Scissors old) => false;
}
