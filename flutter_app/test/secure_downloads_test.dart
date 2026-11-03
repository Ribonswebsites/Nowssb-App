import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nowssb/data/secure_downloads.dart';

void main() {
  late Directory tmp;
  final key = List<int>.generate(32, (i) => i * 7 % 256);
  final audio = Uint8List.fromList(List<int>.generate(5000, (i) => i % 251));

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('nwsb_dl_test');
    SecureDownloads.debugDir = () async => tmp;
    SecureDownloads.debugKey = key;
    SecureDownloads.debugClient = MockClient((req) async => http.Response.bytes(audio, 200));
    SecureDownloads.instance.debugReset();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('AES-256-GCM round trip and tamper detection', () async {
    final c = await DownloadCipher.fromBytes(key);
    final enc = await c.encrypt(audio);
    expect(enc.length, audio.length + 12 + 16);
    expect(await c.decrypt(enc), audio);
    final bad = Uint8List.fromList(enc)..[20] ^= 0xFF;
    expect(() => c.decrypt(bad), throwsA(anything));
  });

  test('download stores ciphertext only, decrypts in memory, removes', () async {
    final dl = SecureDownloads.instance;
    await dl.download(id: 'word:om', title: 'Om', kind: 'word', url: 'https://example.com/om.mp3');
    expect(dl.isDownloaded('word:om'), isTrue);
    final files = tmp.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.bin'));
    expect(files.length, 1);
    final onDisk = files.first.readAsBytesSync();
    expect(onDisk, isNot(equals(audio)));
    expect(await dl.bytesFor('word:om'), audio);
    await dl.remove('word:om');
    expect(dl.isDownloaded('word:om'), isFalse);
    expect(files.first.existsSync(), isFalse);
  });

  test('only real audio URLs can be downloaded', () {
    expect(SecureDownloads.canDownload(''), isFalse);
    expect(SecureDownloads.canDownload('assets/a.mp3'), isFalse);
    expect(SecureDownloads.canDownload('https://x/a.mp3'), isTrue);
  });
}
