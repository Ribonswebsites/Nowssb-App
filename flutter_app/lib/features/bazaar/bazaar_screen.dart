import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../economy/play_billing.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../screens/store/store_terms_sheet.dart';
import '../../screens/subscription.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/four_banners.dart';
import '../../admin/template/editable.dart';

class BazaarScreen extends StatelessWidget {
  const BazaarScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final listening = ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) => ListView(
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const FourBanners(
            splitTitle: 'Resell',
            splitCta: 'List a word',
            blackTitle: 'Your words',
            blackSub: 'Half to one and a half times the original.',
          ),
          const SizedBox(height: 12),
          const GlassLine(text: 'Listings stay off until Play allows them. You can still read the rules.'),
          const SizedBox(height: 12),
          const ColoredSplitPromoBanner(
            margin: EdgeInsets.zero,
            spec: SplitPromoSpec(
              title: 'Resell',
              cta: 'Browse listings',
              leftColor: Color(0xFF3D2914),
              rightColor: Color(0xFFE07A3D),
              art: SplitPromoArts.whiteRobot,
            ),
          ),
          const SizedBox(height: 12),
          const ColoredSplitPromoBanner(
            margin: EdgeInsets.zero,
            spec: SplitPromoSpec(
              title: 'List a word',
              cta: 'Open your words',
              leftColor: Color(0xFF24143D),
              rightColor: Color(0xFFC8A96E),
              art: SplitPromoArts.blondeLotus,
            ),
          ),
          const SizedBox(height: 12),
          GlassWrap(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EconomyNote(
                  'Resale price stays between 50% and 150% of the original. The platform cut starts at 20% and falls toward 10% as you sell more. 3% goes to the content owner. No refunds on resold items. NowssB can delist a listing. You must own the word before you list it.',
                ),
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Terms and conditions',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SubscriptionTermsScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                const EditableLabel('bazaar_screen.BazaarScreen', 'WORDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
                const SizedBox(height: 8),
                const _SampleWords(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const EditableLabel('bazaar_screen.BazaarScreen', 'YOUR OWNED WORDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          const _OwnedList(),
          const SizedBox(height: 18),
          const EditableLabel('bazaar_screen.BazaarScreen', 'LIVE LISTINGS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          const _LiveListings(),
        ],
      ),
    );
    if (embedded) return listening;
    return StoreTermsHost(
      which: 'bazaar',
      head: 'Before you resell',
      child: EconomyPage(
        title: 'Resell',
        mark: NwsbMarks.bag,
        child: listening,
      ),
    );
  }
}

class _OwnedList extends StatelessWidget {
  const _OwnedList();

  @override
  Widget build(BuildContext context) {
    final uid = EconomyMirror.instance.uid;
    if (!NwsbFirebase.ready || uid == null) {
      return const EconomyNote('Sign in to list a word you own.');
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users/$uid/owned').limit(30).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EconomyNote('Owned words appear here after a verified purchase.');
        return Column(
          children: [
            for (final doc in docs) _ListCard(doc: doc),
          ],
        );
      },
    );
  }
}

class _ListCard extends StatefulWidget {
  const _ListCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  State<_ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<_ListCard> {
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final original = (widget.doc.data()['originalPrice'] as num?)?.toInt() ??
        (widget.doc.data()['price'] as num?)?.toInt() ??
        49;
    _price = TextEditingController(text: '$original');
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final title = (data['title'] as String?) ?? widget.doc.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditableLabel('bazaar_screen.ListCard', title, style: const TextStyle(color: Colors.white)),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Resale price'),
          ),
          GoldButton(
            label: 'List $title',
            filled: false,
            onTap: () => runPrivate(context, () => EconomyApi.call('createListing', {
                  'itemId': widget.doc.id,
                  'price': int.tryParse(_price.text.trim()) ?? 0,
                })),
          ),
        ],
      ),
    );
  }
}

class _SampleWords extends StatelessWidget {
  const _SampleWords();

  static const _words = <(String, int)>[
    ('Ananda', 99),
    ('Prana', 99),
    ('Tejas', 149),
    ('Soma', 99),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final word in _words)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x29FFFFFF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(
                          'Original ${FxBook.instance.formatCents(word.$2)} · list ${FxBook.instance.formatCents((word.$2 * 0.5).round())}–${FxBook.instance.formatCents((word.$2 * 1.5).round())}',
                          style: const TextStyle(color: NwsbColors.mist, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => runPrivate(context, () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Own ${word.$1} before you list it.')),
                      );
                    }),
                    child: const EditableLabel('bazaar_screen.SampleWords', 'List'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveListings extends StatelessWidget {
  const _LiveListings();

  @override
  Widget build(BuildContext context) {
    if (!NwsbFirebase.ready) return const EconomyNote('Firebase is not connected on this build.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('status', isEqualTo: 'live')
          .limit(40)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (snap.hasError || docs.isEmpty) {
          return EconomyNote(
            snap.hasError
                ? 'Listings are quiet right now. The words above are still here to list once you own them.'
                : 'No live listings yet. Own a word, then list it between half and one and a half times the original price.',
          );
        }
        return Column(
          children: [
            for (final doc in docs) _ListingTile(doc: doc),
          ],
        );
      },
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final title = (data['title'] as String?) ?? 'Word';
    final mine = data['sellerUid'] == EconomyMirror.instance.uid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title · ${FxBook.instance.formatCents(price)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text('${data['kind'] ?? 'word'} · seller ${data['sellerUid']}', style: const TextStyle(color: NwsbColors.mist, fontSize: 12)),
          const SizedBox(height: 6),
          if (!mine)
            GoldButton(
              label: 'Buy with Play',
              onTap: () => runPrivate(context, () async {
                final quote = CashQuote.forPrice(price: price, balance: EconomyMirror.instance.coins);
                await PlayCheckout.buy(
                  callable: 'purchaseListing',
                  productId: quote.productId,
                  payload: {'listingId': doc.id, 'coins': quote.coins},
                );
              }),
            ),
          if (mine) ...[
            GoldButton(
              label: 'Boost 3 days · 60 coins',
              filled: false,
              onTap: () => runPrivate(context, () => EconomyApi.call('spendCoins', {
                    'purpose': 'boost',
                    'listingId': doc.id,
                  })),
            ),
            const SizedBox(height: 6),
            GoldButton(
              label: 'Flash sale −10%',
              filled: false,
              onTap: () => runPrivate(context, () => EconomyApi.call('setFlashSale', {
                    'listingId': doc.id,
                    'price': (price * 0.9).round(),
                    'hours': 24,
                  })),
            ),
          ],
          if (data['status'] == 'sold' && data['buyerUid'] == EconomyMirror.instance.uid)
            GoldButton(
              label: 'Review up',
              filled: false,
              onTap: () => runPrivate(context, () => EconomyApi.call('reviewResale', {
                    'listingId': doc.id,
                    'up': true,
                    'comment': 'Helpful resale',
                  })),
            ),
        ],
      ),
    );
  }
}
