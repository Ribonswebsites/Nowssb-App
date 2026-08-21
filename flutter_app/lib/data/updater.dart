/// In-app update. The installed app asks GitHub what the latest build is
/// and shows a glass sheet so a new file is not required for every change.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/tokens.dart';

class NwsbUpdate {
  static const localBuild = 2026082114;
  static const _url =
      'https://raw.githubusercontent.com/Ribonswebsites/Nowssb-App/main/version.json';

  static Future<Map<String, dynamic>?> fetch() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('$_url?t=${DateTime.now().millisecondsSinceEpoch}'));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final snooze = prefs.getInt('nwsb_update_snooze') ?? 0;
    if (snooze > DateTime.now().millisecondsSinceEpoch) return;
    final info = await fetch() ??
        {
          'version': '9.6.1',
          'build': localBuild,
          'title': 'Update available',
          'notes':
              'The player is a real watch-bezel now. Wind the knurled ring. This update installs inside the app — no new download.',
        };
    if (!context.mounted) return;
    final remote = (info['build'] as num?)?.toInt() ?? 0;
    final seen = prefs.getInt('nwsb_seen_build') ?? 0;
    if (remote <= seen) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _Sheet(info: info, prefs: prefs),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.info, required this.prefs});
  final Map<String, dynamic> info;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final version = '${info['version'] ?? ''}';
    final notes = '${info['notes'] ?? ''}';
    final title = '${info['title'] ?? 'Update available'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF50C1424),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x2ED7F2FF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x29D7F2FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('NEW',
                    style: TextStyle(
                      color: Color(0xFFD7F2FF),
                      fontSize: 10,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text('NowssB $version', style: const TextStyle(color: Color(0x8CFFFFFF))),
              const SizedBox(height: 14),
              Text(notes, style: const TextStyle(color: Color(0xC7FFFFFF), height: 1.55, fontSize: 14)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        prefs.setInt(
                          'nwsb_update_snooze',
                          DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        prefs.setInt('nwsb_seen_build', (info['build'] as num?)?.toInt() ?? NwsbUpdate.localBuild);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD7F2FF),
                        foregroundColor: NwsbColors.ink,
                      ),
                      child: const Text('Update now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
