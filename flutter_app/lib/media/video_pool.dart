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

  /// How many times this clip has refused to open, and the earliest moment it
  /// may be tried again.
  ///
  /// This used to be a hard cap: three failures and the clip was struck off
  /// for the life of the app. On a phone that is the wrong rule — the three
  /// failures are usually the first three seconds after launch, before the
  /// radio has a route, and every Cloudinary clip on the page would be
  /// permanently dead because of a network that came back a moment later.
  /// So it backs off instead of giving up, and a clip that opens resets to
  /// zero.
  int _failures = 0;
  DateTime? _retryAt;

  bool get _eligible {
    final t = _retryAt;
    return t == null || DateTime.now().isAfter(t);
  }

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
      c.play();
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

  /// The ceiling.
  ///
  /// This was 4, and 4 was too few — not in theory, on the page. The Fashion
  /// home's film fills the screen and holds one slot for the whole session,
  /// so three were left for everything else, and the hero's television and
  /// the Customize · Features · Earn strip take two of those between them.
  /// Anything below them showed a poster while it was plainly on screen.
  ///
  /// Eight is still a ceiling and still the point of this class — a hundred
  /// clips on a page cost eight decoders, which is what the website could
  /// not do. It is comfortably inside what Android has given for concurrent
  /// AVC decode on anything of the last several years, and every clip here
  /// is a short muted loop rather than a 4K stream.
  ///
  /// IF A DEVICE EVER STRUGGLES, THIS IS THE ONE NUMBER TO LOWER. Nothing
  /// else has to change: every test asserts against this constant rather
  /// than against the literal, so the invariant holds at whatever it is set
  /// to.
  static const int maxLive = 8;

  /// How long a clip gets to open before it counts as failed.
  ///
  /// TWO NUMBERS, because the two cases are nothing alike. A remote clip can
  /// stall forever and 12 seconds is already generous for one. A BUNDLED file
  /// cannot stall — there is no network in front of it — it can only be slow,
  /// and it is slowest exactly when several open at once on a busy device,
  /// which is the moment a deadline must not fire.
  ///
  /// A single 12s deadline for both is what put
  /// `store-section.mp4: TimeoutException after 0:00:12` on the debug
  /// readout: a local asset, killed mid-open, its slot handed back, and the
  /// section left showing a still for no reason at all. Failing a file that
  /// was going to work is worse than waiting for it.
  static const _openRemote = Duration(seconds: 12);
  static const _openLocal = Duration(seconds: 45);

  /// How long any single platform round trip gets before the pool stops
  /// waiting on it. Nothing in here is allowed to wait forever.
  static const _giveUp = Duration(seconds: 8);

  /// The longest a whole pass may take before [_passGuard] declares it hung
  /// and lets a new one start.
  static const _passLimit = Duration(seconds: 90);

  /// How many clips may be OPENING at once.
  ///
  /// THIS IS WHY NOTHING WAS PLAYING.
  ///
  /// A pass used to start every bring-up in the same instant. Five
  /// ExoPlayers calling initialize() together do not open five times
  /// faster — they contend for one MediaCodec allocator, one disk and one
  /// media service, and every one of them crawls. The readout said it
  /// exactly: `decoders 5/8  playing 1`. Five slots taken, ONE clip open;
  /// the other four were not refusing to play, they were still opening, all
  /// four fighting each other to do it. Then a deadline fired and killed
  /// them mid-open, and the next pass started the same pile-up again.
  ///
  /// Two at a time opens each one quickly and the set comes up in a second
  /// or so, one after another, instead of none of them coming up at all.
  /// The ceiling on how many EXIST is [maxLive] and is unchanged; this is
  /// only how many may be in the act of starting.
  static const int _openAtOnce = 2;

  int _opening = 0;
  final List<VideoLease> _openQueue = [];

  void _queueOpen(VideoLease l) {
    _openQueue.add(l);
    _drainOpenQueue();
  }

  void _drainOpenQueue() {
    while (_opening < _openAtOnce && _openQueue.isNotEmpty) {
      final l = _openQueue.removeAt(0);
      // Evicted, or the widget went away, while it sat in the queue.
      if (l._disposed || !_live.contains(l)) continue;
      _opening++;
      unawaited(_bringUp(l).whenComplete(() {
        _opening--;
        _drainOpenQueue();
      }));
    }
  }

  /// Deadline timers currently ticking, so they can be called off.
  ///
  /// `Future.timeout` is the obvious way to write this and the wrong one
  /// here: it owns a Timer nobody else can reach, and a bring-up is no
  /// longer awaited by anything, so a widget test that ends mid-open leaves
  /// a twelve-second timer running and fails on "a Timer is still pending
  /// even after the widget tree was disposed". Owning them means
  /// [debugDropAll] can put them out.
  final Set<Timer> _timers = {};

  /// Widget tests run on a fake clock and finish the moment their last pump
  /// returns, so a deadline still ticking on an in-flight open fails them on
  /// "a Timer is still pending even after the widget tree was disposed" —
  /// and a bring-up is deliberately not awaited any more, so there is always
  /// one in flight. Nothing in a widget test is testing a timeout;
  /// video_pool_test.dart does that, in real async, with this left on.
  @visibleForTesting
  static bool debugDeadlines = true;

  /// [f], but it gives up after [d].
  Future<T> _byThen<T>(Future<T> f, Duration d, String what) {
    if (!debugDeadlines) return f;
    final done = Completer<T>();
    final t = Timer(d, () {
      if (!done.isCompleted) {
        done.completeError(TimeoutException(what, d));
      }
    });
    _timers.add(t);
    f.then<void>(
      (v) {
        if (!done.isCompleted) done.complete(v);
      },
      onError: (Object e, StackTrace s) {
        if (!done.isCompleted) done.completeError(e, s);
      },
    ).whenComplete(() {
      t.cancel();
      _timers.remove(t);
    });
    return done.future;
  }

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
  /// How many are actually MOVING — not how many decoders exist.
  ///
  /// The two came apart once already and the readout could not tell: six
  /// decoders existed, all six were playing, and every one of them was
  /// invisible behind its own poster because the picture had no size yet.
  /// "decoders 6/8" looked healthy while the page looked frozen. This is
  /// the number that says which of those two is happening.
  int get playingCount {
    var n = 0;
    for (final l in _live) {
      final c = l._controller;
      if (c != null && c.value.isInitialized && c.value.isPlaying) n++;
    }
    return n;
  }

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
    _openQueue.clear();
    _opening = 0;
    _again = false;
    // The in-flight flags too. A pass abandoned mid-await leaves _rebalancing
    // true, and a true _rebalancing is permanent: every later request just
    // sets _again and returns, so the pool never grants another decoder as
    // long as the app runs. Not only a test concern — it is the one state
    // this object has that can wedge.
    _rebalancing = false;
    _passStarted = null;
    _scheduled = false;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @visibleForTesting
  Future<void> debugReset() async {
    for (final l in _leases.toList()) {
      l.dispose();
    }
    _leases.clear();
    // The open queue is state too. A test that ends with clips still queued
    // leaves _opening above zero, and a non-zero _opening with nothing left
    // to complete it stalls every later open — the same shape of wedge the
    // pass guard exists for.
    _openQueue.clear();
    _opening = 0;
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
  DateTime? _passStarted;

  /// The last line of defence.
  ///
  /// Everything a pass awaits now has a deadline, so it should not be
  /// possible for one to hang — but "should not be possible" is exactly what
  /// was believed about the state that produced `decoders 1/8`. If a pass has
  /// been open longer than any pass can legitimately take, it is abandoned
  /// and the next request is allowed through. A pool that occasionally
  /// double-passes is a much smaller problem than a pool that stops.
  bool get _passGuard {
    if (!_rebalancing) return false;
    final t = _passStarted;
    if (t != null && DateTime.now().difference(t) > _passLimit) {
      debugPrint('NowssB video: a rebalance hung — starting a fresh one');
      _rebalancing = false;
      return false;
    }
    return true;
  }

  Future<void> _rebalance() async {
    // One pass at a time. A pass gives players back and then takes new ones,
    // and both halves are asynchronous — two passes interleaved would be two
    // sets of "take" running against one set of "give back", which is how
    // the ceiling gets exceeded. A request that arrives mid-pass is
    // remembered and run once this one finishes.
    if (_passGuard) {
      _again = true;
      return;
    }
    _rebalancing = true;
    _passStarted = DateTime.now();

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
            .where((l) => l._distance != double.infinity && l._eligible)
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
        // Bounded. A platform that never answers a dispose would otherwise
        // hold this await — and this await open is this whole object wedged;
        // see [_passGuard].
        if (going.isNotEmpty) {
          await _byThen(Future.wait(going), _giveUp, 'giving players back');
        }

        // Then take.
        //
        // NOT AWAITED, and that is the fix for "decoders 1/8, playing 1".
        //
        // A slot is claimed by `_live.add` on the line above — synchronously,
        // before anything asynchronous starts — so the ceiling is already
        // enforced and waiting here buys nothing. What it cost was the pool
        // itself: _bringUp awaits initialize(), initialize() on a Cloudinary
        // URL can stall indefinitely, and one stalled clip held this pass
        // open forever. _rebalancing stays true, every later request just
        // sets _again and returns, and the pool never grants another decoder
        // for the rest of the session. Four clips on screen, eight slots
        // free, one player running, and no way out of it.
        //
        // The comment in debugDropAll has described this state from the
        // beginning — "a true _rebalancing is permanent" — as a test concern.
        // It was not a test concern. It was the bug.
        //
        // And NOT parked in `_draining` either. That set is teardowns — it
        // is awaited at the head of every pass, so a stalled bring-up put in
        // there starves the next pass instead of this one, which is the same
        // bug wearing a different hat. A bring-up cleans up after itself and
        // the slot is already reserved; nothing needs to wait on it.
        for (final l in keep) {
          if (!_live.contains(l)) {
            _live.add(l);
            _queueOpen(l);
          }
        }
      } while (_again && ++turns < 4);

      // Anything still outstanding is left to the next frame rather than
      // spun on here.
      if (_again) {
        _again = false;
        _rebalanceSoon();
      }
    } finally {
      _rebalancing = false;
      _passStarted = null;
    }
  }

  Future<void> _bringUp(VideoLease l) async {
    if (l._disposed || l._controller != null) return;

    // A bundled file OR a URL. The website plays most of these straight
    // from Cloudinary, and until now this could only open an asset — so
    // every remote clip had been quietly replaced with whatever local file
    // was nearest in meaning, and the app was playing the wrong film in
    // half its sections.
    final c = _isRemote(l.assetPath)
        ? VideoPlayerController.networkUrl(Uri.parse(l.assetPath))
        : VideoPlayerController.asset(l.assetPath);
    l._controller = c;

    try {
      // WITH A DEADLINE. A local asset opens in milliseconds; a Cloudinary
      // URL opens in a second or two on a good connection and NEVER on a bad
      // one — initialize() does not time out on its own, it simply does not
      // return. An un-deadlined await here is the difference between "this
      // clip is slow" and "this app plays no video again until you kill it".
      await _byThen(
        c.initialize(),
        _isRemote(l.assetPath) ? _openRemote : _openLocal,
        'opening ${l.assetPath}',
      );
    } catch (e) {
      // A clip that will not open is not worth taking the app down for. The
      // poster is already on screen and stays there — and now the reason is
      // recorded rather than only printed, because a debugPrint cannot be
      // read from a phone in someone's hand.
      lastError = '${l.assetPath.split('/').last}: $e';
      debugPrint('NowssB video: could not open ${l.assetPath} — $e');
      l._failures++;
      // Back off, do not strike off. Five seconds, then ten, then fifteen,
      // up to a minute — so a clip that failed because the phone had no
      // route yet is playing a few seconds later instead of being dead for
      // the session.
      final wait = Duration(seconds: 5 * l._failures.clamp(1, 12));
      l._retryAt = DateTime.now().add(wait);
      l._controller = null;
      _live.remove(l);
      try {
        await _byThen(c.dispose(), _giveUp, 'dispose');
      } catch (_) {}
      l._changed();
      // The slot this clip just gave back belongs to whoever is next.
      _rebalanceSoon();
      return;
    }

    // It opened. Whatever went wrong before did not go wrong this time.
    l._failures = 0;
    l._retryAt = null;

    // Disposed, or evicted again, while we were awaiting initialize().
    if (l._disposed || !_live.contains(l)) {
      l._controller = null;
      await c.dispose();
      return;
    }

    await c.setLooping(l.loop);
    // Muted, always. Every clip in this app is decoration, and a video
    // playing with sound is what put the website in Android's notification
    // shade next to a music player.
    await c.setVolume(0);
    if (l._wantsPlay) await c.play();

    l._changed();
    // Asking once is not the same as it having happened. The readout said
    // `decoders 4/8  playing 1`: four players existed, three of them were
    // not moving, and a single fire-and-forget play() is why. See
    // [_assertPlaying].
    _assertPlaying();
  }

  static bool _isRemote(String p) =>
      p.startsWith('http://') || p.startsWith('https://');

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
      await _byThen(c.pause(), _giveUp, 'pause');
    } catch (_) {
      // Already gone, or not answering. Dispose it anyway.
    }
    try {
      await _byThen(c.dispose(), _giveUp, 'dispose');
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

  /// Make every lease that holds a decoder and wants to move actually move.
  ///
  /// `play()` is asked for once, immediately after initialize(), and on
  /// Android that request does not always take: the surface may not be
  /// attached yet, and the call returns without error having done nothing.
  /// The result is a player that exists, is initialized, holds its slot and
  /// sits on frame one — which is exactly what "the videos are not playing"
  /// looked like, with the readout reporting four decoders and one of them
  /// moving.
  ///
  /// So it is asserted rather than assumed: cheap to check, harmless to
  /// repeat, and the heartbeat runs it every two seconds so a player that
  /// misses its moment gets another one.
  void _assertPlaying() {
    for (final l in _live) {
      if (!l._wantsPlay) continue;
      final c = l._controller;
      if (c == null || !c.value.isInitialized) continue;
      if (c.value.isPlaying) continue;
      c.play();
    }
  }

  /// A slow heartbeat, as a backstop for anything the per-frame measuring
  /// misses — a screen that is completely static produces no frames, so it
  /// reports nothing, so a clip that arrived during the quiet would wait
  /// forever. Two seconds costs nothing and cannot deadlock.
  Timer? _beat;
  void startHeartbeat() {
    _beat ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (_leases.isEmpty) return;
      _rebalanceSoon();
      // A player that missed its start gets another chance every beat.
      _assertPlaying();
    });
  }
}
