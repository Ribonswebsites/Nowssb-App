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
    this.artFit = BoxFit.contain,
  });

  final VoidCallback? onTap;
  final bool compact;
  final bool bare;
  final String title;
  final String? mark;
  final String art;
  final Alignment artAlignment;
  final BoxFit artFit;

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
          // B040: the text column widens (art narrows) before the title
          // font shrinks, so the longest word fits at a readable size.
          child: LayoutBuilder(builder: (context, row) {
            final textW = brandTitleColumnWidth(
                title, row.maxWidth, MediaQuery.textScalerOf(context));
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: row.maxWidth - textW,
                  child: EditableImage.asset(
                    art,
                    height: h,
                    fit: artFit,
                    alignment: artAlignment,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF120818),
                    ),
                    slot: 'brand_top_banner.BrandTopBanner',
                  ),
                ),
                SizedBox(
                  width: textW,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (mark != null) ...[
                          // Mark gives way when the 3-line title grows.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: NwsbIcon(mark!,
                                    size: 20, color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        // B040: shrink the title so its longest word fits the
                        // column; lines then break only between words.
                        LayoutBuilder(
                          builder: (c, box) {
                            const base = TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            );
                            final size = brandTitleFitSize(title, base,
                                box.maxWidth, MediaQuery.textScalerOf(c));
                            return EditableLabel(
                              'brand_top_banner.BrandTopBanner',
                              title,
                              maxLines: 3,
                              style: base.copyWith(fontSize: size),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
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

/// Text column width: 5/11 of the banner, widened up to 70% so the title's
/// longest word fits at its full size (plus the column's 22px padding).
double brandTitleColumnWidth(String title, double rowW, TextScaler scaler) {
  if (!rowW.isFinite) return 160;
  final base = rowW * 5 / 11;
  final need = brandTitleWordWidth(title, _titleStyle, scaler) + 22;
  return need.clamp(base, rowW * .7).toDouble();
}

const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.05);

double brandTitleWordWidth(String title, TextStyle style, TextScaler scaler) {
  var widest = 0.0;
  for (final w in title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    final tp = TextPainter(
        text: TextSpan(text: w, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler)
      ..layout();
    if (tp.width > widest) widest = tp.width;
  }
  return widest;
}

/// Largest font size (<= style's) at which [title]'s longest word fits [maxW].
double brandTitleFitSize(
    String title, TextStyle style, double maxW, TextScaler scaler) {
  final base = style.fontSize ?? 14;
  if (!maxW.isFinite || maxW <= 0) return base;
  var widest = 0.0;
  for (final w in title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    final tp = TextPainter(
        text: TextSpan(text: w, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler)
      ..layout();
    if (tp.width > widest) widest = tp.width;
  }
  if (widest <= maxW) return base;
  return (base * maxW / widest).floorToDouble().clamp(8.0, base);
}
