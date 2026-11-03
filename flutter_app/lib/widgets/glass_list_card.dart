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

/// One item, one card — the "NowssB Reference / Your links" look: its own
/// glass pane, white circle icon, small label over a big title, and a single
/// black pill row (subtitle · arrow). Menu and Settings use one per item so
/// nothing is stacked into a grouped list.
class GlassItemCard extends StatelessWidget {
  const GlassItemCard({
    super.key,
    required this.icon,
    required this.overline,
    required this.title,
    required this.pill,
    this.pillSub,
    this.pillIcon,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final IconData icon;
  final String overline;
  final String title;
  final String pill;
  final String? pillSub;
  final IconData? pillIcon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassListCard(
        margin: margin,
        icon: icon,
        overline: overline,
        title: title,
        children: [
          GlassTile(
            icon: pillIcon ?? icon,
            title: pill,
            sub: pillSub,
            onTap: onTap,
            trailing: trailing,
            danger: danger,
          ),
        ],
      ),
    );
  }
}

/// The glass search field at the top of Menu and Settings.
class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search settings and pages',
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xB30B0B10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x26FFFFFF)),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0B0B10)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const ValueKey('glass-search'),
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: const TextStyle(color: kGlassMuted, fontSize: 14),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (_, __) => controller.text.isEmpty
                  ? const SizedBox(width: 8)
                  : IconButton(
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close_rounded, color: kGlassMuted, size: 18),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A darker veil laid over the purple film behind Menu and Settings so the
/// video sits quietly under the cards.
class QuietFilmVeil extends StatelessWidget {
  const QuietFilmVeil({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xC7060C18), Color(0xB3060C18), Color(0xD9060C18)],
          ),
        ),
      ),
    );
  }
}
