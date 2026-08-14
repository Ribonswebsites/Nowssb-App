/// The app's own marks.
///
/// Every icon in index.html is a DRAWN SVG path, not a picture — the comment
/// at :768 says why it matters: the three header marks used to be CDN
/// photographs, "three requests before the header could finish, each one a
/// picture of a shape that takes four lines to draw, and none of them able to
/// take the colour of whatever they sit on."
///
/// Up to now this app substituted a Material glyph that looked roughly right
/// for each one. Roughly right is not right: Material's bell, house and
/// hamburger are different shapes from these, and the difference is the first
/// thing you see holding the two side by side.
///
/// So the paths are pasted in verbatim, each with the file and line it came
/// from. Nothing here is drawn by eye. A mark that changes on the web is a
/// copy-paste to change here.
///
/// All of them are stroked, never filled: `fill="none" stroke="currentColor"`
/// with round caps and joins, on a 24x24 box. [NwsbIcon] rebuilds exactly
/// that wrapper so only the path data has to be carried.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// One drawn mark, on the standard 24x24 box.
class NwsbIcon extends StatelessWidget {
  const NwsbIcon(
    this.body, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.strokeWidth = 1.7,
  });

  /// The `<path>`/`<circle>` elements, exactly as they appear in the source.
  final String body;

  final double size;
  final Color color;

  /// `stroke-width`. 1.7 is the app's usual; the header's menu is 1.9 and
  /// the greeting orb's marks are 1.7.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">$body</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// The marks themselves. Grouped by where they live, and every one carries
/// the file and line it was copied from.
class NwsbMarks {
  NwsbMarks._();

  // ── The fixed header — index.html:776-796 ────────────────────────────

  static const bell =
      '<path d="M12 3.2a5.8 5.8 0 0 0-5.8 5.8c0 5-2.1 6.6-2.1 6.6h15.8s-2.1-1.6-2.1-6.6A5.8 5.8 0 0 0 12 3.2z"/>'
      '<path d="M10.1 19a2.1 2.1 0 0 0 3.8 0"/>';

  /// The way back to the Normal home. A house, not a "home" glyph.
  static const house = '<path d="M3.4 10.6 12 3.6l8.6 7"/>'
      '<path d="M5.6 9.4V20h12.8V9.4"/>'
      '<path d="M9.8 20v-5.4h4.4V20"/>';

  /// Three rules, and the third is SHORT — which Material's hamburger is
  /// not. Drawn at 1.9 rather than 1.7.
  static const menu = '<path d="M4 7h16M4 12h16M4 17h10"/>';

  // ── The greeting orb — app/js/part083.js:177-186 ─────────────────────
  // "The disc's mark reads the clock: the sun climbing, the sun high, the
  // sun setting, the moon."

  static const sun = '<circle cx="12" cy="12" r="4.4"/>'
      '<path d="M12 2.6v2.4M12 19v2.4M21.4 12H19M5 12H2.6M18.6 5.4 17 7'
      'M7 17l-1.6 1.6M18.6 18.6 17 17M7 7 5.4 5.4"/>';

  static const dawn = '<path d="M3.4 18.4h17.2"/>'
      '<circle cx="12" cy="13.6" r="4"/>'
      '<path d="M12 4.6v2.2M19.2 7.6l-1.6 1.6M4.8 7.6l1.6 1.6"/>';

  static const moon =
      '<path d="M20.4 14.6A8.6 8.6 0 0 1 9.4 3.6a8.6 8.6 0 1 0 11 11z"/>';

  /// timeMark() — :184. Which of the three, by the hour.
  static String forHour(int h) =>
      (h < 5 || h >= 21) ? moon : (h < 9 ? dawn : (h < 17 ? sun : dawn));

  // ── The hero rail — app/js/part083.js:50-66 ──────────────────────────

  static const crown = '<path d="M4 8.4l3.6 3.2L12 5.4l4.4 6.2L20 8.4l-1.6 9.2H5.6z"/>'
      '<path d="M5.6 19.6h12.8"/>';

  /// The bag both stores wear. "The same shop, two things sold in it" — the
  /// Word Store's carries a sound wave, the Meaning Store's a line of text.
  static const _bag =
      '<path d="M4.4 7.6h15.2l-1.1 12.2a1.5 1.5 0 0 1-1.5 1.4H7a1.5 1.5 0 0 1-1.5-1.4z"/>'
      '<path d="M8.7 10V6.6a3.3 3.3 0 0 1 6.6 0V10"/>';

  /// The plain bag — `.hs-shop` at :447, and the store sections.
  static const bag = _bag;

  static const word =
      '$_bag<path d="M8.4 15.6v1.6M10.8 13.8v5.2M13.2 12.8v6.2M15.6 15.2v2.4"/>';

  static const meaning = '$_bag<path d="M8.6 14.4h6.8M8.6 17.4h4.4"/>';

  static const book =
      '<path d="M4 5.4h6.4a2 2 0 0 1 2 2v11.2a2.4 2.4 0 0 0-2-1H4z"/>'
      '<path d="M20 5.4h-6.4a2 2 0 0 0-2 2v11.2a2.4 2.4 0 0 1 2-1H20z"/>';

  static const sound = '<path d="M11.4 4.6 6.8 8.6H3.6v6.8h3.2l4.6 4V4.6z"/>'
      '<path d="M15.6 8.8a4.6 4.6 0 0 1 0 6.4M18.4 6a8.6 8.6 0 0 1 0 12"/>';

  static const signature =
      '<path d="M3.6 16.6c3-.4 5-2.2 6.6-5.4 1.2-2.4 2-4.6 3.2-4.6 1 0 1.4 1 1 2.4'
      '-.5 1.8-2 3-3.4 3.6-1.4.6-2 1.4-1.6 2.2.4.8 1.8.9 3.2.4 1.6-.6 2.8-1.6 4-3"/>'
      '<path d="M4 20h16"/>';

  /// The arrow every black bar closes with — `VB_ARROW` and the `.ncb-btn`
  /// mark, drawn at 1.7.
  static const arrow = '<path d="M5 12h14M12 5l7 7-7 7"/>';
}
