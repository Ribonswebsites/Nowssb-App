/// In-app Android update flow for the native Flutter build.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';

class NwsbUpdate {
  static const localVersion = '9.6.17';
  static const localBuild = 2026082409;
  static const _url = 'https://raw.githubusercontent.com/Ribonswebsites/Nowssb-App/main/version.json';
  static const _channel = MethodChannel('nowssb/updater');

  static Future<Map<String, dynamic>?> fetch() async {
    HttpClient? client;
    try {
      client = HttpClient();
      final req = await client.getUrl(Uri.parse('$_url?t=${DateTime.now().millisecondsSinceEpoch}'));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      return jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static String apkUrl(Map<String, dynamic> info) =>
      '${info['flutterApk'] ?? info['apk'] ?? ''}';

  static Future<void> downloadAndInstall(Map<String, dynamic> info, ValueChanged<int>? onProgress) async {
    if (!Platform.isAndroid) throw const NwsbUpdateException('Android installation is available only on Android.');
    final url = apkUrl(info);
    if (!url.startsWith('https://github.com/Ribonswebsites/Nowssb-App/releases/download/')) {
      throw const NwsbUpdateException('This release does not have an approved Flutter APK URL yet.');
    }
    Future<void> handler(MethodCall call) async {
      if (call.method == 'progress' && call.arguments is Map) {
        final args = Map<Object?, Object?>.from(call.arguments as Map);
        final percent = (args['percent'] as num?)?.toInt();
        if (percent != null) onProgress?.call(percent);
      }
    }
    _channel.setMethodCallHandler(handler);
    try {
      await _channel.invokeMethod<void>('downloadAndInstall', <String, Object>{
        'url': url,
        'filename': 'nowssb-flutter-update.apk',
      });
    } on PlatformException catch (error) {
      throw NwsbUpdateException(error.message ?? 'The Android installer could not be opened.');
    } finally {
      _channel.setMethodCallHandler(null);
    }
  }

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final snooze = prefs.getInt('nwsb_update_snooze') ?? 0;
    if (snooze > DateTime.now().millisecondsSinceEpoch) return;
    final info = await fetch();
    if (!context.mounted || info == null || info['version'] == null) return;
    final remote = (info['build'] as num?)?.toInt() ?? 0;
    final seen = prefs.getInt('nwsb_seen_build') ?? localBuild;
    if (remote <= seen || !isNewer('${info['version']}', localVersion)) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _Sheet(info: info, prefs: prefs),
    );
  }

  static bool isNewer(String remote, String local) {
    final a = remote.split('.').map((v) => int.tryParse(v) ?? 0).toList();
    final b = local.split('.').map((v) => int.tryParse(v) ?? 0).toList();
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}

class NwsbUpdateException implements Exception {
  const NwsbUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.info, required this.prefs});
  final Map<String, dynamic> info;
  final SharedPreferences prefs;
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  bool _busy = false;
  int _progress = 0;
  String? _error;

  Future<void> _update() async {
    setState(() { _busy = true; _error = null; _progress = 0; });
    try {
      await NwsbUpdate.downloadAndInstall(widget.info, (value) { if (mounted) setState(() => _progress = value); });
      await widget.prefs.setInt('nwsb_seen_build', (widget.info['build'] as num?)?.toInt() ?? NwsbUpdate.localBuild);
      if (mounted) setState(() { _busy = false; _progress = 100; });
    } catch (error) {
      if (mounted) setState(() { _busy = false; _error = error.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = '${widget.info['version'] ?? ''}';
    final notes = '${widget.info['notes'] ?? ''}';
    final title = '${widget.info['title'] ?? 'Update available'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xF50C1424), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0x2ED7F2FF))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0x29D7F2FF), borderRadius: BorderRadius.circular(99)), child: const Text('NEW', style: TextStyle(color: Color(0xFFD7F2FF), fontSize: 10, letterSpacing: 2.2, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('NowssB $version', style: const TextStyle(color: Color(0x8CFFFFFF))),
            const SizedBox(height: 14),
            Text(notes, style: const TextStyle(color: Color(0xC7FFFFFF), height: 1.55, fontSize: 14)),
            if (_busy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress / 100, color: const Color(0xFFD7F2FF), backgroundColor: const Color(0x2ED7F2FF)),
              const SizedBox(height: 7),
              Text(_progress > 0 ? 'Downloading update… $_progress%' : 'Downloading update securely…', style: const TextStyle(color: Color(0xB8FFFFFF), fontSize: 12)),
            ],
            if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Color(0xFFFF9A9A), height: 1.35, fontSize: 12))],
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: _busy ? null : () { widget.prefs.setInt('nwsb_update_snooze', DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch); Navigator.pop(context); }, child: const Text('Later'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: _busy ? null : _update, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD7F2FF), foregroundColor: NwsbColors.ink), child: Text(_busy ? 'Updating…' : (_error == null ? 'Update now' : 'Try again')))),
            ]),
          ]),
        ),
      ),
    );
  }
}
