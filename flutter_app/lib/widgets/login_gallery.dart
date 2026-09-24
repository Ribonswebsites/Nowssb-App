/// Login stage. The handset stays small in the middle. Twenty campaign
/// stills travel the four walls of a tunnel, looping toward the camera.
library;

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
      duration: const Duration(seconds: 18),
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
        var phoneH = h * 0.5;
        var phoneW = phoneH * (606 / 1296);
        if (phoneW > w * 0.46) {
          phoneW = w * 0.46;
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
                const ColoredBox(color: Color(0xFF010208)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.08),
                      radius: 0.72,
                      colors: [Color(0x553A2CFF), Color(0x22101840), Color(0xFF010208)],
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
                        ..setEntry(3, 2, 0.0014)
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
                          left: phoneW * 0.07,
                          right: phoneW * 0.07,
                          top: phoneH * 0.1,
                          bottom: phoneH * 0.06,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(phoneW * 0.08),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF0A1024), Color(0xFF12082A), Color(0xFF06182C)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: phoneW * 0.1,
                          top: phoneH * 0.13,
                          width: phoneW * 0.8,
                          height: phoneH * 0.76,
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
                Positioned(
                  left: w * 0.28,
                  right: w * 0.28,
                  top: h * 0.5 + phoneH * 0.42,
                  child: IgnorePointer(
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: const [
                          BoxShadow(color: Color(0xAA3D6BFF), blurRadius: 28, spreadRadius: 4),
                          BoxShadow(color: Color(0x667A3CFF), blurRadius: 40, spreadRadius: 8),
                        ],
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
    final cy = h * 0.46;
    final focal = w * 0.82;
    const depthCount = 4;
    const lanes = 3;
    var n = 0;
    for (var wall = 0; wall < 4; wall++) {
      for (var lane = 0; lane < lanes; lane++) {
        for (var d = 0; d < depthCount; d++) {
          final asset = _cards[n % _cards.length];
          n++;
          var zNorm = (d + lane * 0.16 + wall * 0.04 - t * depthCount) % depthCount;
          if (zNorm < 0) zNorm += depthCount;
          final z = 1.28 + (zNorm / depthCount) * 5.15;
          final laneT = (lane - 1).toDouble();
          var wx = 0.0;
          var wy = 0.0;
          var rx = 0.0;
          var ry = 0.0;
          const wallDist = 1.08;
          const spread = 0.78;
          const cardWorld = 1.18;
          if (wall == 0) {
            wx = -wallDist;
            wy = laneT * spread;
            ry = 0.58;
          } else if (wall == 1) {
            wx = wallDist;
            wy = laneT * spread;
            ry = -0.58;
          } else if (wall == 2) {
            wy = -wallDist * 0.96;
            wx = laneT * spread;
            rx = 0.64;
          } else {
            wy = wallDist;
            wx = laneT * spread;
            rx = -0.56;
          }
          final sx = cx + (wx / z) * focal;
          final sy = cy + (wy / z) * focal;
          final cw = (cardWorld / z) * focal;
          final ch = cw * 0.66;
          final nearFade = ((z - 1.22) / 0.28).clamp(0.0, 1.0);
          final farFade = ((6.7 - z) / 0.7).clamp(0.0, 1.0);
          tiles.add(_Tile(
            asset: asset,
            x: sx - cw / 2,
            y: sy - ch / 2,
            w: cw,
            h: ch,
            rx: rx,
            ry: ry,
            opacity: nearFade * farFade,
            depth: z,
          ));
        }
      }
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88E7F0FF), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0xCC000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}
