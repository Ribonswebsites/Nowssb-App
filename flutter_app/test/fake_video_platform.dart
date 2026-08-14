/// A stand-in for the platform's video plugin.
///
/// There is no ExoPlayer in a unit test, so a real VideoPlayerController
/// never finishes initialising and the pool's own error path — correctly —
/// hands the slot straight back. That would leave the tests measuring
/// nothing.
///
/// This registers a fake platform instead, so [VideoPlayerController] behaves
/// exactly as it does on a device: create() returns a player id, an
/// initialized event arrives, and dispose() is recorded. The pool under test
/// is the real one, running its real code path.
///
/// [FakeVideoPlatform.created] and [.disposed] are what make the important
/// assertion possible: not "how many does the pool think it has" but HOW MANY
/// PLAYERS WERE ACTUALLY ASKED FOR AND GIVEN BACK — which is the number that
/// decides whether a phone survives the app.
library;

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlatform extends VideoPlayerPlatform {
  FakeVideoPlatform() {
    // The interface guards against being implemented from outside its own
    // package; registering the instance is the sanctioned way in.
    VideoPlayerPlatform.instance = this;
  }

  int _next = 1;

  /// Every player id ever handed out, in order.
  final List<int> created = [];

  /// Every player id given back.
  final List<int> disposed = [];

  final Map<int, StreamController<VideoEvent>> _events = {};

  /// Players asked for and not yet returned — the number that matters.
  int get alive => created.length - disposed.length;

  void reset() {
    created.clear();
    disposed.clear();
    for (final c in _events.values) {
      c.close();
    }
    _events.clear();
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _next++;
    created.add(id);

    // The initialized event goes out ON SUBSCRIBE, not from create().
    //
    // VideoPlayerController subscribes to videoEventsFor() only after
    // create() has returned, so an event emitted here — even one turn later —
    // lands on a broadcast stream with no listener and is dropped. The
    // controller then awaits an initialization that has already happened and
    // never completes. That is not a hypothetical: it is what this file did
    // first, and it made the pool's own tests hang mid-pass while still
    // reporting green, because they were counting create() calls rather than
    // controllers that came up.
    late final StreamController<VideoEvent> c;
    c = StreamController<VideoEvent>.broadcast(onListen: () {
      // A turn later, so it is asynchronous the way the real plugin is —
      // the demuxer has to read the header before it can report a size.
      scheduleMicrotask(() {
        if (!c.isClosed) {
          c.add(VideoEvent(
            eventType: VideoEventType.initialized,
            duration: const Duration(seconds: 15),
            size: const Size(1280, 720),
          ));
        }
      });
    });
    _events[id] = c;
    return id;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      create(options.dataSource);

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
    await _events.remove(playerId)?.close();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) =>
      _events[playerId]?.stream ?? const Stream.empty();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();
}
