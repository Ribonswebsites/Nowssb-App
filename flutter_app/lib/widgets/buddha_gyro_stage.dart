/// Today's Quotes — two auto-rotating cards.
///
/// The type plate fills the card in black. Dragging it left and right
/// reveals the other side of the poster; anything past the plate stays
/// black, never the home's glass or neu colour. The Buddha is smaller and
/// sits on the bottom edge so the words stay readable around it.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'app_thinking_loader.dart';
import 'glass_wrap.dart';
import 'neumorphic.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class BuddhaGyroStage extends StatefulWidget {
  const BuddhaGyroStage({
    super.key,
    this.neumorphic = false,
    this.onOpenQuotes,
  });

  /// Normal home. Fashion never gets a neu wrapper.
  final bool neumorphic;
  final VoidCallback? onOpenQuotes;

  @override
  State<BuddhaGyroStage> createState() => _BuddhaGyroStageState();
}

class _BuddhaGyroStageState extends State<BuddhaGyroStage> {
  StreamSubscription<AccelerometerEvent>? _sub;
  Timer? _pageAuto;
  late final PageController _pager;
  double _pitch = 0;
  double _pan = 0;
  var _page = 0;
  var _userPaging = false;

  static const _stageH = 680.0;

  @override
  void initState() {
    super.initState();
    _pager = PageController();
    if (_flutterTest) return;
    try {
      _sub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((e) {
        if (!mounted) return;
        final pitch = math.atan2(e.z, e.y);
        final next = (pitch / 0.55).clamp(-1.0, 1.0);
        if ((next - _pitch).abs() < 0.02) return;
        setState(() => _pitch = next);
      }, onError: (_) {});
    } catch (_) {}
    _pageAuto = Timer.periodic(const Duration(milliseconds: 5200), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % 2;
      _pager.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pageAuto?.cancel();
    _pager.dispose();
    super.dispose();
  }

  void _drag(double dx) {
    final box = context.findRenderObject();
    final w = box is RenderBox && box.hasSize ? box.size.width : 340.0;
    // Travel far enough to reveal the other side of the poster, then black.
    final limit = (w * 0.92).clamp(160.0, 520.0);
    setState(() => _pan = (_pan + dx).clamp(-limit, limit));
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.neumorphic ? const Color(0xFF2B2D33) : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            "Today's Quotes",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _enterBar(),
        ),
        SizedBox(
          height: _stageH,
          child: PageView(
            controller: _pager,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => _page = i,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _shell(0, _stage('assets/banners/gyro/buddha.png')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _shell(
                  1,
                  _stage('assets/banners/gyro/buddha-hand.png', orb: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shell(int index, Widget child) {
    if (widget.neumorphic) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: index == 0 ? 18 : 26,
        elevation: index == 0 ? NwsbElevation.md : NwsbElevation.sm,
        child: child,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: index == 0 ? 18 : 26,
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  Widget _stage(String figure, {bool orb = false}) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _drag(d.delta.dx),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              // The plate is the poster’s own shape, contained in the card,
              // so the whole line reads. Dragging it still lands on black.
              const posterAspect = 844 / 1500;
              final plateH = h * 0.92;
              final plateW = plateH * posterAspect;
              final plateTilt = Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateX(_pitch * 0.22)
                ..rotateY((_pan / w).clamp(-1.0, 1.0) * 0.08);
              final tilt = Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_pitch * 0.28)
                ..translateByDouble(0, _pitch * 8, 0, 1);
              const aspect = 844 / 1500;
              final imgH = h * 0.42;
              final imgW = imgH * aspect;
              final left = (w - imgW) / 2;
              final top = h - imgH;
              const orbSize = 46.0;
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: (w - plateW) / 2 + _pan,
                    top: (h - plateH) / 2 + _pitch * -18,
                    width: plateW,
                    height: plateH,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: plateTilt,
                      child: Image.asset(
                        'assets/banners/gyro/words-bg.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: imgW,
                    height: imgH,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: tilt,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              figure,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          if (orb)
                            Positioned(
                              // Fingertips of the raised hand, not the type.
                              left: imgW * 0.90 - orbSize * 0.5,
                              top: imgH * 0.47 - orbSize * 0.45,
                              child: const AppThinkingLoader(
                                size: orbSize,
                                state: OrbState.composing,
                                blackCircle: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _enterBar() {
    final bar = GestureDetector(
      onTap: widget.onOpenQuotes,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const AppThinkingLoader(
              size: 34,
              state: OrbState.composing,
              blackCircle: true,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 28, color: const Color(0x33FFFFFF)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This week's quotes",
                    style: TextStyle(
                      color: Color(0xFFE8D5A3),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Today, last day, and the rest of the week.',
                    style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Enter',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.neumorphic) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: 18,
        elevation: NwsbElevation.sm,
        child: bar,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      child: bar,
    );
  }
}
