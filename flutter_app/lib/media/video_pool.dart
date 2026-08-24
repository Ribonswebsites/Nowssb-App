/// THE VIDEO POOL — why this file exists and why it is the first thing
/// written in the port.
///
/// The website is slow for one reason, and it is not HTML. It is that a
/// phone has a fixed, small number of hardware video decoders — on most
/// Android devices somewhere between four and sixteen — and the app was
/// asking for a hundred. When you ask for more than the chip has, the
/// request does not politely queue: playback stutters, frames arrive late,
/// surfaces come back black, and eventually the media server gives up and
/// takes the app down with it. That is the lag, the black banners and the
/// crashes, all of them, in one sentence.
///
/// Rebuilding in Flutter does NOT make a decoder faster. The same chip
/// decodes the same H.264 at the same speed whether the frame is handed to
/// a WebView or to an ExoPlayer texture. What Flutter gives is something
/// the browser never would: exact, total control over how many exist.
/// A VideoPlayerController is a real ExoPlayer instance and it is created
/// and destroyed when this file says so, not when a garbage collector
/// somewhere decides the page has moved on.
///
/// So the rule this file enforces is absolute:
///
///     AT MOST [maxLive] DECODERS EXIST AT ANY MOMENT.
///
/// Not "are playing" — exist. Everything else on screen is showing its
/// poster, which is a picture and costs nothing. A clip that scrolls away
/// has its controller disposed, not paused; when it comes back it is built
/// again, seeks in a local file, and the poster covers the frame or two
/// that takes.
///
/// Eviction is by distance from the middle of the screen, so what you are
/// looking at holds its decoder and what you are not gives it up. A clip
/// that is genuinely the point of its section — the television, a hero —
/// can claim priority and is evicted last.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'cdn.dart';

/// How badly a clip wants to keep its decoder when the pool is full.
enum ClipPriority {
  /// A banner or a background loop. First to lose its slot.
  decoration,

  /// The clip IS the section — the television screen, the hero rail's
  /// current cell. Evicted only when nothing decorative is left to take.
  feature,
}

/// One clip's claim on a decoder.
///
/// A widget creates a lease, tells the pool where it is on screen, and
/// listens. It never touches a controller directly — [controller] is null
/// whenever this lease does not hold a decoder, which is the normal state
/// for most clips most of the time, and the widget shows its poster then.
class VideoLease extends ChangeNotifier {
  VideoLease._(this._pool, this.assetPath, this.priority, this.loop);

  final VideoPool _pool;

  /// The bundled asset path. Always local — nothing here streams.
  final String assetPath;

  final ClipPriority priority;
  final bool loop;

  VideoPlayerController? _controller;
  bool _wantsPlay = false;
  bool _disposed = false;
  /// How many times this clip has refused to open. Kept so a broken file
  /// cannot be retried on every single pass forever.
  int _failures = 0;
  double _distance = double.infinity;

  /// Non-null only while this lease holds one of the pool's decoders.
  VideoPlayerController? get controller => _controller;

  /// True once the controller exists AND has decoded enough to draw. Until
  /// then the widget must keep showing the poster: a controller that is
  /// initialising paints nothing, and "nothing" is a black rectangle.
  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Distance in logical pixels from the centre of this clip to the centre
  /// of the viewport. The pool ranks by this: nearest keeps its decoder.
  /// [double.infinity] means off screen entirely.
  double get distance => _distance;

  /// Called by the widget after every frame it is laid out in.
  ///
  /// It has to be cheap AND it has to be quiet, and the second one is the
  /// subtle part: the widget measures itself in a post-frame callback, so a
  /// report that always asked the pool to re-rank would notify the widget,
  /// which would rebuild, which would measure again — a frame loop that
  /// never settles. On a device that is a flat battery; in a widget test it
  /// is a test that never finishes, which is how it was found.
  ///
  /// So the pool is only disturbed when the answer could actually differ:
  /// the clip crossed on or off screen, or it moved far enough for the
  /// ranking to plausibly change.
  static const _reportSlop = 24.0;
  double _reported = double.infinity;

