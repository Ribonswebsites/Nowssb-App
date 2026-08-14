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
  late VideoLease _lease;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lease = VideoPool.instance.lease(
      widget.asset,
      priority: widget.priority,
      loop: widget.loop,
    );
    if (widget.autoplay) _lease.play();
    _lease.addListener(_onLease);
  }

  /// Only what changes the picture causes a rebuild.
  ///
  /// The lease notifies whenever the pool grants or takes back a decoder, but
  /// the only thing this widget draws differently is "poster" versus "moving
  /// picture". Rebuilding on anything else would re-run the post-frame
  /// measure, which reports, which notifies — round and round.
  bool _wasReady = false;

  void _onLease() {
    final ready = _lease.isReady;
    if (ready == _wasReady) return;
    _wasReady = ready;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(NwsbVideo old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) {
      _lease.removeListener(_onLease);
      _lease.dispose();
      _lease = VideoPool.instance.lease(
        widget.asset,
        priority: widget.priority,
        loop: widget.loop,
      );
      if (widget.autoplay) _lease.play();
      _lease.addListener(_onLease);
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
    _lease.removeListener(_onLease);
    _lease.dispose();
    super.dispose();
  }

  /// Where this clip is relative to the middle of the screen, measured from
  /// the render object rather than from a scroll offset — which means it
  /// works the same inside a list, a page view, a nested scroller or none of
  /// them, and no parent has to cooperate.
  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      _lease.reportDistance(double.infinity);
      return;
    }
    final screen = MediaQuery.maybeOf(context)?.size;
    if (screen == null) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final centre = top + box.size.height / 2;

    // One viewport of slack on each side, so a clip is granted its decoder
    // a screen's worth of travel before you reach it and keeps it a screen
    // after — scrolling back up does not restart everything.
    final visible = top < screen.height * 2 && top + box.size.height > -screen.height;
    _lease.reportDistance(
        visible ? (centre - screen.height / 2).abs() : double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final c = _lease.controller;
    final ready = _lease.isReady && c != null;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget._poster,
            fit: widget.fit,
            alignment: widget.alignment,
            // A missing poster must never be an exception in a list that is
            // scrolling. Nothing is a worse picture than a red error box.
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          // 220ms, which is long enough that a decoder arriving mid-scroll
          // reads as the picture coming to life rather than as a flicker.
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
