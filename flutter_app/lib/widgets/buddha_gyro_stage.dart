/// Mid-home stage: the type plate is the background, the Buddha is the
/// centre. Tilting the phone up and down (accelerometer pitch) swings both
/// in perspective — the plate less, the figure more — the way the hero
/// header separates a subject from what sits behind it.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
  double _pitch = 0;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: SizedBox(
          height: 480,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _pitch * -22),
                child: Transform.scale(
                  scale: 1.12,
                  child: Image.asset(
                    'assets/banners/gyro/words-bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment(0, _pitch * 0.15),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.08 + _pitch * 0.06),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014)
                    ..rotateX(_pitch * 0.42)
                    ..translateByDouble(0, _pitch * 18, 0, 1),
                  child: Image.asset(
                    'assets/banners/gyro/buddha.png',
                    height: 430,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.neumorphic) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: NeuCard(
          padding: const EdgeInsets.all(8),
          child: stage,
        ),
      );
    }
    return GlassWrap(
      padding: const EdgeInsets.all(8),
      child: stage,
    );
  }
}
