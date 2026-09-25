/// Login stage. A fashion-home glass panel stays in the middle.
/// Twenty stills, one size, sit in a grid and drift from the top
/// to the bottom. No overlap. They loop.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';

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
    final pad = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const gap = 10.0;
        const cols = 4;
        const rows = 5;
        final tile = ((w - gap * (cols + 1)) / cols).floorToDouble();
        final gridH = rows * tile + (rows - 1) * gap;
        final stride = gridH + gap;
        return AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final dy = _drift.value * stride;
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const ColoredBox(color: Color(0xFF000000)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: w,
                        maxWidth: w,
                        minHeight: 0,
                        maxHeight: double.infinity,
                        child: Transform.translate(
                          offset: Offset(0, -stride + dy),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: gap),
                            child: Column(
                              children: [
                                for (var i = 0; i < (h / stride).ceil() + 1; i++) ...[
                                  if (i > 0) const SizedBox(height: gap),
                                  _grid(tile, gap),
                                ],
                              ],
                            ),
                          ),
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
                          filter: ImageFilter.blur(
                            sigmaX: GlassWrap.blurSigma,
                            sigmaY: GlassWrap.blurSigma,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0x2EFFFFFF),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0x55FFFFFF)),
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

  Widget _grid(double tile, double gap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < 5; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Row(
            children: [
              for (var c = 0; c < 4; c++) ...[
                if (c > 0) SizedBox(width: gap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _cards[r * 4 + c],
                    width: tile,
                    height: tile,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
