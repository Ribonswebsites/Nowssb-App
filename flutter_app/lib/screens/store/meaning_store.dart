/// The Meaning Store — unique meanings experience (not a Word Atelier clone).
/// Header: NowssB Store + one-line "The Meaning Store".
/// One hero/video max; no word mid-rail banner stacks; meaning icons only.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/colored_split_promo_banner.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_select_sheet.dart';
import 'request_words.dart';
import 'store_routes.dart';
import 'signature_store.dart';

class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => PageShell(
        eyebrow: '',
        title: 'NowssB Store',
        subtitle: 'The Meaning Store',
        film: nwsbVideo(kStoreMeaningDoorVidFile),
        usePageFilm: false,
        onBack: () => Navigator.of(context).pop(),
        onStorePicker: () => showStoreSelectSheet(
          context,
          current: 'meaning',
          onSelect: (id) =>
              openStoreFromPicker(context, id, current: 'meaning'),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            sliver: SliverList.list(children: const [_MeaningStoreBody()]),
          ),
        ],
      );
}

class _MeaningStoreBody extends StatefulWidget {
  const _MeaningStoreBody();
  @override
  State<_MeaningStoreBody> createState() => _MeaningStoreBodyState();
}

class _MeaningStoreBodyState extends State<_MeaningStoreBody> {
  final _search = TextEditingController();
  String _query = '';
  String _chip = 'ALL';
  var _allRows = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Prefer MS_BASE_MEANINGS card art from the catalogue.
  List<MsMeaning> get _base {
    final live = ContentStore.instance.meanings;
    final byKey = {for (final m in kMsBaseMeanings) m.key: m};
    for (final m in live) {
      if (byKey.containsKey(m.key)) {
        final base = byKey[m.key]!;
        byKey[m.key] = MsMeaning(
          word: base.word,
          key: base.key,
          root: base.root,
          category: base.category,
          price: m.price > 0 ? m.price : base.price,
          img: base.img,
        );
      } else {
        byKey[m.key] = MsMeaning(
          word: m.name,
          key: m.key,
          root: m.sub.isNotEmpty ? m.sub : 'NowssB Meaning',
          category: 'Studio',
          price: m.price,
          img: m.img.isNotEmpty ? m.img : kMsCardImg,
        );
      }
    }
    return byKey.values.toList();
  }

  void _openViewAll(String title) {
    showStoreViewAllPanel(
      context,
      title: title,
      items: storeDefaultViewAllItems(),
      onOpenWord: (word, root, img, price) {
        final hit = _base
            .where((m) => m.word.toLowerCase() == word.toLowerCase())
            .toList();
        if (hit.isNotEmpty) openMeaningDetail(context, hit.first);
      },
    );
  }

  void _openMeaning(String word, String root, String img, num price) {
    final hit = _base
        .where((m) => m.word.toLowerCase() == word.toLowerCase())
        .toList();
    if (hit.isNotEmpty) openMeaningDetail(context, hit.first);
  }

