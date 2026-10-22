/// One store shelf: five working card rails, filtered by place and language.
library;

import 'package:flutter/material.dart';

import '../../widgets/hub_rails.dart';
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
    const pool = [
      'assets/rails/art-scratch.jpg',
      'assets/rails/art-gift-red.jpg',
      'assets/rails/art-gift-gold.jpg',
      'assets/rails/art-gift-black.jpg',
      'assets/rails/art-spin.jpg',
      'assets/rails/art-coins.jpg',
      'assets/rails/art-listen.jpg',
      'assets/rails/art-book.jpg',
    ];
    final seen = <String>{};
    var n = 0;
    String artFor(String art) {
      if (art.isNotEmpty && seen.add(art)) return art;
      return pool[n++ % pool.length];
    }

    final byKey = <String, StorePiece>{};
    final rails = List.generate(5, (_) => <RailCard>[]);
    for (var i = 0; i < widget.pieces.length && i < 30; i++) {
      final p = widget.pieces[i];
      final key = '${p.title}|${p.line}';
      byKey[key] = p;
      rails[i % 5].add(RailCard(p.title, p.line, p.group, art: artFor(p.art)));
    }
    return HubRails(
      a: rails[0],
      b: rails[1],
      c: rails[2],
      d: rails[3],
      e: rails[4],
      labels: const ['Feature', 'Your list', 'Challenge', 'Glass', 'Clear'],
      openGuide: false,
      onOpen: (card) => byKey['${card.title}|${card.line}']?.onTap(),
    );
  }
}
