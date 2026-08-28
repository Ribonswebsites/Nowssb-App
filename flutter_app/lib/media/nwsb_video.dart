/// One widget for every clip in the app.
///
/// It shows the clip's poster, asks [VideoPool] for a decoder while it is on
/// screen, and crossfades to the moving picture when one is granted. When
/// the pool takes the decoder back it fades to the poster again. Nothing
/// that uses this has to know any of that happened — it is a picture that
/// sometimes moves.
///
/// The poster is not an optimisation, it is the contract. Because at most
/// four clips decode at once, MOST OF THESE ARE SHOWING A PICTURE MOST OF
/// THE TIME, and the app looks right only if that picture is the clip's own
/// first frame. Every mp4 in assets/video has a -poster.webp beside it,
/// generated from the file itself, so what you see while a clip waits is
/// exactly what it would be showing anyway.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_pool.dart';

class NwsbVideo extends StatefulWidget {
  const NwsbVideo({
    super.key,
    required this.asset,
    this.poster,
    this.fit = BoxFit.cover,
    this.priority = ClipPriority.decoration,
    this.loop = true,
    this.autoplay = true,
    this.alignment = Alignment.center,
    this.showPoster = true,
  });

  /// Bundled path, e.g. 'assets/video/store-section.mp4'.
  final String asset;

  /// Bundled poster. Defaults to the clip's own '-poster.webp', which is the
  /// convention every file in assets/video follows.
  final String? poster;

  final BoxFit fit;
  final ClipPriority priority;
  final bool loop;
  final bool autoplay;
  final Alignment alignment;

  /// TV-frame clips deliberately show only the moving video through the
  /// bezel. Other app surfaces can retain their loading poster.
  final bool showPoster;

  /// True when [asset] is a URL rather than a bundled file.
  bool get isRemote =>
      asset.startsWith('http://') || asset.startsWith('https://');

  /// A bundled clip's poster is its own first frame, beside it in the
  /// bundle. A REMOTE clip has no such file — deriving one would name an
  /// asset that does not exist and paint a black rectangle over the video
  /// until it opens, so a remote clip simply has no poster unless one is
  /// given.
  String? get _poster {
    if (!showPoster) return null;
    if (poster != null) return poster;
    if (isRemote) return null;
    return asset.replaceAll(RegExp(r'\.mp4$'), '-poster.webp');
  }

  @override
  State<NwsbVideo> createState() => _NwsbVideoState();
}

