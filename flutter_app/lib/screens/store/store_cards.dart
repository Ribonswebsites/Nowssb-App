/// Shared Store card widgets — mirror website `.rm-word-card`, `.ms-card`,
/// `.rm-cat-banner`, ebook rows, and gold Signature tags.
library;

import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';

String inr(num value) {
  if (value <= 0) return 'Included';
  final n = value is int ? value : value.round();
  return '₹$n';
}

/// Clean NowssB bag + headphones product shot — NEVER fashion heels /
/// meditation collection posters. Used in every notification pill.
const kStoreProductArt = 'assets/store/nowssb-bag-headphones.webp';

/// Pill / banner product art for a collection/word. Always the store bag
/// product (collection posters contain fashion BS the user rejected).
String storePillProductArt(String? id) => kStoreProductArt;

/// Legacy collection poster map — only for non-pill decorative rails that
/// still need a keyed asset. Prefer [storePillProductArt] for pills.
String storeCollectionArt(String? id) {
  // Pills and banners must never show fashion heels / meditation stock.
  return storePillProductArt(id);
}

Color storeCardTint(String seed) {
  const palette = <Color>[
    Color(0xFF1A1428),
    Color(0xFF0F1F2E),
    Color(0xFF1A2214),
    Color(0xFF2A1520),
    Color(0xFF142028),
    Color(0xFF221A14),
    Color(0xFF1A1828),
    Color(0xFF14241C),
    Color(0xFF281418),
    Color(0xFF182028),
  ];
  var h = 0;
  for (final c in seed.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}


class StoreNetImage extends StatelessWidget {
  const StoreNetImage({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const ColoredBox(color: Color(0xFF0A0F1C));
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF0A0F1C)),
      errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF0A0F1C)),
    );
  }
}

/// Notification-style category banner — Fashion [GlassWrap] tokens, heading
/// above taller black pill: SVG circle → separator → bag-headphones product
/// art with ripple (no fashion heels / meditation stock).
class RmCatBanner extends StatelessWidget {
  const RmCatBanner({
    super.key,
    required this.title,
    required this.sub,
    this.badge,
    this.labelColor,
    this.logoAsset = 'assets/icons/collection-icon.webp',
    this.logoUrl,
    this.artAsset,
    this.categoryId,
    this.svgBody,
  });

  final String title;
  final String sub;
  final String? badge;
  final Color? labelColor;

  /// Bundled collection disc (legacy; SVG preferred).
  final String logoAsset;

  /// Optional remote logo (Meaning Store MS_CAT_LOGO).
  final String? logoUrl;

  /// Real store product image shown inside the black pill.
  final String? artAsset;

  /// Used to resolve [artAsset] when not provided.
  final String? categoryId;

  /// NowssB SVG path body for the circular mark (defaults to bag).
  final String? svgBody;

  @override
  Widget build(BuildContext context) {
    final titleColor = labelColor ?? NwsbColors.goldLight;
    final art = artAsset ?? storePillProductArt(categoryId);
    final mark = svgBody ?? NwsbMarks.bag;
    final r = BorderRadius.circular(kGlassRadius);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: const [
            BoxShadow(
              color: Color(0x57000000),
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassWrap.blurSigma,
              sigmaY: GlassWrap.blurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: r,
                color: GlassWrap.fill,
                border: Border.all(color: GlassWrap.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: titleColor.withValues(alpha: 0.45)),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 11, color: Color(0x88FFFFFF)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x18E8D5A3),
                            border: Border.all(color: titleColor.withValues(alpha: 0.45)),
                          ),
                          alignment: Alignment.center,
                          child: NwsbIcon(mark, size: 20, color: titleColor),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: const Color(0x33FFFFFF),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: StorePillRippleArt(
                              asset: art,
                              height: 52,
                              radius: 18,
                              fallbackLogoUrl: logoUrl,
                              fallbackLogoAsset: logoAsset,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft expanding ripple over the store product image inside black pills.
class StorePillRippleArt extends StatefulWidget {
  const StorePillRippleArt({
    super.key,
    required this.asset,
    this.height = 48,
    this.radius = 16,
    this.fallbackLogoUrl,
    this.fallbackLogoAsset,
    this.accent = const Color(0x66E8D5A3),
  });

  final String asset;
  final double height;
  final double radius;
  final String? fallbackLogoUrl;
  final String? fallbackLogoAsset;
  final Color accent;

  @override
  State<StorePillRippleArt> createState() => _StorePillRippleArtState();
}

class _StorePillRippleArtState extends State<StorePillRippleArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                if (widget.fallbackLogoUrl != null) {
                  return Image.network(
                    widget.fallbackLogoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      widget.fallbackLogoAsset ?? kStoreProductArt,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return Image.asset(
                  widget.fallbackLogoAsset ?? kStoreProductArt,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF0A0F1C)),
                );
              },
            ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                return CustomPaint(
                  painter: _PillRipplePainter(
                    progress: _c.value,
                    color: widget.accent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PillRipplePainter extends CustomPainter {
  _PillRipplePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.72, size.height * 0.5);
    final maxR = size.width * 0.55;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final r = maxR * t;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: (1 - t) * 0.55);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PillRipplePainter old) =>
      old.progress != progress || old.color != color;
}

/// Full-width looping row break video (part010 ROW_VIDS).
class RmRowVid extends StatelessWidget {
  const RmRowVid({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: NwsbVideo(asset: url, priority: ClipPriority.decoration),
        ),
      ),
    );
  }
}

