/// Coupons, rewards, gifts and the store lanes, in the same layout and
/// colours as a coin shop: purple and blue bars, white cards, gold coins.
/// The words, prices and actions are NowssB's.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../screens/store/product_detail.dart';
import '../../shell/nwsb_links.dart';
import 'coupon_tickets.dart';
import 'economy_api.dart';

const _blue = Color(0xFF2874F0);
const _ink = Color(0xFF212121);
const _muted = Color(0xFF717171);
const _purple = Color(0xFF6C2BD9);

class ShopBar extends StatelessWidget implements PreferredSizeWidget {
  const ShopBar({super.key, required this.title, required this.color, this.trailing});
  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final _fg = color.computeLuminance() > 0.6 ? _ink : Colors.white;
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.maybePop(context), icon: Icon(Icons.arrow_back, color: _fg)),
              Expanded(child: Text(title, style: TextStyle(color: _fg, fontSize: 18, fontWeight: FontWeight.w600))),
              if (trailing != null) Padding(padding: const EdgeInsets.only(right: 12), child: IconTheme(data: IconThemeData(color: _fg), child: DefaultTextStyle.merge(style: TextStyle(color: _fg), child: trailing!))),
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

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: const ShopBar(title: 'My Coupons', color: Colors.white),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDE4FF), Color(0xFFF7F7F7)]),
                  ),
                  child: Column(
                    children: [
                      const Text('Level up your savings', style: TextStyle(color: _purple, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('COUPONS FOR YOU', style: TextStyle(color: _purple, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFE4D4FF), borderRadius: BorderRadius.circular(20)),
                        child: Text('You have ${kWideCoupons.length} coupons', style: const TextStyle(color: _purple, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 12),
                      const _TicketPair(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFE0E0E0))),
                    child: Row(
                      children: [
                        Expanded(child: TextField(controller: _code, decoration: const InputDecoration(hintText: 'Enter coupon code', border: InputBorder.none))),
                        TextButton(onPressed: () => _add(_code.text), child: const Text('Add coupon', style: TextStyle(color: _ink, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Text('Save more with coupons', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final f in const ['All', 'WORD', 'MEANING', 'SUBSCRIPTION'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f == 'All' ? 'Categories' : f),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Material(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _add(c.copy),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset('assets/store/nowssb-bag-headphones.webp', width: 92, height: 92, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.kicker, style: const TextStyle(color: _muted, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(c.banner, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
                                    Text(c.line, style: const TextStyle(color: _muted, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    const Text('Use this coupon  ›', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.card_giftcard, color: _purple), label: const Text('All rewards', style: TextStyle(color: _ink)))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.scratch == null
                            ? null
                            : () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => Padding(padding: const EdgeInsets.all(16), child: widget.scratch!),
                                ),
                        icon: const Icon(Icons.confirmation_number, color: Color(0xFFF5A623)),
                        label: const Text('Scratch cards', style: TextStyle(color: _ink)),
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

class _TicketPair extends StatelessWidget {
  const _TicketPair();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(angle: -0.18, child: _ticket(const Color(0xFF7C4DFF))),
          const SizedBox(width: 8),
          Transform.rotate(angle: 0.12, child: _ticket(const Color(0xFF5E35B1))),
        ],
      ),
    );
  }

  Widget _ticket(Color color) => Container(
        width: 110,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: const Text('%', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      );
}

class RewardsFace extends StatefulWidget {
  const RewardsFace({super.key, this.onCoupons});
  final VoidCallback? onCoupons;
  @override
  State<RewardsFace> createState() => _RewardsFaceState();
}

class _RewardsFaceState extends State<RewardsFace> {
  var _chip = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: ShopBar(
        title: 'My Rewards',
        color: _blue,
        trailing: GestureDetector(onTap: widget.onCoupons, child: const Text('Add Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(const ['All', 'Coin Zone', 'Practice', 'Gifts'][i]),
                      selected: _chip == i,
                      selectedColor: Colors.white,
                      onSelected: (_) => setState(() => _chip = i),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _chip == 2 ? _empty() : _grid()),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
            child: const Icon(Icons.bolt, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No rewards in Practice yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _blue),
            onPressed: () => NwsbLinks.tab(context, 1),
            child: const Text('Open Practice'),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    final colors = [const Color(0xFFE91E63), const Color(0xFF7E57C2), const Color(0xFFFFB300), const Color(0xFF5C6BC0)];
    final cards = kWideCoupons;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.78),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        final tint = colors[i % colors.length];
        final plain = i.isOdd && _chip == 0;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onCoupons,
            child: plain
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 36),
                        const SizedBox(height: 8),
                        Text(c.banner, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(c.line, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: tint,
                          alignment: Alignment.center,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.card_giftcard, size: 36),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: tint.withValues(alpha: 0.25),
                        padding: const EdgeInsets.all(8),
                        child: Text(c.banner, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
          ),
        );
      },
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
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: const ShopBar(title: 'Gifts', color: _blue),
      body: ListenableBuilder(
        listenable: EconomyMirror.instance,
        builder: (context, _) {
          final coins = EconomyMirror.instance.coins;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.62),
            itemCount: offers.length,
            itemBuilder: (_, i) {
              final o = offers[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _sheet(context, o, coins),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          color: const Color(0xFFE8F5E9),
                          alignment: Alignment.center,
                          child: Image.asset('assets/store/intro-words.webp', fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Text(o.title, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(o.line, maxLines: 2, style: const TextStyle(color: _muted, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border.all(color: _blue), borderRadius: BorderRadius.circular(8)),
                          child: Text('Use $coins + ₹${o.rupees}', style: const TextStyle(color: _blue, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
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
            Text('Claim ${o.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Coin balance: $coins', style: const TextStyle(color: _muted)),
            const Divider(),
            Text('• ${o.line}'),
            const Text('• A gifted pass does not raise a rank.'),
            const Text('• Coins are not cash.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _blue),
                onPressed: () {
                  Navigator.pop(ctx);
                  onClaim(o);
                },
                child: const Text('Claim Now', style: TextStyle(fontWeight: FontWeight.w800)),
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
      appBar: ShopBar(title: title, color: const Color(0xFFC026D3)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFFA21CAF)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FREE COINBACK', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      const Text('ON EVERY ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Earn coins on a cleared sale', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(art, width: 110, height: 120, fit: BoxFit.cover)),
              ],
            ),
          ),
          for (final cat in cats) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Up to coinback on ${cat.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: cat.words.take(6).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final w = cat.words[i];
                  return GestureDetector(
                    onTap: () => openAtelierWord(context, word: w.word, root: w.root, img: art),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(art, fit: BoxFit.cover, width: double.infinity))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(16)),
              child: const Text('Shop & earn coins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
