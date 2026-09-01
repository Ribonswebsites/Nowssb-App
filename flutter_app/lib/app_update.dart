/// Checks the stable update manifest, downloads the APK inside the app, and
/// hands it to Android's package installer. Android still requires the user
/// to approve the install; no ordinary app can silently replace itself.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class NwsbAppUpdate {
  const NwsbAppUpdate({required this.build, required this.websiteUrl, required this.apkUrl});

  static const currentBuild = int.fromEnvironment('NWSB_BUILD_NUMBER', defaultValue: 1);
  static final Uri _manifest = Uri.parse(
    'https://github.com/Ribonswebsites/Nowssb-App/releases/download/nowssb-flutter-android/NowssB-Flutter-update.json',
  );
  static const _channel = MethodChannel('com.nowssb.app/update');

  final int build;
  final Uri websiteUrl;
  final Uri apkUrl;

  static Future<NwsbAppUpdate?> findNewer() async {
    try {
      final uri = _manifest.replace(queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'});
      final response = await http.get(uri, headers: const {'Cache-Control': 'no-cache'}).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map) return null;
      final build = int.tryParse('${json['build'] ?? ''}') ?? 0;
      if (build <= currentBuild) return null;
      final website = Uri.tryParse('${json['websiteUrl'] ?? ''}');
      final apk = Uri.tryParse('${json['apkUrl'] ?? ''}');
      if (website == null || !website.hasScheme || apk == null || !apk.hasScheme) return null;
      return NwsbAppUpdate(build: build, websiteUrl: website, apkUrl: apk);
    } catch (_) {
      return null;
    }
  }

  static Future<void> downloadAndInstall(NwsbAppUpdate update) async {
    if (!Platform.isAndroid) throw UnsupportedError('In-app APK installation is Android-only');
    final dir = await getApplicationSupportDirectory();
    final file = File(path.join(dir.path, 'nowssb-update-${update.build}.apk'));
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', update.apkUrl)).timeout(const Duration(minutes: 5));
      if (response.statusCode != 200) throw HttpException('APK download failed: ${response.statusCode}');
      final sink = file.openWrite();
      try {
        await response.stream.pipe(sink);
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
    await _channel.invokeMethod<void>('installApk', {'path': file.path});
  }
}
