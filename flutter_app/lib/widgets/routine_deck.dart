/// One working horizontal card row, in the original My Routine language.
///
/// Title, black banner, step dots, image cards with the store mark and a
/// black action bar. Every card calls [WorkCard.onTap]. No second rail.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../admin/template/editable.dart';
import 'nwsb_icon.dart';

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
    this.flip,
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
  /// The other face. When set, the picture flips to it every second.
  final String? flip;
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
            height: widget.cards.any((c) => c.onBuy != null || c.onCart != null) ? 530 : 420,
            // B025: a card never outgrows a narrow deck (320 x1.3).
            child: LayoutBuilder(builder: (context, box) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: n,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _RoutineCard(card: widget.cards[i], image: widget.cards[i].image ?? kRoutineArts[i % kRoutineArts.length], width: math.min(330, box.maxWidth)),
            )),
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
  const _RoutineCard({required this.card, required this.image, this.width = 330});
  final WorkCard card;
  final double width;
  final String image;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    final shop = card.onBuy != null || card.onCart != null;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          card.onTap();
        },
        child: shop ? _shopFace(radius) : _plainFace(radius),
      ),
    );
  }

  Widget _plainFace(double radius) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _glass(
              radius,
              height: 297,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.category, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 12)),
                  const SizedBox(height: 10),
                  _photo(image, height: 152, fit: BoxFit.cover),
                  const SizedBox(height: 12),
                  Text(card.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
                ],
              ),
            ),
            const SizedBox(height: 38),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(child: Text(card.action, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ],
        ),
        const Positioned(left: 135, top: 269, child: _StoreDot()),
      ],
    );
  }

  Widget _shopFace(double radius) {
    return _glass(
      radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.category, style: const TextStyle(color: Color(0xC6FFFFFF), fontSize: 12)),
          const SizedBox(height: 10),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              _FlipFrame(front: image, back: card.flip ?? image, height: 290),
              const Positioned(bottom: -28, child: _StoreDot()),
            ],
          ),
          const SizedBox(height: 36),
          Text(card.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 12)),
          const SizedBox(height: 4),
          Text(card.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 14),
          _OctButtons(onCart: card.onCart, onBuy: card.onBuy),
        ],
      ),
    );
  }

  Widget _glass(double radius, {double? height, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x0EFFFFFF),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x21FFFFFF)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: child,
        ),
      ),
    );
  }

  Widget _photo(String src, {required double height, required BoxFit fit}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: src.startsWith('http')
            ? Image.network(src, height: height, width: double.infinity, fit: fit, errorBuilder: (_, __, ___) => SizedBox(height: height))
            : EditableImage.asset(src, height: height, width: double.infinity, fit: fit, slot: 'routine_deck.RoutineCard'),
      ),
    );
  }
}

class _FlipFrame extends StatefulWidget {
  const _FlipFrame({required this.front, required this.back, required this.height});
  final String front;
  final String back;
  final double height;

  @override
  State<_FlipFrame> createState() => _FlipFrameState();
}

class _FlipFrameState extends State<_FlipFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  bool _showingFront = true;
  bool _run = true;

  @override
  void initState() {
    super.initState();
    if (widget.front != widget.back) _loop();
  }

  Future<void> _loop() async {
    while (_run && mounted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!_run || !mounted || widget.front == widget.back) return;
      await _c.forward(from: 0);
      if (!_run || !mounted) return;
      setState(() => _showingFront = !_showingFront);
      _c.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _FlipFrame old) {
    super.didUpdateWidget(old);
    if (old.back != widget.back && widget.front != widget.back && !_run) {
      _run = true;
      _loop();
    }
  }

  @override
  void dispose() {
    _run = false;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.front == widget.back) return _still(widget.front, widget.height);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final past = t >= 0.5;
        final showFront = _showingFront ? !past : past;
        final angle = (t < 0.5 ? t : 1 - t) * 3.14159;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY(angle),
          child: _still(showFront ? widget.front : widget.back, widget.height),
        );
      },
    );
  }
}

Widget _still(String src, double height) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColoredBox(
      color: Colors.black,
      child: src.startsWith('http')
          ? Image.network(src, height: height, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => SizedBox(height: height))
          : EditableImage.asset(src, height: height, width: double.infinity, fit: BoxFit.contain, slot: 'routine_deck.RoutineCard'),
    ),
  );
}

class _StoreDot extends StatelessWidget {
  const _StoreDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9C1A5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const EditableImage.asset(
        'assets/banners/promo/store.png',
        fit: BoxFit.contain,
        slot: 'routine_deck.RoutineCard',
      ),
    );
  }
}

class _OctButtons extends StatelessWidget {
  const _OctButtons({required this.onCart, required this.onBuy});
  final VoidCallback? onCart;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCart == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onCart!();
                },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xE60A101C),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66E8D5A3)),
            ),
            child: const NwsbIcon(NwsbMarks.cart, size: 16, color: Color(0xFFE8D5A3)),
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 28, color: const Color(0x66FFFFFF)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onBuy == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onBuy!();
                },
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: 12, right: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [Color(0xFFF3E4B7), Color(0xFFC8A96E)]),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Buy Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF060C18))),
                SizedBox(width: 7),
                _BagDisc(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BagDisc extends StatelessWidget {
  const _BagDisc();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const NwsbIcon(NwsbMarks.bag, size: 15, color: Color(0xFF060C18)),
    );
  }
}
