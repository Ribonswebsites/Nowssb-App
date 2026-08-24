/// One widget for every clip in the app.
///
/// It shows the clip's poster, asks [VideoPool] for a decoder while it is on
/// screen, and crossfades to the moving picture when one is granted. When
/// the pool takes the decoder back it fades to the poster again. Nothing
/// that uses this has to know any of that happened — it is a picture that
/// sometimes moves.
///
/// The poster is not an optimisation, it is the contract. Off-screen clips
/// show a picture and cost nothing; every on-screen clip is granted a
/// decoder (capped with the website at 24). Every mp4 in assets/video has
/// a -poster.webp beside it, generated from the file itself, so what you
/// see while a clip waits is exactly what it would be showing anyway.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/settings.dart';
import 'cdn.dart';
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

  String get _poster =>
      poster ?? asset.replaceAll(RegExp(r'\.mp4$'), '-poster.webp');

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
    Settings.instance.addListener(_onSettings);
    if (_shouldPlay) _take();
    _pump();
  }

  /// Every visual clip is autoplay decoration in this app. The WebView starts
  /// all visible muted films together; Flutter must not turn section videos
  /// into posters merely because the Fashion Plus preference is off. The
  /// preference can still shape the page skin, but it is not a play/stop gate.
  bool get _shouldPlay => widget.autoplay;

  void _onSettings() {
    final want = _shouldPlay;
    if (want && _lease == null) {
      _take();
    } else if (!want && _lease != null) {
      _drop();
      if (mounted) setState(() {});
    }
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
  bool _wasReady = false;

  void _onLease() {
    final ready = _lease?.isReady ?? false;
    if (ready == _wasReady) return;
    _wasReady = ready;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(NwsbVideo old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.autoplay != widget.autoplay) {
      _drop();
      if (_shouldPlay) _take();
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
    Settings.instance.removeListener(_onSettings);
    WidgetsBinding.instance.removeObserver(this);
    _drop();
    super.dispose();
  }

  void _pump() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
      _pump();
    });
  }

  void _measure() {
    if (!mounted) return;
    final lease = _lease;
    if (lease == null) return;
    // Inactive IndexedStack tabs stay laid out at the same coordinates as
    // the visible one. TickerMode is how IndexedStack says "this child is
    // not being looked at" — same job as the website's shown() check, so
    // Practice/Library/Store/Profile do not steal the home's films.
    if (!TickerMode.valuesOf(context).enabled) {
      lease.reportDistance(double.infinity);
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      return;
    }
    final screen = MediaQuery.maybeOf(context)?.size;
    if (screen == null) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final centre = top + box.size.height / 2;

    final visible = top < screen.height * 2 && top + box.size.height > -screen.height;
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
          Image.asset(
            widget._poster,
            fit: widget.fit,
            alignment: widget.alignment,
            errorBuilder: (_, __, ___) => Image.network(
              NwsbCdn.url(widget._poster),
              fit: widget.fit,
              alignment: widget.alignment,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Colors.black),
            ),
          ),
          AnimatedOpacity(
            opacity: ready ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: ready
                ? FittedBox(
                    fit: widget.fit,
                    alignment: widget.alignment,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