/// Horizontally scrolling `.rm-word-card` row.
class RmWordRow extends StatelessWidget {
  const RmWordRow({super.key, required this.children});
  final List<Widget> children;

  /// Horizontal thicker cards — fixed height avoids yellow overflow stripes.
  static const double rowHeight = RmWordCard.cardHeight + 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4, bottom: 2),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class RmWordCard extends StatelessWidget {
  const RmWordCard({
    super.key,
    required this.name,
    required this.root,
    required this.imgUrl,
    this.signature = false,
    this.price,
    this.onTap,
    this.onBuyNow,
    this.onWishlist,
    this.onAddCart,
    this.tint,
  });

  final String name;
  final String root;
  final String imgUrl;
  final bool signature;
  final num? price;
  final VoidCallback? onTap;
  final VoidCallback? onBuyNow;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddCart;
  final Color? tint;

  /// Thicker horizontal card: image left, text + actions right.
  static const double cardHeight = 152;
  static const double cardWidth = 310;

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = tint ?? storeCardTint(name);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: signature ? const Color(0x55E8D5A3) : const Color(0x2EFFFFFF),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              SizedBox(
                width: 118,
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: StoreNetImage(url: imgUrl),
                    ),
                    if (signature)
                      const Positioned(
                        top: 6,
                        left: 6,
                        child: _SignatureTag(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      root.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        height: 1.1,
                        color: Color(0x8CC8E8F5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price == null ? '—' : inr(price!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (onBuyNow != null) {
                                onBuyNow!();
                              } else if (onTap != null) {
                                onTap!();
                              } else {
                                _toast(context, 'Opening $name…');
                              }
                            },
                            child: Container(
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)],
                                ),
                              ),
                              child: const Text(
                                'Buy Now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Color(0xFF060C18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _CardAction(
                          icon: Icons.favorite_border,
                          onTap: () {
                            if (onWishlist != null) {
                              onWishlist!();
                            } else {
                              _toast(context, 'Saved $name to wishlist');
                            }
                          },
                        ),
                        const SizedBox(width: 5),
                        _CardAction(
                          icon: Icons.shopping_bag_outlined,
                          accent: true,
                          onTap: () {
                            if (onAddCart != null) {
                              onAddCart!();
                            } else {
                              _toast(context, 'Added $name to cart');
                            }
                          },
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
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.onTap, this.accent = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0x22FFFFFF),
          border: Border.all(
            color: accent ? const Color(0x55E8D5A3) : const Color(0x33FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: accent ? NwsbColors.goldLight : const Color(0xCCFFFFFF),
        ),
      ),
    );
  }
}

class _SignatureTag extends StatelessWidget {
  const _SignatureTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)]),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Signature',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFF060C18),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xD1060C18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

/// Meaning Store `.ms-card` tile (3-column grid).
class MsCard extends StatelessWidget {
  const MsCard({
    super.key,
    required this.word,
    required this.root,
    required this.imgUrl,
    required this.price,
    this.signature = false,
    this.onTap,
  });

  final String word;
  final String root;
  final String imgUrl;
  final num price;
  final bool signature;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: signature ? const Color(0x55E8D5A3) : const Color(0x12FFFFFF),
            ),
            color: const Color(0x08FFFFFF),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.42,
                child: StoreNetImage(url: imgUrl),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0060C18), Color(0x00060C18)],
                    stops: [0, 0.65],
                  ),
                ),
              ),
              if (signature)
                const Positioned(top: 6, left: 6, child: _SignatureTag()),
              Positioned(
                top: 6,
                right: 6,
                child: Column(
                  children: [
                    _MiniChip(icon: Icons.favorite_border, color: const Color(0xB3FFFFFF)),
                    const SizedBox(height: 5),
                    _MiniChip(icon: Icons.shopping_bag_outlined, color: NwsbColors.goldLight),
                  ],
                ),
              ),
              Positioned(
                left: 7,
                right: 7,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xE6FFFFFF),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      root,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8, color: Color(0x61C8E8F5)),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x14E8D5A3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x2EE8D5A3)),
                      ),
                      child: Text(
                        inr(price),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xBFE8D5A3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MsGrid extends StatelessWidget {
  const MsGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 3 / 4,
      children: children,
    );
  }
}

/// Filter / category chip matching store chip style.
class StoreFilterChip extends StatelessWidget {
  const StoreFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0x28C8E8F5) : const Color(0x14FFFFFF),
          border: Border.all(
            color: selected ? const Color(0x55C8E8F5) : const Color(0x26FFFFFF),
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}

class StoreSearchBar extends StatelessWidget {
  const StoreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Type any word, name, country…',
    this.onGo,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final VoidCallback? onGo;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        border: Border.all(color: const Color(0x38FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: Color(0x80FFFFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w300),
              cursorColor: NwsbColors.goldLight,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0x52FFFFFF), fontSize: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close, size: 17, color: Color(0x99FFFFFF)),
            ),
          GestureDetector(
            onTap: onGo,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0x26C8E8F5),
                border: Border(left: BorderSide(color: Color(0x4DC8E8F5))),
              ),
              child: const Text(
                'GO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Color(0xFFC8E8F5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreDisclaimer extends StatelessWidget {
  const StoreDisclaimer({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disclaimer & Confidentiality',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NwsbColors.gold),
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 11, height: 1.55, color: Color(0x73FFFFFF))),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'NowssB\n© 2026 Adv. Sanjaykumar Gadge · Shabdapathy',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, height: 1.6, color: Color(0x73FFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}