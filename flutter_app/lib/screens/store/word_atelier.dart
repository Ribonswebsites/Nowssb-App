/// The Word Atelier — plain black `.rm-cat-banner` rows + `.rm-word-card`s.
/// Media matches index.html / app/js/part010.js (no collection photo banners).
library;

import 'package:flutter/material.dart';
import '../../kit/kit.dart';
import 'newui/store_feed.dart';
import 'newui/store_page.dart';

import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/hype_rail.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import '../../theme/ui_tokens.dart';
import 'store_actions.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import 'ebooks_store.dart';
import 'meaning_store.dart';
import 'request_words.dart';
import 'signature_store.dart';
import 'store_routes.dart';
import 'store_terms_sheet.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';
import '../../widgets/glass_black_card.dart';
import '../../data/app_control.dart';

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key});

  @override
  Widget build(BuildContext context) => NewUiGate(
        page: 'store',
        legacy: _retired,
        rebuilt: (_) => const StoreDeptPage(dept: StoreDept.words),
      );

  Widget _retired(BuildContext context) => StoreTermsHost(
        which: 'word',
        head: 'Words described by sound',
        child: PageShell(
          eyebrow: '',
          title: 'NowssB Store',
          subtitle: 'The Word Atelier',
          film: 'assets/video/player-bg-loop.mp4',
          usePageFilm: false,
          // Calm: plain NowssB deep base, no film or swirl behind content.
          background: const ColoredBox(color: NwsbColors.deep),
          onBack: () => Navigator.of(context).pop(),
          onStorePicker: () => showStoreSelectSheet(
            context,
            current: 'word',
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
  var _allRows = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The "50% OFF · Limited time" collection is left out: no real sale
  /// backs that title (Task Master, Oct 12).
  static final _all =
      kRmCategories.where((c) => c.id != 'off50').toList(growable: false);

  List<RmCategory> get _cats {
    if (_chip == 'ALL') return _all;
    return _all.where((c) => c.id == _chip).toList();
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
        content: EditableLabel('word_atelier.WordAtelierBody',
            'Your cart is waiting in Profile → Cart'),
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
    // Calm: 4 collections on ALL; a chip shows any one of them.
    final cats = _chip == 'ALL' ? _cats.take(4).toList() : _cats;
    final k = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final rows = <Widget>[];
    for (final cat in cats) {
      final items = [
        for (final w in cat.words)
          if (_match(w.word, w.root)) w,
      ];
      if (items.isEmpty) continue;
      rows.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 40, 4, 16),
        child: Text(cat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3)),
      ));
      rows.add(SizedBox(
        height: 236 + (k - 1) * 56,
        child: ListView.separated(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final w = items[i];
            final name = w.word.isEmpty
                ? w.word
                : '${w.word[0].toUpperCase()}${w.word.substring(1)}';
            final id = 'word:${name.toLowerCase()}';
            final price = StorePrices.instance.priceFor(id);
            return _WordTile(
              name: name,
              art: storeCollectionArt(cat.id),
              price: price,
              originalPrice: StorePrices.instance.regularIfOnSale(id),
              onOpen: () => openAtelierWord(context,
                  word: w.word, root: w.root, img: kRmWordImg, price: price),
              onBag: () => storeAddToCart(
                  context,
                  wordBagItem(
                      name: name, root: w.root, img: kRmWordImg, price: price)),
            );
          },
        ),
      ));
    }
    if (rows.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: TextButton(
            onPressed: () => openRequestWords(context),
            child: const Text('Request this word',
                style: TextStyle(color: NwsbColors.gold)),
          ),
        ),
      ));
    }

    // Rebuild C (Ribon, 8:26): one hero film, one search, chips, 3-4 rows.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: layoutIndexed(context, 'store.atelier', const {
        0: ('hero', 'Hero film'),
        1: ('search', 'Search'),
        2: ('chips', 'Category chips'),
        3: ('rows', 'Word collections'),
        -1: ('disclaimer', 'Disclaimer'),
      }, [
        StorePixelsHero(
          onBrowseAll: _browseAll,
          onViewCart: _viewCart,
          videoAsset: nwsbVideo(kRmHeroVidFile),
          videoTitle: '',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: GlassBlackCard(
            padding: const EdgeInsets.all(5),
            child: StoreSearchBar(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              onGo: () {
                if (_query.trim().isEmpty) {
                  openRequestWords(context);
                  return;
                }
                final any =
                    _all.any((c) => c.words.any((w) => _match(w.word, w.root)));
                if (!any) openRequestWords(context);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StoreFilterChip(
                    label: 'ALL',
                    selected: _chip == 'ALL',
                    black: true,
                    onTap: () => setState(() => _chip = 'ALL')),
                const SizedBox(width: 8),
                for (final c in _all) ...[
                  StoreFilterChip(
                    label: c.label.toUpperCase(),
                    selected: _chip == c.id,
                    black: true,
                    onTap: () => setState(() => _chip = c.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        const Padding(
          padding: EdgeInsets.only(top: 32),
          child: _InfoDisclaimer(
            text:
                'Words shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked. Any information you share with us is kept strictly confidential and never sold or shared with third parties.',
          ),
        ),
      ]),
    );
  }
}

/// A calm word tile: art, name, price, one bag button.
class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.name,
    required this.art,
    required this.price,
    required this.originalPrice,
    required this.onOpen,
    required this.onBag,
  });
  final String name, art;
  final num price;
  final num? originalPrice;
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
                borderRadius: BorderRadius.circular(UiRadii.md),
                child: SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: ColoredBox(
                    color: Colors.black,
                    child: Image.asset(art,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
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
                      Text.rich(
                        TextSpan(children: [
                          if (originalPrice != null)
                            TextSpan(
                                text:
                                    '${localizedMoney(context, originalPrice!)}  ',
                                style: const TextStyle(
                                    color: Color(0x66FFFFFF),
                                    decoration: TextDecoration.lineThrough)),
                          TextSpan(text: localizedMoney(context, price)),
                        ]),
                        maxLines: 1,
                        style: const TextStyle(
                            color: Color(0x99FFFFFF), fontSize: 13),
                      ),
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

/// The disclaimer sits behind a small (i) icon (compliance, Oct 12).
class _InfoDisclaimer extends StatelessWidget {
  const _InfoDisclaimer({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: IconButton(
          tooltip: 'About these words',
          icon: const Icon(Icons.info_outline, color: Color(0x80FFFFFF)),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(UiSpace.md),
                child: GlassBlackCard(
                  child: Text(text,
                      style: const TextStyle(
                          color: Color(0xB3FFFFFF), fontSize: 12, height: 1.5)),
                ),
              ),
            ),
          ),
        ),
      );
}
