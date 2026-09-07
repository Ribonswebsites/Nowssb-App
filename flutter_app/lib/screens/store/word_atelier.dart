/// The Word Atelier — plain black `.rm-cat-banner` rows + `.rm-word-card`s.
/// Media matches index.html / app/js/part010.js (no collection photo banners).
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/intro_gate.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key});

  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Word Science',
        eyebrow: '',
        title: 'The Word Atelier',
        body: 'Every word carries a vibrational signature that predates all dictionaries. Explore the phonetic origin of any word in any language.',
        stats: const ['Unlimited Words', 'AI-Powered', 'Every Language'],
        art: 'assets/store/intro-words.webp',
        fullBleed: true,
        enterLabel: 'Enter The Word Atelier',
        onBack: () => Navigator.of(context).pop(),
        child: PageShell(
          eyebrow: 'NowssB Store',
          title: 'The Word Atelier',
          film: nwsbVideo(kRmHeroVidFile),
          onBack: () => Navigator.of(context).pop(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              sliver: SliverList.list(children: const [_WordAtelierBody()]),
            ),
          ],
        ),
      );
}

class _WordAtelierBody extends StatefulWidget {
  const _WordAtelierBody();
  @override
  State<_WordAtelierBody> createState() => _WordAtelierBodyState();
}

class _WordAtelierBodyState extends State<_WordAtelierBody> {
  final _search = TextEditingController();
  String _query = '';
  String _chip = 'ALL';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<RmCategory> get _cats {
    if (_chip == 'ALL') return kRmCategories;
    return kRmCategories.where((c) => c.id == _chip).toList();
  }

  bool _match(String word, String root) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return word.toLowerCase().contains(q) || root.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final cats = _cats;
    final sections = <Widget>[];
    for (var i = 0; i < cats.length; i++) {
      final cat = cats[i];
      sections.add(RmCatBanner(
        title: cat.label,
        sub: cat.sub,
        badge: cat.badge,
        labelColor: cat.labelColor != null ? Color(cat.labelColor!) : null,
        logoAsset: kRmCatLogoAsset,
      ));
      sections.add(Builder(builder: (context) {
        final cards = <Widget>[];
        for (final w in cat.words) {
          if (!_match(w.word, w.root)) continue;
          final name = w.word.isEmpty ? w.word : '${w.word[0].toUpperCase()}${w.word.substring(1)}';
          // Live price when present; card art is always RM_WORD_IMG (part010).
          final live = ContentStore.instance.library
              .where((x) => x.word.toLowerCase() == w.word.toLowerCase())
              .toList();
          final price = live.isNotEmpty ? live.first.price : (cat.id == 'off50' ? 24.5 : 49);
          const img = kRmWordImg;
          cards.add(RmWordCard(
            name: name,
            root: w.root,
            imgUrl: img,
            price: price,
            onTap: () => openAtelierWord(context, word: w.word, root: w.root, img: img, price: price),
          ));
        }
        final sig = cat.signature;
        if (sig != null && _match(sig.name, 'Most Exclusive')) {
          cards.add(RmWordCard(
            name: sig.name,
            root: 'Most Exclusive',
            imgUrl: sig.img,
            signature: true,
            price: kMsSignaturePrice,
            onTap: () => openAtelierWord(
              context,
              word: sig.name,
              root: 'Most Exclusive',
              img: sig.img,
              signature: true,
            ),
          ));
        }
        if (cards.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No words match this search in this collection.',
              style: TextStyle(color: Color(0x8CFFFFFF), fontSize: 12),
            ),
          );
        }
        return RmWordRow(children: cards);
      }));
      // Every fifth category row — same as part010 ROW_VIDS.
      if (_chip == 'ALL' && (i + 1) % 5 == 0) {
        final vidIdx = (i + 1) ~/ 5 - 1;
        if (vidIdx >= 0 && vidIdx < kRmRowVids.length) {
          sections.add(RmRowVid(url: nwsbVideo(kRmRowVids[vidIdx])));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NwsbVideo(
                  asset: nwsbVideo(kRmHeroVidFile),
                  priority: ClipPriority.feature,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22060C18), Color(0xE6060C18)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'The Word Atelier',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StoreSearchBar(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        const Text(
          'YOUR WORD LIBRARY',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.2, color: NwsbColors.gold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every word carries a vibrational signature.',
          style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              StoreFilterChip(label: 'ALL', selected: _chip == 'ALL', onTap: () => setState(() => _chip = 'ALL')),
              const SizedBox(width: 7),
              for (final c in kRmCategories) ...[
                StoreFilterChip(
                  label: c.label.toUpperCase(),
                  selected: _chip == c.id,
                  onTap: () => setState(() => _chip = c.id),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...sections,
        const StoreDisclaimer(
          text:
              'Words shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked. Any information you share with us is kept strictly confidential and never sold or shared with third parties.',
        ),
      ],
    );
  }
}