class _NwsbVideoState extends State<NwsbVideo> with WidgetsBindingObserver {
  /// Null when this clip is not meant to move at all.
  ///
  /// autoplay:false used to still take out a lease and simply not press
  /// play — which meant a "still" background held one of the four decoders,
  /// paused, doing nothing, while a clip that wanted to move went without.
  /// With Fashion Plus off that is every page background in the app.
  ///
  /// A clip that is not going to move does not ask for a decoder at all. It
  /// is its poster, and its poster is a picture.
  VideoLease? _lease;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Every mounted video is live in the normal home. Keep the legacy flag
    // accepted for compatibility, but do not let it disable playback.
    _take();
    _pump();
  }

  void _take() {
    final l = VideoPool.instance.lease(
      widget.asset,
      priority: widget.priority,
      loop: widget.loop,
    );
    l.play();
    l.addListener(_onLease);
    _lease = l;
  }

  void _drop() {
    _lease?.removeListener(_onLease);
    _lease?.dispose();
    _lease = null;
    _wasReady = false;
  }

  /// Only what changes the picture causes a rebuild.
  ///
  /// The lease notifies whenever the pool grants or takes back a decoder, but
  /// the only thing this widget draws differently is "poster" versus "moving
  /// picture". Rebuilding on anything else would re-run the post-frame
  /// measure, which reports, which notifies — round and round.
  bool _wasReady = false;

  /// Whether the platform has told us how big the picture is yet.
  ///
  /// This is NOT the same as being initialized, and the difference is what
  /// made every clip in the app look frozen. On Android `isInitialized`
  /// turns true when the player is ready to be driven; `value.size` stays
  /// Size.zero until the first frame has actually been DECODED, which is
  /// some frames later. Between the two, the build below was handing a
  /// FittedBox a 0x0 child — which paints nothing — so the poster underneath
  /// was all you saw. And because readiness had already flipped, nothing
  /// ever rebuilt this widget again, so the clip stayed invisible for as
  /// long as it was on screen: playing, decoding, holding its slot, and
  /// showing a still.
  bool _wasSized = false;

  void _onLease() {
    final c = _lease?.controller;
    final ready = _lease?.isReady ?? false;
    final sized = c != null && !c.value.size.isEmpty;
    if (ready == _wasReady && sized == _wasSized) return;
    _wasReady = ready;
    _wasSized = sized;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(NwsbVideo old) {
    super.didUpdateWidget(old);
    // A changed clip, or the motion switch moving under it. Both are the
    // same thing here: let go of what was held, take what is now wanted.
    if (old.asset != widget.asset) {
      _drop();
      _take();
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      VideoPool.instance.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      VideoPool.instance.releaseAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drop();
    super.dispose();
  }

  /// Measure after every frame, for as long as this widget is alive.
  ///
  /// This used to be registered inside build(), which looked equivalent and
  /// was not: a post-frame callback fires ONCE, and a ListView does not
  /// rebuild the children that are merely scrolling past. So the clip
  /// measured itself on its first frame and never again — and because the
  /// widget only rebuilds when the pool grants it a decoder, a clip that
  /// failed to get one on that single measurement could never ask for
  /// another. Nothing on screen played, ever, and the readout said 0/4.
  ///
  /// Re-registering does NOT schedule a frame of its own, so an idle app
  /// stays idle — the callback simply runs on whatever frames the app was
  /// producing anyway, which is exactly when a clip can have moved.
  void _pump() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      _pump();
    });
  }

  /// Where this clip is relative to the middle of the screen, measured from
  /// the render object rather than from a scroll offset — which means it
  /// works the same inside a list, a page view, a nested scroller or none of
  /// them, and no parent has to cooperate.
  void _measure() {
    if (!mounted) return;
    final lease = _lease;
    if (lease == null) return; // a still has nothing to report
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      // Not laid out YET is not the same as off screen. Saying "infinity"
      // here would hand the decoder away on the one frame before the first
      // layout, so this simply waits for the next.
      return;
    }
    final screen = MediaQuery.maybeOf(context)?.size;
    if (screen == null) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final centre = top + box.size.height / 2;

    // One viewport of slack on each side, so a clip is granted its decoder
    // a screen's worth of travel before you reach it and keeps it a screen
    // after — scrolling back up does not restart everything.
    final visible =
        top < screen.height * 2 && top + box.size.height > -screen.height;
    lease.reportDistance(
        visible ? (centre - screen.height / 2).abs() : double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final c = _lease?.controller;
    final ready = (_lease?.isReady ?? false) && c != null;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget._poster case final p?)
            p.startsWith('http://') || p.startsWith('https://')
                ? Image.network(
                    p,
                    fit: widget.fit,
                    alignment: widget.alignment,
                    // The WebView Player uses a paired image beneath each
                    // remote motion theme. Keep that image visible while
                    // Flutter's decoder opens rather than flashing black.
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black),
                  )
                : Image.asset(
                    p,
                    fit: widget.fit,
                    alignment: widget.alignment,
                    // A missing poster must never be an exception in a list
                    // that is scrolling. Nothing is a worse picture than a
                    // red error box.
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Colors.black),
                  )
          else
            const ColoredBox(color: Colors.black),
          // 220ms, which is long enough that a decoder arriving mid-scroll
          // reads as the picture coming to life rather than as a flicker.
          AnimatedOpacity(
            opacity: ready ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: ready
                // A zero size means the first frame has not been decoded
                // yet. Cropping to the clip's own dimensions needs those
                // dimensions; without them the player simply fills the box,
                // which is the right picture a fraction early rather than no
                // picture at all.
                ? (c.value.size.isEmpty
                    ? VideoPlayer(c)
                    : FittedBox(
                        fit: widget.fit,
                        alignment: widget.alignment,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: c.value.size.width,
                          height: c.value.size.height,
                          child: VideoPlayer(c),
                        ),
                      ))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
