/// Kling-style login stage: the twenty campaign stills drift on four walls
/// around a phone frame. The frame is the supplied handset; sign-in sits
/// inside its screen.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoginGallery extends StatefulWidget {
  const LoginGallery({super.key, required this.child});

  final Widget child;

  @override
  State<LoginGallery> createState() => _LoginGalleryState();
}

class _LoginGalleryState extends State<LoginGallery>
    with SingleTickerProviderStateMixin {
  static const _cards = [
    'assets/login/card-01.jpg',
    'assets/login/card-02.jpg',
    'assets/login/card-03.jpg',
    'assets/login/card-04.jpg',
    'assets/login/card-05.jpg',
    'assets/login/card-06.jpg',
    'assets/login/card-07.jpg',
    'assets/login/card-08.jpg',
    'assets/login/card-09.jpg',
    'assets/login/card-10.jpg',
    'assets/login/card-11.jpg',
    'assets/login/card-12.jpg',
    'assets/login/card-13.jpg',
    'assets/login/card-14.jpg',
    'assets/login/card-15.jpg',
    'assets/login/card-16.jpg',
    'assets/login/card-17.jpg',
    'assets/login/card-18.jpg',
    'assets/login/card-19.jpg',
    'assets/login/card-20.jpg',
  ];

  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        var phoneH = h * 0.9;
        var phoneW = phoneH * (606 / 1296);
        if (phoneW > w * 0.86) {
          phoneW = w * 0.86;
          phoneH = phoneW * (1296 / 606);
        }
        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final tiles = _layout(_drift.value, w, h);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const ColoredBox(color: Color(0xFF02030A)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.05),
                      radius: 0.85,
                      colors: [Color(0x332A4CFF), Color(0x0002030A)],
                    ),
                  ),
                ),
                for (final tile in tiles)
                  Positioned(
                    left: tile.x,
                    top: tile.y,
                    width: tile.w,
                    height: tile.h,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..rotateY(tile.ry)
                        ..rotateX(tile.rx),
                      child: Opacity(
                        opacity: tile.opacity,
                        child: _Still(asset: tile.asset),
                      ),
                    ),
                  ),
                Center(
                  child: SizedBox(
                    width: phoneW,
                    height: phoneH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: phoneW * 0.09,
                          top: phoneH * 0.115,
                          width: phoneW * 0.82,
                          height: phoneH * 0.78,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(phoneW * 0.07),
                            child: const ColoredBox(color: Color(0xFF070B16)),
                          ),
                        ),
                        Positioned(
                          left: phoneW * 0.11,
                          top: phoneH * 0.145,
                          width: phoneW * 0.78,
                          height: phoneH * 0.72,
                          child: widget.child,
                        ),
                        IgnorePointer(
                          child: Image.asset(
                            'assets/login/phone-frame.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_Tile> _layout(double t, double w, double h) {
    final tiles = <_Tile>[];
    const perWall = 5;
    for (var wall = 0; wall < 4; wall++) {
      for (var i = 0; i < perWall; i++) {
        final index = wall * perWall + i;
        final phase = (t + i / perWall) % 1.0;
        final near = phase;
        final fadeIn = (near / 0.08).clamp(0.0, 1.0);
        final fadeOut = ((1 - near) / 0.07).clamp(0.0, 1.0);
        final opacity = math.min(fadeIn, fadeOut);
        final cw = w * (0.16 + near * 0.2);
        final ch = cw * 1.15;
        final spread = 0.16 + near * 0.7;
        final stagger = (i - 2) * (10 + near * 34);
        late double x;
        late double y;
        var rx = 0.0;
        var ry = 0.0;
        if (wall == 0) {
          x = w * 0.5 - w * spread * 0.58 - cw * 0.85;
          y = h * 0.42 - ch * 0.5 + stagger;
          ry = 0.62;
        } else if (wall == 1) {
          x = w * 0.5 + w * spread * 0.42 - cw * 0.1;
          y = h * 0.46 - ch * 0.5 + stagger * 0.85;
          ry = -0.62;
        } else if (wall == 2) {
          x = w * 0.5 - cw * 0.5 + stagger * 1.15;
          y = h * 0.46 - h * spread * 0.5 - ch * 0.35;
          rx = 0.78;
        } else {
          x = w * 0.5 - cw * 0.5 + stagger;
          y = h * 0.5 + h * spread * 0.38 - ch * 0.15;
          rx = -0.72;
        }
        tiles.add(_Tile(
          asset: _cards[index],
          x: x,
          y: y,
          w: cw,
          h: ch,
          rx: rx,
          ry: ry,
          opacity: opacity,
          depth: near,
        ));
      }
    }
    tiles.sort((a, b) => a.depth.compareTo(b.depth));
    return tiles;
  }
}

class _Tile {
  const _Tile({
    required this.asset,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.rx,
    required this.ry,
    required this.opacity,
    required this.depth,
  });

  final String asset;
  final double x;
  final double y;
  final double w;
  final double h;
  final double rx;
  final double ry;
  final double opacity;
  final double depth;
}

class _Still extends StatelessWidget {
  const _Still({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66D6E4FF), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}
