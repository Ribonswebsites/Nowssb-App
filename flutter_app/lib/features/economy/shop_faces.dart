/// Coupons, rewards, gifts and the store lanes.
/// Same layout and colours as the coin-shop screens: blue bar, purple
/// coupon hero, pink coinback, white cards, gold coins. The offers are NowssB.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../screens/store/product_detail.dart';
import '../../shell/nwsb_links.dart';
import 'coupon_tickets.dart';
import 'economy_api.dart';

const _blue = Color(0xFF2874F0);
const _ink = Color(0xFF212121);
const _muted = Color(0xFF878787);
const _purple = Color(0xFF5E35B1);
const _page = Color(0xFFF1F3F6);

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
  const ShopBar({super.key, required this.title, required this.color, this.trailing, this.light = false});
  final String title;
  final Color color;
  final Widget? trailing;
  final bool light;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final fg = light ? _ink : Colors.white;
    return Material(
      color: color,
      elevation: light ? 0.4 : 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.maybePop(context), icon: Icon(Icons.arrow_back, color: fg)),
              Expanded(child: Text(title, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w600))),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ShopBar(title: 'My Coupons', color: Colors.white, light: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF4ECFF), Color(0xFFE7D8FF), Colors.white],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('✦  Level up your savings  ✦', style: TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      const Text('COUPONS FOR YOU', style: TextStyle(color: _purple, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(color: const Color(0xFFD9C6FF), borderRadius: BorderRadius.circular(20)),
                        child: Text('You have ${kWideCoupons.length} coupons', style: const TextStyle(color: _purple, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      const _TicketPair(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _code,
                            decoration: const InputDecoration(hintText: 'Enter coupon code', hintStyle: TextStyle(color: Color(0xFF9E9E9E)), border: InputBorder.none, isDense: true),
                          ),
                        ),
                        TextButton(onPressed: () => _add(_code.text), child: const Text('Add coupon', style: TextStyle(color: _ink, fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('Save more with coupons', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final f in const ['All', 'WORD', 'MEANING'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _DropChip(label: f == 'All' ? 'Categories' : f, on: _filter == f, onTap: () => setState(() => _filter = f)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < list.length; i++)
                  _SpineCard(
                    first: i == 0,
                    last: i == list.length - 1,
                    child: _OfferRow(data: list[i], art: _arts[i % _arts.length], fresh: i.isEven, onUse: () => _add(list[i].copy), onOpen: () => _open(list[i])),
                  ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: _Foot(icon: Icons.card_giftcard, tint: _purple, label: 'All rewards', onTap: () => Navigator.maybePop(context))),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFEDE7F6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? _purple : const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: on ? _purple : _ink, fontWeight: FontWeight.w600, fontSize: 13)),
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
    return Material(
      color: const Color(0xFFF6F2FF),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(art, width: 92, height: 92, fit: BoxFit.cover),
                  ),
                  if (fresh)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(4)),
                        child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.kicker == 'WORD COUPON' ? 'Festive offer' : 'Special discount', style: const TextStyle(color: _muted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(data.banner, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800, height: 1.15)),
                    const SizedBox(height: 2),
                    Text(data.line, maxLines: 2, style: const TextStyle(color: _muted, fontSize: 12, height: 1.25)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onOpen,
                      child: const Text('View products  ›', style: TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
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

class _SpineCard extends StatelessWidget {
  const _SpineCard({required this.child, required this.first, required this.last});
  final Widget child;
  final bool first;
  final bool last;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -14,
            top: first ? 18 : 0,
            bottom: last ? null : 0,
            child: Container(width: 2, height: last ? 18 : null, color: const Color(0xFFE4E4E4)),
          ),
          Positioned(
            left: -22,
            top: 14,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE4E4E4), width: 3)),
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
        ],
      ),
    );
  }
}

class _TicketPair extends StatelessWidget {
  const _TicketPair();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 90, top: 18, child: Transform.rotate(angle: 0.18, child: const _Stub(color: Color(0xFF7E57C2)))),
          Positioned(right: 90, top: 8, child: Transform.rotate(angle: -0.22, child: const _Stub(color: Color(0xFF5E35B1)))),
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
      clipper: _NotchClip(),
      child: Container(
        width: 128,
        height: 78,
        color: color,
        alignment: Alignment.center,
        child: const Text('%', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _NotchClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final box = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, size.height / 2), radius: 8))
      ..addOval(Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 8));
    return Path.combine(PathOperation.difference, box, holes);
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
        side: const BorderSide(color: Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
    return Scaffold(
      backgroundColor: _page,
      appBar: ShopBar(
        title: 'My Rewards',
        color: _blue,
        trailing: GestureDetector(onTap: widget.onCoupons, child: const Text('Add Coupon')),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
                          color: _chip == i ? Colors.white : const Color(0xFFE8EAED),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _chip == i ? _blue : Colors.transparent, width: 1.4),
                        ),
                        child: Text(_names[i], style: TextStyle(color: _chip == i ? _blue : _ink, fontWeight: FontWeight.w700)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BoltCoin(size: 84),
          const SizedBox(height: 18),
          const Text('No coin rewards yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _blue, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            onPressed: () => NwsbLinks.tab(context, 1),
            child: const Text('Open Practice', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
          Container(width: size * 0.62, height: size * 0.62, decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33FFC107), blurRadius: 16)])),
          Icon(Icons.bolt, color: Colors.white, size: size * 0.36),
          ..._pips(size),
        ],
      ),
    );
  }

  List<Widget> _pips(double size) {
    const spots = [Offset(-0.42, -0.2), Offset(0.4, -0.28), Offset(-0.36, 0.32), Offset(0.38, 0.3), Offset(0, -0.46)];
    return [
      for (final s in spots)
        Positioned(
          left: size / 2 + s.dx * size - 4,
          top: size / 2 + s.dy * size - 4,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFD6DCE5), borderRadius: BorderRadius.circular(4))),
        ),
    ];
  }
}