  void reportDistance(double d) {
    if (_disposed) return;
    _distance = d;

    final wasOff = _reported == double.infinity;
    final isOff = d == double.infinity;
    if (wasOff == isOff && !isOff && (d - _reported).abs() < _reportSlop) {
      return;
    }
    _reported = d;
    _pool._rebalanceSoon();
  }

  /// Ask to be playing whenever a decoder is held. The pool decides whether
  /// one is available; this only records the intent.
  void play() {
    _wantsPlay = true;
    final c = _controller;
    if (c != null && c.value.isInitialized && !c.value.isPlaying) {
      unawaited(_pool._playMuted(this, c));
    }
  }

  void pause() {
    _wantsPlay = false;
    final c = _controller;
    if (c != null && c.value.isInitialized && c.value.isPlaying) {
      c.pause();
    }
  }

  /// notifyListeners is protected, and rightly so — but the pool is what
  /// grants and takes back a decoder, so the pool is what knows when a
  /// lease has changed. This is the one door it comes through.
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pool._release(this);
    super.dispose();
  }
}

/// The pool itself. One per app — see [VideoPool.instance].
class VideoPool {
  VideoPool._();

  static final VideoPool instance = VideoPool._();

  /// All mounted eligible clips stay live so a section video does not stop
  /// when the user scrolls. The protected launch animation is managed by the
  /// Splash widget and never enters this pool.
  static const int maxLive = 256;

  final List<VideoLease> _leases = [];
  final Set<VideoLease> _live = {};
  bool _scheduled = false;

  /// While this is true the pool grants nothing at all.
  ///
  /// The start animation is the one clip that plays on every launch and it is
  /// the only thing anyone can see for its whole length — but the app is
  /// built behind it, so without this the home would be quietly taking four
  /// decoders while the splash holds a fifth. On the devices that struggle
  /// most, the launch would be the worst moment of the session. Nothing
  /// decodes underneath the splash; everything on screen takes its slot the
  /// moment it ends. Same rule the website states in app/js/part051.js.
  bool _held = false;
  bool get held => _held;

  void hold() {
    _held = true;
    releaseAll();
  }

  void unhold() {
    if (!_held) return;
    _held = false;
    _rebalanceSoon();
  }

  /// Diagnostics, for the debug overlay and for tests.
  int get liveCount => _live.length;
  int get leaseCount => _leases.length;

  /// How many leases currently say they are on screen. If this is zero while
  /// clips are plainly visible, the measuring is wrong; if it is healthy and
  /// liveCount is zero, the opening is. Two very different bugs that look
  /// identical from the outside, which is why both numbers are on the HUD.
  int get nearCount {
    var n = 0;
    for (final l in _leases) {
      if (l._distance != double.infinity) n++;
    }
    return n;
  }

  /// The last clip that would not open, and what the platform said about it.
  /// Null while nothing has failed.
  String? lastError;

  @visibleForTesting
  Set<VideoLease> get debugLive => Set.unmodifiable(_live);

  @visibleForTesting
  List<VideoLease> get debugLeases => List.unmodifiable(_leases);

  /// Empty the pool and wait until it is genuinely quiet.
  ///
  /// The pool is a singleton and a pass is asynchronous, so a test that just
  /// disposed its leases can still have a rebalance in flight when the next
  /// one starts — which showed up as tests that passed alone and failed
  /// together. This drains everything and does not return until no pass is
  /// running.
  /// True while a pass is in flight. Tests wait on this; nothing in the app
  /// reads it.
  @visibleForTesting
  bool get debugBusy => _rebalancing;

