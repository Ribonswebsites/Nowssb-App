/// Three horizontal card rails.
///
/// Feature, list and challenge cards follow the glass references:
/// avatar pile, Active pill, clock / star / bookmark, Continue,
/// and the circular Skip / Next card. No fake status bar.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../features/programs/program_router.dart';

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







const kGlassArt = <String>[
  'assets/rails/glass-01.jpg',
  'assets/rails/glass-02.jpg',
  'assets/rails/glass-03.jpg',
  'assets/rails/glass-04.jpg',
];

const kClearArt = <String>[
  'assets/rails/clear-01.jpg',
  'assets/rails/clear-02.jpg',
  'assets/rails/clear-03.jpg',
  'assets/rails/clear-04.jpg',
];
const _dur = ['18h 9m', '12h 24m', '4 min', '8 min', '21 min'];
const _rate = ['4.7', '4.8', '4.9', '4.6', '5.0'];
const _saves = ['16', '12', '8', '24', '31'];
const _people = ['+12', '+8', '+2k', '+6', '+19'];

ImageProvider<Object> railImage(String art) => art.startsWith('http') ? NetworkImage(art) : AssetImage(art);

Widget railPicture(String art, {double? width, double? height, Alignment alignment = Alignment.center, BoxFit fit = BoxFit.cover}) {
  final broken = ColoredBox(color: const Color(0xFF2A1038), child: SizedBox(width: width, height: height));
  if (art.startsWith('http')) {
    return Image.network(art, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => broken);
  }
  return Image.asset(art, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: (_, __, ___) => broken);
}

class RailCard {
  const RailCard(this.title, this.line, this.meta, {this.art = ''});
  final String title;
  final String line;
  final String meta;
  final String art;
}

List<RailCard> railSet(List<String> titles, String meta) => [
      for (var i = 0; i < titles.length; i++) RailCard(titles[i], '${i + 1} of ${titles.length}', meta),
    ];



class HubRails extends StatelessWidget {
  const HubRails({
    super.key,
    required this.a,
    required this.b,
    required this.c,
    this.d = const [],
    this.e = const [],
    this.arts = kRailArt,
    this.labels = const ['Continue', 'Your list', 'Challenges'],
    this.onOpen,
  });

  final List<RailCard> a;
  final List<RailCard> b;
  final List<RailCard> c;
  final List<RailCard> d;
  final List<RailCard> e;
  final List<String> arts;
  final List<String> labels;
  final void Function(RailCard card)? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (a.isNotEmpty) ...[
          _label(labels[0]),
          _rail(context, 292, 332, a, 0),
        ],
        if (b.isNotEmpty) ...[
          _label(labels.length > 1 ? labels[1] : 'Your list'),
          _rail(context, 318, 168, b, 1),
        ],
        if (c.isNotEmpty) ...[
          _label(labels.length > 2 ? labels[2] : 'Challenges'),
          _rail(context, 214, 312, c, 2),
        ],
        if (d.isNotEmpty) ...[
          _label(labels.length > 3 ? labels[3] : 'Glass'),
          _rail(context, 300, 392, d, 3),
        ],
        if (e.isNotEmpty) ...[
          _label(labels.length > 4 ? labels[4] : 'Clear'),
          _rail(context, 250, 430, e, 4),
        ],
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      );

  Widget _rail(BuildContext context, double w, double h, List<RailCard> list, int rail) {
    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final card = list[i];
          final art = card.art.isNotEmpty ? card.art : _pick(rail, i);
          final child = switch (rail) {
            0 => _FeatureCard(card: card, art: art, index: i),
            1 => _RowCard(card: card, art: art, index: i),
            2 => _ChallengeCard(card: card, art: art, index: i),
            3 => _GlassCourseCard(card: card, art: art, index: i, total: list.length),
            _ => _ClearChallengeCard(card: card, art: art, index: i),
          };
          return SizedBox(
            width: w,
            child: GestureDetector(
              onTap: () {
                onOpen?.call(card);
              },
              child: child,
            ),
          );
        },
      ),
    );
  }

  String _pick(int rail, int i) {
    if (rail == 3) return kGlassArt[i % kGlassArt.length];
    if (rail == 4) return kClearArt[i % kClearArt.length];
    final n = arts.length;
    if (n == 0) return kRailArt[i % kRailArt.length];
    if (n >= 15) return arts[(rail * 5 + i) % n];
    if (rail == 0) return arts[i % n];
    if (rail == 1) return arts[(i + (n > 5 ? 5 : 2)) % n];
    return arts[(n - 1 - i) % n];
  }
}

