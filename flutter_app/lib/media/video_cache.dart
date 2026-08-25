/// Private, app-only storage for the decorative video pack.
///
/// The pack is downloaded with a small bounded number of workers into the
/// application support directory. It is never written to Downloads or the
/// user's gallery. A `.part` file is retained across transient failures so a
/// supported CDN can resume from the last received byte; only a complete file
/// is handed to the video player.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'video_catalog.dart';

class VideoPackState {
  const VideoPackState({
    required this.total,
    required this.completed,
    required this.failed,
    required this.running,
    this.activeUrl,
    this.error,
  });

  final int total;
  final int completed;
  final int failed;
  final bool running;
  final String? activeUrl;
  final String? error;

  double get progress => total == 0 ? 1 : completed / total;
  bool get complete => total > 0 && completed >= total;
}

class _VideoJob {
  _VideoJob(this.url, this.completer);

  final String url;
  final Completer<String?> completer;
}

class VideoCache extends ChangeNotifier {
  VideoCache._();

  static final VideoCache instance = VideoCache._();
  static const _version = 'video-pack-v2';
  static const _promptKey = 'nowssb.video-pack.prompted.v1';
  static const _acceptedKey = 'nowssb.video-pack.accepted.v1';

  final http.Client _client = http.Client();
  final Map<String, Future<String?>> _inFlight = <String, Future<String?>>{};
  final List<_VideoJob> _jobs = <_VideoJob>[];
  static const int _maxConcurrent = 4;
  int _activeJobs = 0;
  final Set<String> _activeUrls = <String>{};

  Directory? _directory;
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _running = false;
  int _completed = 0;
  int _failed = 0;
  String? _error;

  VideoPackState get state => VideoPackState(
        total: kNowssbVideoPackUrls.length,
        completed: _completed,
        failed: _failed,
        running: _running,
        activeUrl: _activeUrls.isEmpty ? null : _activeUrls.first,
        error: _error,
      );

  bool get isComplete => state.complete;
  bool get hasPrompted => _prefs?.getBool(_promptKey) ?? false;
  bool get accepted => _prefs?.getBool(_acceptedKey) ?? false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    final support = await getApplicationSupportDirectory();
    _directory = Directory('${support.path}/nowssb-video-pack/$_version');
    await _directory!.create(recursive: true);
    _initialized = true;
    await _refreshCompleted();
    notifyListeners();
  }

  Future<void> markPrompted() async {
    await init();
    await _prefs!.setBool(_promptKey, true);
  }

  Future<void> markAccepted() async {
    await init();
    await _prefs!.setBool(_promptKey, true);
    await _prefs!.setBool(_acceptedKey, true);
  }

  String _fileName(String url) =>
      '${base64UrlEncode(utf8.encode(url)).replaceAll('=', '')}.mp4';

  Future<File> _fileFor(String url) async {
    await init();
    return File('${_directory!.path}/${_fileName(url)}');
  }

  Future<void> _refreshCompleted() async {
    if (_directory == null) return;
    var count = 0;
    for (final url in kNowssbVideoPackUrls) {
      final file = File('${_directory!.path}/${_fileName(url)}');
      if (await file.exists() && await file.length() > 0) count++;
    }
    _completed = count;
  }

  /// Returns a complete private file for [url], downloading it through the
  /// bounded worker queue when needed. A failure returns null and never reaches
  /// the video decoder, so the widget can remain on its poster.
  Future<String?> ensure(String url, {bool priority = true}) async {
    await init();
    final file = await _fileFor(url);
    if (await file.exists() && await file.length() > 0) return file.path;
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _enqueue(url, priority: priority);
    _inFlight[url] = future;
    future.whenComplete(() => _inFlight.remove(url));
    return future;
  }

  Future<String?> _enqueue(String url, {required bool priority}) {
    final completer = Completer<String?>();
    final job = _VideoJob(url, completer);
    if (priority) {
      _jobs.insert(0, job);
    } else {
      _jobs.add(job);
    }
    _pumpQueue();
    return completer.future;
  }

  void _pumpQueue() {
    while (_activeJobs < _maxConcurrent && _jobs.isNotEmpty) {
      final job = _jobs.removeAt(0);
      _activeJobs++;
      unawaited(_runJob(job));
    }
  }

  Future<void> _runJob(_VideoJob job) async {
    try {
      job.completer.complete(await _downloadOne(job.url));
    } catch (error, stack) {
      job.completer.completeError(error, stack);
    } finally {
      _activeJobs--;
      _pumpQueue();
    }
  }

  Future<String?> _downloadOne(String url) async {
    final file = await _fileFor(url);
    final part = File('${file.path}.part');
    _activeUrls.add(url);
    _error = null;
    notifyListeners();

    try {
      for (var attempt = 1; attempt <= 5; attempt++) {
        try {
          var offset = await part.exists() ? await part.length() : 0;
          final request = http.Request('GET', Uri.parse(url));
          if (offset > 0) request.headers['Range'] = 'bytes=$offset-';
          final response = await _client
              .send(request)
              .timeout(const Duration(seconds: 45));
          final resumes = offset > 0 && response.statusCode == HttpStatus.partialContent;
          if (response.statusCode != HttpStatus.ok && !resumes) {
            /* A server that ignores Range returns 200; overwrite the partial
               file and continue rather than appending a duplicate stream. */
            if (offset > 0 && response.statusCode == HttpStatus.ok) {
              offset = 0;
            } else {
              throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
            }
          }
          final sink = part.openWrite(mode: offset > 0 && resumes ? FileMode.append : FileMode.write);
          try {
            await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
              sink.add(chunk);
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
          if (!await part.exists() || await part.length() == 0) {
            throw const FileSystemException('Empty video response');
          }
          if (await file.exists()) await file.delete();
          await part.rename(file.path);
          _completed = await _countCompleted();
          _error = null;
          return file.path;
        } catch (error) {
          _error = error.toString();
          /* Keep a partial file. The next attempt asks for the remaining
             bytes when the CDN supports HTTP Range. */
          if (attempt < 5) {
            await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
          }
        }
      }
      _failed++;
      return null;
    } finally {
      _activeUrls.remove(url);
      notifyListeners();
    }
  }

  Future<int> _countCompleted() async {
    var count = 0;
    for (final url in kNowssbVideoPackUrls) {
      final file = File('${_directory!.path}/${_fileName(url)}');
      if (await file.exists() && await file.length() > 0) count++;
    }
    return count;
  }

  /// Starts the full pack download through the bounded worker queue. Calling this twice
  /// is harmless; the second call simply observes the existing run.
  Future<void> downloadAll() async {
    await init();
    if (_running || isComplete) return;
    _running = true;
    _failed = 0;
    _error = null;
    notifyListeners();
    try {
      /* Enqueue the whole catalog at once. The queue pumps four downloads in
         parallel and Future.wait keeps this lifecycle alive until every job
         has either completed or exhausted its retries. */
      final jobs = <Future<String?>>[];
      for (final url in kNowssbVideoPackUrls) {
        if (_running == false) break;
        jobs.add(ensure(url, priority: false));
      }
      await Future.wait(jobs);
    } finally {
      _running = false;
      await _refreshCompleted();
      notifyListeners();
    }
  }

  void stopQueue() {
    // This stops starting the next file. The current HTTP stream is allowed to
    // finish cleanly; its complete file remains usable and a future run resumes.
    _running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
