/// The Word Atelier — plain black `.rm-cat-banner` rows + `.rm-word-card`s.
/// Media matches index.html / app/js/part010.js (no collection photo banners).
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../data/store_catalog.dart';
import '../../features/stage_practice/stage_pack.dart';
import '../../data/store_prices.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import 'ebooks_store.dart';
import 'meaning_store.dart';
import 'request_words.dart';
import 'store_actions.dart';
import 'store_art.dart';
import 'store_routes.dart';
import 'store_drift_banners.dart';
import 'daily_deals.dart';
import 'store_shelf.dart';
import '../../widgets/routine_deck.dart';
import 'store_terms_sheet.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

class WordAtelierScreen extends StatelessWidget {
  const WordAtelierScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'word',
        head: 'Words described by sound',
        child: PageShell(
        eyebrow: '',
        title: 'NowssB Store',
        subtitle: 'The Word Atelier',
        film: 'assets/video/subscription-bg.mp4',
        usePageFilm: true,
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
        content: EditableLabel('word_atelier.WordAtelierBody', 'Your cart is waiting in Profile → Cart'),
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

  List<StorePiece> _pieces() {
    final out = <StorePiece>[];
    final seen = <String>{};
    void add(String title, String line, String group, String art, VoidCallback tap) {
      final key = title.toLowerCase();
      if (!seen.add(key) || !_match(title, line)) return;
      out.add(StorePiece(title: title, line: line, art: art, group: group, onTap: tap));
    }

    for (final cat in kRmCategories) {
      for (final w in cat.words) {
        final name = w.word.isEmpty ? w.word : '${w.word[0].toUpperCase()}${w.word.substring(1)}';
        final id = 'word:${name.toLowerCase()}';
        final price = StorePrices.instance.priceFor(id);
        add(name, w.root, cat.label, kRmWordImg, () => openAtelierWord(context, word: w.word, root: w.root, img: kRmWordImg, price: price));
      }
    }
    for (final w in _stageWords()) {
      final name = _cap(w.word);
      add(name, _stageLine(w), 'Recorded stages', kRmWordImg, () => openAtelierWord(context, word: w.key, root: _stageLine(w), img: kRmWordImg, price: w.price));
    }
    return out;
  }

  /// Library words that ship with the client's recorded practice stages.
  List<Word> _stageWords() => [
        for (final w in ContentStore.instance.library)
          if (StagePack.forWord(w) != null) w,
      ];

  static String _cap(String w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';

  static String _stageLine(Word w) {
    final n = StagePack.forWord(w)?.stages.length ?? 0;
    return '$n recorded stages · practice with a score';
  }

  void _openDeal(DailyDeal d) => openAtelierWord(
        context,
        word: d.word,
        root: d.root,
        img: kNowssbStoreMark,
        price: StorePrices.instance.priceFor('word:${d.word.toLowerCase()}'),
      );

  @override
  Widget build(BuildContext context) {
    final staged = [
      for (final w in _stageWords())
        if (_match(w.word, _stageLine(w))) w
    ];
    final decks = <Widget>[
        if (staged.isNotEmpty)
          RoutineDeck(
            title: 'Recorded stages',
            banner: 'Recorded stages',
            bannerSub: 'Teacher-recorded words you practise stage by stage',
            cards: [
              for (final w in staged)
                WorkCard(
                  category: 'Recorded stages',
                  title: _cap(w.word),
                  meta: _stageLine(w),
                  action: 'Open',
                  image: kNowssbStoreMark,
                  flip: storeWaveFor(w.word),
                  onTap: () => openAtelierWord(context, word: w.key, root: _stageLine(w), img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.key}')),
                  onCart: () => storeAddToCart(context, wordBagItem(name: _cap(w.word), root: _stageLine(w), img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.key}'))),
                  onBuy: () => storeBuyNow(context, wordBagItem(name: _cap(w.word), root: _stageLine(w), img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.key}'))),
                ),
            ],
          ),
        for (final cat in kRmCategories)
          if (cat.words.any((w) => _match(w.word, w.root)))
            RoutineDeck(
              title: cat.label,
              banner: cat.label,
              bannerSub: cat.sub,
              onBanner: () => _openViewAll(cat.label),
              cards: [
                for (final w in cat.words)
                  if (_match(w.word, w.root))
                    WorkCard(
                      category: cat.label,
                      title: w.word.isEmpty ? w.word : '${w.word[0].toUpperCase()}${w.word.substring(1)}',
                      meta: w.root,
                      action: 'Open',
                      image: kNowssbStoreMark,
                      flip: storeWaveFor(w.word),
                      onTap: () => openAtelierWord(context, word: w.word, root: w.root, img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.word.toLowerCase()}')),
                      onCart: () => storeAddToCart(context, wordBagItem(name: w.word, root: w.root, img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.word.toLowerCase()}'))),
                      onBuy: () => storeBuyNow(context, wordBagItem(name: w.word, root: w.root, img: kNowssbStoreMark, price: StorePrices.instance.priceFor('word:${w.word.toLowerCase()}'))),
                    ),
              ],
            ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StoreRoomDeck(current: 'word'),
        ...everyFiveStoreRows(decks, onDeal: _openDeal),
      ],
    );
  }
}