class _RewardGrid extends StatelessWidget {
  const _RewardGrid({required this.giftsOnly, this.onTap});
  final bool giftsOnly;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final cards = kWideCoupons;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.86),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final gift = giftsOnly || i < 5;
        if (!gift) return _WhiteReward(data: cards[i], dead: i > 8, onTap: onTap);
        return _GiftTile(tint: const [Color(0xFFE91E63), Color(0xFF7E57C2), Color(0xFFFFB300)][i % 3], title: i == 4 ? '5 new rewards' : cards[i].banner, onTap: onTap);
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
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const Positioned(left: 10, top: 8, child: Icon(Icons.star, color: Colors.white24, size: 14)),
                  const Positioned(right: 16, top: 18, child: Icon(Icons.star, color: Colors.white24, size: 10)),
                  const Positioned(left: 28, bottom: 12, child: Icon(Icons.star, color: Colors.white24, size: 8)),
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                      child: Icon(Icons.card_giftcard, color: tint, size: 42),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8E1),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.15)),
            ),
          ],
        ),
      ),
    );
  }
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
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: dead ? null : onTap,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE0E0E0))),
                      child: const Text('N', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Text(data.banner, textAlign: TextAlign.center, maxLines: 3, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
                    const SizedBox(height: 4),
                    const Text('Valid on this account', style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
            if (dead)
              Container(
                width: double.infinity,
                color: const Color(0xFFF3F4F6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text('Expired', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
              ),
          ],
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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('Coins\neverywhere', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.05)),
              ),
              Column(
                children: [
                  _Tag('EARN', const Color(0xFFFF7043)),
                  const SizedBox(height: 6),
                  _Tag('USE', const Color(0xFFFFD54F), ink: _ink),
                  const SizedBox(height: 6),
                  _Tag('GIFT', Colors.white, ink: _ink),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _Partner('Words', 'Open a word', () => openAtelierWord(context, word: 'fire', root: 'Proto-Indo-European', img: _arts[0])),
              _Partner('Meanings', 'Open a meaning', () => NwsbLinks.meanings(context)),
              _Partner('Plans', 'See plans', () => NwsbLinks.subscription(context)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Save with coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => GestureDetector(
              onTap: onCoupons,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: i.isEven ? _purple : const Color(0xFFE91E63), width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(_arts[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color, {this.ink = Colors.white});
  final String text;
  final Color color;
  final Color ink;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _Partner extends StatelessWidget {
  const _Partner(this.title, this.sub, this.onTap);
  final String title;
  final String sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ),
      ),
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

class GiftsFace extends StatelessWidget {
  const GiftsFace({super.key, required this.offers, required this.onClaim});
  final List<GiftOffer> offers;
  final void Function(GiftOffer offer) onClaim;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: const ShopBar(title: 'Gifts', color: Colors.white, light: true),
      body: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final coins = EconomyMirror.instance.coins;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 0.66),
            itemCount: offers.length,
            itemBuilder: (_, i) {
              final o = offers[i];
              final art = _arts[i % _arts.length];
              return Material(
                color: Colors.white,
                elevation: 0,
                child: InkWell(
                  onTap: () => _sheet(context, o, coins),
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
                              if (i < 3)
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('NowssB', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(o.title, maxLines: 2, style: const TextStyle(color: _ink, height: 1.2)),
                      const SizedBox(height: 8),
                      Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF90CAF9))),
                        child: Text('Use  $coins  +  ₹${o.rupees}', style: const TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _sheet(BuildContext context, GiftOffer o, int coins) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim this gift  ·  $coins coins + ₹${o.rupees}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Coin balance:  $coins', style: const TextStyle(color: _muted)),
            const Divider(height: 22),
            Text('• ${o.line}. The rest is paid on Google Play.'),
            const SizedBox(height: 6),
            const Text('• Once you pay, this gift is issued to the account. It is not cash.'),
            const SizedBox(height: 6),
            const Text('• A gifted pass does not raise a rank.'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                onPressed: () {
                  Navigator.pop(ctx);
                  onClaim(o);
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

class CoinbackPage extends StatelessWidget {
  const CoinbackPage({super.key, required this.title, required this.art});
  final String title;
  final String art;

  @override
  Widget build(BuildContext context) {
    final cats = kRmCategories.where((c) => c.words.isNotEmpty).take(4).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ShopBar(title: title, color: const Color(0xFFD946EF)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE879F9), Color(0xFFC026D3), Color(0xFF7E22CE)]),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FREE COINBACK', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
                      SizedBox(height: 4),
                      Text('ON A CLEARED ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                      SizedBox(height: 10),
                      _HeroPill(),
                    ],
                  ),
                ),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(art, width: 108, height: 120, fit: BoxFit.cover)),
              ],
            ),
          ),
          for (var n = 0; n < cats.length; n++) ...[
            if (n.isOdd)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF7DD3FC), borderRadius: BorderRadius.circular(16)),
                child: Text(cats[n].label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(cats[n].label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            SizedBox(
              height: 196,
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
                    child: Container(
                      width: 148,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(cardArt, fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Text(w.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text('Earn coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          _EarnRow(art: _arts[5], title: 'Practice', line: 'Coins for a finished session', cta: 'Open', onTap: () => NwsbLinks.tab(context, 1)),
          _EarnRow(art: _arts[0], title: 'A word', line: 'Open one from the atelier', cta: 'See words', flip: true, onTap: () => openAtelierWord(context, word: 'fire', root: 'Proto-Indo-European', img: _arts[0])),
          _EarnRow(art: _arts[2], title: 'A plan', line: 'A pass is not a rank', cta: 'See plans', onTap: () => NwsbLinks.subscription(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Expanded(child: Text('Shop and the coins come off at checkout', style: TextStyle(fontWeight: FontWeight.w800))),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: _ink, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF6D28D9), borderRadius: BorderRadius.circular(20)),
      child: const Text('Coins are not cash', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _EarnRow extends StatelessWidget {
  const _EarnRow({required this.art, required this.title, required this.line, required this.cta, required this.onTap, this.flip = false});
  final String art;
  final String title;
  final String line;
  final String cta;
  final VoidCallback onTap;
  final bool flip;
  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(art, width: 120, height: 78, fit: BoxFit.cover));
    final copy = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 2),
          Text(line, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$cta  ›', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
            child: Row(children: flip ? [copy, const SizedBox(width: 8), photo] : [photo, const SizedBox(width: 12), copy]),
          ),
        ),
      ),
    );
  }
}
