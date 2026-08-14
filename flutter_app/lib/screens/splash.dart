/// The start animation — the film that opens the app.
///
/// One clip, once, then the app. Same as the website, and the same standing
/// rule about the file itself: assets/video/start-animation.mp4 is not
/// re-encoded, not muted at the file level, not touched. It is played muted
/// here, which is a decision about this playback rather than about the clip.
///
/// It does NOT go through the pool. The pool exists to stop a hundred idle
/// decoders existing at once; the splash is one clip, it is the only thing on
/// screen, and it is the first thing the app does. Handing it to a controller
/// that might rank it against something else would be solving a problem that
/// cannot happen here. Everything else in the app goes through NwsbVideo —
/// this is the single exception and it is deliberate.
///
/// It always ends. Three ways out: the clip finishes, the reader taps Skip,
/// or a hard eight-second ceiling fires. A splash that can hang because a
/// file failed to open is a splash that can brick the app on a bad device.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/tokens.dart';

class Splash extends StatefulWidget {
  const Splash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  VideoPlayerController? _c;
  Timer? _ceiling;
  bool _leaving = false;

  static const _asset = 'assets/video/start-animation.mp4';

  @override
  void initState() {
    super.initState();
    _start();
    // The backstop. Whatever happens to the clip, the app opens.
    _ceiling = Timer(const Duration(seconds: 8), _leave);
  }

  Future<void> _start() async {
    final c = VideoPlayerController.asset(_asset);
    _c = c;
    try {
      await c.initialize();
    } catch (_) {
      // No clip, no splash. Straight in rather than a black rectangle.
      _leave();
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    await c.setVolume(0);
    await c.setLooping(false);
    c.addListener(_watch);
    await c.play();
    setState(() {});
  }

  void _watch() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    final v = c.value;
    // position >= duration is the honest end. isCompleted alone is not
    // reliable across platforms.
    if (!v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) {
      _leave();
    }
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _ceiling?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _ceiling?.cancel();
    _c?.removeListener(_watch);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            // The clip's own first frame while it opens, so the launch is
            // never a black hole even for the half-second before playback.
            Image.asset(
              'assets/video/start-animation-poster.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
            ),

          // Skip. Small, out of the way, and always there — nobody should
          // have to sit through this twice.
          Positioned(
            right: 16,
            bottom: 28,
            child: SafeArea(
              child: TextButton(
                onPressed: _leave,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0x33FFFFFF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.goldLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
