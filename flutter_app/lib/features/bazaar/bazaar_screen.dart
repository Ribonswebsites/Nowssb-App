import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/firebase.dart';
import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../economy/economy_theme.dart';
import '../economy/money.dart';
import '../economy/play_billing.dart';

class BazaarScreen extends StatelessWidget {
  const BazaarScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const EconomyNote(
            'Resale price stays between 50% and 150% of the original. The platform cut starts at 20% and falls toward 10% as you sell more. 3% goes to the content owner. No refunds on resold items. NowssB can delist a listing. You must own the word before you list it.',
          ),
          const SizedBox(height: 16),
          const Text('YOUR OWNED WORDS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          const _OwnedList(),
          const SizedBox(height: 18),
          const Text('LIVE LISTINGS', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 8),
          const _LiveListings(),
        ],
    );
    if (embedded) return body;
    return EconomyPage(title: 'Word Bazaar', requireAuth: true, child: body);
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
          Text(title, style: const TextStyle(color: Colors.white)),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Resale price'),
          ),
          GoldButton(
            label: 'List $title',
            filled: false,
            onTap: () => runEconomy(context, () => EconomyApi.call('createListing', {
                  'itemId': widget.doc.id,
                  'price': int.tryParse(_price.text.trim()) ?? 0,
                })),
          ),
        ],
      ),
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
        if (snap.hasError) return EconomyNote('${snap.error}');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EconomyNote('No live listings yet.');
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
              onTap: () => runEconomy(context, () async {
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
              onTap: () => runEconomy(context, () => EconomyApi.call('spendCoins', {
                    'purpose': 'boost',
                    'listingId': doc.id,
                  })),
            ),
            const SizedBox(height: 6),
            GoldButton(
              label: 'Flash sale −10%',
              filled: false,
              onTap: () => runEconomy(context, () => EconomyApi.call('setFlashSale', {
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
              onTap: () => runEconomy(context, () => EconomyApi.call('reviewResale', {
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
