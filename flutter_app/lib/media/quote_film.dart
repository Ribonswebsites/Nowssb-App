/// The Today's Quote wave, opened before the pop-up needs it.
///
/// The pop-up used to ask the shared [VideoPool] for a decoder at the moment
/// it appeared, then open a 12 MB clip from cold — a visible wait on a black
/// band. Now the home starts this controller as soon as it loads (only on a
/// day the pop-up is still due), the band paints the clip's first frame as a
/// picture straight away, and the video fades in over it the moment its own
/// first frame is decoded. There is never a blank gap: the poster stays
/// underneath the whole time.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class QuoteFilm {
  QuoteFilm._();

  /// 1272×840 H.264 High, 15 s, ~4.6 MB, no audio, faststart. The wave is
  /// 636×420 in the source film, so it is upscaled 2× with Real-ESRGAN
  /// (general-x4v3) from the 6.5 Mbps original rather than stretched on the
  /// phone.
  static const asset = 'assets/video/quote-wave.mp4';

  /// The clip's own first frame.
  static const poster = 'assets/video/quote-wave-poster.webp';

  static VideoPlayerController? _c;
  static Future<VideoPlayerController?>? _opening;

  /// The open controller, or null while it is opening or could not open.
  static final ValueNotifier<VideoPlayerController?> controller =
      ValueNotifier<VideoPlayerController?>(null);

  /// Decode the poster into the image cache so the first frame of the
  /// pop-up already has it.
  static Future<void> precachePoster(BuildContext context) async {
    try {
      await precacheImage(const AssetImage(poster), context,
          onError: (_, __) {});
    } catch (_) {}
  }

  /// Open (once) and keep the wave ready, paused on frame 0.
  static Future<VideoPlayerController?> prepare() {
    final c = _c;
    if (c != null) return Future.value(c);
    return _opening ??= _open();
  }

  static Future<VideoPlayerController?> _open() async {
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.asset(
        asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await c.initialize().timeout(const Duration(seconds: 20));
      await c.setVolume(0);
      await c.setLooping(true);
      _c = c;
      controller.value = c;
      return c;
    } catch (e) {
      debugPrint('NowssB video: quote wave not opened — $e');
      try {
        await c?.dispose();
      } catch (_) {}
      return null;
    } finally {
      _opening = null;
    }
  }

  /// Give the decoder back once the pop-up is closed. The controller is
  /// detached at once; its teardown runs in the background.
  static Future<void> release() {
    final c = _c;
    _c = null;
    controller.value = null;
    if (c != null) {
      unawaited(Future<void>(() async {
        try {
          await c.dispose();
        } catch (_) {}
      }));
    }
    return Future<void>.value();
  }

  @visibleForTesting
  static Future<void> debugReset() => release();
}

/// The wave: its poster immediately, the video crossfaded over it.
class QuoteFilmBand extends StatefulWidget {
  const QuoteFilmBand({super.key});

  @override
  State<QuoteFilmBand> createState() => _QuoteFilmBandState();
}

class _QuoteFilmBandState extends State<QuoteFilmBand> {
  VideoPlayerController? _c;
  var _live = false;
  Timer? _grace;

  @override
  void initState() {
    super.initState();
    QuoteFilm.controller.addListener(_onController);
    _onController();
    unawaited(QuoteFilm.prepare());
  }

  void _onController() {
    final next = QuoteFilm.controller.value;
    if (identical(next, _c)) return;
    _c?.removeListener(_onTick);
    _c = next;
    _live = false;
    if (next != null) {
      next.addListener(_onTick);
      unawaited(next.play());
      // Some decoders never move position off zero on the first report;
      // after a beat the texture is drawn either way.
      _grace?.cancel();
      _grace = Timer(const Duration(milliseconds: 160), () {
        if (mounted && _c != null && !_live) setState(() => _live = true);
      });
    }
    if (mounted) setState(() {});
  }

  void _onTick() {
    final c = _c;
    if (c == null || _live) return;
    final v = c.value;
    if (v.isInitialized && v.isPlaying && v.position > Duration.zero) {
      if (mounted) setState(() => _live = true);
    }
  }

  @override
  void dispose() {
    _grace?.cancel();
    QuoteFilm.controller.removeListener(_onController);
    _c?.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final size = c?.value.size ?? Size.zero;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            QuoteFilm.poster,
            key: const ValueKey('quote-wave-poster'),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF07070C)),
          ),
          if (c != null && c.value.isInitialized && !size.isEmpty)
            AnimatedOpacity(
              opacity: _live ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
