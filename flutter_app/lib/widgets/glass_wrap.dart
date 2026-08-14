/// The pane every Fashion-home section sits on.
///
/// Lifted value for value from `:is(#home, .stw-prev-stage) .glass-wrap` in
/// nowssb-nm.css:7904, including the second rule underneath it that squares
/// the corners — these wrappers are NOT rounded on the Fashion home, and the
/// Flutter version had them at a 20px radius, which is the single thing that
/// made the whole page read as a different app.
///
///     padding   12
///     fill      rgba(255,255,255,0.055)
///     border    1px rgba(255,255,255,0.13)
///     radius    0            ← border-radius: 0 !important
///     blur      blur(18px) saturate(1.25)
///     shadow    0 16px 40px rgba(0,0,0,0.34)
///     box       width: calc(100% - 32px); margin: 18px 16px
///
/// The blur is a real BackdropFilter. CSS blur(18px) is a Gaussian standard
/// deviation of about 9, not 18 — the CSS number is the diameter and
/// ImageFilter takes the sigma, so halving it is what makes the two match
/// rather than a guess.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GlassWrap extends StatelessWidget {
  const GlassWrap({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  /// CSS blur(18px) → sigma 9.
  static const double blurSigma = 9;

  static const fill = Color(0x0EFFFFFF); // rgba(255,255,255,0.055)
  static const line = Color(0x21FFFFFF); // rgba(255,255,255,0.13)

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x57000000), // rgba(0,0,0,0.34)
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        ),
        // ClipRect, not ClipRRect: square, and the clip is what stops the
        // backdrop filter bleeding past the pane.
        child: ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: line),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The head that introduces a section — `.qa-tv-head` and its siblings.
///
/// `display:flex; align-items:center; gap:14px; padding:0 2px 14px`, a round
/// white mark, then a light eyebrow over a heavy title. Every wrapped block
/// on this home opens with one.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.icon,
    this.mark,
  });

  final String eyebrow;
  final String title;

  /// A Material stand-in, used until [mark] can point at the real artwork.
  final IconData? icon;

  /// The section's own mark, when it is a bundled picture.
  final Widget? mark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: mark ??
                Icon(icon ?? Icons.circle_outlined,
                    size: 22, color: const Color(0xFF1A1A2E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xA6FFFFFF),
                    height: 1.35,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
