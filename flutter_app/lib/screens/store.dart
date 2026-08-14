/// The Store — words, meanings and eBooks.
///
/// Three shelves, three Firestore documents, one screen. The website splits
/// these across the Word Atelier, the Meaning Store and the eBooks rail; they
/// are the same shape of thing — a name, a price, a picture — so they are
/// three tabs here rather than three screens.
///
/// The shelves are empty until the studio publishes to `content/words` and
/// `content/meanings`, which is true on the website too and is not a bug: what
/// ships with the app is the LIBRARY, and the catalogue is authored. Each tab
/// says so rather than showing a blank.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'word_detail.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final counts = [store.library.length, store.meanings.length, store.books.length];

    return PageShell(
      eyebrow: 'Own the sounds that heal',
      title: 'NowssB Store',
      film: 'assets/video/store-section.mp4',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            _Tabs(
              index: _tab,
              labels: const ['Words', 'Meanings', 'eBooks'],
              counts: counts,
              onTap: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 20),
            if (_tab == 0) ..._words(context),
            if (_tab == 1) ..._meanings(),
            if (_tab == 2) ..._books(),
          ]),
        ),
      ],
    );
  }

  List<Widget> _words(BuildContext context) {
    final words = ContentStore.instance.library;
    if (words.isEmpty) {
      return const [_Await('No words on the shelf yet.')];
    }
    return [
      for (final w in words)
        WordRow(
          word: w.word,
          deva: w.deva,
          sub: w.meaning.isNotEmpty ? w.meaning : w.organ,
          trailing: _Price(w.price),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WordDetail(word: w)),
          ),
        ),
    ];
  }

  List<Widget> _meanings() {
    final items = ContentStore.instance.meanings;
    if (items.isEmpty) {
      return const [
        _Await('The Meaning Store is published from the studio — '
            'nothing has been put on this shelf yet.'),
      ];
    }
    return [
      for (final m in items)
        WordRow(
          word: m.name,
          deva: '',
          sub: m.sub,
          trailing: _Price(m.price),
        ),
    ];
  }

  List<Widget> _books() {
    final items = ContentStore.instance.books;
    if (items.isEmpty) {
      return const [_Await('No eBooks yet.')];
    }
    return [
      for (final b in items)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF14141C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book,
                    size: 22, color: NwsbColors.goldLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    if (b.sub.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        b.sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x8CFFFFFF),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _Price(b.price),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.index,
    required this.labels,
    required this.counts,
    required this.onTap,
  });

  final int index;
  final List<String> labels;
  final List<int> counts;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${labels[i]}  ${counts[i]}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          i == index ? FontWeight.w700 : FontWeight.w400,
                      color: i == index
                          ? NwsbColors.ink
                          : const Color(0xB3FFFFFF),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price(this.value);
  final num value;

  @override
  Widget build(BuildContext context) {
    if (value <= 0) {
      return const Text(
        'Included',
        style: TextStyle(fontSize: 11, color: Color(0x8CFFFFFF)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1FC8A96E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '₹$value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: NwsbColors.goldLight,
        ),
      ),
    );
  }
}

class _Await extends StatelessWidget {
  const _Await(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined,
              size: 32, color: Color(0x66FFFFFF)),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0x8CFFFFFF),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
