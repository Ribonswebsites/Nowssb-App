/// How a slot key is made. The Python sweep in tools/admin-slot-sweep.py
/// computes the same keys for the generated manifest, so the two must match
/// character for character: change one, change the other.
///
/// A key is `<slot>.<element>`:
///   * `<slot>` names WHERE — `<file>.<Class>` for everything the sweep
///     converted, e.g. `home_normal.HomeNormal`. Authors of new UI may pass
///     their own, e.g. `store.meaning.hero`.
///   * `<element>` names WHAT — the file name of a picture or clip without
///     its extension, or a short slug of the default text.
///
/// Neither half is a list index, so a key does not move when a list grows.
library;

import 'dart:convert';

/// FNV-1a, 32 bit, over the UTF-8 bytes. Eight lowercase hex digits.
String slotHash(String s) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(s)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// ASCII-only slug: a-z, 0-9 and single dashes. Long text is cut at 40
/// characters and the hash of the whole text is appended so two long lines
/// that start the same way stay apart. Text with no ASCII letters at all
/// (Devanagari, symbols) becomes `t` + hash.
String slotSlug(String text) {
  final b = StringBuffer();
  var dash = false;
  for (final c in text.codeUnits) {
    var ch = c;
    if (ch >= 65 && ch <= 90) ch += 32; // A-Z -> a-z
    final ok = (ch >= 97 && ch <= 122) || (ch >= 48 && ch <= 57);
    if (ok) {
      b.writeCharCode(ch);
      dash = false;
    } else if (!dash && b.isNotEmpty) {
      b.write('-');
      dash = true;
    }
  }
  var out = b.toString();
  while (out.endsWith('-')) {
    out = out.substring(0, out.length - 1);
  }
  if (out.length > 40) {
    out = out.substring(0, 40);
    while (out.endsWith('-')) {
      out = out.substring(0, out.length - 1);
    }
    out = '$out-${slotHash(text)}';
  }
  if (out.isEmpty) out = 't${slotHash(text)}';
  return out;
}

/// The element half for a picture or clip: its file name without the
/// extension, slugged. Works for bundled paths and URLs alike.
String slotMediaId(String pathOrUrl) {
  var p = pathOrUrl;
  final q = p.indexOf('?');
  if (q >= 0) p = p.substring(0, q);
  final slash = p.lastIndexOf('/');
  if (slash >= 0) p = p.substring(slash + 1);
  final dot = p.lastIndexOf('.');
  if (dot > 0) p = p.substring(0, dot);
  return slotSlug(p);
}

/// Firestore document ids cannot contain '/'.
String slotDocId(String key) => key.replaceAll('/', '~');

/// The page a key belongs to in the All slots list: its first segment.
String slotGroup(String key) {
  final i = key.indexOf('.');
  return i < 0 ? key : key.substring(0, i);
}

/// `orb` is a thinking-orb loader (which animation, size, black circle).
/// Slots inside a section the owner added from the UI Editor
/// (`tpl.<page>.<entry>.<field>`, template_sections.dart). Their words live
/// in the section's own props — the one place they are edited — so a text
/// override on them is never drawn.
bool isTemplateSlot(String key) => key.startsWith('tpl.');

/// The template prop a template slot draws: (entry id, field), or null when
/// [key] is not a slot of a template on [pageId].
(String, String)? templateSlotField(String key, String pageId) {
  final prefix = 'tpl.$pageId.';
  if (!key.startsWith(prefix)) return null;
  final rest = key.substring(prefix.length).split('.');
  if (rest.length != 2 || rest[0].isEmpty || rest[1].isEmpty) return null;
  return (rest[0], rest[1]);
}

enum SlotType { image, video, text, orb }

SlotType? slotTypeFrom(String? s) {
  switch (s) {
    case 'image':
      return SlotType.image;
    case 'video':
      return SlotType.video;
    case 'text':
      return SlotType.text;
    case 'orb':
      return SlotType.orb;
  }
  return null;
}
