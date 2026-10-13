import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The app's original background video only: no gradient, orbs or shapes.
/// (The shared GlassVideoScaffold adds violet glow orbs, which Ribon's
/// correction rules out; switch back when the kit makes them optional.)
class CoinsVideoBackground extends StatefulWidget {
  const CoinsVideoBackground({super.key, required this.poster, this.video, required this.child});
  final String poster;
  final String? video;
  final Widget child;
  @override
  State<CoinsVideoBackground> createState() => _CoinsVideoBackgroundState();
}

class _CoinsVideoBackgroundState extends State<CoinsVideoBackground> {
  VideoPlayerController? _c;
  @override
  void initState() {
    super.initState();
    final v = widget.video;
    if (v != null) {
      _c = VideoPlayerController.asset(v, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _c!.play();
          }
        }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      if (!ready) Image.asset(widget.poster, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
      if (ready)
        RepaintBoundary(child: FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge,
            child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)))),
      widget.child,
    ]);
  }
}