  @override
  Widget build(BuildContext context) {
    final all = _base;
    final cats = <String, List<MsMeaning>>{};
    for (final m in all) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!m.word.toLowerCase().contains(q) &&
            !m.root.toLowerCase().contains(q) &&
            !m.category.toLowerCase().contains(q)) {
          continue;
        }
      }
      if (_chip != 'ALL' && m.category != _chip) continue;
      (cats[m.category] ??= []).add(m);
    }
    final order = [
      'Elements',
      'Human',
      'Emotions',
      'Cosmos',
      'Nations & People',
      ...cats.keys.where((k) => !const {
            'Elements',
            'Human',
            'Emotions',
            'Cosmos',
            'Nations & People'
          }.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single hero/video area — no back-to-back promo banners.
        StorePixelsHero(
          videoAsset: nwsbVideo(kStoreMeaningDoorVidFile),
          videoTitle: '',
        ),
        StoreSubscribeBanner(
          pillIconAsset: kMsMeaningProductArt,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: StoreSearchBar(
            controller: _search,
            hint: 'Search meanings…',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              StoreFilterChip(
                  label: 'ALL',
                  selected: _chip == 'ALL',
                  onTap: () => setState(() => _chip = 'ALL')),
              const SizedBox(width: 7),
              for (final c in [
                'Elements',
                'Human',
                'Emotions',
                'Cosmos',
                'Nations & People'
              ]) ...[
                StoreFilterChip(
                    label: c.toUpperCase(),
                    selected: _chip == c,
                    onTap: () => setState(() => _chip = c)),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        StoreFrequencyPackage(
          meanings: true,
          onSelectCategory: (id) {
            const map = {
              'elements': 'Elements',
              'sacred': 'Emotions',
              'nature': 'Elements',
              'warriors': 'Human',
              'focus': 'Emotions',
              'calm': 'Emotions',
              'cosmos': 'Cosmos',
            };
            setState(() => _chip = map[id] ?? 'ALL');
          },
          onSeeAll: () => _openViewAll('Browse by Goal'),
          onRequestWords: () => openRequestWords(context),
          onOpenWord: _openMeaning,
        ),
        StoreRecommendedSection(
          meanings: true,
          onSeeAll: () => _openViewAll('Recommended for You'),
          onOpenWord: _openMeaning,
        ),
        ColoredSplitPromoBanner.forSurface(
          SplitPromoSurface.meaningStore,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SignatureStoreScreen(),
            ),
          ),
        ),
        StoreFeaturedPlaylistSection(
          meanings: true,
          onSeeAll: () => _openViewAll('Featured Playlist'),
          onOpenWord: _openMeaning,
        ),
        StoreGlassPlaylistCarousel(
          meanings: true,
          onSeeAll: () => _openViewAll('Featured Collections'),
          onOpenWord: _openMeaning,
        ),
        ..._meaningCollectionSections(context, order, cats),
        if (cats.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
                child: Text('No meanings match.',
                    style: TextStyle(color: Color(0x8CFFFFFF)))),
          ),
        const StoreDisclaimer(
          text:
              'Meanings shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked.',
        ),
      ],
    );
  }

  List<Widget> _meaningCollectionSections(
    BuildContext context,
    List<String> order,
    Map<String, List<MsMeaning>> cats,
  ) {
    final out = <Widget>[];
    // No word-style stacked category banner rail (CURATED/FEATURED/ATELIER…).
    var shown = 0;
    for (final cat in order) {
      if (cats[cat]?.isNotEmpty != true) continue;
      if (!_allRows && _chip == 'ALL' && shown >= 10) continue;
      shown++;
      out.add(RmRowHeader(
        title: cat,
        onViewAll: () => _openViewAll(cat),
      ));
      out.add(MsGrid(
        children: [
          for (final m in cats[cat]!)
            MsCard(
              word: m.word,
              root: m.root,
              imgUrl: m.img,
              price: m.price,
              onTap: () => openMeaningDetail(context, m),
            ),
          if (kMsSignature.containsKey(cat) && _query.isEmpty)
            MsCard(
              word: kMsSignature[cat]!.word,
              root: kMsSignature[cat]!.root,
              imgUrl: kMsSignatureImg,
              price: kMsSignaturePrice,
              signature: true,
              onTap: () => openMeaningDetail(
                context,
                MsMeaning(
                  word: kMsSignature[cat]!.word,
                  key: kMsSignature[cat]!.key,
                  root: kMsSignature[cat]!.root,
                  category: cat,
                  price: kMsSignaturePrice,
                  img: kMsSignatureImg,
                ),
                signature: true,
              ),
            ),
        ],
      ));
    }
    if (!_allRows && _chip == 'ALL') {
      final total = order.where((c) => cats[c]?.isNotEmpty == true).length;
      if (total > 10) {
        out.add(StoreViewMoreTap(
          leftover: total - 10,
          onTap: () => setState(() => _allRows = true),
        ));
      }
    }
    return out;
  }
}
