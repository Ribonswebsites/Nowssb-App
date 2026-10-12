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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../features/economy/shop_faces.dart';
import '../../media/nwsb_video.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/hype_rail.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/app_thinking_loader.dart';
import '../../widgets/sections/artist_cards_section.dart';
import '../../widgets/sections/category_tiles_section.dart';
import '../../widgets/sections/section_config.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_actions.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import 'request_words.dart';
import 'store_routes.dart';
import 'store_terms_sheet.dart';
import 'signature_store.dart';
import '../../shell/nwsb_links.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_black_card.dart';

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

/// Rebuild C (7:55 PM rule): the Meaning Store copies Ribon's CLiQ Perks
/// reference in its own colours. A light, quiet page with centred caps
/// headings, full-width image banners with an outlined DISCOVER pill, an
/// auto-sliding hero with dash dots and a "Want to know more?" tile row.
class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => const CoinbackPage(title: 'Meanings', art: 'assets/store/intro-meanings.webp');

  Widget _retired(BuildContext context) => StoreTermsHost(
        which: 'meaning',
        head: 'Meanings described by sound',
        child: PageShell(
          eyebrow: '',
          title: 'NowssB Store',
          subtitle: 'The Meaning Store',
          film: 'assets/video/player-bg-loop.mp4',
          usePageFilm: false,
          // Calm: plain NowssB deep base, no film behind content.
          background: const ColoredBox(color: NwsbColors.deep),
          onBack: () => Navigator.of(context).pop(),
          onStorePicker: () => showStoreSelectSheet(
            context,
            current: 'meaning',
            onSelect: (id) =>
                openStoreFromPicker(context, id, current: 'meaning'),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
              sliver: SliverList.list(children: const [_MeaningStoreBody()]),
            ),
          ],
        ),
      );
}

const _paper = Color(0xFF0B0B0D);
const _ink = Colors.white;
const _soft = Color(0x8CFFFFFF);
const _line = Color(0x24FFFFFF);

class _MeaningStoreBody extends StatefulWidget {
  const _MeaningStoreBody();
  @override
  State<_MeaningStoreBody> createState() => _MeaningStoreBodyState();
}

class _MeaningStoreBodyState extends State<_MeaningStoreBody> {
  final _search = TextEditingController();
  String _query = '';

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

  static const _order = [
    'Elements',
    'Human',
    'Emotions',
    'Cosmos',
    'Nations & People',
  ];

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _showAbout() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF111114),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Text(
              'Meanings shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked.',
              style: TextStyle(color: _ink, fontSize: 13, height: 1.5),
            ),
          ),
        ),
      );

  void _scrollToCat(String cat) {
    final key = _catKeys[cat];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    }
  }

  final _catKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    final k = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final cats = <String, List<MsMeaning>>{};
    final q = _query.toLowerCase();
    for (final m in _base) {
      if (q.isNotEmpty &&
          !m.word.toLowerCase().contains(q) &&
          !m.root.toLowerCase().contains(q) &&
          !m.category.toLowerCase().contains(q)) {
        continue;
      }
      (cats[m.category] ??= []).add(m);
    }
    final order = [
      ..._order,
      ...cats.keys.where((k) => !_order.contains(k)),
    ].where((c) => cats[c]?.isNotEmpty == true).toList();

    final children = <Widget>[
      // Original media (main 235ae99): the Meaning door hero film.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StorePixelsHero(
          videoAsset: nwsbVideo(kStoreMeaningDoorVidFile),
          videoTitle: '',
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: StoreGlassPanel(
          radius: 32,
          padding: const EdgeInsets.all(5),
          child: StoreSearchBar(
            controller: _search,
            hint: 'Search meanings…',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      for (final cat in (_query.isEmpty ? order.take(4) : order)) ...[
        _CapsHeading(cat.toUpperCase(),
            key: _catKeys.putIfAbsent(cat, () => GlobalKey())),
        SizedBox(
          height: 236 + (k - 1) * 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cats[cat]!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final m = cats[cat]![i];
              final art = _msOnlyArt(m.key, m.img);
              return _MeanTile(
                name: m.word,
                art: art,
                price: m.price,
                onOpen: () => openMeaningDetail(context, m),
                onBag: () => storeAddToCart(
                    context,
                    meaningBagItem(
                        word: m.word, root: m.root, img: art, price: m.price)),
              );
            },
          ),
        ),
      ],
      if (order.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: Column(children: [
            const Text('No meanings match.',
                style: TextStyle(color: _soft, fontSize: 14)),
            TextButton(
              onPressed: () => openRequestWords(context),
              child: const Text('Request it',
                  style: TextStyle(
                      color: NwsbColors.gold, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
        child: Center(
          child: IconButton(
            tooltip: 'About meanings',
            onPressed: _showAbout,
            icon: const Icon(Icons.info_outline, color: Color(0x80FFFFFF)),
          ),
        ),
      ),
    ];

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _CapsHeading extends StatelessWidget {
  const _CapsHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 18),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _ink,
                fontSize: 16,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w400)),
      );
}

/// A calm meaning tile: art, name, price, one bag button.
class _MeanTile extends StatelessWidget {
  const _MeanTile({
    required this.name,
    required this.art,
    required this.price,
    required this.onOpen,
    required this.onBag,
  });
  final String name, art;
  final num price;
  final VoidCallback onOpen, onBag;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: onOpen,
            child: GlassBlackCard(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Image.asset(art,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Colors.black)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: GestureDetector(
                onTap: onOpen,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(localizedMoney(context, price),
                          maxLines: 1,
                          style: const TextStyle(
                              color: Color(0x99FFFFFF), fontSize: 13)),
                    ]),
              ),
            ),
            Semantics(
              button: true,
              label: 'Add $name to bag',
              child: GestureDetector(
                onTap: onBag,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: NwsbColors.gold),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 17, color: Colors.black),
                ),
              ),
            ),
          ]),
        ]),
      );
}
