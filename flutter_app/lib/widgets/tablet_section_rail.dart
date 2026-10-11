/// On a tablet, a section stays the width of a phone. It does not grow
/// to fill the screen. The spare width on its right is a real piece —
/// a banner, a stack of cards, or a row you can scroll — and which one
/// depends on the section, so the page is not the same strip repeated.
/// A phone is unchanged.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material's tablet breakpoint: shortest side, so a landscape phone stays
/// a phone.
bool nwsbTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// How wide a section is allowed to get. Wider than this is a tablet,
/// and the section stays here instead of stretching.
const double kTabletPhoneWidth = 400;

class TabletSectionRow extends StatelessWidget {
  const TabletSectionRow({super.key, required this.seed, required this.child});

  final String seed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!nwsbTablet(context)) return child;
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth.isFinite && box.maxWidth > 0
          ? box.maxWidth
          : MediaQuery.sizeOf(context).width;
      const gap = 12.0;
      final phone = math.min(kTabletPhoneWidth, width);
      final spare = width - phone - gap;
      final mq = MediaQuery.of(context);
      final section = MediaQuery(
        data: mq.copyWith(size: Size(phone, mq.size.height)),
        child: child,
      );
      // Not enough room for a second column: still don't stretch.
      if (spare < 150) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: phone, child: section),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: phone, child: section),
          const SizedBox(width: gap),
          Expanded(child: _SidePiece(seed: seed)),
        ],
      );
    });
  }
}

class _SidePiece extends StatelessWidget {
  const _SidePiece({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final h = seed.hashCode.abs();
    final light = Theme.of(context).scaffoldBackgroundColor.computeLuminance() > 0.45;
    final kind = h % 3;
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: switch (kind) {
        0 => _Banner(seed: h),
        1 => _CardStack(seed: h, light: light),
        _ => _CardRow(seed: h, light: light),
      },
    );
  }
}

const _shots = <String>[
  'assets/banners/stories/prana.png',
  'assets/banners/stories/soma.png',
  'assets/banners/stories/aura.png',
  'assets/banners/stories/pitta.png',
];

const _copy = <(String, String)>[
  ('Word Atelier', 'The sound behind the word'),
  ('Meanings', 'Where a word begins'),
  ('Practice', 'One sitting, one word'),
  ('Sound Library', 'Hear it, then keep it'),
  ('Signature', 'The rare set'),
  ('eBooks', 'Read it slowly'),
  ('Rewards', 'Streak, quests, season'),
  ('Quotes', 'This week, in order'),
];

(String, String) _line(int seed, int n) => _copy[(seed + n) % _copy.length];

String _shot(int seed, int n) => _shots[(seed + n) % _shots.length];

class _Banner extends StatelessWidget {
  const _Banner({required this.seed});
  final int seed;

  @override
  Widget build(BuildContext context) {
    final line = _line(seed, 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_shot(seed, 0), fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xCC000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(line.$1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(line.$2, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStack extends StatelessWidget {
  const _CardStack({required this.seed, required this.light});
  final int seed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Mini(seed: seed, n: i, light: light),
        ],
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.seed, required this.light});
  final int seed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(
          width: 148,
          child: _Mini(seed: seed, n: i, light: light, picture: true),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.seed, required this.n, required this.light, this.picture = false});
  final int seed;
  final int n;
  final bool light;
  final bool picture;

  @override
  Widget build(BuildContext context) {
    final line = _line(seed, n);
    final ink = light ? const Color(0xFF16181E) : Colors.white;
    final mute = light ? const Color(0xFF5C564E) : const Color(0xB3FFFFFF);
    final fill = light ? Colors.white : const Color(0xFF12141A);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: light ? const Color(0x14000000) : const Color(0x28FFFFFF)),
        boxShadow: light
            ? const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(4, 4))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picture)
              SizedBox(
                height: 92,
                width: double.infinity,
                child: Image.asset(_shot(seed, n), fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.$1, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(line.$2, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: mute, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
