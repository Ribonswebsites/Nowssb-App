/// A word's own recording, when it has one.
///
/// Admin mode records one voice per word and uploads it to Cloudflare R2
/// (`Word.audio`). This plays it — from the phone's cache after the first
/// time, so a word heard once still plays offline. When a word has no
/// recording, or it cannot be fetched, [play] answers false and the caller
/// speaks the word with text-to-speech exactly as before.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';

import 'models.dart';
import 'secure_downloads.dart';

class WordVoice {
  WordVoice._();
  static final WordVoice instance = WordVoice._();

  AudioPlayer? _player;
  int _token = 0;

  static final CacheManager cache = CacheManager(
    Config(
      'nwsbWordVoice',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 400,
    ),
  );

  /// A recording that can be played: uploaded (http) or shipped inside the
  /// app (`asset:assets/…`, the client-recorded words in
  /// assets/content/client_words.json).
  static bool hasVoice(Word w) => isRemote(w) || isBundled(w);

  static bool isRemote(Word w) => w.voice.startsWith('http');
  static bool isBundled(Word w) => w.voice.startsWith('asset:');
  static String assetPath(Word w) => w.voice.substring('asset:'.length);

  /// The id a word's recording is downloaded under.
  static String downloadId(Word w) => 'word:${w.key}';

  /// Download ahead of time so the first play is instant. Never throws.
  static Future<void> prefetch(Word w) async {
    if (!isRemote(w)) return;
    try {
      await cache.getSingleFile(w.voice);
    } catch (_) {}
  }

  /// Plays [w]'s recording to the end. True if it played; false means
  /// "use text-to-speech".
  /// Tests: stands in for the audio plugin. [stopped] turns true once
  /// [stop] (or another play) ends this one, as the real player does.
  @visibleForTesting
  static Future<bool> Function(Word w, bool Function() stopped)? debugPlay;

  /// Tests: the bundled asset each [play] loaded, newest last.
  @visibleForTesting
  static final List<String> debugPlayed = [];

  /// The run that is playing now: [stop] or a newer [play] completes it at
  /// once, so a caller never waits on a player event that may never come.
  Completer<void>? _run;

  /// Player set-up and tear-down run one at a time. A stop still releasing
  /// the platform player must never land after the next play has loaded
  /// (that left the second stage silent with the clock stuck at the end).
  Future<void> _lane = Future<void>.value();
  Future<T> _serial<T>(Future<T> Function() job) {
    final next = _lane.then((_) => job());
    _lane = next.then((_) {}, onError: (_) {});
    return next;
  }

  void _endRun() {
    final r = _run;
    _run = null;
    if (r != null && !r.isCompleted) r.complete();
  }

  /// Plays [w]'s recording, or the bundled [asset] when given (a teacher
  /// stage's edited recording, e.g. `assets/words/america/america_stage1_music.m4a`).
  /// Every call starts from the beginning on a fresh player, however often
  /// it is called and whatever the last run did (ended, stopped, replaced).
  Future<bool> play(Word w, {double volume = 1, double speed = 1, String? asset}) async {
    if (asset == null && !hasVoice(w)) return false;
    final token = ++_token;
    _endRun();
    final bundled = asset ?? (isBundled(w) ? assetPath(w) : null);
    if (bundled != null) debugPlayed.add(bundled);
    if (debugPlay != null) return debugPlay!(w, () => token != _token);
    final run = Completer<void>();
    _run = run;
    StreamSubscription<PlayerState>? sub;
    try {
      AudioSource? offline;
      File? file;
      if (bundled == null) {
        // A downloaded word plays from its encrypted copy, decrypted in memory.
        offline = await SecureDownloads.instance.audioSource(downloadId(w));
        file = offline == null ? await cache.getSingleFile(w.voice).timeout(const Duration(seconds: 15)) : null;
      }
      if (token != _token) return true; // stopped or replaced meanwhile
      Duration? length;
      final started = await _serial(() async {
        if (token != _token) return false;
        final old = _player;
        _player = null;
        if (old != null) {
          try {
            await old.dispose();
          } catch (_) {}
        }
        if (token != _token) return false;
        final p = AudioPlayer();
        _player = p;
        if (bundled != null) {
          length = await p.setAsset(bundled);
        } else if (offline != null) {
          length = await p.setAudioSource(offline);
        } else {
          length = await p.setFilePath(file!.path);
        }
        if (token != _token) return false;
        await p.setVolume(volume.clamp(0.0, 1.0));
        await p.setSpeed(speed.clamp(0.5, 2.0));
        sub = p.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed && !run.isCompleted) run.complete();
        });
        unawaited(p.play());
        return true;
      });
      if (!started) return true;
      final cap = length == null
          ? const Duration(minutes: 2)
          : Duration(milliseconds: (length!.inMilliseconds / speed.clamp(0.5, 2.0)).round() + 2500);
      await run.future.timeout(cap, onTimeout: () {});
      return true;
    } catch (e) {
      debugPrint('NowssB voice for ${w.key}: $e');
      return false;
    } finally {
      await sub?.cancel();
      if (identical(_run, run)) _run = null;
    }
  }

  /// Live volume while a recording is playing (0 = mute).
  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> stop() async {
    _token++;
    _endRun();
    await _serial(() async {
      try {
        await _player?.stop();
      } catch (_) {}
    });
  }
}
