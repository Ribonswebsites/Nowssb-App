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

  /// Translate a selection. Uses the documented public MyMemory API (books
  /// are English, so the pair is en→[to]); a single English word with
  /// `to == 'en'` gets a dictionary definition instead. Returns null when no
  /// service answers — the reader then offers Google Translate in the
  /// browser ([webTranslateUri]) rather than calling an unofficial endpoint.
  static Future<String?> translate(String text, String to) async {
    final q = text.trim();
    if (q.isEmpty) return null;
    if (to == 'en') return define(q);
    try {
      final uri = Uri.https('api.mymemory.translated.net', '/get', {
        'q': q.length > 480 ? q.substring(0, 480) : q,
        'langpair': 'en|$to',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j is! Map) return null;
      if ('${j['responseStatus']}' != '200') return null;
      final out = '${(j['responseData'] as Map?)?['translatedText'] ?? ''}'.trim();
      if (out.isEmpty || out.toUpperCase().contains('MYMEMORY WARNING')) return null;
      return out;
    } catch (_) {
      return null;
    }
  }

  /// English definition for one word (dictionaryapi.dev, free and public).
  static Future<String?> define(String text) async {
    final w = text.trim().split(RegExp(r'\s+'));
    if (w.length != 1) return null;
    try {
      final r = await http
          .get(Uri.https('api.dictionaryapi.dev', '/api/v2/entries/en/${Uri.encodeComponent(w.first.toLowerCase())}'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body);
      if (j is! List || j.isEmpty) return null;
      final lines = <String>[];
      for (final m in ((j.first as Map)['meanings'] as List? ?? const []).take(3)) {
        final pos = '${(m as Map)['partOfSpeech'] ?? ''}';
        final d = (m['definitions'] as List?)?.isNotEmpty == true ? '${(m['definitions'] as List).first['definition']}' : '';
        if (d.isNotEmpty) lines.add(pos.isEmpty ? d : '($pos) $d');
      }
      return lines.isEmpty ? null : lines.join('\n');
    } catch (_) {
      return null;
    }
  }

  /// Google Translate in the browser — the graceful fallback.
  static Uri webTranslateUri(String text, String to) => Uri.https(
      'translate.google.com', '/', {'sl': 'auto', 'tl': to, 'text': text, 'op': 'translate'});

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
