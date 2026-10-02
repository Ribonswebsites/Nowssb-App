/// The in-app updater (interim, until the app ships through Google Play).
///
/// HOW AN UPDATE IS FOUND. Every successful main build of
/// .github/workflows/flutter-apk.yml publishes release-mode APKs to the
/// `nowssb-flutter-android` GitHub release, then `NowssB-Flutter-update.json`
/// last. The manifest names the build number, an optional `minBuild` (below
/// it the app is blocked until updated), and one APK per ABI with its exact
/// size and SHA-256. [NwsbAppUpdate.findNewer] reads it; this build knows its
/// own number from `--dart-define=NWSB_BUILD_NUMBER`.
///
/// HOW IT DOWNLOADS. [NwsbUpdater] streams the APK for this phone's ABI into
/// `<app support>/updates/*.part`:
///   · HTTP Range resume — a drop, a timeout or a killed app continues from
///     the bytes already on disk, never from zero;
///   · a 30 s stall timer on the stream (a dead socket used to hang forever)
///     and automatic retries with backoff;
///   · it belongs to this controller, not to the dialog, so closing the
///     dialog or leaving the app does not stop it; a small Android foreground
///     service keeps the process up and shows progress in a notification;
///   · size and SHA-256 are checked before Android's installer is opened.
///
/// HOW IT REMINDS. A dismissal is only ever remembered in memory: every cold
/// start prompts again, a return to the app prompts again once the reminder
/// interval has passed, and the banner (lib/widgets/update_prompt.dart)
/// stays on screen until the update is installed.
///
/// Android still asks the user to approve the install; no ordinary app can
/// silently replace itself.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One downloadable APK named by the manifest.
class NwsbUpdateApk {
  const NwsbUpdateApk({required this.abi, required this.url, this.size = 0, this.sha256 = ''});

  final String abi;
  final Uri url;

  /// Exact byte count, 0 when the manifest did not say.
  final int size;

  /// Lower-case hex SHA-256, empty when the manifest did not say.
  final String sha256;

  static NwsbUpdateApk? parse(String abi, Object? json) {
    if (json is! Map) return null;
    final url = Uri.tryParse('${json['url'] ?? ''}');
    if (url == null || !url.hasScheme) return null;
    return NwsbUpdateApk(
      abi: abi,
      url: url,
      size: int.tryParse('${json['size'] ?? ''}') ?? 0,
      sha256: '${json['sha256'] ?? ''}'.toLowerCase(),
    );
  }
}

/// The update manifest. `build`, `websiteUrl` and `apkUrl` are the fields the
/// first updater read, so older installs keep working off the same file.
class NwsbAppUpdate {
  const NwsbAppUpdate({
    required this.build,
    required this.websiteUrl,
    required this.apkUrl,
    this.minBuild = 0,
    this.apks = const {},
    this.universal,
    this.notes = '',
  });

  static const currentBuild = int.fromEnvironment('NWSB_BUILD_NUMBER', defaultValue: 1);
  static final Uri _manifest = Uri.parse(
    'https://github.com/Ribonswebsites/Nowssb-App/releases/download/nowssb-flutter-android/NowssB-Flutter-update.json',
  );

  final int build;
  final Uri websiteUrl;
  final Uri apkUrl;

  /// Builds below this number must update before using the app.
  final int minBuild;

  /// Per-ABI APKs, keyed by Android ABI name (`arm64-v8a`, `armeabi-v7a`).
  final Map<String, NwsbUpdateApk> apks;

  /// The APK that runs on every supported phone (also [apkUrl]).
  final NwsbUpdateApk? universal;
  final String notes;

  bool get required => currentBuild < minBuild;

