/// Plain words for what the owner sees in the UI Editor: no designer
/// jargon ("Hero", "curve") in section names.
library;

String plainWords(String title) {
  var t = title;
  t = t.replaceAll(RegExp(r',?\s*curve\s*(&|and)\s*', caseSensitive: false), ' & ');
  t = t.replaceAll(RegExp(r'\s*\bcurved?\b', caseSensitive: false), '');
  t = t.replaceAllMapped(RegExp(r'\bHero\b( header| film| row| card)?', caseSensitive: false), (m) {
    return switch ((m.group(1) ?? '').trim().toLowerCase()) {
      'header' => 'Top header',
      'film' => 'Top video',
      'row' => 'Top row',
      'card' => 'Top card',
      _ => 'Top banner',
    };
  });
  t = t.replaceAll(RegExp(r'Top banner:\s*'), 'Top: ');
  t = t.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(RegExp(r'\s+([,&])\s*&'), r' &').trim();
  return t.isEmpty ? title : t;
}
