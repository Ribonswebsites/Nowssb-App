/// Coupons, rewards, gifts and the store lanes, laid out like the coin-shop
/// screens. Colours and card shapes follow those screens. The offers are NowssB.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../screens/store/product_detail.dart';
import '../../shell/nwsb_links.dart';
import 'coupon_tickets.dart';
import 'economy_api.dart';

const _blue = Color(0xFF2874F0);
const _ink = Color(0xFF212121);
const _muted = Color(0xFF878787);
const _purple = Color(0xFF5E2B9B);

const _arts = <String>[
  'assets/store/intro-words.webp',
  'assets/store/intro-meanings.webp',
  'assets/store/intro-signature.webp',
  'assets/store/intro-ebooks.webp',
  'assets/store/nowssb-bag-headphones.webp',
  'assets/store/picker-words.png',
  'assets/store/picker-meaning.png',
  'assets/store/picker-ebooks.png',
];

class ShopBar extends StatelessWidget implements PreferredSizeWidget {
  const ShopBar({super.key, required this.title, required this.color, this.trailing, this.light = false, this.actions});
  final String title;
  final Color color;
  final Widget? trailing;
  final bool light;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final fg = light ? _ink : Colors.white;
    return Material(
      color: color,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.maybePop(context), icon: Icon(Icons.arrow_back, color: fg)),
              Expanded(child: Text(title, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w600))),
              if (actions != null) ...actions!,
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: DefaultTextStyle.merge(style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600), child: trailing!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPage extends StatelessWidget {
  const _GlassPage({required this.wash, required this.bar, required this.child});
  final Color wash;
  final PreferredSizeWidget bar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wash,
      appBar: bar,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CouponsFace extends StatefulWidget {
  const CouponsFace({super.key, this.scratch});
  final Widget? scratch;
  @override
  State<CouponsFace> createState() => _CouponsFaceState();
}

class _CouponsFaceState extends State<CouponsFace> {
  final _code = TextEditingController();
  var _filter = 'All';

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  List<WideCouponData> get _list {
    if (_filter == 'All') return kWideCoupons;
    return kWideCoupons.where((c) => c.kicker.toLowerCase().contains(_filter.toLowerCase())).toList();
  }

  Future<void> _add(String code) async {
    final raw = code.trim();
    if (raw.isEmpty) return;
    try {
      final r = await EconomyApi.call('claimTicket', {'code': raw});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['how'] ?? r['title'] ?? 'Coupon added'}')));
    } on EconomyException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _open(WideCouponData c) {
    final k = c.kicker.toUpperCase();
    if (k.contains('MEAN')) {
      NwsbLinks.meanings(context);
    } else if (k.contains('SUB') || k.contains('EPIC')) {
      NwsbLinks.subscription(context);
    } else if (k.contains('EBOOK')) {
      NwsbLinks.ebooks(context);
    } else {
      final w = kRmCategories.first.words.first;
      openAtelierWord(context, word: w.word, root: w.root, img: _arts.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return _GlassPage(
      wash: const Color(0xFFD2B4F5),
      bar: const ShopBar(title: 'My Coupons', color: Colors.white, light: true),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                const _CouponHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE4E4E4))),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _code,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(hintText: 'Enter coupon code', hintStyle: TextStyle(color: Color(0xFFB0B0B0)), border: InputBorder.none),
                          ),
                        ),
                        TextButton(onPressed: () => _add(_code.text), child: const Text('Add coupon', style: TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 15))),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
                  child: Text('Save more with coupons', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _DropChip(label: 'Categories', on: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
                      const SizedBox(width: 8),
                      _DropChip(label: 'Brands', on: _filter != 'All', onTap: () => setState(() => _filter = _filter == 'WORD' ? 'MEANING' : 'WORD')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _OfferRow(data: list[i], art: _arts[i % _arts.length], fresh: i.isEven, onUse: () => _add(list[i].copy), onOpen: () => _open(list[i])),
                        Positioned(
                          left: 36,
                          top: -9,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFEDEDED), width: 4), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2)]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 12,
            shadowColor: Colors.black26,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: _Foot(icon: Icons.card_giftcard, tint: const Color(0xFFE91E63), label: 'All rewards', onTap: () => Navigator.maybePop(context))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Foot(
                        icon: Icons.confirmation_number,
                        tint: const Color(0xFFF5A623),
                        label: 'Scratch cards',
                        onTap: widget.scratch == null
                            ? null
                            : () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: const Color(0xFF141820),
                                  builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), child: widget.scratch!),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponHero extends StatelessWidget {
  const _CouponHero();
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeroCurve(),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.05, colors: [Color(0xFFF8F4FF), Color(0xFFE6D4FF), Color(0xFFD2B4F5)]),
        ),
        child: const Column(
          children: [
            SizedBox(height: 8),
            Text('✦   Level up your savings   ✦', style: TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
            SizedBox(height: 6),
            Text('COUPONS FOR YOU', style: TextStyle(color: _purple, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
            SizedBox(height: 10),
            _CountPill(),
            SizedBox(height: 8),
            _TicketPair(),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFD7C2F5), borderRadius: BorderRadius.circular(20)),
      child: Text('You have ${kWideCoupons.length} coupons', style: const TextStyle(color: _purple, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class _HeroCurve extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(size.width / 2, size.height + 10, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DropChip extends StatelessWidget {
  const _DropChip({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: on ? _purple : const Color(0xFFE0E0E0))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: on ? _purple : _ink, fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: on ? _purple : _muted),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.data, required this.art, required this.fresh, required this.onUse, required this.onOpen});
  final WideCouponData data;
  final String art;
  final bool fresh;
  final VoidCallback onUse;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final festive = data.kicker.toUpperCase().contains('WORD');
    return Material(
      color: const Color(0xFFF4EEFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onUse,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(art, width: 96, height: 96, fit: BoxFit.cover)),
                  if (fresh)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(4)),
                        child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(festive ? 'Festive offer' : 'Special discount', style: const TextStyle(color: _muted, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(data.banner, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800, height: 1.15)),
                    const SizedBox(height: 2),
                    Text(data.line, maxLines: 2, style: const TextStyle(color: _muted, fontSize: 12, height: 1.25)),
                    const SizedBox(height: 6),
                    GestureDetector(onTap: onOpen, child: const Text('View products  ›', style: TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 14))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketPair extends StatelessWidget {
  const _TicketPair();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(left: 78, top: 16, child: Transform.rotate(angle: -0.22, child: const _Stub(color: Color(0xFF6A35C9)))),
          Positioned(right: 78, top: 6, child: Transform.rotate(angle: 0.28, child: const _Stub(color: Color(0xFF512DA8)))),
        ],
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  const _Stub({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TornTop(),
      child: Container(
        width: 132,
        height: 86,
        color: color,
        alignment: Alignment.center,
        child: const Text('%', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _TornTop extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..moveTo(0, 16);
    for (var x = 0.0; x < size.width; x += 16) {
      p.quadraticBezierTo(x + 8, x % 32 == 0 ? 0 : 18, x + 16, 16);
    }
    p
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Foot extends StatelessWidget {
  const _Foot({required this.icon, required this.tint, required this.label, this.onTap});
  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: const BorderSide(color: Color(0xFFE6E6E6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
      ),
      icon: Icon(icon, color: tint, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class RewardsFace extends StatefulWidget {
  const RewardsFace({super.key, this.onCoupons});
  final VoidCallback? onCoupons;
  @override
  State<RewardsFace> createState() => _RewardsFaceState();
}

class _RewardsFaceState extends State<RewardsFace> {
  var _chip = 0;
  static const _names = ['All', 'Coin Zone', 'Practice', 'Gifts'];

  @override
  Widget build(BuildContext context) {
    return _GlassPage(
      wash: const Color(0xFF2874F0),
      bar: ShopBar(title: 'My Rewards', color: _blue, trailing: GestureDetector(onTap: widget.onCoupons, child: const Text('Add Coupon'))),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              children: [
                for (var i = 0; i < _names.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _chip = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _chip == i ? _blue : const Color(0xFFD0D0D0), width: _chip == i ? 1.6 : 1),
                        ),
                        child: Text(_names[i], style: TextStyle(color: _chip == i ? _blue : _ink, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_chip == 2) return const _EmptyRewards();
    if (_chip == 1) return _CoinZone(onCoupons: widget.onCoupons);
    return _RewardGrid(giftsOnly: _chip == 3, onTap: widget.onCoupons);
  }
}

class _EmptyRewards extends StatelessWidget {
  const _EmptyRewards();
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BoltCoin(size: 96),
            const SizedBox(height: 22),
            const Text('No coin rewards yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _blue, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
              onPressed: () => NwsbLinks.tab(context, 1),
              child: const Text('Open Practice', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoltCoin extends StatelessWidget {
  const _BoltCoin({this.size = 64});
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.cloud_outlined, color: const Color(0xFFD5DCE6), size: size * 0.9),
          Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
            child: Icon(Icons.bolt, color: Colors.white, size: size * 0.3),
          ),
        ],
      ),
    );
  }
}

class _RewardGrid extends StatelessWidget {
  const _RewardGrid({required this.giftsOnly, this.onTap});
  final bool giftsOnly;
  final VoidCallback? onTap;
  static const _tints = [Color(0xFFE23B7B), Color(0xFF7E57C2), Color(0xFFFFB300)];
  @override
  Widget build(BuildContext context) {
    final cards = kWideCoupons;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.92),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final gift = giftsOnly || i < 5;
        if (!gift) return _WhiteReward(data: cards[i], dead: i > 8, onTap: onTap);
        final tint = _tints[i % 3];
        return _GiftTile(tint: tint, title: i == 4 ? '5 new rewards' : 'Won for shopping', onTap: onTap);
      },
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.tint, required this.title, this.onTap});
  final Color tint;
  final String title;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final band = Color.lerp(tint, Colors.white, 0.72)!;
    final disc = Color.lerp(tint, Colors.white, 0.35)!;
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(left: 12, top: 10, child: Icon(Icons.star, color: Colors.white24, size: 12)),
                  const Positioned(right: 18, top: 22, child: Icon(Icons.star, color: Colors.white30, size: 10)),
                  const Positioned(left: 22, bottom: 8, child: Icon(Icons.circle, color: Colors.white24, size: 8)),
                  const Positioned(right: 10, bottom: 16, child: Icon(Icons.star, color: Colors.white24, size: 8)),
                  Container(
                    width: 86,
                    height: 86,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
                    child: GiftMark(ribbon: Color.lerp(tint, Colors.black, 0.15)!),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: band,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const Text('On this account', style: TextStyle(fontSize: 11, color: Color(0xFF5C5C5C))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GiftMark extends StatelessWidget {
  const GiftMark({super.key, this.ribbon = const Color(0xFFC2185B)});
  final Color ribbon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 46, height: 46, child: CustomPaint(painter: _GiftPainter(ribbon)));
  }
}

class _GiftPainter extends CustomPainter {
  _GiftPainter(this.ribbon);
  final Color ribbon;
  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(Rect.fromLTWH(6, 18, size.width - 12, size.height - 20), const Radius.circular(2));
    canvas.drawRRect(box, Paint()..color = Colors.white);
    final r = Paint()..color = ribbon..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 3, 18, 6, size.height - 20), r);
    canvas.drawRect(Rect.fromLTWH(6, 26, size.width - 12, 5), r);
    final bow = Paint()..color = ribbon..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(size.width / 2 - 16, 4, 16, 16), 0.4, 2.4, false, bow);
    canvas.drawArc(Rect.fromLTWH(size.width / 2, 4, 16, 16), 3.4, 2.4, false, bow);
  }

  @override
  bool shouldRepaint(covariant _GiftPainter oldDelegate) => oldDelegate.ribbon != ribbon;
}

class _WhiteReward extends StatelessWidget {
  const _WhiteReward({required this.data, required this.dead, this.onTap});
  final WideCouponData data;
  final bool dead;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: dead ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE6E6E6))),
                child: const GiftMark(ribbon: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 10),
              Text(data.banner, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.2)),
              const SizedBox(height: 4),
              const Text('On this account', style: TextStyle(color: _muted, fontSize: 12)),
              const Spacer(),
              Text(dead ? 'Expired' : 'T&C', style: TextStyle(color: dead ? _muted : _ink, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinZone extends StatelessWidget {
  const _CoinZone({this.onCoupons});
  final VoidCallback? onCoupons;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(28)),
          child: Row(
            children: [
              const Expanded(child: Text('Shop & earn coins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
          itemCount: 4,
          itemBuilder: (_, i) {
            final word = kRmCategories[i % kRmCategories.length].words.first;
            return GestureDetector(
              onTap: () => openAtelierWord(context, word: word.word, root: word.root, img: _arts[i]),
              child: i.isEven ? _TagCard(art: _arts[i], word: word.word) : _PlainCard(art: _arts[i], word: word.word),
            );
          },
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCoupons,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)]),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Coins come off at checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                Icon(Icons.bolt, color: Color(0xFFFFC107), size: 36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TagCard extends StatelessWidget {
  const _TagCard({required this.art, required this.word});
  final String art;
  final String word;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(art, fit: BoxFit.cover),
          Positioned(
            left: 10,
            top: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(8)),
              child: Text('$word\ncoinback', style: const TextStyle(fontWeight: FontWeight.w900, height: 1.1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.art, required this.word});
  final String art;
  final String word;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(art, width: double.infinity, fit: BoxFit.cover))),
        const SizedBox(height: 6),
        Text(word, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class GiftOffer {
  const GiftOffer(this.id, this.title, this.line, this.rupees);
  final String id;
  final String title;
  final String line;
  final int rupees;
}

class GiftsFace extends StatefulWidget {
  const GiftsFace({super.key, required this.offers, required this.onClaim});
  final List<GiftOffer> offers;
  final void Function(GiftOffer offer) onClaim;
  @override
  State<GiftsFace> createState() => _GiftsFaceState();
}

class _GiftsFaceState extends State<GiftsFace> {
  var _flip = false;

  @override
  Widget build(BuildContext context) {
    final offers = _flip ? widget.offers.reversed.toList() : widget.offers;
    return _GlassPage(
      wash: const Color(0xFFE8EEF6),
      bar: ShopBar(
        title: 'Gifts',
        color: Colors.white,
        light: true,
        actions: [
          IconButton(onPressed: () => NwsbLinks.cart(context), icon: const Icon(Icons.shopping_bag_outlined, color: _ink)),
        ],
      ),
      child: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final coins = EconomyMirror.instance.coins;
          return Column(
            children: [
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(child: _Tool(icon: Icons.swap_vert, label: 'Sort', onTap: () => setState(() => _flip = !_flip))),
                    Container(width: 1, height: 22, color: const Color(0xFFE0E0E0)),
                    Expanded(child: _Tool(icon: Icons.tune, label: 'Filter', onTap: () => setState(() => _flip = false))),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 12, childAspectRatio: 0.62),
                  itemCount: offers.length,
                  itemBuilder: (_, i) => _Voucher(offer: offers[i], art: _arts[i % _arts.length], coins: coins, fresh: i < 4, onTap: () => _sheet(context, offers[i], coins)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sheet(BuildContext context, GiftOffer o, int coins) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Claim offer using  ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const _MiniCoin(),
                Text('  $coins  +  ₹${o.rupees}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [const Text('Coin balance:  ', style: TextStyle(color: _muted)), const _MiniCoin(), Text('  $coins', style: const TextStyle(color: _muted))]),
            const Divider(height: 22),
            Text('•  Coins come off ₹${o.rupees}. The rest is paid on Google Play.'),
            const SizedBox(height: 8),
            const Text('•  Once paid, this gift stays on the account. It is not cash, and it cannot be swapped for another.'),
            const SizedBox(height: 8),
            const Text('•  A gifted pass does not raise a rank.'),
            const SizedBox(height: 14),
            const Text('Read more details', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onClaim(o);
                },
                child: const Text('Claim Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCoin extends StatelessWidget {
  const _MiniCoin();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
      child: const Icon(Icons.bolt, size: 12, color: Colors.white),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _Voucher extends StatelessWidget {
  const _Voucher({required this.offer, required this.art, required this.coins, required this.fresh, required this.onTap});
  final GiftOffer offer;
  final String art;
  final int coins;
  final bool fresh;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(art, fit: BoxFit.cover),
                  if (fresh)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('NowssB', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(offer.title, maxLines: 2, style: const TextStyle(height: 1.2, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF90CAF9))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Use  ', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                const _MiniCoin(),
                Text('  $coins  +  ₹${offer.rupees}', style: const TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoinbackPage extends StatelessWidget {
  const CoinbackPage({super.key, required this.title, required this.art});
  final String title;
  final String art;

  @override
  Widget build(BuildContext context) {
    final cats = kRmCategories.where((c) => c.words.isNotEmpty).take(4).toList();
    return _GlassPage(
      wash: const Color(0xFFD58BFF),
      bar: ShopBar(
        title: title,
        color: const Color(0xFFD58BFF),
        actions: [
          IconButton(onPressed: () => NwsbLinks.cart(context), icon: const Icon(Icons.search, color: Colors.white)),
          IconButton(onPressed: () => NwsbLinks.cart(context), icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white)),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            height: 168,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const RadialGradient(colors: [Color(0xFFE9D5FF), Color(0xFFC084FC), Color(0xFF9333EA)])),
            child: Row(
              children: [
                ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)), child: Image.asset(art, width: 110, height: 168, fit: BoxFit.cover)),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('FREE COINBACK', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
                        SizedBox(height: 4),
                        Text('ON EVERY ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        SizedBox(height: 10),
                        _HeroPill(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var n = 0; n < cats.length; n++) ...[
            if (n.isOdd)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFBFDBFE), borderRadius: BorderRadius.circular(18)),
                child: Text(cats[n].label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Text(cats[n].label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            SizedBox(
              height: n.isOdd ? 230 : 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cats[n].words.take(6).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final w = cats[n].words[i];
                  final cardArt = _arts[(n + i) % _arts.length];
                  return GestureDetector(
                    onTap: () => openAtelierWord(context, word: w.word, root: w.root, img: cardArt),
                    child: n.isOdd ? _MoreCard(art: cardArt, word: w.word) : _PillCard(art: cardArt, word: w.word),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(20)),
      child: const Text('Coins back on a cleared sale', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _PillCard extends StatelessWidget {
  const _PillCard({required this.art, required this.word});
  final String art;
  final String word;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: BoxDecoration(color: const Color(0xFFE9D5FF), borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(art, width: double.infinity, fit: BoxFit.cover))),
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)]),
              child: Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.art, required this.word});
  final String art;
  final String word;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(22)),
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(art, width: double.infinity, fit: BoxFit.cover)),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              width: 120,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)]),
              child: Column(
                children: [
                  Text(word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  const Text('AND MORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
