/// The glass course face: avatar, two tabs, one feature card, chips, one row.
/// No clock, wifi, or battery.
library;

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CourseChip {
  const CourseChip(this.label, this.count);
  final String label;
  final int count;
}

class CourseFace extends StatelessWidget {
  const CourseFace({
    super.key,
    required this.avatar,
    required this.onAvatar,
    required this.segments,
    required this.segment,
    required this.onSegment,
    required this.image,
    required this.title,
    required this.meta,
    required this.foot,
    required this.indexLabel,
    required this.onContinue,
    this.chips = const [],
    this.chip = 0,
    this.onChip,
    this.rowTitle,
    this.rowMeta,
    this.rowImage,
    this.onRow,
    this.onRowImage,
    this.onImage,
    this.onBell,
    this.extra,
    this.instead,
    this.rowCircle = false,
  });

  final Widget avatar;
  final VoidCallback onAvatar;
  final List<String> segments;
  final int segment;
  final ValueChanged<int> onSegment;
  final String image;
  final String title;
  final String meta;
  final String foot;
  final String indexLabel;
  final VoidCallback onContinue;
  final List<CourseChip> chips;
  final int chip;
  final ValueChanged<int>? onChip;
  final String? rowTitle;
  final String? rowMeta;
  final String? rowImage;
  final VoidCallback? onRow;
  final VoidCallback? onRowImage;
  final VoidCallback? onImage;
  final VoidCallback? onBell;
  final Widget? extra;
  final Widget? instead;
  final bool rowCircle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(onTap: onAvatar, child: avatar),
            const Spacer(),
            if (onBell != null)
              GestureDetector(
                onTap: onBell,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x22FFFFFF),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        // The segment pill keeps its size and only scales down when large
        // text on a narrow screen makes it wider than the card (B015).
        Center(
          child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x33110A18),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < segments.length; i++)
                  GestureDetector(
                    onTap: () => onSegment(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: i == segment ? const Color(0xCC2A2038) : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        segments[i],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: i == segment ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),
        if (instead != null)
          instead!
        else ...[
        GestureDetector(
          onTap: onImage ?? onContinue,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _pic(image),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x00000000), Color(0xCC7A2EA8)],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text('Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.05)),
                        const SizedBox(height: 8),
                        Text(meta, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Both sides give way at large text instead of
                            // overflowing the picture (B015).
                            Expanded(child: Text(indexLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCFFFFFF)))),
                            const SizedBox(width: 8),
                            Flexible(
                              child: GestureDetector(
                              onTap: onContinue,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: Text(foot, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++)
                  GestureDetector(
                    onTap: () => onChip?.call(i),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: chips[i].label, style: TextStyle(color: i == chip ? Colors.white : const Color(0x99FFFFFF), fontWeight: FontWeight.w700, fontSize: 15)),
                            TextSpan(text: '  ${chips[i].count}', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
                          ])),
                          const SizedBox(height: 6),
                          Container(height: 2, width: 28, color: i == chip ? Colors.white : Colors.transparent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (rowTitle != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRow,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xF0101016), borderRadius: BorderRadius.circular(26)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onRowImage,
                    child: rowCircle
                        ? ClipOval(child: SizedBox(width: 88, height: 88, child: _pic(rowImage ?? image)))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(width: 108, height: 108, child: _pic(rowImage ?? image)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rowTitle!, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.05)),
                        const SizedBox(height: 8),
                        Text(rowMeta ?? '', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Color(0xFF2A2A32), shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (extra != null) ...[
          const SizedBox(height: 14),
          extra!,
        ],
        ],
      ],
    );
  }

  Widget _pic(String src) {
    if (src.startsWith('http')) {
      return CachedNetworkImage(imageUrl: src, fit: BoxFit.cover, errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF2A1038)));
    }
    if (src.startsWith('file:')) {
      return Image.file(File(src.substring(5)), fit: BoxFit.cover);
    }
    return Image.asset(src, fit: BoxFit.cover);
  }
}
