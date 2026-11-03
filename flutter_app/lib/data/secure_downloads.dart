// ignore_for_file: experimental_member_use
/// Offline downloads, encrypted at rest.
///
/// * AES-256-GCM, one random 12-byte nonce per file, 16-byte tag.
/// * The 256-bit key is made once per device and kept in
///   flutter_secure_storage (Android Keystore-backed). It never leaves it.
/// * Files live in app-private support storage (`nwsb_dl/`), never in a
///   shared folder. There is no export, share or save-to-gallery path.
/// * Playback decrypts into memory only ([audioSource]).
///
/// Only items with a real http(s) recording can be downloaded.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadItem {
  const DownloadItem({required this.id, required this.title, required this.kind, required this.url, this.bytes = 0, this.at = 0});
  final String id;
  final String title;

  /// 'word' or 'session'.
  final String kind;
  final String url;
  final int bytes;
  final int at;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'kind': kind, 'url': url, 'bytes': bytes, 'at': at};
  static DownloadItem fromJson(Map m) => DownloadItem(
        id: '${m['id']}',
        title: '${m['title']}',
        kind: '${m['kind']}',
        url: '${m['url']}',
        bytes: (m['bytes'] as num?)?.toInt() ?? 0,
        at: (m['at'] as num?)?.toInt() ?? 0,
      );
}

/// AES-256-GCM box: nonce(12) | ciphertext | tag(16).
class DownloadCipher {
  DownloadCipher(this._key);
  final SecretKey _key;
  static final _algo = AesGcm.with256bits();

  static Future<DownloadCipher> fromBytes(List<int> key) async {
    if (key.length != 32) throw ArgumentError('AES-256 key must be 32 bytes');
    return DownloadCipher(SecretKey(List<int>.unmodifiable(key)));
  }

  Future<Uint8List> encrypt(List<int> plain) async {
    final box = await _algo.encrypt(plain, secretKey: _key, nonce: _algo.newNonce());
    return box.concatenation();
  }

  Future<Uint8List> decrypt(List<int> data) async {
    final box = SecretBox.fromConcatenation(data, nonceLength: 12, macLength: 16, copy: false);
    return Uint8List.fromList(await _algo.decrypt(box, secretKey: _key));
  }
}

class SecureDownloads extends ChangeNotifier {
  SecureDownloads._();
  static final SecureDownloads instance = SecureDownloads._();

  static const _keyName = 'nwsb_dl_key_v1';
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  /// Tests set these to avoid platform channels.
  @visibleForTesting
  static Future<Directory> Function()? debugDir;
  @visibleForTesting
  static List<int>? debugKey;
  @visibleForTesting
  static http.Client? debugClient;

  DownloadCipher? _cipher;
  Directory? _dir;
  final Map<String, DownloadItem> _items = {};
  final Map<String, double> _progress = {};
  bool _loaded = false;

  static bool canDownload(String url) => url.startsWith('https://') || url.startsWith('http://');

  List<DownloadItem> get items => _items.values.toList()..sort((a, b) => b.at.compareTo(a.at));
  bool isDownloaded(String id) => _items.containsKey(id);
  double? progressOf(String id) => _progress[id];

  Future<DownloadCipher> _cipherNow() async {
    if (_cipher != null) return _cipher!;
    if (debugKey != null) return _cipher = await DownloadCipher.fromBytes(debugKey!);
    var b64 = await _storage.read(key: _keyName);
    if (b64 == null) {
      final r = Random.secure();
      b64 = base64Encode(List<int>.generate(32, (_) => r.nextInt(256)));
      await _storage.write(key: _keyName, value: b64);
    }
    return _cipher = await DownloadCipher.fromBytes(base64Decode(b64));
  }

  Future<Directory> _dirNow() async {
    if (_dir != null) return _dir!;
    final base = debugDir != null ? await debugDir!() : await getApplicationSupportDirectory();
    final d = Directory('${base.path}/nwsb_dl');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _dir = d;
  }

  String _fileName(String id) => '${hash.sha256.convert(utf8.encode(id))}.bin';
  File _index(Directory d) => File('${d.path}/index.json');

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final f = _index(await _dirNow());
      if (f.existsSync()) {
        final list = jsonDecode(await f.readAsString()) as List;
        for (final m in list.whereType<Map>()) {
          final it = DownloadItem.fromJson(m);
          if (File('${_dir!.path}/${_fileName(it.id)}').existsSync()) _items[it.id] = it;
        }
      }
    } catch (e) {
      debugPrint('NowssB downloads index: $e');
    }
    notifyListeners();
  }

  Future<void> _saveIndex() async {
    final d = await _dirNow();
    await _index(d).writeAsString(jsonEncode([for (final i in _items.values) i.toJson()]));
  }

  /// Downloads, encrypts and stores [url]. Returns false on failure.
  Future<bool> download({required String id, required String title, required String kind, required String url}) async {
    if (!canDownload(url) || _progress.containsKey(id)) return false;
    await load();
    _progress[id] = 0;
    notifyListeners();
    final client = debugClient ?? http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(url)));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final total = res.contentLength ?? 0;
      final buf = BytesBuilder(copy: false);
      await for (final chunk in res.stream) {
        buf.add(chunk);
        if (total > 0) {
          _progress[id] = buf.length / total;
          notifyListeners();
        }
      }
      final plain = buf.takeBytes();
      if (plain.isEmpty) throw const HttpException('empty file');
      final enc = await (await _cipherNow()).encrypt(plain);
      final d = await _dirNow();
      await File('${d.path}/${_fileName(id)}').writeAsBytes(enc, flush: true);
      _items[id] = DownloadItem(id: id, title: title, kind: kind, url: url, bytes: plain.length, at: DateTime.now().millisecondsSinceEpoch);
      await _saveIndex();
      return true;
    } catch (e) {
      debugPrint('NowssB download $id: $e');
      return false;
    } finally {
      if (debugClient == null) client.close();
      _progress.remove(id);
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    await load();
    _items.remove(id);
    try {
      final f = File('${(await _dirNow()).path}/${_fileName(id)}');
      if (f.existsSync()) await f.delete();
      await _saveIndex();
    } catch (_) {}
    notifyListeners();
  }

  /// Decrypted bytes, in memory only. Null if not downloaded.
  Future<Uint8List?> bytesFor(String id) async {
    await load();
    if (!_items.containsKey(id)) return null;
    final f = File('${(await _dirNow()).path}/${_fileName(id)}');
    if (!f.existsSync()) return null;
    return (await _cipherNow()).decrypt(await f.readAsBytes());
  }

  /// A just_audio source that plays the decrypted bytes from memory.
  Future<AudioSource?> audioSource(String id) async {
    final b = await bytesFor(id);
    return b == null ? null : _MemoryAudio(b);
  }

  @visibleForTesting
  void debugReset() {
    _cipher = null;
    _dir = null;
    _items.clear();
    _progress.clear();
    _loaded = false;
  }
}

class _MemoryAudio extends StreamAudioSource {
  _MemoryAudio(this._bytes);
  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