  /// The newest published build, or null when this build is current, the
  /// manifest is unreachable, or this is not Android.
  static Future<NwsbAppUpdate?> findNewer() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final uri = _manifest.replace(queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'});
      final response = await http.get(uri, headers: const {'Cache-Control': 'no-cache'}).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map) return null;
      final build = int.tryParse('${json['build'] ?? ''}') ?? 0;
      if (build <= currentBuild) return null;
      final website = Uri.tryParse('${json['websiteUrl'] ?? ''}');
      final apk = Uri.tryParse('${json['apkUrl'] ?? ''}');
      if (website == null || !website.hasScheme || apk == null || !apk.hasScheme) return null;
      final apks = <String, NwsbUpdateApk>{};
      final rawApks = json['apks'];
      if (rawApks is Map) {
        rawApks.forEach((abi, value) {
          final parsed = NwsbUpdateApk.parse('$abi', value);
          if (parsed != null) apks['$abi'] = parsed;
        });
      }
      final universal = NwsbUpdateApk(
        abi: 'universal',
        url: apk,
        size: int.tryParse('${json['apkSize'] ?? ''}') ?? 0,
        sha256: '${json['apkSha256'] ?? ''}'.toLowerCase(),
      );
      return NwsbAppUpdate(
        build: build,
        websiteUrl: website,
        apkUrl: apk,
        minBuild: int.tryParse('${json['minBuild'] ?? ''}') ?? 0,
        apks: apks,
        universal: universal,
        notes: '${json['notes'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }
}

enum NwsbUpdatePhase { idle, downloading, retrying, verifying, ready, installing, failed }

/// Owns the update check, the resumable download and the install hand-off.
/// Widgets only listen to it; nothing here depends on a dialog being open.
/// True in the Play Store bundle (see .github/workflows/flutter-apk.yml).
const kNwsbPlayBuild = bool.fromEnvironment('NWSB_PLAY_BUILD');

class NwsbUpdater extends ChangeNotifier {
  NwsbUpdater._();
  static final NwsbUpdater instance = NwsbUpdater._();

  static const _channel = MethodChannel('com.nowssb.app/update');

  /// How long a "Later" quiets the prompt when coming back to the app. Never
  /// persisted: a cold start always prompts.
  static const remindEvery = Duration(hours: 3);

  /// Returning to the app re-reads the manifest at most this often.
  static const _recheckEvery = Duration(minutes: 10);
  static const _stallTimeout = Duration(seconds: 30);
  static const _maxFailuresWithoutProgress = 8;
  static const _resumePref = 'nwsb_update_resume_build';

  /// Google Play builds (`flutter build appbundle
  /// --dart-define=NWSB_PLAY_BUILD=true`) never self-update: Play policy
  /// forbids installing APKs from outside the store, and Play updates them.
  bool get supported => !kNwsbPlayBuild && !kIsWeb && Platform.isAndroid;

  NwsbAppUpdate? _available;
  NwsbAppUpdate? get available => _available;

  /// True when this build is below the manifest's minBuild.
  bool get required => _available?.required ?? false;

  NwsbUpdatePhase _phase = NwsbUpdatePhase.idle;
  NwsbUpdatePhase get phase => _phase;
  bool get busy =>
      _phase == NwsbUpdatePhase.downloading ||
      _phase == NwsbUpdatePhase.retrying ||
      _phase == NwsbUpdatePhase.verifying;

  int _received = 0;
  int _total = 0;
  int get received => _received;
  int get total => _total;
  double? get progress => _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;

  String _message = '';
  String get message => _message;
  DateTime? _retryAt;
  DateTime? get retryAt => _retryAt;

  /// Only the banner and the blocking screen switch on these, so the whole
  /// app is not rebuilt on every progress tick.
  final ValueNotifier<bool> bannerVisible = ValueNotifier(false);
  final ValueNotifier<bool> blocking = ValueNotifier(false);

  File? _apk;
  int? _apkBuild;
  Future<void>? _download;
  Future<NwsbAppUpdate?>? _checking;
  DateTime? _lastCheck;
  DateTime? _dismissedAt;
  bool _promptedThisLaunch = false;
  bool _awaitingPermission = false;
  bool _autoInstallDone = false;
  bool _foreground = true;
  bool _serviceStarted = false;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastNative = DateTime.fromMillisecondsSinceEpoch(0);
  NwsbApkFetch? _fetcher;
  bool _started = false;
  bool _restart = false;

