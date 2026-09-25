/// Login stage. No phone. A glass panel stays in the middle.
/// Ten stills fall from the top like shooting stars. Ten rise from the
/// bottom. Left and right walls travel the opposite way. Black, looping.
library;

import 'dart:ui' show ImageFilter;

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
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final tiles = _layout(_drift.value, w, h);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const ColoredBox(color: Color(0xFF000000)),
                IgnorePointer(
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      for (final tile in tiles)
                        if (tile.opacity > 0.04)
                          Positioned(
                            left: tile.x,
                            top: tile.y,
                            width: tile.w,
                            height: tile.h,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0011)
                                ..rotateX(tile.rx)
                                ..rotateY(tile.ry),
                              child: Opacity(
                                opacity: tile.opacity,
                                child: _Still(asset: tile.asset),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.02),
                      radius: 0.95,
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0x99000000),
                      ],
                      stops: [0.5, 0.78, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.22,
                  right: w * 0.22,
                  top: h * 0.58,
                  child: const IgnorePointer(
                    child: SizedBox(
                      height: 36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xCC3D6BFF),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: Color(0x887A3CFF),
                              blurRadius: 48,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, pad.top + 12, 18, pad.bottom + 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: h - pad.top - pad.bottom - 24,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xC4101422),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0x66FFFFFF)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99000000),
                                  blurRadius: 32,
                                  offset: Offset(0, 18),
                                ),
                              ],
                            ),
                            child: widget.child,
                          ),
                        ),
                      ),
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
    final cx = w / 2;
    final cy = h * 0.48;
    final focal = w * 1.05;

    void add({
      required String asset,
      required double worldX,
      required double worldY,
      required double z,
      required double rx,
      required double ry,
      required double phase,
      double cardWorld = 1.12,
    }) {
      final fadeIn = (phase / 0.07).clamp(0.0, 1.0);
      final fadeOut = ((1 - phase) / 0.1).clamp(0.0, 1.0);
      final sx = cx + (worldX / z) * focal;
      final sy = cy + (worldY / z) * focal;
      final cw = (cardWorld / z) * focal;
      final ch = cw * 0.72;
      tiles.add(_Tile(
        asset: asset,
        x: sx - cw / 2,
        y: sy - ch / 2,
        w: cw,
        h: ch,
        rx: rx,
        ry: ry,
        opacity: fadeIn * fadeOut,
        depth: z,
      ));
    }

    // Top puzzle: images 1–10. Rows fall from the top toward the glass.
    for (var c = 0; c < 5; c++) {
      for (var k = 0; k < 3; k++) {
        final phase = ((k / 3) + t) % 1.0;
        final lane = (c - 2).toDouble();
        final z = 4.2 - phase * 2.5;
        final worldY = -3.36 + phase * 2.95;
        add(
          asset: _cards[c + (k % 2) * 5],
          worldX: lane * 0.9,
          worldY: worldY,
          z: z,
          rx: 0.78,
          ry: lane * -0.05,
          phase: phase,
        );
      }
    }

    // Bottom puzzle: images 11–20. Same grid, shooting up from below.
    for (var c = 0; c < 5; c++) {
      for (var k = 0; k < 3; k++) {
        final phase = ((k / 3) + t) % 1.0;
        final lane = (c - 2).toDouble();
        final z = 1.7 + phase * 2.5;
        final worldY = 1.49 - phase * 0.48;
        add(
          asset: _cards[10 + c + (k % 2) * 5],
          worldX: lane * 0.9,
          worldY: worldY,
          z: z,
          rx: -0.74,
          ry: lane * 0.05,
          phase: phase,
          cardWorld: 1.22,
        );
      }
    }

    // Left wall falls. Right wall rises.
    for (var i = 0; i < 5; i++) {
      final phase = ((i / 5) + t) % 1.0;
      add(
        asset: _cards[i * 2],
        worldX: -1.15 - phase * 0.12,
        worldY: -1.6 + phase * 3.2,
        z: 3.2 - phase * 1.35,
        rx: 0,
        ry: 0.82,
        phase: phase,
        cardWorld: 1.3,
      );
    }
    for (var i = 0; i < 5; i++) {
      final phase = ((i / 5) + t) % 1.0;
      add(
        asset: _cards[10 + i * 2],
        worldX: 1.15 + phase * 0.12,
        worldY: 1.6 - phase * 3.2,
        z: 1.85 + phase * 1.35,
        rx: 0,
        ry: -0.82,
        phase: phase,
        cardWorld: 1.3,
      );
    }

    tiles.sort((a, b) => b.depth.compareTo(a.depth));
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
        border: Border.all(color: const Color(0xAAE7F4FF), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Color(0xE6000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}
