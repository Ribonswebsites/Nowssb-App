/// Black glass banner row — Notifications-level blur language.
///
/// Layout: title/sub on the left, thin vertical divider, then an SVG (or
/// child) icon inside a **white circle** on the **right**. Used by the
/// Sentence builder and anywhere a NowssB black/white glass action row
/// is needed. No emoji — SVG only.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nwsb_icon.dart';

/// Notifications-sheet blur (CSS blur(26px) → sigma ≈ 13).
const double kNotifGlassSigma = 13;

class BlackGlassBanner extends StatelessWidget {
  const BlackGlassBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.mark,
    this.markViewBox = 24,
    this.icon,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  final String title;
  final String? subtitle;
  final String? mark;
  final double markViewBox;
  final Widget? icon;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);
    final body = Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: kNotifGlassSigma,
            sigmaY: kNotifGlassSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xB8000000),
              borderRadius: r,
              border: Border.all(color: const Color(0x24FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x73000000),
                  blurRadius: 32,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Color(0x9EFFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0x33FFFFFF),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: icon ??
                        NwsbIcon(
                          mark ?? NwsbMarks.arrow,
                          size: 20,
                          viewBox: markViewBox,
                          color: const Color(0xFF0A0A12),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return body;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: r,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: body,
      ),
    );
  }
}

/// Frosted glass panel — Notifications sheet fill/blur/radius.
class NotifGlassPanel extends StatelessWidget {
  const NotifGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: kNotifGlassSigma,
            sigmaY: kNotifGlassSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: r,
              border: Border.all(color: const Color(0x24FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8C000000),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
