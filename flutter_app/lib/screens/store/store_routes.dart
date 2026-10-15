/// Shared store-to-store navigation for the glass store picker sheet.
library;

import 'package:flutter/material.dart';

import '../../widgets/routine_deck.dart';
import 'store_art.dart';
import 'ebooks_store.dart';
import 'meaning_store.dart';
import 'signature_store.dart';
import 'word_atelier.dart';

void openStoreFromPicker(BuildContext context, String id, {required String current}) {
  if (id == current) return;
  late final Widget page;
  switch (id) {
    case 'meaning':
      page = const MeaningStoreScreen();
      break;
    case 'ebooks':
      page = const EbooksStoreScreen();
      break;
    case 'signature':
      page = const SignatureStoreScreen();
      break;
    case 'word':
    default:
      page = const WordAtelierScreen();
      break;
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

/// One working row. Tapping the room you are already in does nothing.
class StoreRoomDeck extends StatelessWidget {
  const StoreRoomDeck({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    const rooms = [
      ('word', 'Word Atelier', 'Words and roots', 'Open the atelier'),
      ('meaning', 'Meaning Store', 'Where the English name comes from', 'Open meanings'),
      ('signature', 'Signature Store', 'The mark on a word', 'Open signatures'),
      ('ebooks', 'eBooks', 'Read the books', 'Open the shelf'),
    ];
    return RoutineDeck(
      title: 'Stores',
      banner: 'The stores',
      bannerSub: 'Atelier, meanings, signature, books',
      cards: [
        for (final r in rooms)
          WorkCard(
            category: 'Store',
            title: r.$2,
            meta: r.$3,
            action: r.$4,
            image: kStoreRoomArt[r.$1] ?? 'assets/rails/store/word.jpg',
            onTap: () => openStoreFromPicker(context, r.$1, current: current),
          ),
      ],
    );
  }
}
