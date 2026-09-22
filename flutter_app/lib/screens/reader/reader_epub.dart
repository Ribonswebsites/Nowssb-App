/// Open a local .epub into ReaderPages — part065.js `readZip` / `buildEpub`.
///
/// The file never leaves the device. EPUB is a ZIP of XHTML; we inflate
/// with `archive`, walk the OPF spine, and keep the text.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../data/reader_store.dart';

OpenedEpub buildEpub(Uint8List bytes, String fileName) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: false);
  final files = <String, String>{};
  for (final f in archive.files) {
    if (!f.isFile) continue;
    final name = f.name.replaceAll('\\', '/');
    try {
      files[name] = utf8.decode(f.content as List<int>, allowMalformed: true);
    } catch (_) {}
  }
  final container = files['META-INF/container.xml'] ??
      files.entries
          .firstWhere(
            (e) => e.key.toLowerCase().endsWith('container.xml'),
            orElse: () => const MapEntry('', ''),
          )
          .value;
  if (container.isEmpty) {
    throw const FormatException('no-opf');
  }
  final opfPath = _attr(container, 'full-path');
  if (opfPath.isEmpty || files[opfPath] == null) {
    throw const FormatException('no-opf');
  }
  final opf = files[opfPath]!;
  var title = _tag(opf, 'dc:title');
  if (title.isEmpty) title = _tag(opf, 'title');
  if (title.isEmpty) {
    title = fileName.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
  }

  final manifest = <String, String>{};
  for (final m in RegExp(
    r'<item\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(opf)) {
    final attrs = m.group(1) ?? '';
    final id = _attrFrom(attrs, 'id');
    final href = _attrFrom(attrs, 'href');
    final type = _attrFrom(attrs, 'media-type');
    if (id.isEmpty || href.isEmpty) continue;
    if (!type.contains('html') && type.isNotEmpty) continue;
    manifest[id] = _resolve(opfPath, href);
  }
  final spine = <String>[];
  for (final m in RegExp(
    r'<itemref\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(opf)) {
    final idref = _attrFrom(m.group(1) ?? '', 'idref');
    final href = manifest[idref];
    if (href != null) spine.add(href);
  }
  if (spine.isEmpty) throw const FormatException('empty-spine');

  final pages = <ReaderPage>[];
  for (final path in spine) {
    final raw = files[path];
    if (raw == null) continue;
    final body = _bodyOf(raw);
    final text = _strip(body);
    if (text.isEmpty) continue;
    final head = _firstHeading(body);
    final paras = text
        .split(RegExp(r'\n{2,}'))
        .map((s) => s.replaceAll('\n', ' ').trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (paras.isEmpty && head.isEmpty) continue;
    pages.add(ReaderPage(
      chapter: pages.length + 1,
      chapterName: head.isEmpty ? 'Chapter ${pages.length + 1}' : head,
      first: true,
      title: head.isEmpty ? title : head,
      body: paras.isEmpty ? [text] : paras,
    ));
  }
  if (pages.isEmpty) throw const FormatException('no-text');
  return OpenedEpub(
    key: 'epub:$fileName',
    title: title,
    sub: fileName,
    pages: pages,
  );
}

String _attr(String xml, String name) {
  final m = RegExp('$name="([^"]+)"', caseSensitive: false).firstMatch(xml) ??
      RegExp("$name='([^']+)'", caseSensitive: false).firstMatch(xml);
  return m?.group(1) ?? '';
}

String _attrFrom(String attrs, String name) => _attr(attrs, name);

String _tag(String xml, String name) {
  final m = RegExp(
    '<$name\\b[^>]*>([^<]*)</$name>',
    caseSensitive: false,
  ).firstMatch(xml);
  return (m?.group(1) ?? '').trim();
}

String _resolve(String base, String href) {
  href = href.split('#').first;
  if (href.startsWith('/')) return href.substring(1);
  final parts = base.split('/')..removeLast();
  for (final seg in href.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

String _bodyOf(String raw) {
  final m = RegExp(
    r'<body\b[^>]*>([\s\S]*)</body>',
    caseSensitive: false,
  ).firstMatch(raw);
  return m?.group(1) ?? raw;
}

String _firstHeading(String html) {
  final m = RegExp(
    r'<h[1-3]\b[^>]*>([\s\S]*?)</h[1-3]>',
    caseSensitive: false,
  ).firstMatch(html);
  if (m == null) return '';
  return _strip(m.group(1) ?? '').trim().charactersTake(90);
}

String _strip(String html) {
  const amp = '&';
  return html
      .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('$amp' 'nbsp;', ' ')
      .replaceAll('$amp' 'lt;', '<')
      .replaceAll('$amp' 'gt;', '>')
      .replaceAll('$amp' 'quot;', '"')
      .replaceAll('$amp' '#39;', "'")
      .replaceAll('$amp' 'apos;', "'")
      .replaceAll('$amp' 'amp;', amp)
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .trim();
}

extension on String {
  String charactersTake(int n) => length <= n ? this : substring(0, n);
}
