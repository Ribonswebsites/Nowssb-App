import 'package:flutter/material.dart';

/// Black home / menu banner: logo and NowssB on the left, portrait on the right.
class BrandTopBanner extends StatelessWidget {
  const BrandTopBanner({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 78.0 : 96.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 8),
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
                ClipOval(
                  child: Image.asset(
                    'assets/icons/logo-disc.webp',
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: compact ? 40 : 48,
                      height: compact ? 40 : 48,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'NowssB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: h,
                  height: h,
                  child: Image.asset(
                    'assets/banners/brand-cleo.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF120818),
                    ),
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
