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
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final shown = _filter == 'All' ? widget.pieces : widget.pieces.where((p) => p.group == _filter).toList();
    final cards = [
      for (final p in shown)
        RailCard(p.title, p.line, p.group, art: p.art),
    ];
    final byTitle = {for (final p in shown) p.title: p};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final name in kStoreFilters) ...[
                StoreFilterChip(
                  label: name.toUpperCase(),
                  selected: _filter == name,
                  black: true,
                  onTap: () => setState(() => _filter = name),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text('Nothing in this filter.', style: TextStyle(color: Color(0xB3FFFFFF))),
          )
        else
          HubRails(
            a: _take(cards, 0),
            b: _take(cards, 1),
            c: _take(cards, 2),
            d: _take(cards, 3),
            e: _take(cards, 4),
            labels: widget.labels,
            openGuide: false,
            onOpen: (card) => byTitle[card.title]?.onTap(),
          ),
      ],
    );
  }

  List<RailCard> _take(List<RailCard> all, int rail) {
    if (all.isEmpty) return const [];
    final out = <RailCard>[];
    for (var i = rail; i < all.length; i += 5) {
      out.add(all[i]);
    }
    if (rail >= 3) return out.take(4).toList();
    return out;
  }
}
