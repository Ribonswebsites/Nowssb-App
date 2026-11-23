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
      onOpen: (card) => byKey['${card.title}|${card.line}']?.onTap(),
    );
  }
}
