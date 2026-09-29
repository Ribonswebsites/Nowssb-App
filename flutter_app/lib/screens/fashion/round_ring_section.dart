/// Fashion home — the round ring.
///
/// The photographs already in the app (promo poses, the word stories, the
/// earn portraits, the fashion still) sit on a spinning cylinder. Under it,
/// the same set is a chooser: tap a face to put it on the ring or take it
/// off. The choice is remembered.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/glass_wrap.dart';
import '../../widgets/round_carousel.dart';

class RingFace {
  const RingFace(this.id, this.asset, this.label);
  final String id;
  final String asset;
  final String label;
}

/// Every photograph the ring is allowed to use. Order here is the order
/// on the ring and in the chooser.
const kRingCatalog = <RingFace>[
  RingFace('pose-01', 'assets/banners/promo/pose-01.png', 'One'),
  RingFace('pose-02', 'assets/banners/promo/pose-02.png', 'Two'),
  RingFace('pose-03', 'assets/banners/promo/pose-03.png', 'Three'),
  RingFace('pose-04', 'assets/banners/promo/pose-04.png', 'Four'),
  RingFace('pose-05', 'assets/banners/promo/pose-05.png', 'Five'),
  RingFace('pose-07', 'assets/banners/promo/pose-07.png', 'Seven'),
  RingFace('pose-08', 'assets/banners/promo/pose-08.png', 'Eight'),
  RingFace('soma', 'assets/banners/stories/soma.png', 'Soma'),
  RingFace('pitta', 'assets/banners/stories/pitta.png', 'Pitta'),
  RingFace('prana', 'assets/banners/stories/prana.png', 'Prana'),
  RingFace('aura', 'assets/banners/stories/aura.png', 'Aura'),
  RingFace('atelier', 'assets/banners/earn/bag-blonde.jpg', 'Atelier'),
  RingFace('sit', 'assets/banners/earn/sit-light.png', 'Sit'),
  RingFace('fashion', 'assets/fashion/fp-intro.webp', 'Fashion'),
];

const _kRingKey = 'nwsb_ring_faces';

const _defaultOn = <String>{
  'pose-01',
  'pose-02',
  'pose-03',
  'pose-04',
  'pose-05',
  'soma',
  'pitta',
  'prana',
};

class RoundRingSection extends StatefulWidget {
  const RoundRingSection({super.key});

  @override
  State<RoundRingSection> createState() => _RoundRingSectionState();
}

class _RoundRingSectionState extends State<RoundRingSection> {
  Set<String> _on = {..._defaultOn};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kRingKey);
    if (!mounted || saved == null) return;
    final known = kRingCatalog.map((e) => e.id).toSet();
    final ids = saved.where(known.contains).toSet();
    if (ids.length < 4) return;
    setState(() => _on = ids);
  }

  Future<void> _toggle(String id) async {
    final next = {..._on};
    if (next.contains(id)) {
      if (next.length <= 4) return;
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => _on = next);
    final prefs = await SharedPreferences.getInstance();
    final ordered =
        kRingCatalog.map((e) => e.id).where(next.contains).toList();
    await prefs.setStringList(_kRingKey, ordered);
  }

  @override
  Widget build(BuildContext context) {
    final chosen =
        kRingCatalog.where((f) => _on.contains(f.id)).toList(growable: false);

    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'THE RING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: Color(0xFFE4C56A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Faces in motion',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: Color(0xFFF4F4F5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${chosen.length} on the ring · drag to turn it',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xB3F4F4F5),
            ),
          ),
          const SizedBox(height: 8),
          RoundCarousel(
            images: chosen.map((f) => f.asset).toList(growable: false),
            speed: 3.2,
            tilt: -8,
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the faces',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF6EDD8),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tap a photograph to put it on the ring or take it off. Four stay, so the ring still has a shape.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0x99F4F4F5),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kRingCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final face = kRingCatalog[i];
                final on = _on.contains(face.id);
                final locked = on && _on.length <= 4;
                return Semantics(
                  button: true,
                  selected: on,
                  label: '${face.label}${on ? ', on the ring' : ''}',
                  child: GestureDetector(
                    onTap: locked ? null : () => _toggle(face.id),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 58,
                          height: 70,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: on
                                  ? const Color(0xFFE4C56A)
                                  : const Color(0x33FFFFFF),
                              width: on ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.asset(
                              face.asset,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFF141414)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 58,
                          child: Text(
                            face.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: on
                                  ? const Color(0xFFE4C56A)
                                  : const Color(0x80F4F4F5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
