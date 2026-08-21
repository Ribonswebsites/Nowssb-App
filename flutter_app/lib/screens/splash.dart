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
/// IT PLAYS ALL THE WAY THROUGH. No Skip, and no timer cutting it short —
/// this is the app introducing itself and it is meant to be seen. It is
/// played a little faster than recorded ([_speed]) so that "all the way
/// through" is not a long wait.
///
/// There is still a ceiling, but it is a FAILSAFE rather than a limit: it is
/// set from the clip's own duration once that is known, so it can only fire
/// if playback has genuinely stalled. A splash with no way out at all is a
/// splash that can brick the app on a device where the file will not open.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../media/cdn.dart';
import '../media/nwsb_image.dart';

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

  /// A quarter faster than recorded. Enough to take the wait off a ten-second
  /// clip without the motion reading as sped-up.
  static const _speed = 1.25;

  @override
  void initState() {
    super.initState();
    _start();
    // Only until the real duration is known — see _start.
    _ceiling = Timer(const Duration(seconds: 20), _leave);
  }

  Future<void> _start() async {
    VideoPlayerController? c = VideoPlayerController.asset(_asset);
    try {
      await c.initialize();
    } catch (_) {
      try {
        await c.dispose();
      } catch (_) {}
      c = null;
      for (final url in NwsbCdn.urls(_asset)) {
        final net = VideoPlayerController.networkUrl(Uri.parse(url));
        try {
          await net.initialize();
          c = net;
          break;
        } catch (_) {
          try {
            await net.dispose();
          } catch (_) {}
        }
      }
    }
    if (c == null) {
      // No clip at all — bundled or network. Straight in rather than a
      // black rectangle.
      _leave();
      return;
    }
    _c = c;
    if (!mounted) {
      await c.dispose();
      return;
    }
    await c.setVolume(0);
    await c.setLooping(false);
    await c.setPlaybackSpeed(_speed);
    c.addListener(_watch);
    await c.play();

    // Now that the clip's length is known, the failsafe becomes its own
    // running time plus a margin. It can no longer cut the animation short —
    // it can only catch playback that has stopped without finishing.
    _ceiling?.cancel();
    final runtime = c.value.duration.inMilliseconds / _speed;
    _ceiling = Timer(
      Duration(milliseconds: runtime.round() + 3000),
      _leave,
    );

    if (mounted) setState(() {});
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
            NwsbImage(
              'assets/video/start-animation-poster.webp',
              fit: BoxFit.cover,
              error: const ColoredBox(color: Colors.black),
            ),
        ],
      ),
    );
  }
}
