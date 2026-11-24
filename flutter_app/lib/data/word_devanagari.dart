import 'models.dart';

/// The word's Devanagari from its content data: the word's own `deva`,
/// else its sound parts' Devanagari joined, when every part has one. Null
/// when there is none; never transliterated.
///
/// Shown only as the line UNDER the English title on word cards (the
/// Practice card, the Stages tab header) — never instead of the title.
String? wordDevanagari(Word word) {
  final own = word.deva.trim();
  if (own.isNotEmpty) return own;
  if (word.parts.isEmpty || word.parts.any((p) => p.deva.trim().isEmpty)) return null;
  return word.parts.map((p) => p.deva.trim()).join();
}
