/// Signature Store — rarest Signature words & meanings.
/// Same store family fixes: one-line subtitle, no double banner title,
/// taller subscribe + pill right-centre, Signature-appropriate labels.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import '../../widgets/sections/artist_cards_section.dart';
import 'store_actions.dart';
import 'store_art.dart';
import 'store_routes.dart';
import 'store_shelf.dart';
import '../../widgets/routine_deck.dart';
import 'store_terms_sheet.dart';
import 'request_words.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'signature',
        head: 'Signatures described by sound',
        child: PageShell(
        eyebrow: '',
        title: 'NowssB Store',
        subtitle: 'The Signature Store',
        film: 'assets/video/player-bg-loop.mp4',
        usePageFilm: true,
        onBack: () => Navigator.of(context).pop(),
        onStorePicker: () => showStoreSelectSheet(
          context,
          current: 'signature',
          onSelect: (id) =>
              openStoreFromPicker(context, id, current: 'signature'),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverList.list(children: const [_SignatureBody()]),
          ),
        ],
        ),
      );
}

class _SignatureBody extends StatelessWidget {
  const _SignatureBody();

  @override
  Widget build(BuildContext context) {
    final words =
        kRmCategories.where((c) => c.signature != null).map((c) => c.signature!).toList();
    final meanings = kMsSignature.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Server-driven order (Admin → UI Editor); bundled order by default.
      children: [
        const StoreRoomDeck(current: 'signature'),
        RoutineDeck(
          title: 'Signature words',
          banner: 'Most exclusive',
          bannerSub: 'The mark on a word',
          cards: [
            for (final s in words)
              WorkCard(
                category: 'Signature',
                title: s.name,
                meta: 'Most exclusive',
                action: 'Open',
                image: kNowssbStoreMark,
                onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true),
                onCart: () => storeAddToCart(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
                onBuy: () => storeBuyNow(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
              ),
          ],
        ),
        RoutineDeck(
          title: 'Signature meanings',
          banner: 'Meanings',
          bannerSub: 'The mark on a meaning',
          cards: [
            for (final e in meanings)
              WorkCard(
                category: e.key,
                title: e.value.word,
                meta: e.value.root,
                action: 'Open',
                image: kNowssbStoreMark,
                onTap: () => openMeaningDetail(
                  context,
                  MsMeaning(word: e.value.word, key: e.value.key, root: e.value.root, category: e.key, price: kMsSignaturePrice, img: kNowssbStoreMark),
                  signature: true,
                ),
                onCart: () => storeAddToCart(context, meaningBagItem(word: e.value.word, root: e.value.root, img: kNowssbStoreMark, price: kMsSignaturePrice, signature: true)),
                onBuy: () => storeBuyNow(context, meaningBagItem(word: e.value.word, root: e.value.root, img: kNowssbStoreMark, price: kMsSignaturePrice, signature: true)),
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
                    image: kNowssbStoreMark,
                    onTap: () => openAtelierWord(context, word: row.$1, root: row.$2, img: kNowssbStoreMark),
                    onCart: () => storeAddToCart(context, wordBagItem(name: row.$1, root: row.$2, img: kNowssbStoreMark, signature: true)),
                    onBuy: () => storeBuyNow(context, wordBagItem(name: row.$1, root: row.$2, img: kNowssbStoreMark, signature: true)),
                  ),
            ],
          ),
      ],
    );
  }
}
