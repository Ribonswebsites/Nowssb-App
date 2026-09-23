/// Today's Quotes — two auto-rotating cards.
///
/// The type plate is the background and can be dragged left and right.
/// The Buddha has no plate of its own, so the words stay visible around it.
/// Tilting the phone up and down swings the figure against that plate.
/// Card two is the raised hand, with the composing orb on the fingertips.
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
  const BuddhaGyroStage({super.key, this.neumorphic = false});

  final bool neumorphic;

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

  static const _stageH = 580.0;

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
    setState(() => _pan = (_pan + dx).clamp(-170.0, 170.0));
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
        SizedBox(
          height: _stageH,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _userPaging = true;
              } else if (n is ScrollEndNotification) {
                _userPaging = false;
              }
              return false;
            },
            child: PageView(
              controller: _pager,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => _page = i,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _shell(
                    0,
                    _stage('assets/banners/gyro/buddha.png'),
                  ),
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
        ),
      ],
    );
  }

  /// Card 0 wears this home's pane. Card 1 wears the other, so the two
  /// wrappers are not the same.
  Widget _shell(int index, Widget child) {
    final glass = widget.neumorphic ? index == 1 : index == 0;
    if (glass) {
      return GlassWrap(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(8),
        child: child,
      );
    }
    return NeuCard(
      padding: const EdgeInsets.all(8),
      radius: 18,
      color: widget.neumorphic ? null : const Color(0xFFF3F0EA),
      child: child,
    );
  }

  Widget _stage(String figure, {bool orb = false}) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) => _drag(d.delta.dx),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(_pan, _pitch * -20),
              child: Transform.scale(
                scale: 1.48,
                child: Image.asset(
                  'assets/banners/gyro/words-bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment(_pan / 220, _pitch * 0.12),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final h = c.maxHeight;
                const aspect = 844 / 1500;
                var imgH = h;
                var imgW = imgH * aspect;
                if (imgW > w) {
                  imgW = w;
                  imgH = imgW / aspect;
                }
                final left = (w - imgW) / 2;
                final top = h - imgH;
                final tilt = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateX(_pitch * 0.38)
                  ..translateByDouble(0, _pitch * 14, 0, 1);
                return Stack(
                  children: [
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
                                left: imgW * 0.86 - 28,
                                top: imgH * 0.46 - 8,
                                child: const AppThinkingLoader(
                                  size: 56,
                                  state: OrbState.composing,
                                  blackCircle: false,
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
          ],
        ),
      ),
    );
  }
}
