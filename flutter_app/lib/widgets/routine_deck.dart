/// One working horizontal card row, in the original My Routine language.
///
/// Title, black banner, step dots, image cards with the store mark and a
/// black action bar. Every card calls [WorkCard.onTap]. No second rail.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin/template/editable.dart';

const kRoutineArts = <String>[
  'assets/routine/trusting-the-breath.png',
  'assets/routine/positive-self-talk.png',
  'assets/routine/your-body-knows.png',
  'assets/routine/stillness.png',
  'assets/routine/softer-voice.png',
  'assets/routine/quiet-within.png',
];

class WorkCard {
  const WorkCard({
    required this.category,
    required this.title,
    required this.meta,
    required this.action,
    required this.onTap,
    this.onBuy,
    this.onCart,
    this.image,
    this.tint = const Color(0xFFE9C1A5),
  });

  final String category;
  final String title;
  final String meta;
  final String action;
  final VoidCallback onTap;
  final VoidCallback? onBuy;
  final VoidCallback? onCart;
  final String? image;
  final Color tint;
}

/// Title, banner, dots and one horizontal row.
class RoutineDeck extends StatefulWidget {
  const RoutineDeck({
    super.key,
    required this.title,
    required this.banner,
    required this.bannerSub,
    required this.cards,
    this.onBanner,
  });

  final String title;
  final String banner;
  final String bannerSub;
  final List<WorkCard> cards;
  final VoidCallback? onBanner;

  @override
  State<RoutineDeck> createState() => _RoutineDeckState();
}

class _RoutineDeckState extends State<RoutineDeck> {
  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
              ),
              Text('$n cards', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _Banner(title: widget.banner, subtitle: widget.bannerSub, onTap: widget.onBanner ?? (n == 0 ? null : widget.cards.first.onTap)),
          const SizedBox(height: 14),
          SizedBox(
            height: 420,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: n,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _RoutineCard(card: widget.cards[i], image: widget.cards[i].image ?? kRoutineArts[i % kRoutineArts.length]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.title, required this.subtitle, this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.05)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(0, 8);
    return Row(
      children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) Expanded(child: Container(height: 2, color: const Color(0x33FFFFFF))),
          Container(
            width: i == active ? 14 : 10,
            height: i == active ? 14 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == active ? const Color(0xFFFF8A2A) : const Color(0xFFD7D7DE),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.card, required this.image});
  final WorkCard card;
  final String image;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    return SizedBox(
      width: 330,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          card.onTap();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                    child: Container(
                      height: 297,
                      decoration: BoxDecoration(
                        color: const Color(0x0EFFFFFF),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(color: const Color(0x21FFFFFF)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.category, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 12)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: image.startsWith('http')
                                ? Image.network(image, height: 152, width: double.infinity, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => const SizedBox(height: 152))
                                : EditableImage.asset(
                                    image,
                                    height: 152,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    slot: 'routine_deck.RoutineCard',
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(card.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 38),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
                  child: card.onBuy != null || card.onCart != null
                      ? Row(
                          children: [
                            Expanded(child: _CardAct(label: 'Add to cart', onTap: card.onCart)),
                            const SizedBox(width: 8),
                            Expanded(child: _CardAct(label: 'Buy now', onTap: card.onBuy, filled: true)),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: Text(card.action, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ],
            ),
            Positioned(
              left: 135,
              top: 269,
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: card.tint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: EditableImage.asset(
                  card.onBuy != null || card.onCart != null ? 'assets/store/nowssb-store-mark.png' : 'assets/banners/promo/store.png',
                  fit: BoxFit.contain,
                  slot: 'routine_deck.RoutineCard',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardAct extends StatelessWidget {
  const _CardAct({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: filled ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
