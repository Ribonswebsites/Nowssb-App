/// The Word Atelier — plain black `.rm-cat-banner` rows + `.rm-word-card`s.
/// Media matches index.html / app/js/part010.js (no collection photo banners).
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
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
import 'signature_store.dart';
import 'store_routes.dart';
import 'store_shelf.dart';
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
        film: 'assets/video/player-bg-loop.mp4',
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
        add(name, w.root, storeGroup(w.word), kRmWordImg, () => openAtelierWord(context, word: w.word, root: w.root, img: kRmWordImg, price: price));
      }
    }
    for (final row in kPlaceRows) {
      add(row.$1, row.$2, row.$3, kRmWordImg, () => openAtelierWord(context, word: row.$1, root: row.$2, img: kRmWordImg));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pieces = _pieces();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StoreRoomDeck(current: 'word'),
        StoreShelf(pieces: pieces),
      ],
    );
  }
}
