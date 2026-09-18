/// The Word Atelier — plain black `.rm-cat-banner` rows + `.rm-word-card`s.
/// Media matches index.html / app/js/part010.js (no collection photo banners).
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/intro_gate.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_select_sheet.dart';
import 'request_words.dart';
import 'store_routes.dart';

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key});

  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Word Science',
        eyebrow: '',
        title: 'The Word Atelier',
        body:
            'Every word carries a vibrational signature that predates all dictionaries. Explore the phonetic origin of any word in any language.',
        stats: const ['Unlimited Words', 'AI-Powered', 'Every Language'],
        art: 'assets/store/intro-words.webp',
        fullBleed: true,
        enterLabel: 'Enter The Word Atelier',
        onBack: () => Navigator.of(context).pop(),
        child: PageShell(
          eyebrow: 'NowssB Store',
          title: 'The Word Atelier',
          film: nwsbVideo(kRmHeroVidFile),
          // Fashion-home AppBackdrop film + PageShell Fashion vignette scrim
          // so the background video is clearly visible (not a solid lid).
          usePageFilm: false,
          onBack: () => Navigator.of(context).pop(),
          onStorePicker: () => showStoreSelectSheet(
            context,
            onSelect: (id) => openStoreFromPicker(context, id, current: 'word'),
          ),
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

  void _browseAll() => setState(() {
        _chip = 'ALL';
        _query = '';
        _search.clear();
      });

  void _viewCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your cart is waiting in Profile → Cart'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openWord(String word, String root, String img, num price) {
    openAtelierWord(context, word: word, root: root, img: img, price: price);
  }

  void _openViewAll(String title) {
    showStoreViewAllPanel(
      context,
      title: title,
      items: storeDefaultViewAllItems(),
      onOpenWord: _openWord,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _cats;
    final sections = <Widget>[];
    if (cats.isNotEmpty) {
      sections.add(RmBannerRail(
        banners: [
          for (final cat in cats)
            RmCatBanner(
              title: cat.label,
              sub: cat.sub,
              badge: cat.badge,
              labelColor:
                  cat.labelColor != null ? Color(cat.labelColor!) : null,
              logoAsset: kRmCatLogoAsset,
              categoryId: cat.id,
              artAsset: storeCollectionArt(cat.id),
              pillLabel: cat.badge ?? cat.label,
              inRail: true,
              onViewAll: () => _openViewAll(cat.label),
            ),
        ],
      ));
    }
    // Count product rails actually emitted (search may empty some).
    var productRailIndex = 0;
    for (var i = 0; i < cats.length; i++) {
      final cat = cats[i];
      sections.add(RmRowHeader(
        title: cat.label,
        onViewAll: () => _openViewAll(cat.label),
      ));
      sections.add(Builder(builder: (context) {
        final cards = <Widget>[];
        for (final w in cat.words) {
          if (!_match(w.word, w.root)) continue;
          final name = w.word.isEmpty
              ? w.word
              : '${w.word[0].toUpperCase()}${w.word.substring(1)}';
          final sale = cat.id == 'off50';
          final price = sale ? kWordSaleInr : kWordPriceInr;
          const img = kRmWordImg;
          cards.add(RmWordCard(
            name: name,
            root: w.root,
            imgUrl: img,
            price: price,
            originalPrice: sale ? kWordPriceInr : null,
            onTap: () => openAtelierWord(context,
                word: w.word, root: w.root, img: img, price: price),
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
      productRailIndex++;

      // Compact mid-rail glass banners between every 2 product rows (exactly 7).
      if (_chip == 'ALL' && productRailIndex % 2 == 0) {
        final midIdx = (productRailIndex ~/ 2) - 1;
        final mid = storeMidRailBannerAt(midIdx);
        if (mid != null) sections.add(mid);
      }

      // After the 4th rail → frequency package (grid + Limited Time Free + Browse by Goal).
      if (_chip == 'ALL' && productRailIndex == 4) {
        sections.add(StoreFrequencyPackage(
          onSelectCategory: (id) => setState(() => _chip = id),
          onSeeAll: () => _openViewAll('Browse by Goal'),
          onOpenWord: _openWord,
          onRequestWords: () => openRequestWords(context),
        ));
      }

      // After the 6th rail → Recommended + Featured Playlist glass (image-4).
      if (_chip == 'ALL' && productRailIndex == 6) {
        sections.add(StoreRecommendedSection(
          onSeeAll: () => _openViewAll('Recommended for You'),
          onOpenWord: _openWord,
        ));
        sections.add(StoreFeaturedPlaylistSection(
          onSeeAll: () => _openViewAll('Featured Playlist'),
          onOpenWord: _openWord,
        ));
      }

      // After the 7th rail → Featured Bundle glass + tall 3-card carousel (image-5).
      if (_chip == 'ALL' && productRailIndex == 7) {
        sections.add(StoreFeaturedBundleSection(
          onSeeAll: () => _openViewAll('Featured Bundle'),
          onOpenWord: _openWord,
        ));
        sections.add(StoreGlassPlaylistCarousel(
          onSeeAll: () => _openViewAll('Playlists'),
          onOpenWord: _openWord,
        ));
      }

      // Every fifth category row — same as part010 ROW_VIDS.
      if (_chip == 'ALL' && (i + 1) % 5 == 0) {
        final vidIdx = (i + 1) ~/ 5 - 1;
        if (vidIdx >= 0 && vidIdx < kRmRowVids.length) {
          sections.add(RmRowVid(url: nwsbVideo(kRmRowVids[vidIdx])));
        }
      }
    }

    // Ensure exactly 6 mid-rail banners when ALL chip (pad if <12 rails).
    if (_chip == 'ALL') {
      final placed = productRailIndex ~/ 2;
      for (var i = placed; i < kStoreMidRailBanners.length; i++) {
        sections.add(StoreMidRailBanner(data: kStoreMidRailBanners[i]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StorePixelsHero(
          onBrowseAll: _browseAll,
          onViewCart: _viewCart,
          videoAsset: nwsbVideo(kRmHeroVidFile),
          videoTitle: 'The Word Atelier',
        ),
        StoreGlassPanel(
          radius: 32,
          padding: const EdgeInsets.all(5),
          child: StoreSearchBar(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'YOUR WORD LIBRARY',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: NwsbColors.gold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every word carries a vibrational signature.',
          style: TextStyle(fontSize: 13, color: Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 12),
        StoreGlassPanel(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StoreFilterChip(
                    label: 'ALL',
                    selected: _chip == 'ALL',
                    onTap: () => setState(() => _chip = 'ALL')),
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
