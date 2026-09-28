// The updater's download core against a local HTTP server: a connection that
// drops midway, a connection that goes silent, and a server that ignores
// Range. In every case the bytes already on disk are kept and the next
// attempt continues from them.
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/app_update.dart';

void main() {
  late Directory dir;
  late HttpServer server;
  final random = Random(7);
  final payload = Uint8List.fromList(List.generate(3 * 1024 * 1024, (_) => random.nextInt(256)));
  final ranges = <String?>[];
  var mode = 'drop'; // drop | stall | ignoreRange | ok
  var requests = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nwsb_update_test');
    ranges.clear();
    requests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests++;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      ranges.add(range);
      if (request.uri.path == '/redirect') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/apk');
        await request.response.close();
        return;
      }
      var start = 0;
      final match = RegExp(r'bytes=(\d+)-').firstMatch(range ?? '');
      if (match != null && mode != 'ignoreRange') start = int.parse(match.group(1)!);
      final res = request.response;
      if (start > 0) {
        res.statusCode = HttpStatus.partialContent;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-${payload.length - 1}/${payload.length}');
      }
      res.contentLength = payload.length - start;
      final firstAttempt = requests == 1;
      if (firstAttempt && mode == 'drop') {
        final socket = await res.detachSocket();
        socket.add(payload.sublist(start, start + 1024 * 1024));
        await socket.flush();
        socket.destroy();
        return;
      }
      if (firstAttempt && mode == 'stall') {
        res.add(payload.sublist(start, start + 512 * 1024));
        await res.flush();
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          await res.close();
        } catch (_) {}
        return;
      }
      res.add(payload.sublist(start));
      await res.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  NwsbApkFetch fetch(File part, {String path = '/apk'}) => NwsbApkFetch(
        url: Uri.parse('http://127.0.0.1:${server.port}$path'),
        part: part,
        expectedSize: payload.length,
        stallTimeout: const Duration(seconds: 1),
      );

  test('a dropped connection resumes from the partial file with Range', () async {
    mode = 'drop';
    final part = File('${dir.path}/a.apk.part');
    await expectLater(fetch(part).run(), throwsA(anything));
    final kept = await part.length();
    expect(kept, greaterThan(0));
    await fetch(part).run();
    expect(ranges.last, 'bytes=$kept-');
    expect(await part.readAsBytes(), payload);
  });

  test('a silent connection times out and keeps what arrived', () async {
    mode = 'stall';
    final part = File('${dir.path}/b.apk.part');
    await expectLater(fetch(part).run(), throwsA(isA<TimeoutException>()));
    final kept = await part.length();
    expect(kept, 512 * 1024);
    await fetch(part).run();
    expect(ranges.last, 'bytes=$kept-');
    expect(await part.readAsBytes(), payload);
  });

  test('Range survives a redirect (GitHub release downloads redirect)', () async {
    mode = 'ok';
    final part = File('${dir.path}/c.apk.part');
    await part.writeAsBytes(payload.sublist(0, 1000));
    await fetch(part, path: '/redirect').run();
    expect(ranges, ['bytes=1000-', 'bytes=1000-']);
    expect(await part.readAsBytes(), payload);
  });

  test('a server that ignores Range restarts the file instead of corrupting it', () async {
    mode = 'ignoreRange';
    final part = File('${dir.path}/d.apk.part');
    await part.writeAsBytes(payload.sublist(0, 4096));
    await fetch(part).run();
    expect(await part.readAsBytes(), payload);
  });

  test('a complete file is not downloaded again', () async {
    mode = 'ok';
    final part = File('${dir.path}/e.apk.part');
    await part.writeAsBytes(payload);
    await fetch(part).run();
    expect(requests, 0);
  });
}