  /// Once per launch: removes update files for builds already installed
  /// (they are ~400 MB each) and the old updater's leftovers.
  Future<void> start() async {
    if (!supported || _started) return;
    _started = true;
    try {
      final support = await getApplicationSupportDirectory();
      await for (final entity in support.list()) {
        if (entity is File && RegExp(r'nowssb-update-\d+\.apk$').hasMatch(entity.path)) {
          await entity.delete();
        }
      }
      final dir = Directory('${support.path}/updates');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          final build = int.tryParse(RegExp(r'nowssb-(\d+)-').firstMatch(entity.path)?.group(1) ?? '');
          if (build == null || build <= NwsbAppUpdate.currentBuild) await entity.delete(recursive: true);
        }
      }
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getInt(_resumePref) ?? 0) <= NwsbAppUpdate.currentBuild) await prefs.remove(_resumePref);
    } catch (_) {
      // Cleanup is best effort.
    }
  }

  void setForeground(bool value) => _foreground = value;

  /// Reads the manifest. Cold starts pass [force]; returns to the app are
  /// throttled to [_recheckEvery]. Resumes a download the user already
  /// started, and starts one straight away when the update is required.
  Future<NwsbAppUpdate?> check({bool force = false}) {
    if (!supported) return Future.value(null);
    final last = _lastCheck;
    if (last != null && DateTime.now().difference(last) < (force ? const Duration(minutes: 1) : _recheckEvery)) {
      return Future.value(_available);
    }
    return _checking ??= _check().whenComplete(() => _checking = null);
  }

  Future<NwsbAppUpdate?> _check() async {
    await start();
    final found = await NwsbAppUpdate.findNewer();
    _lastCheck = DateTime.now();
    if (found == null) {
      // Unreachable manifest keeps what we knew; a current build clears it.
      return _available;
    }
    final previous = _available;
    _available = found;
    if (previous != null && previous.build != found.build && !busy && _phase != NwsbUpdatePhase.installing) {
      _apk = null;
      _phase = NwsbUpdatePhase.idle;
      _message = '';
      _autoInstallDone = false;
    }
    _syncFlags();
    notifyListeners();
    if (!busy) {
      // A file finished and verified on an earlier launch is simply offered.
      await _adoptFinishedFile(found);
      final prefs = await SharedPreferences.getInstance();
      if (_phase != NwsbUpdatePhase.ready && (found.required || prefs.getInt(_resumePref) == found.build)) {
        unawaited(download());
      }
    }
    return found;
  }

  void _syncFlags() {
    bannerVisible.value = _available != null && !required;
    blocking.value = required;
  }

  /// Whether to show the dialog now. Always on the first check of a cold
  /// start; otherwise not within [remindEvery] of the last "Later".
  bool shouldPrompt({required bool coldStart}) {
    if (_available == null || required) return false;
    if (coldStart && !_promptedThisLaunch) return true;
    final dismissed = _dismissedAt;
    return dismissed == null || DateTime.now().difference(dismissed) >= remindEvery;
  }

  void prompted() => _promptedThisLaunch = true;

  /// The dialog was closed without installing. Remembered in memory only.
  void dismissed() => _dismissedAt = DateTime.now();

  /// Starts (or joins) the download. Safe to call repeatedly.
  Future<void> download() {
    final update = _available;
    if (update == null || !supported) return Future.value();
    if (_phase == NwsbUpdatePhase.ready && _apk != null && _apkBuild == update.build) return Future.value();
    final running = _download;
    if (running != null) return running;
    late final Future<void> run;
    run = _run(update).whenComplete(() {
      if (identical(_download, run)) _download = null;
      if (_restart) {
        _restart = false;
        unawaited(download());
      }
    });
    _download = run;
    return run;
  }

  Future<void> _run(NwsbAppUpdate update) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resumePref, update.build);
    _received = 0;
    _total = 0;
    _setPhase(NwsbUpdatePhase.downloading, 'Preparing the download…');
    await _startService('Downloading NowssB update');
    try {
      final apk = await _pickApk(update);
      if (apk == null) {
        _setPhase(NwsbUpdatePhase.failed, 'No update file for this phone. Download it from nowssb.com instead.');
        return;
      }
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/updates');
      await dir.create(recursive: true);
      final tag = 'nowssb-${update.build}-${apk.abi}';
      final part = File('${dir.path}/$tag.apk.part');
      final done = File('${dir.path}/$tag.apk');
      await for (final entity in dir.list()) {
        if (entity.path != part.path && entity.path != done.path) await entity.delete(recursive: true);
      }
      if (await done.exists() && (apk.size <= 0 || await done.length() == apk.size)) {
        _markReady(update, done);
        return;
      }
      _total = apk.size;
      var failures = 0;
      var damaged = 0;
      while (true) {
        final before = await _length(part);
        try {
          _received = before;
          _setPhase(
            NwsbUpdatePhase.downloading,
            before > 0 ? 'Resuming from ${_mb(before)}…' : 'Downloading the update…',
          );
          await _fetch(apk, part);
          final length = await _length(part);
          if (apk.size > 0 && length != apk.size) {
            if (length > apk.size) await part.delete();
            throw HttpException('Size mismatch: $length of ${apk.size} bytes');
          }
          if (apk.sha256.isNotEmpty) {
            _setPhase(NwsbUpdatePhase.verifying, 'Checking the downloaded file…');
            final digest = await _sha256(part.path);
            if (digest != apk.sha256) {
              await part.delete();
              damaged++;
              if (damaged >= 2) {
                _setPhase(NwsbUpdatePhase.failed, 'The download arrived damaged twice. Tap Try again.');
                return;
              }
              continue;
            }
          }
          if (await done.exists()) await done.delete();
          await part.rename(done.path);
          _markReady(update, done);
          return;
        } on FileSystemException catch (e) {
          final noSpace = e.osError?.errorCode == 28 || '${e.osError?.message}'.toLowerCase().contains('space');
          _setPhase(
            NwsbUpdatePhase.failed,
            noSpace
                ? 'Not enough free storage for the update (${_mb(apk.size)}). Free some space and tap Try again.'
                : 'Could not save the update. Tap Try again.',
          );
          return;
        } on _Gone {
          // The file was replaced by a newer build: read the manifest again.
          _lastCheck = null;
          final fresh = await NwsbAppUpdate.findNewer();
          if (fresh != null && fresh.build != update.build) {
            _available = fresh;
            _syncFlags();
            _restart = true;
            return;
          }
          failures++;
        } catch (_) {
          final after = await _length(part);
          failures = after > before ? 0 : failures + 1;
        }
        if (failures >= _maxFailuresWithoutProgress) {
          _setPhase(
            NwsbUpdatePhase.failed,
            'The connection keeps dropping. ${_mb(await _length(part))} is saved — tap Try again to continue.',
          );
          return;
        }
        final wait = Duration(seconds: math.min(60, 2 << failures));
        _retryAt = DateTime.now().add(wait);
        final kept = await _length(part);
        _received = kept;
        _setPhase(
          NwsbUpdatePhase.retrying,
          'Connection interrupted. Retrying in ${wait.inSeconds}s — ${_mb(kept)} saved.',
        );
        await Future<void>.delayed(wait);
        _retryAt = null;
      }
    } catch (_) {
      _setPhase(NwsbUpdatePhase.failed, 'Update download failed. Tap Try again.');
    } finally {
      await _stopService();
    }
  }

  /// One HTTP attempt: resumes from the bytes already in [part].
  Future<void> _fetch(NwsbUpdateApk apk, File part) async {
    final fetch = NwsbApkFetch(
      url: apk.url,
      part: part,
      expectedSize: apk.size,
      stallTimeout: _stallTimeout,
      onProgress: (received, total) {
        _received = received;
        if (total > 0) _total = total;
        _tick();
      },
    );
    _fetcher = fetch;
    try {
      await fetch.run();
    } finally {
      _fetcher = null;
    }
  }

  /// Opens Android's installer for the verified file.
  Future<void> install() async {
    final apk = _apk;
    if (apk == null || !await apk.exists()) {
      _apk = null;
      _setPhase(NwsbUpdatePhase.idle, '');
      unawaited(download());
      return;
    }
    _autoInstallDone = true;
    _setPhase(NwsbUpdatePhase.installing, 'Opening Android installer…');
    try {
      await _channel.invokeMethod<void>('installApk', {'path': apk.path});
      _awaitingPermission = false;
      _setPhase(NwsbUpdatePhase.ready, 'Confirm the install in Android\'s installer.');
    } on PlatformException catch (e) {
      if (e.code == 'INSTALL_PERMISSION') {
        _awaitingPermission = true;
        _setPhase(NwsbUpdatePhase.ready, 'Allow "Install unknown apps" for NowssB, then come back to finish.');
      } else {
        _setPhase(NwsbUpdatePhase.ready, 'Could not open the installer. Tap Install to try again.');
      }
    } catch (_) {
      _setPhase(NwsbUpdatePhase.ready, 'Could not open the installer. Tap Install to try again.');
    }
  }

  /// Back in the foreground: finish an install that was waiting for the
  /// "Install unknown apps" permission.
  Future<void> onResumed() async {
    _foreground = true;
    if (_phase != NwsbUpdatePhase.ready) return;
    if (!_autoInstallDone) {
      // Finished while the app was in the background.
      await install();
      return;
    }
    if (!_awaitingPermission) return;
    try {
      final allowed = await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
      if (allowed) await install();
    } catch (_) {}
  }

  void _markReady(NwsbAppUpdate update, File file) {
    _apk = file;
    _apkBuild = update.build;
    _received = _total = file.lengthSync();
    _setPhase(NwsbUpdatePhase.ready, 'Update downloaded. Tap Install to finish.');
    // The user asked for this download; open the installer as soon as it is
    // done if they are looking at the app. Only once per file, so backing
    // out of the installer does not throw them straight back into it.
    if (_foreground && !_autoInstallDone) unawaited(install());
  }

  /// A previous launch already finished and verified the file.
  Future<void> _adoptFinishedFile(NwsbAppUpdate update) async {
    if (_phase == NwsbUpdatePhase.ready) return;
    try {
      final dir = Directory('${(await getApplicationSupportDirectory()).path}/updates');
      if (!await dir.exists()) return;
      await for (final entity in dir.list()) {
        if (entity is File && RegExp('nowssb-${update.build}-[^/]+\\.apk\$').hasMatch(entity.path)) {
          _apk = entity;
          _apkBuild = update.build;
          _received = _total = await entity.length();
          _autoInstallDone = true;
          _setPhase(NwsbUpdatePhase.ready, 'Update downloaded. Tap Install to finish.');
          return;
        }
      }
    } catch (_) {}
  }

  Future<NwsbUpdateApk?> _pickApk(NwsbAppUpdate update) async {
    var abis = <String>[];
    try {
      abis = await _channel.invokeListMethod<String>('supportedAbis') ?? const [];
    } catch (_) {}
    if (abis.isEmpty) {
      final v = Platform.version;
      if (v.contains('android_arm64')) {
        abis = const ['arm64-v8a'];
      } else if (v.contains('android_arm')) {
        abis = const ['armeabi-v7a'];
      } else if (v.contains('android_x64')) {
        abis = const ['x86_64'];
      }
    }
    for (final abi in abis) {
      final apk = update.apks[abi];
      if (apk != null) return apk;
    }
    return update.universal;
  }

  static Future<int> _length(File file) async => await file.exists() ? await file.length() : 0;

  static Future<String> _sha256(String filePath) => Isolate.run(() async {
        final digest = await sha256.bind(File(filePath).openRead()).first;
        return digest.toString();
      });

  static String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(bytes >= 100 * 1024 * 1024 ? 0 : 1)} MB';

  String get sizeLabel => _total > 0 ? '${_mb(_received)} of ${_mb(_total)}' : _mb(_received);

  void _setPhase(NwsbUpdatePhase phase, String message) {
    _phase = phase;
    _message = message;
    _lastNotify = DateTime.now();
    notifyListeners();
    unawaited(_nativeProgress(force: true));
  }

  void _tick() {
    final now = DateTime.now();
    if (now.difference(_lastNotify) >= const Duration(milliseconds: 250)) {
      _lastNotify = now;
      notifyListeners();
    }
    unawaited(_nativeProgress());
  }

  Future<void> _nativeProgress({bool force = false}) async {
    if (!_serviceStarted || !busy) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastNative) < const Duration(seconds: 1)) return;
    _lastNative = now;
    final p = progress;
    try {
      await _channel.invokeMethod<void>('updateDownloadProgress', {
        'percent': p == null || _phase == NwsbUpdatePhase.verifying ? -1 : (p * 100).floor(),
        'text': _phase == NwsbUpdatePhase.retrying
            ? 'Connection interrupted — retrying'
            : _phase == NwsbUpdatePhase.verifying
                ? 'Checking the download…'
                : '$sizeLabel${p == null ? '' : ' · ${(p * 100).floor()}%'}',
      });
    } catch (_) {}
  }

  Future<void> _startService(String text) async {
    try {
      _serviceStarted = await _channel.invokeMethod<bool>('startDownloadService', {'text': text}) ?? false;
    } catch (_) {
      _serviceStarted = false;
    }
  }

  Future<void> _stopService() async {
    final wasStarted = _serviceStarted;
    _serviceStarted = false;
    try {
      await _channel.invokeMethod<void>('stopDownloadService', {
        'doneText': wasStarted && _phase == NwsbUpdatePhase.ready && !_foreground
            ? 'Update downloaded — tap to install'
            : null,
      });
    } catch (_) {}
  }

  @visibleForTesting
  void debugAbort() => _fetcher?.abort();
}

