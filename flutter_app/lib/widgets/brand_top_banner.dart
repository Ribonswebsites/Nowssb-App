import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'nwsb_icon.dart';
import '../admin/template/editable.dart';

/// Black banner in a glass wrapper. The portrait is on the left, large,
/// and sat on the bottom so the face is not cropped off the top.
class BrandTopBanner extends StatelessWidget {
  const BrandTopBanner({
    super.key,
    this.onTap,
    this.compact = false,
    this.bare = false,
    this.title = 'NowssB',
    this.mark,
    this.art = 'assets/banners/brand-cleo.png',
    this.artAlignment = Alignment.bottomLeft,
  });

  final VoidCallback? onTap;
  final bool compact;
  final bool bare;
  final String title;
  final String? mark;
  final String art;
  final Alignment artAlignment;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 156.0 : 210.0;
    final banner = Material(
      color: const Color(0xFF000000),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 6,
                child: EditableImage.asset(
                  art,
                  height: h,
                  fit: BoxFit.contain,
                  alignment: artAlignment,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF120818),
                  ),
                  slot: 'brand_top_banner.BrandTopBanner',
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (mark != null) ...[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: NwsbIcon(mark!, size: 20, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                      ],
                      EditableLabel(
                        'brand_top_banner.BrandTopBanner',
                        title,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final glass = GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      radius: 22,
      child: banner,
    );
    if (bare) return glass;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 8),
      child: glass,
    );
  }
}
