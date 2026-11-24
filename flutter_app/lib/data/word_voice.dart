/// A word's own recording, when it has one.
///
/// Admin mode records one voice per word and uploads it to Cloudflare R2
/// (`Word.audio`). This plays it — from the phone's cache after the first
/// time, so a word heard once still plays offline. When a word has no
/// recording, or it cannot be fetched, [play] answers false and the caller
/// speaks the word with text-to-speech exactly as before.
library;

import 'dart:async';

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

  /// Plays [w]'s recording, or the bundled [asset] when given (a teacher
  /// stage's edited recording, e.g. `assets/words/america/america_stage1_music.m4a`).
  Future<bool> play(Word w, {double volume = 1, double speed = 1, String? asset}) async {
    if (asset == null && !hasVoice(w)) return false;
    final token = ++_token;
    final bundled = asset ?? (isBundled(w) ? assetPath(w) : null);
    if (bundled != null) debugPlayed.add(bundled);
    if (debugPlay != null) return debugPlay!(w, () => token != _token);
    try {
      if (bundled != null) {
        final p = _player ??= AudioPlayer();
        await p.stop();
        await p.setAsset(bundled);
        if (token != _token) return true;
        await p.setVolume(volume.clamp(0.0, 1.0));
        await p.setSpeed(speed.clamp(0.5, 2.0));
        final done = p.playerStateStream
            .firstWhere((s) => s.processingState == ProcessingState.completed || token != _token);
        unawaited(p.play());
        await done.timeout(const Duration(minutes: 2), onTimeout: () => p.playerState);
        return true;
      }
      // A downloaded word plays from its encrypted copy, decrypted in memory.
      final offline = await SecureDownloads.instance.audioSource(downloadId(w));
      final file = offline == null ? await cache.getSingleFile(w.voice).timeout(const Duration(seconds: 15)) : null;
      if (token != _token) return true; // stopped or replaced meanwhile
      final p = _player ??= AudioPlayer();
      await p.stop();
      if (offline != null) {
        await p.setAudioSource(offline);
      } else {
        await p.setFilePath(file!.path);
      }
      await p.setVolume(volume.clamp(0.0, 1.0));
      await p.setSpeed(speed.clamp(0.5, 2.0));
      final done = p.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed || token != _token);
      unawaited(p.play());
      await done.timeout(const Duration(minutes: 2), onTimeout: () => p.playerState);
      return true;
    } catch (e) {
      debugPrint('NowssB voice for ${w.key}: $e — using text-to-speech');
      return false;
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
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
