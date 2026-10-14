/// One store shelf: five working card rails, filtered by place and language.
library;

import 'package:flutter/material.dart';

import '../../widgets/routine_deck.dart';
import 'store_cards.dart';

class StorePiece {
  const StorePiece({
    required this.title,
    required this.line,
    required this.art,
    required this.group,
    required this.onTap,
  });

  final String title;
  final String line;
  final String art;
  final String group;
  final VoidCallback onTap;
}

const kStoreFilters = ['All', 'Countries', 'Capitals', 'Currency', 'Language'];

const kPlaceRows = <(String, String, String)>[
  ('India', 'Country', 'Countries'),
  ('Japan', 'Country', 'Countries'),
  ('Egypt', 'Country', 'Countries'),
  ('Greece', 'Country', 'Countries'),
  ('France', 'Country', 'Countries'),
  ('Brazil', 'Country', 'Countries'),
  ('Kenya', 'Country', 'Countries'),
  ('Canada', 'Country', 'Countries'),
  ('Delhi', 'Capital', 'Capitals'),
  ('Tokyo', 'Capital', 'Capitals'),
  ('Cairo', 'Capital', 'Capitals'),
  ('Athens', 'Capital', 'Capitals'),
  ('Paris', 'Capital', 'Capitals'),
  ('Brasilia', 'Capital', 'Capitals'),
  ('Nairobi', 'Capital', 'Capitals'),
  ('Ottawa', 'Capital', 'Capitals'),
  ('Rupee', 'Currency', 'Currency'),
  ('Yen', 'Currency', 'Currency'),
  ('Pound', 'Currency', 'Currency'),
  ('Dollar', 'Currency', 'Currency'),
  ('Euro', 'Currency', 'Currency'),
  ('Dinar', 'Currency', 'Currency'),
  ('Krone', 'Currency', 'Currency'),
  ('Peso', 'Currency', 'Currency'),
  ('Sanskrit', 'Language', 'Language'),
  ('Latin', 'Language', 'Language'),
  ('Greek', 'Language', 'Language'),
  ('Arabic', 'Language', 'Language'),
  ('English', 'Language', 'Language'),
  ('Hindi', 'Language', 'Language'),
  ('French', 'Language', 'Language'),
  ('Japanese', 'Language', 'Language'),
];

String storeGroup(String word) {
  final n = word.toLowerCase();
  for (final row in kPlaceRows) {
    if (row.$1.toLowerCase() == n) return row.$3;
  }
  return 'Language';
}

/// The five rails used on Word, Meaning, Signature and Ebooks.
class StoreShelf extends StatefulWidget {
  const StoreShelf({super.key, required this.pieces, this.labels = const ['Open', 'Your list', 'Guides', 'Glass', 'Clear']});

  final List<StorePiece> pieces;
  final List<String> labels;

  @override
  State<StoreShelf> createState() => _StoreShelfState();
}

class _StoreShelfState extends State<StoreShelf> {
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<StorePiece>>{};
    for (final p in widget.pieces) {
      final key = kStoreFilters.contains(p.group) ? p.group : 'Language';
      (groups[key] ??= []).add(p);
    }
    final order = [for (final name in kStoreFilters) if (name != 'All' && (groups[name]?.isNotEmpty ?? false)) name];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final name in order)
          RoutineDeck(
            title: name,
            banner: name,
            bannerSub: '${groups[name]!.length} in this row',
            cards: [
              for (final p in groups[name]!.take(12))
                WorkCard(
                  category: p.group,
                  title: p.title,
                  meta: p.line,
                  action: 'Open',
                  image: p.art,
                  onTap: p.onTap,
                ),
            ],
          ),
      ],
    );
  }
}
