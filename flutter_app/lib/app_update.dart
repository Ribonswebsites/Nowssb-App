/// Checks a stable, successful-build manifest when the Flutter app enters the
/// foreground. No background process is kept alive and no APK is downloaded
/// automatically: Android must show its own installer confirmation.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class NwsbAppUpdate {
  const NwsbAppUpdate({required this.build, required this.websiteUrl, required this.apkUrl});

  static const currentBuild = int.fromEnvironment('NWSB_BUILD_NUMBER', defaultValue: 1);
  static final Uri _manifest = Uri.parse(
    'https://github.com/Ribonswebsites/Nowssb-App/releases/download/nowssb-flutter-android/NowssB-Flutter-update.json',
  );

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
}
