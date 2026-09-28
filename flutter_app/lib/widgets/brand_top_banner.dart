import 'package:flutter/material.dart';

import 'nwsb_icon.dart';
import '../admin/template/editable.dart';

/// Black home / menu banner: logo and NowssB on the left, portrait on the right.
class BrandTopBanner extends StatelessWidget {
  const BrandTopBanner({
    super.key,
    this.onTap,
    this.compact = false,
    this.bare = false,
    this.title = 'NowssB',
    this.mark,
    this.art = 'assets/banners/brand-cleo.png',
    this.artAlignment = Alignment.topCenter,
  });

  final VoidCallback? onTap;
  final bool compact;

  /// No outer page inset — for use inside a glass card or a sheet.
  final bool bare;
  final String title;

  /// When set, a white circle with this SVG replaces the disc logo.
  final String? mark;

  /// Portrait cropped on the right of the black banner.
  final String art;
  final Alignment artAlignment;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 78.0 : 96.0;
    final disc = compact ? 40.0 : 48.0;
    return Padding(
      padding: bare
          ? EdgeInsets.zero
          : EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 8),
      child: Material(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: h,
            child: Row(
              children: [
                const SizedBox(width: 14),
                if (mark != null)
                  Container(
                    width: disc,
                    height: disc,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: NwsbIcon(mark!, size: disc * 0.46, color: Colors.black),
                  )
                else
                  ClipOval(
                    child: EditableImage.asset(
                      'assets/icons/logo-disc.webp',
                      width: disc,
                      height: disc,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SizedBox(width: disc, height: disc),
                      slot: 'brand_top_banner.BrandTopBanner',
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: EditableLabel('brand_top_banner.BrandTopBanner',
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: h,
                  height: h,
                  child: EditableImage.asset(
                    art,
                    fit: BoxFit.cover,
                    alignment: artAlignment,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF120818),
                    ),
                    slot: 'brand_top_banner.BrandTopBanner',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