  /// Drop everything without waiting for the platform.
  ///
  /// For widget tests, which run on a fake clock: [debugReset] awaits the
  /// platform actually releasing each player, and that await cannot complete
  /// between pumps — it deadlocks the test rather than cleaning it up. This
  /// forgets the leases and cancels the pending pass synchronously, which is
  /// all a widget test needs, and leaves the awaited version for the unit
  /// tests that run in real async.
  @visibleForTesting
  void debugDropAll() {
    for (final l in _leases.toList()) {
      final c = l._controller;
      l._controller = null;
      c?.dispose();
    }
    _leases.clear();
    _live.clear();
    _draining.clear();
    _again = false;
    // The in-flight flags too. A pass abandoned mid-await leaves _rebalancing
    // true, and a true _rebalancing is permanent: every later request just
    // sets _again and returns, so the pool never grants another decoder as
    // long as the app runs. Not only a test concern — it is the one state
    // this object has that can wedge.
    _rebalancing = false;
    _scheduled = false;
  }

  @visibleForTesting
  Future<void> debugReset() async {
    for (final l in _leases.toList()) {
      l.dispose();
    }
    _leases.clear();
    await releaseAll();

    var guard = 0;
    while ((_rebalancing || _scheduled) && guard++ < 100) {
      await Future<void>.delayed(Duration.zero);
    }

    _live.clear();
    _again = false;
  }

  /// Take out a lease on [assetPath]. The widget owns the returned object
  /// and must dispose it — that is what gives the decoder back.
  VideoLease lease(
    String assetPath, {
    ClipPriority priority = ClipPriority.decoration,
    bool loop = true,
  }) {
    final l = VideoLease._(this, assetPath, priority, loop);
    _leases.add(l);
    _rebalanceSoon();
    return l;
  }

  /// Players handed back but not yet actually gone.
  ///
  /// A widget scrolled out of a list disposes its lease immediately, and
  /// dispose() cannot be awaited — nothing calls it with a Future in hand. So
  /// the teardown it starts is parked here, and [_rebalance] waits on
  /// everything in this set before it creates anything. Without that, a
  /// scrolling list hands back four and takes four while the first four are
  /// still shutting down, and the phone briefly holds eight. A widget test
  /// scrolling the real home caught exactly that.
  final Set<Future<void>> _draining = {};

  void _drain(Future<void> f) {
    _draining.add(f);
    f.whenComplete(() => _draining.remove(f));
  }

  void _release(VideoLease l) {
    _leases.remove(l);
    if (_live.remove(l)) {
      _drain(_tearDown(l));
    }
    // Nothing left to give the freed slot to — closing the last screen should
    // not schedule work.
    if (_leases.isNotEmpty) _rebalanceSoon();
  }

