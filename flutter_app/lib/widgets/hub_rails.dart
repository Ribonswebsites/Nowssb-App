/// Three horizontal card rails. No status bar, no wifi, no battery.
/// Centre art is the bundled meditation stills.
library;

import 'package:flutter/material.dart';

const kRailArt = <String>[
  'assets/rails/01.png',
  'assets/rails/02.png',
  'assets/rails/03.png',
  'assets/rails/04.png',
  'assets/rails/05.png',
  'assets/rails/06.png',
  'assets/rails/07.png',
  'assets/rails/08.png',
  'assets/rails/09.png',
  'assets/rails/10.png',
  'assets/rails/11.png',
];

class RailCard {
  const RailCard(this.title, this.line, this.meta);
  final String title;
  final String line;
  final String meta;
}

class HubRails extends StatelessWidget {
  const HubRails({super.key, required this.a, required this.b, required this.c});

  final List<RailCard> a;
  final List<RailCard> b;
  final List<RailCard> c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Continue'),
        _rail(280, 250, a, (i, card) => _FeatureCard(card: card, art: kRailArt[i % kRailArt.length])),
        _label('Your list'),
        _rail(300, 132, b, (i, card) => _RowCard(card: card, art: kRailArt[(i + 3) % kRailArt.length])),
        _label('Challenges'),
        _rail(210, 250, c, (i, card) => _ChallengeCard(card: card, art: kRailArt[(i + 6) % kRailArt.length])),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 0, 8),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _rail(double w, double h, List<RailCard> list, Widget Function(int, RailCard) item) {
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: w, child: item(i, list[i])),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.card, required this.art});
  final RailCard card;
  final String art;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(art, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC6A1B9A)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                const Spacer(),
                Text(card.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(card.meta, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(card.line, style: const TextStyle(color: Color(0x99FFFFFF))),
                    const Spacer(),
                    const Text('Continue  ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.card, required this.art});
  final RailCard card;
  final String art;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xCC101018),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.asset(art, width: 108, height: 116, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(card.meta, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFF1C1C24), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.card, required this.art});
  final RailCard card;
  final String art;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1028),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        children: [
          ClipOval(child: Image.asset(art, width: 92, height: 92, fit: BoxFit.cover)),
          const SizedBox(height: 10),
          Text(card.title, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(card.line, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('Next', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

List<RailCard> railSet(List<String> titles, String meta) => [
      for (var i = 0; i < titles.length; i++) RailCard(titles[i], '${i + 1} of ${titles.length}', meta),
    ];
