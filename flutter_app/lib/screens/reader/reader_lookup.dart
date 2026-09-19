/// In-reader translate and look-up — part065.js `rdWebOpen`.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

class ReaderLookup {
  ReaderLookup._();

  static const langs = <(String, String)>[
    ('en', 'English'),
    ('hi', 'हिन्दी'),
    ('mr', 'मराठी'),
    ('es', 'Español'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
    ('ar', 'العربية'),
    ('ja', '日本語'),
  ];

  static Future<String?> translate(String text, String to) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=auto&tl=${Uri.encodeComponent(to)}&dt=t'
      '&q=${Uri.encodeQueryComponent(text)}',
    );
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j is! List || j.isEmpty || j[0] is! List) return null;
      final out = StringBuffer();
      for (final p in j[0] as List) {
        if (p is List && p.isNotEmpty && p[0] != null) out.write(p[0]);
      }
      final s = out.toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  static Future<List<(String, String)>> search(String text) async {
    final q = text.split(RegExp(r'\s+')).take(10).join(' ');
    final out = <(String, String)>[];
    try {
      final wiki = await http
          .get(Uri.parse(
              'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(q.replaceAll(' ', '_'))}'))
          .timeout(const Duration(seconds: 8));
      if (wiki.statusCode == 200) {
        final j = jsonDecode(wiki.body);
        if (j is Map &&
            j['extract'] is String &&
            '${j['extract']}'.isNotEmpty) {
          out.add(('Wikipedia', '${j['extract']}'));
        }
      }
    } catch (_) {}
    try {
      final ddg = await http
          .get(Uri.parse(
              'https://api.duckduckgo.com/?format=json&no_html=1&skip_disambig=1&q=${Uri.encodeQueryComponent(q)}'))
          .timeout(const Duration(seconds: 8));
      if (ddg.statusCode == 200) {
        final j = jsonDecode(ddg.body);
        if (j is Map) {
          final abs = '${j['AbstractText'] ?? ''}';
          if (abs.isNotEmpty) {
            out.add(('${j['AbstractSource'] ?? 'DuckDuckGo'}', abs));
          } else if (j['RelatedTopics'] is List) {
            final bits = <String>[];
            for (final t in (j['RelatedTopics'] as List).take(3)) {
              if (t is Map && t['Text'] != null) bits.add('${t['Text']}');
            }
            if (bits.isNotEmpty) out.add(('DuckDuckGo', bits.join('\n\n')));
          }
        }
      }
    } catch (_) {}
    return out;
  }
}