/// One resumable HTTP GET of an APK into [part]: continues from the bytes
/// already on disk with a Range request, checks the server really resumed at
/// that offset, and fails (so the caller retries) when the stream goes quiet
/// for [stallTimeout]. Whatever arrived before a failure stays in [part].
class NwsbApkFetch {
  NwsbApkFetch({
    required this.url,
    required this.part,
    this.expectedSize = 0,
    this.stallTimeout = const Duration(seconds: 30),
    this.onProgress,
  });

  final Uri url;
  final File part;
  final int expectedSize;
  final Duration stallTimeout;
  final void Function(int received, int total)? onProgress;
  HttpClient? _client;

  void abort() => _client?.close(force: true);

  Future<void> run() async {
    final size = expectedSize;
    var offset = await part.exists() ? await part.length() : 0;
    if (size > 0 && offset > size) {
      await part.delete();
      offset = 0;
    }
    if (size > 0 && offset == size) return;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 15)
      ..autoUncompress = false;
    _client = client;
    try {
      // GitHub answers with a redirect to a short-lived signed URL, so every
      // attempt starts from the stable URL; dart:io carries Range across it.
      final request = await client.getUrl(url).timeout(const Duration(seconds: 30));
      request.followRedirects = true;
      request.maxRedirects = 8;
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (offset > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$offset-');
      final response = await request.close().timeout(const Duration(seconds: 45));
      var append = false;
      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        await _drain(response);
        if (size > 0 && offset == size) return;
        await part.delete();
        throw const HttpException('Range not satisfiable');
      } else if (response.statusCode == HttpStatus.partialContent) {
        final range = RegExp(r'bytes (\d+)-(\d+)/(\d+|\*)')
            .firstMatch(response.headers.value(HttpHeaders.contentRangeHeader) ?? '');
        final start = int.tryParse(range?.group(1) ?? '');
        final whole = int.tryParse(range?.group(3) ?? '');
        if (start != offset || (size > 0 && whole != null && whole != size)) {
          await _drain(response);
          await part.delete();
          throw const HttpException('Unexpected Content-Range');
        }
        append = true;
      } else if (response.statusCode == HttpStatus.ok) {
        offset = 0; // The server ignored Range: start this file over.
      } else if (response.statusCode == HttpStatus.notFound) {
        await _drain(response);
        throw const _Gone();
      } else {
        await _drain(response);
        throw HttpException('HTTP ${response.statusCode}');
      }
      final total = size > 0 ? size : (response.contentLength > 0 ? offset + response.contentLength : 0);
      var received = offset;
      onProgress?.call(received, total);
      final sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
      try {
        // A socket that goes silent without closing used to freeze the old
        // download for good. [stallTimeout] without a byte is a retry.
        await for (final chunk in response.timeout(stallTimeout)) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
      _client = null;
    }
  }

  static Future<void> _drain(HttpClientResponse response) async {
    try {
      await response.drain<void>();
    } catch (_) {}
  }
}

class _Gone implements Exception {
  const _Gone();
}
