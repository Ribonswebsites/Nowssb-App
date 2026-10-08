/// On a tablet, a section stays about a phone wide and is centred. The
/// strip on its right is a vertical stack of 3D motion, so the page is not
/// one stretched phone layout. A phone is unchanged.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin/layout/anims/anim_library.dart';
import '../admin/layout/scopes.dart';
import '../screens/normal/glassmorphism_theme.dart';
import 'glass_wrap.dart';

/// Material's tablet breakpoint: shortest side, so a landscape phone stays
/// a phone.
bool nwsbTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

const _threeD = <String>[
  'orb.sphere',
  'orb.gyro',
  'orb.atom',
  'orb.globe',
  'orb.prism',
  'orb.galaxy',
  'orb.plasma',
  'orb.yarn',
  'orb.eclipse',
  'orb.nebula',
  'bg.warp',
  'bg.synth',
];

/// [child] is the section. On a phone this is just [child].
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
      if (width < 480) return child;
      const railMax = 200.0;
      final content = (width - 168).clamp(280.0, 520.0);
      final rail = math.min(railMax, math.max(120.0, width - content));
      final column = math.min(content, width - rail);
      final mq = MediaQuery.of(context);
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: column + rail,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(right: rail),
                child: MediaQuery(
                  data: mq.copyWith(size: Size(column, mq.size.height)),
                  child: child,
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 6,
                width: rail - 12,
                child: _SideMotion(seed: seed),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SideMotion extends StatelessWidget {
  const _SideMotion({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final h = seed.hashCode.abs();
    final picked = <AnimSpec>[
      for (final n in [0, 3, 7])
        if (animById(_threeD[(h + n) % _threeD.length]) case final s?) s,
    ];
    if (picked.isEmpty) return const SizedBox.shrink();
    final still = editorHoldsStill(context);
    final light = StoreSurface.lightOf(context) || NormalGlassMode.of(context);
    return LayoutBuilder(builder: (context, box) {
      final height = box.maxHeight;
      final width = box.maxWidth;
      if (!height.isFinite || height < 40 || width < 36) {
        return const SizedBox.shrink();
      }
      final count = height < 150 ? 1 : (height < 280 ? 2 : 3);
      final specs = picked.take(count).toList();
      final fit = math.min(width - 4, (height - 8) / specs.length - 6);
      if (fit < 32) return const SizedBox.shrink();
      final dim = fit.clamp(32.0, 128.0);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: light ? const Color(0x14000000) : const Color(0x28E8D5A3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final s in specs)
              AnimView(
                spec: s,
                size: dim,
                fps: 24,
                fixedT: still ? 0.35 : null,
                ink: AnimInk(onLight: light),
              ),
          ],
        ),
      );
    });
  }
}