  /// Scrolling fires distance reports on every frame, and rebalancing
  /// allocates and disposes platform resources — doing that per report would
  /// be worse than the problem it solves. So they coalesce: many reports in
  /// one frame become one pass.
  ///
  /// A microtask rather than a zero-duration Timer. Every clip on screen
  /// measures itself in a post-frame callback, and those all run in the same
  /// turn, so a microtask scheduled by the first of them runs once, after the
  /// last — exactly the coalescing wanted. It also leaves nothing behind: a
  /// pending Timer outlives a disposed widget tree, which is a leak the test
  /// framework is right to fail on and which a real app pays for every time a
  /// screen closes.
  void _rebalanceSoon() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      _rebalance();
    });
  }

  bool _rebalancing = false;
  bool _again = false;

  Future<void> _rebalance() async {
    // One pass at a time. A pass gives players back and then takes new ones,
    // and both halves are asynchronous — two passes interleaved would be two
    // sets of "take" running against one set of "give back", which is how
    // the ceiling gets exceeded. A request that arrives mid-pass is
    // remembered and run once this one finishes.
    if (_rebalancing) {
      _again = true;
      return;
    }
    _rebalancing = true;

    try {
      // Bounded. Scrolling sets _again on almost every frame, so an unbounded
      // "run again if anything changed" loop is a loop that never ends while
      // a thumb is moving — it holds the pass open and starves the very
      // rebalance it is trying to perform. A handful of turns is enough to
      // settle, and the zero timer picks up whatever is left on the next
      // frame anyway.
      var turns = 0;
      do {
        _again = false;

        // Who wants a decoder: anything on screen, nearest and highest
        // priority first. Off-screen clips are not candidates at all — that
        // is the whole point, and it is why a hundred idle clips now cost a
        // hundred pictures instead of a hundred ExoPlayers.
        final want = _leases
            .where((l) => l._failures < 3)
            .toList()
          ..sort((a, b) {
            if (a.priority != b.priority) {
              return a.priority == ClipPriority.feature ? -1 : 1;
            }
            return a._distance.compareTo(b._distance);
          });

        // Held: nothing is kept, so the pass becomes a pure give-back.
        final keep = _held ? <VideoLease>{} : want.take(maxLive).toSet();

        // GIVE BACK FIRST, AND WAIT FOR IT.
        //
        // This await is the whole correctness of the pool and it was not
        // here to begin with. Disposing a controller is a round trip to the
        // platform: the Dart object is released immediately, the ExoPlayer
        // behind it a moment later. Without the wait, a pass could hand back
        // four and create four in the same breath and the phone would
        // briefly hold eight — which on a device already at its decoder
        // limit is not a swap, it is a failure. A widget test scrolling the
        // real home caught exactly that: five players alive at once.
        final going = <Future<void>>[];
        for (final l in _live.toList()) {
          if (!keep.contains(l)) {
            _live.remove(l);
            going.add(_tearDown(l));
          }
        }
        // Everything this pass is evicting, AND everything a disposed widget
        // handed back since the last pass. Both are players the phone has not
        // finished releasing, and both have to be gone before a new one is
        // asked for.
        going.addAll(_draining);
        if (going.isNotEmpty) await Future.wait(going);

        // Then take. Anything that changed while we were waiting is picked
        // up by the loop rather than by racing this one.
        final coming = <Future<void>>[];
        for (final l in keep) {
          if (!_live.contains(l)) {
            _live.add(l);
            coming.add(_bringUp(l));
          }
        }
        if (coming.isNotEmpty) await Future.wait(coming);
      } while (_again && ++turns < 4);

      // Anything still outstanding is left to the next frame rather than
      // spun on here.
      if (_again) {
        _again = false;
        _rebalanceSoon();
      }
    } finally {
      _rebalancing = false;
    }
  }

  Future<void> _bringUp(VideoLease l) async {
    if (l._disposed || l._controller != null) return;

    final c = await _open(l.assetPath);
    if (c == null) {
      lastError = '${l.assetPath.split('/').last}: would not open (bundle or network)';
      debugPrint('NowssB video: could not open ${l.assetPath}');
      l._failures++;
      _live.remove(l);
      l._changed();
      return;
    }

    l._controller = c;

    // Disposed, or evicted again, while we were awaiting initialize().
    if (l._disposed || !_live.contains(l)) {
      l._controller = null;
      await c.dispose();
      return;
    }

    await c.setLooping(true);
    // Muted, always. Every clip in this app is decoration, and a video
    // playing with sound is what put the website in Android's notification
    // shade next to a music player. Keep the initial play guarded so one
    // ExoPlayer rejection cannot abort the rest of the visible pool.
    if (l._wantsPlay) {
      await _playMuted(l, c);
    } else {
      await c.setVolume(0);
    }

    l._changed();
  }

  /// R2 catalog first, then the bundled file, then the public site.
  ///
  /// The posters are always there. R2 is the shared source used by both the
  /// WebView and Flutter; the bundled copy keeps the same screen usable when
  /// the network is unavailable.
  Future<VideoPlayerController?> _open(String assetPath) async {
    // Some Flutter sections intentionally use the exact Cloudinary film that
    // the WebView uses. Treat an HTTP asset as a URL; passing it to
    // VideoPlayerController.asset produces the misleading "bundle or network"
    // failure seen in the debug HUD.
    if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
      final net = VideoPlayerController.networkUrl(Uri.parse(assetPath));
      try {
        await net.initialize();
        debugPrint('NowssB video: opened direct $assetPath');
        return net;
      } catch (e) {
        debugPrint('NowssB video: direct network miss $assetPath — $e');
        try {
          await net.dispose();
        } catch (_) {}
        return null;
      }
    }

    // R2 is the canonical playback source after migration. The bundled
    // lookup is retained only as a harmless compatibility attempt for the
    // protected launch family; eligible clips resolve to R2 below.
    final urls = NwsbCdn.urls(assetPath).toList();

    Future<VideoPlayerController?> openNetwork() async {
      for (final url in urls) {
        final net = VideoPlayerController.networkUrl(Uri.parse(url));
        try {
          await net.initialize();
          debugPrint('NowssB video: opened $url');
          return net;
        } catch (e) {
          debugPrint('NowssB video: network miss $url — $e');
          try {
            await net.dispose();
          } catch (_) {}
        }
      }
      return null;
    }

    final asset = VideoPlayerController.asset(assetPath);
    try {
      await asset.initialize();
      return asset;
    } catch (e) {
      debugPrint('NowssB video: bundle miss $assetPath — $e');
      try {
        await asset.dispose();
      } catch (_) {}
    }

    return openNetwork();
  }

  /// Returns when the PLATFORM has actually let the player go, not when the
  /// Dart object was dropped. Callers wait on this before creating anything —
  /// see the comment in [_rebalance].
  Future<void> _tearDown(VideoLease l) async {
    final c = l._controller;
    l._controller = null;
    l._changed();
    if (c == null) return;
    // Disposed, not paused. A paused ExoPlayer still holds its decoder, and
    // holding it is the entire thing this file exists to stop.
    try {
      await c.pause();
    } catch (_) {
      // Already gone. Dispose it anyway.
    }
    try {
      await c.dispose();
    } catch (_) {}
  }

  /// Everything stops when the app is backgrounded. Android will reclaim
  /// decoders from a background app anyway, and a controller that is holding
  /// one when that happens comes back to a dead surface.
  Future<void> releaseAll() async {
    final going = <Future<void>>[];
    for (final l in _live.toList()) {
      _live.remove(l);
      going.add(_tearDown(l));
    }
    going.addAll(_draining);
    if (going.isNotEmpty) await Future.wait(going);
  }

  /// After a return to the foreground, whoever is on screen takes theirs
  /// back.
  void resume() => _rebalanceSoon();

  /// A slow heartbeat, as a backstop for anything the per-frame measuring
  /// misses — a screen that is completely static produces no frames, so it
  /// reports nothing, so a clip that arrived during the quiet would wait
  /// forever. Two seconds costs nothing and cannot deadlock.
  Timer? _beat;
  void startHeartbeat() {
    _beat ??= Timer.periodic(const Duration(seconds: 2), (_) {
      _retryPausedVisiblePlayers();
      if (_leases.isNotEmpty) _rebalanceSoon();
    });
  }

  void _retryPausedVisiblePlayers() {
    if (_held) return;
    for (final l in _live) {
      final c = l._controller;
      if (l._wantsPlay && c != null && c.value.isInitialized && !c.value.isPlaying) {
        unawaited(_playMuted(l, c));
      }
    }
  }

  Future<void> _playMuted(VideoLease l, VideoPlayerController c) async {
    if (l._disposed || !l._wantsPlay) return;
    try {
      await c.setVolume(0);
      await c.play();
    } catch (e) {
      debugPrint('NowssB video: retry play failed ${l.assetPath} — $e');
    }
  }
}