class RailFaces extends StatelessWidget {
  const RailFaces({super.key, required this.count, this.size = 28});
  final String count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size;
    Widget face(String asset, double left) => Positioned(
          left: left,
          top: 0,
          child: Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
            ),
          ),
        );
    return SizedBox(
      width: s * 2.45,
      height: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face('assets/profile/rails/avatar_a.jpg', 0),
          face('assets/profile/rails/avatar_b.jpg', s * 0.58),
          Positioned(
            left: s * 1.16,
            top: 0,
            child: Container(
              width: s,
              height: s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: const Color(0xFF161616),
                  fontWeight: FontWeight.w800,
                  fontSize: count.length > 2 ? s * 0.28 : s * 0.34,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.index, this.color = Colors.white});
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600);
    final dim = color.withValues(alpha: 0.92);
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: dim),
        const SizedBox(width: 4),
        Text(_dur[index % _dur.length], style: style),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC857)),
        const SizedBox(width: 2),
        Text(_rate[index % _rate.length], style: style),
        const SizedBox(width: 8),
        Icon(Icons.bookmark_border_rounded, size: 14, color: dim),
        const SizedBox(width: 3),
        Text(_saves[index % _saves.length], style: style),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            railPicture(art),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x33201030), Color(0xCC5A1878), Color(0xE0460F62)],
                  stops: [0.18, 0.48, 0.78, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RailFaces(count: _people[index % _people.length]),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Active', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.05, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  SizedBox(height: 18, width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _MetaRow(index: index))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(card.line, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 13)),
                      const Spacer(),
                      const Text('Continue  ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0121218),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: railPicture(art, width: 112, height: 148, alignment: const Alignment(0, -0.4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(alignment: Alignment.centerRight, child: RailFaces(count: _people[(index + 2) % _people.length], size: 24)),
                  const SizedBox(height: 6),
                  Text(card.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.3)),
                  const Spacer(),
                  SizedBox(height: 16, width: double.infinity, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _MetaRow(index: index))),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Color(0xFF2A2A32), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE01A102C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        child: Column(
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x66FFFFFF), width: 2),
                image: DecorationImage(image: railImage(art), fit: BoxFit.cover, alignment: const Alignment(0, 0.35)),
              ),
            ),
            const SizedBox(height: 12),
            Text(card.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.15)),
            const SizedBox(height: 6),
            Text(card.meta, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, height: 1.25)),
            const Spacer(),
            Row(
              children: [
                const Text('Skip', style: TextStyle(color: Color(0xB3FFFFFF), fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Next', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var dot = 0; dot < 3; dot++)
                  Container(
                    width: dot == index % 3 ? 7 : 5,
                    height: dot == index % 3 ? 7 : 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(color: dot == index % 3 ? Colors.white : const Color(0x55FFFFFF), shape: BoxShape.circle),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// The fourth and fifth rails. The first three card widgets are unchanged.
class _GlassCourseCard extends StatelessWidget {
  const _GlassCourseCard({required this.card, required this.art, required this.index, required this.total});
  final RailCard card;
  final String art;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x66FFFFFF)),
            color: const Color(0x1AFFFFFF),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              railPicture(art),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x33000000), Color(0xCC120818)],
                    stops: [0.35, 0.62, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RailFaces(count: _people[index % _people.length]),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Active', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.05)),
                    const SizedBox(height: 8),
                    _MetaRow(index: index),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('${index + 1} of $total', style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 13)),
                        const Spacer(),
                        const Text('Continue  ›', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearChallengeCard extends StatelessWidget {
  const _ClearChallengeCard({required this.card, required this.art, required this.index});
  final RailCard card;
  final String art;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x55FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x88FFFFFF), width: 2),
                    image: DecorationImage(image: railImage(art), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x55FFFFFF)),
                          color: const Color(0x1AFFFFFF),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.1)),
                              const SizedBox(height: 4),
                              Text(card.meta, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.25)),
                              const Spacer(),
                              Row(
                                children: [
                                  const Text('Skip', style: TextStyle(color: Color(0xE6FFFFFF), fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0x33FFFFFF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0x88FFFFFF)),
                                    ),
                                    child: const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var dot = 0; dot < 4; dot++)
                                    Container(
                                      width: dot == index % 4 ? 7 : 5,
                                      height: dot == index % 4 ? 7 : 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(color: dot == index % 4 ? Colors.white : const Color(0x66FFFFFF), shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

