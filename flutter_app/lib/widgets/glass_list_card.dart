/// The Menu / Settings card: a dark translucent glass card with a subtle
/// border, a white circular badge, a small muted overline over a large white
/// title, then black rounded tile rows (circle icon · divider · title, muted
/// subtitle · arrow). Every Menu and Settings screen is built from it.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../admin/template/editable.dart';

const kGlassMuted = Color(0x8CFFFFFF);
const kGlassTile = Color(0xF2050507);

class GlassListCard extends StatelessWidget {
  const GlassListCard({
    super.key,
    required this.icon,
    required this.overline,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.margin = const EdgeInsets.only(bottom: 16),
    this.trailing,
  });

  final IconData icon;
  final String overline;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsets margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0x8C14141C),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, size: 22, color: const Color(0xFF0B0B10)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(overline.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kGlassMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                      const SizedBox(height: 2),
                      EditableLabel('glass_list_card.GlassListCard', title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kGlassMuted, fontSize: 12, height: 1.3)),
                      ],
                    ]),
                  ),
                  if (trailing != null) trailing!,
                ]),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    children[i],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One black row inside a [GlassListCard].
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback? onTap;

  /// Replaces the arrow (a switch, a value pill).
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ink = danger ? const Color(0xFFF87171) : Colors.white;
    return Material(
      color: kGlassTile,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
              child: Icon(icon, size: 18, color: ink),
            ),
            Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0x26FFFFFF)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                EditableLabel('glass_list_card.GlassTile', title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w700)),
                if (sub != null && sub!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kGlassMuted, fontSize: 12, height: 1.25)),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            trailing ?? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: danger ? const Color(0x99F87171) : kGlassMuted),
          ]),
        ),
      ),
    );
  }
}
