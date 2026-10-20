/// The Meaning Store — unique meanings experience (not a Word Atelier clone).
/// Header: NowssB Store + one-line "The Meaning Store".
/// One hero/video max; no word mid-rail banner stacks; meaning icons only.
///
/// Asset roles (meanings-only):
/// - meanings-store-swirl.png → store hub / picker / icon ONLY
/// - meanings-device.png → in-store product cards (coloured backs where needed)
/// - meanings-branding.jpg → playlist / goals
/// - meanings-clean.jpg → fallback
/// Video banners stay unchanged.
library;

import 'store_first_use_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../widgets/page_shell.dart';
import 'store_actions.dart';
import 'store_art.dart';
import 'store_routes.dart';
import '../../widgets/routine_deck.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/app_thinking_loader.dart';
import '../../widgets/sections/artist_cards_section.dart';
import '../../widgets/sections/category_tiles_section.dart';
import '../../widgets/sections/section_config.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_shelf.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import 'request_words.dart';
import 'store_terms_sheet.dart';
import 'signature_store.dart';
import '../../shell/nwsb_links.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';


/// Warm Meaning + picker + ebook arts before painting (no empty black flash).
const kMeaningWarmAssets = <String>[
  kMsMeaningStoreIcon,
  kMsMeaningIconAsset,
  kMsMeaningProductArt,
  kMsMeaningIntroArt,
  'assets/store/picker-words.png',
  'assets/store/picker-meaning.png',
  'assets/store/picker-signature.png',
  'assets/store/picker-ebooks.png',
  kEbProductArt,
  kEbIntroArt,
];

String _msOnlyArt(String key, String candidate) {
  if (candidate.startsWith('assets/meanings/')) return candidate;
  const arts = <String>[
    kMsMeaningIntroArt,
    kMsMeaningProductArt,
    kMsMeaningIconAsset,
  ];
  return arts[key.hashCode.abs() % arts.length];
}

class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'meaning',
        head: 'Meanings described by sound',
        child: PageShell(
        eyebrow: '',
        title: 'NowssB Store',
        subtitle: 'The Meaning Store',
        film: 'assets/video/subscription-bg.mp4',
        usePageFilm: true,
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
        ),
      ).withStoreGuide('meaning_store');
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
  var _ready = false;

  /// UI-6 artist row config, built once from the catalogue (stable identity).
  late final SectionConfig _artists =
      MeaningMix.artists(_base, (m) => _msOnlyArt(m.key, m.img));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warm());
  }

  Future<void> _warm() async {
    if (!mounted) return;
    for (final path in kMeaningWarmAssets) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }

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
          img: _msOnlyArt(base.key, base.img),
        );
      } else {
        byKey[m.key] = MsMeaning(
          word: m.name,
          key: m.key,
          root: m.sub.isNotEmpty ? m.sub : 'NowssB Meaning',
          category: 'Studio',
          price: m.price,
          img: _msOnlyArt(m.key, m.img.isNotEmpty ? m.img : kMsCardImg),
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

  void _openArtist(SectionMediaItem item) {
    final hit = _base.where((m) => m.key == item.id).toList();
    if (hit.isNotEmpty) {
      openMeaningDetail(context, hit.first);
    } else {
      storeMixOpenLink(context, item);
    }
  }

  void _onMixTile(SectionMediaItem item) {
    if ((item.ctaLink ?? '').trim().isNotEmpty) {
      storeMixOpenLink(context, item);
      return;
    }
    setState(() => _chip = item.id);
  }

  void _openMeaning(String word, String root, String img, num price) {
    final hit = _base
        .where((m) => m.word.toLowerCase() == word.toLowerCase())
        .toList();
    if (hit.isNotEmpty) openMeaningDetail(context, hit.first);
  }


  List<StorePiece> _meaningPieces() {
    final out = <StorePiece>[];
    final seen = <String>{};
    void add(String title, String line, String group, String art, VoidCallback tap) {
      if (!seen.add(title.toLowerCase())) return;
      if (_query.isNotEmpty && !title.toLowerCase().contains(_query.toLowerCase()) && !line.toLowerCase().contains(_query.toLowerCase())) return;
      out.add(StorePiece(title: title, line: line, art: art, group: group, onTap: tap));
    }
    for (final m in _base) {
      add(m.word, m.root, storeGroup(m.word) == 'Language' && m.category == 'Nations & People' ? 'Countries' : storeGroup(m.word), m.img, () => openMeaningDetail(context, m));
    }
    for (final row in kPlaceRows) {
      add(row.$1, row.$2, row.$3, kMsMeaningProductArt, () {
        openMeaningDetail(context, MsMeaning(word: row.$1, key: row.$1.toLowerCase(), root: row.$2, category: row.$3, price: 49, img: kMsMeaningProductArt));
      });
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
        height: 420,
        child: Center(
          child: AppThinkingLoader(
            size: 72,
            state: OrbState.composing,
            label: 'Loading meanings…',
          ),
        ),
      );
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StoreRoomDeck(current: 'meaning'),
        for (final cat in cats.keys)
          RoutineDeck(
            title: cat,
            banner: cat,
            bannerSub: '${cats[cat]!.length} meanings',
            onBanner: () => _openViewAll(cat),
            cards: [
              for (final m in cats[cat]!)
                WorkCard(
                  category: cat,
                  title: m.word,
                  meta: m.root,
                  action: 'Open',
                  image: kMeaningsIcon,
                  flip: storeMeaningFlip(m.word),
                  onTap: () => openMeaningDetail(context, m),
                  onCart: () => storeAddToCart(context, meaningBagItem(word: m.word, root: m.root, img: kNowssbStoreMark, price: m.price)),
                  onBuy: () => storeBuyNow(context, meaningBagItem(word: m.word, root: m.root, img: kNowssbStoreMark, price: m.price)),
                ),
            ],
          ),
        for (final group in const ['Countries', 'Capitals', 'Currency', 'Language'])
          RoutineDeck(
            title: group,
            banner: group,
            bannerSub: 'The ${group.toLowerCase()} row',
            cards: [
              for (final row in kPlaceRows)
                if (row.$3 == group)
                  WorkCard(
                    category: group,
                    title: row.$1,
                    meta: row.$2,
                    action: 'Open',
                    image: kMeaningsIcon,
                    flip: storeWaveFor(row.$1),
                    onTap: () => openMeaningDetail(context, MsMeaning(word: row.$1, key: row.$1.toLowerCase(), root: row.$2, category: row.$3, price: 49, img: kNowssbStoreMark)),
                    onCart: () => storeAddToCart(context, meaningBagItem(word: row.$1, root: row.$2, img: kNowssbStoreMark, price: 49)),
                    onBuy: () => storeBuyNow(context, meaningBagItem(word: row.$1, root: row.$2, img: kNowssbStoreMark, price: 49)),
                  ),
            ],
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
      // Word Atelier row template structure — meanings labels/arts only.
      final rowChildren = <Widget>[
        for (final m in cats[cat]!)
          SizedBox(
            width: 132,
            child: MsCard(
              word: m.word,
              root: m.root,
              imgUrl: _msOnlyArt(m.key, m.img),
              price: m.price,
              onTap: () => openMeaningDetail(context, m),
            ),
          ),
        if (kMsSignature.containsKey(cat) && _query.isEmpty)
          SizedBox(
            width: 132,
            child: MsCard(
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
          ),
      ];
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rowChildren.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => rowChildren[i],
            ),
          ),
        ),
      );
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
