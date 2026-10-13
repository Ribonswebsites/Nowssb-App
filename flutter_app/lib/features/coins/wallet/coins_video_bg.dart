import '../../../nowssb_ui/app_video_backdrop.dart';
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
  Widget build(BuildContext context) => NAppBackdrop(child: widget.child);
}
