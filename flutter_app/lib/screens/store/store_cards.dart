/// Shared Store card widgets — mirror website `.rm-word-card`, `.ms-card`,
/// `.rm-cat-banner`, ebook rows, and gold Signature tags.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/cart_bag.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import 'store_actions.dart';

String inr(num value) {
  if (value <= 0) return 'Included';
  final n = value is int ? value : value.round();
  return '₹$n';
}

/// Full word price in rupees. 50% off is [kWordSaleInr].
const kWordPriceInr = 92;
const kWordSaleInr = 46;

String localizedMoney(BuildContext context, num inrValue) {
  if (inrValue <= 0) return 'Included';
  final locale = Localizations.localeOf(context);
  final country = (locale.countryCode ?? '').toUpperCase();
  final language = locale.languageCode.toLowerCase();
  var symbol = '₹';
  var rate = 1.0;
  var decimals = 0;
  const euroCountries = {
    'AT',
    'BE',
    'CY',
    'DE',
    'EE',
    'ES',
    'EU',
    'FI',
    'FR',
    'GR',
    'IE',
    'IT',
    'LT',
    'LU',
    'LV',
    'MT',
    'NL',
    'PT',
    'SI',
    'SK',
  };
  const euroLang = {
    'de',
    'el',
    'es',
    'et',
    'fi',
    'fr',
    'it',
    'lt',
    'lv',
    'nl',
    'pt',
    'sk',
    'sl',
  };
  if (country == 'IN' || language == 'hi') {
    symbol = '₹';
    rate = 1.0;
    decimals = 0;
  } else if (country == 'US' || (country.isEmpty && language == 'en')) {
    symbol = r'$';
    rate = 0.012;
    decimals = 2;
  } else if (country == 'GB') {
    symbol = '£';
    rate = 0.0095;
    decimals = 2;
  } else if (euroCountries.contains(country) || euroLang.contains(language)) {
    symbol = '€';
    rate = 0.011;
    decimals = 2;
  } else if (country == 'AE') {
    symbol = 'د.إ';
    rate = 0.044;
    decimals = 2;
  } else if (country == 'SG') {
    symbol = r'S$';
    rate = 0.016;
    decimals = 2;
  } else if (country == 'AU') {
    symbol = r'A$';
    rate = 0.018;
    decimals = 2;
  } else if (country == 'CA') {
    symbol = r'C$';
    rate = 0.0165;
    decimals = 2;
  } else if (country == 'JP') {
    symbol = '¥';
    rate = 1.75;
    decimals = 0;
  } else {
    symbol = '₹';
    rate = 1.0;
    decimals = 0;
  }
  final converted = inrValue * rate;
  if (decimals == 0) return '$symbol${converted.round()}';
  return '$symbol${converted.toStringAsFixed(2)}';
}

String saleOriginalMoney(BuildContext context, num salePrice) =>
    localizedMoney(context, kWordPriceInr);

/// Clean NowssB bag + headphones product shot — NEVER fashion heels /
/// meditation collection posters. Used in every notification pill.
const kStoreProductArt = 'assets/store/nowssb-bag-headphones.webp';

/// Meaning Store arts — attached Meanings device only (never word bag).
/// Swirl ([kMsMeaningStoreIcon]) is reserved for store hub / picker / icon tile.
const kMsMeaningStoreIcon = 'assets/meanings/meanings-store-swirl.png';
const kMsMeaningIconAsset = 'assets/meanings/meanings-clean.jpg';
const kMsMeaningProductArt = 'assets/meanings/meanings-branding.jpg';
/// Clean Meanings device (solid black). When shown on dark UI / as circle or
/// split-banner centre, pair with a solid COLOURED back (not flat black).
const kMsMeaningIntroArt = 'assets/meanings/meanings-device.png';

/// Ebooks Store product art — attached E-books arts only (never word bag).
const kEbProductArt = 'assets/ebooks/ebooks-headphones.jpg';
const kEbIntroArt = 'assets/ebooks/ebooks-pair.png';

String wordVibrationTag(String name) {
  switch (name.toLowerCase()) {
    case 'fire':
      return 'Ignites clarity and transformation';
    case 'earth':
      return 'Grounds presence and steady growth';
    case 'water':
      return 'Restores flow, feeling, and release';
    case 'air':
      return 'Opens movement, breath, and insight';
    default:
      return 'A sound signature for focused practice';
  }
}

/// Pill / banner product art for a collection/word. Always the store bag
/// product (collection posters contain fashion BS the user rejected).
String storePillProductArt(String? id) => kStoreProductArt;

/// Meaning Store pill/banner art — gold Meanings emblem / picker only.
String storeMeaningPillArt(String? id) => kMsMeaningProductArt;

/// Ebooks Store pill/banner art — ebook picker only.
String storeEbookPillArt(String? id) => kEbProductArt;

/// Legacy collection poster map — only for non-pill decorative rails that
/// still need a keyed asset. Prefer [storePillProductArt] for pills.
String storeCollectionArt(String? id) {
  // Pills and banners must never show fashion heels / meditation stock.
  return storePillProductArt(id);
}

Color storeCardTint(String seed) {
  // Visually distinct per-word tints (Fire ≠ Earth ≠ Water ≠ Air…).
  const palette = <Color>[
    Color(0xFF5A1E12), // fire / ember
    Color(0xFF1B3D24), // earth / forest
    Color(0xFF123A5C), // water / deep sea
    Color(0xFF3A2A08), // air / amber dusk
    Color(0xFF3D1450), // violet cosmos
    Color(0xFF0E3D3A), // teal healing
    Color(0xFF5A1230), // rose / passion
    Color(0xFF2A3D0E), // olive / nature
    Color(0xFF14285A), // indigo night
    Color(0xFF4A2E0E), // bronze / warrior
    Color(0xFF0E2A40), // steel blue
    Color(0xFF4A1840), // magenta dusk
  ];
  final key = seed.trim().toLowerCase();
  // Named element words get locked hues so Fire vs Earth never collide.
  const named = <String, Color>{
    'fire': Color(0xFF5A1E12),
    'earth': Color(0xFF1B3D24),
    'water': Color(0xFF123A5C),
    'air': Color(0xFF3A2A08),
    'aether': Color(0xFF3D1450),
    'peace': Color(0xFF0E3D3A),
    'warrior': Color(0xFF4A2E0E),
    'sacred': Color(0xFF3D1450),
    'divine': Color(0xFF14285A),
    'mythical': Color(0xFF4A1840),
  };
  for (final e in named.entries) {
    if (key == e.key || key.contains(e.key)) return e.value;
  }
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
/// above taller black pill: LEFT text label | separator | RIGHT one small
/// circular store bag/word image with ripple (never a wide stretched strip).
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
    this.onViewAll,
    this.pillLabel,
    this.inRail = false,
  });

  final String title;
  final String sub;
  final String? badge;
  final Color? labelColor;

  /// Bundled collection disc (legacy; SVG preferred).
  final String logoAsset;

  /// Optional remote logo (Meaning Store MS_CAT_LOGO).
  final String? logoUrl;

  /// Real store product image shown inside the black pill circle.
  final String? artAsset;

  /// Used to resolve [artAsset] when not provided.
  final String? categoryId;

  /// NowssB SVG path body for optional circle chrome (defaults to bag).
  final String? svgBody;

  /// Opens blur + 3D View-all carousel when set.
  final VoidCallback? onViewAll;

  /// Short label inside the black pill (defaults to badge or title).
  final String? pillLabel;

  /// When true the banner sits in the top horizontal rail (no extra margin).
  final bool inRail;

  @override
  Widget build(BuildContext context) {
    final titleColor = labelColor ?? NwsbColors.goldLight;
    final art = artAsset ?? storePillProductArt(categoryId);
    final mark = svgBody ?? NwsbMarks.bag;
    final leftLabel = (pillLabel ?? badge ?? title).trim();
    final r = BorderRadius.circular(kGlassRadius);
    return Padding(
      padding: EdgeInsets.only(top: inRail ? 0 : 18, bottom: inRail ? 0 : 10),
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
                      Expanded(
                        child: Row(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: titleColor.withValues(alpha: 0.45),
                                  ),
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
                      ),
                      if (onViewAll != null) ...[
                        const SizedBox(width: 8),
                        StoreViewAllControl(onTap: onViewAll!),
                      ],
                    ],
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0x88FFFFFF),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  StoreBlackPill(
                    label: leftLabel.isEmpty ? title : leftLabel,
                    artAsset: art,
                    accent: titleColor,
                    svgBody: mark,
                    fallbackLogoUrl: logoUrl,
                    fallbackLogoAsset: logoAsset,
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

/// Taller black pill: LEFT text | vertical sep | RIGHT one small circular
/// store image with ripple animation on that circle.
class StoreBlackPill extends StatelessWidget {
  const StoreBlackPill({
    super.key,
    required this.label,
    required this.artAsset,
    required this.accent,
    this.svgBody,
    this.fallbackLogoUrl,
    this.fallbackLogoAsset,
    this.height = 76,
  });

  final String label;
  final String artAsset;
  final Color accent;
  final String? svgBody;
  final String? fallbackLogoUrl;
  final String? fallbackLogoAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final circle = height - 18;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    height: 1.15,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: height * 0.52,
            color: const Color(0x44FFFFFF),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StorePillRippleArt(
              asset: artAsset.isEmpty ? kStoreProductArt : artAsset,
              size: circle,
              accent: accent.withValues(alpha: 0.65),
              svgBody: svgBody,
              fallbackLogoUrl: fallbackLogoUrl,
              fallbackLogoAsset: fallbackLogoAsset,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft expanding ripple over a SMALL circular store product image.
class StorePillRippleArt extends StatefulWidget {
  const StorePillRippleArt({
    super.key,
    required this.asset,
    this.size = 52,
    this.fallbackLogoUrl,
    this.fallbackLogoAsset,
    this.accent = const Color(0x66E8D5A3),
    this.svgBody,
  });

  final String asset;
  final double size;
  final String? fallbackLogoUrl;
  final String? fallbackLogoAsset;
  final Color accent;
  final String? svgBody;

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
    final d = widget.size;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft chrome ring (optional SVG sits in the ring language).
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.22),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          ClipOval(
            child: SizedBox(
              width: d - 6,
              height: d - 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: const Color(0xFF0A0F1C)),
                  Padding(
                    padding: EdgeInsets.all(d * 0.16),
                    child: Image.asset(
                      widget.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        if (widget.fallbackLogoUrl != null) {
                          return Image.network(
                            widget.fallbackLogoUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              widget.fallbackLogoAsset ?? kStoreProductArt,
                              fit: BoxFit.contain,
                            ),
                          );
                        }
                        return Image.asset(
                          widget.fallbackLogoAsset ?? kStoreProductArt,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF0A0F1C)),
                        );
                      },
                    ),
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
          ),
          if (widget.svgBody != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: d * 0.34,
                height: d * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xEE060C18),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.55),
                  ),
                ),
                alignment: Alignment.center,
                child: NwsbIcon(
                  widget.svgBody!,
                  size: d * 0.16,
                  color: widget.accent,
                ),
              ),
            ),
        ],
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
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxR = size.shortestSide * 0.58;
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final r = maxR * t;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: (1 - t) * 0.6);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PillRipplePainter old) =>
      old.progress != progress || old.color != color;
}

/// Premium 3D "View all" control — opens blur + carousel panel.
class StoreViewAllControl extends StatelessWidget {
  const StoreViewAllControl({
    super.key,
    required this.onTap,
    this.label = 'View all',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0022)
          ..rotateX(-0.12)
          ..rotateY(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xEEFFFFFF), Color(0xCCE8D5A3)],
            ),
            border: Border.all(color: const Color(0x66FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
              BoxShadow(
                color: Color(0x55E8D5A3),
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Color(0xFF060C18),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF060C18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// UFC-style row title: name on the left, View all pinned right.
class RmRowHeader extends StatelessWidget {
  const RmRowHeader({super.key, required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (onViewAll != null) StoreViewAllControl(onTap: onViewAll!),
        ],
      ),
    );
  }
}

/// Auto-moving horizontal strip of category banners (one place, not per row).
class RmBannerRail extends StatefulWidget {
  const RmBannerRail({super.key, required this.banners});

  final List<Widget> banners;

  @override
  State<RmBannerRail> createState() => _RmBannerRailState();
}

class _RmBannerRailState extends State<RmBannerRail> {
  late final PageController _pc;
  Timer? _timer;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.92);
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
        if (!mounted || !_pc.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: SizedBox(
        height: 188,
        child: PageView.builder(
          controller: _pc,
          padEnds: false,
          onPageChanged: (i) => _page = i,
          itemCount: widget.banners.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: widget.banners[i],
          ),
        ),
      ),
    );
  }
}

/// Full-width looping row break video (part010 ROW_VIDS).
class RmRowVid extends StatelessWidget {
  const RmRowVid({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: GlassWrap(
        margin: EdgeInsets.zero,
        radius: 22,
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 6.4,
            child: NwsbVideo(asset: url, priority: ClipPriority.feature),
          ),
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
    this.originalPrice,
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
  final num? originalPrice;
  final VoidCallback? onTap;
  final VoidCallback? onBuyNow;
  final VoidCallback? onWishlist;
  final VoidCallback? onAddCart;
  final Color? tint;

  /// Taller horizontal card so the UFC-style price can sit large and clear.
  static const double cardHeight = 228;
  static const double cardWidth = 338;

  BagItem get _item => wordBagItem(
        name: name,
        root: root,
        img: imgUrl,
        price: price ?? kWordPriceInr,
        signature: signature,
      );

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: bg.withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: signature
                    ? const Color(0x66E8D5A3)
                    : const Color(0x38FFFFFF),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bg.withOpacity(0.22),
                  const Color(0x1AFFFFFF),
                  const Color(0x12000000),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.18),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const NwsbIcon(
                      NwsbMarks.bag,
                      size: 18,
                      color: Color(0xFFE8D5A3),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 16,
                      color: const Color(0x66FFFFFF),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (onWishlist != null) {
                          onWishlist!();
                        } else {
                          CartBag.instance.addWishlist(_item);
                          _toast(context, 'Saved $name to wishlist');
                        }
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const NwsbIcon(
                          NwsbMarks.wishlist,
                          size: 16,
                          color: Color(0xFF0A101C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 132,
                        height: 132,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xD9060C18),
                                borderRadius: BorderRadius.circular(15),
                                border:
                                    Border.all(color: const Color(0x28FFFFFF)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: StoreNetImage(
                                  url: imgUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
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
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              root.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .8,
                                color: Color(0x99C8E8F5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              wordVibrationTag(name),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.25,
                                color: Color(0xB8FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (price != null)
                              _CenteredPrice(
                                price: price!,
                                originalPrice: originalPrice,
                              ),
                            const Spacer(),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Semantics(
                                    button: true,
                                    container: true,
                                    excludeSemantics: true,
                                    label: 'Add to Cart',
                                    child: GestureDetector(
                                      onTap: () {
                                        if (onAddCart != null) {
                                          onAddCart!();
                                        } else {
                                          storeAddToCart(context, _item);
                                          _toast(
                                            context,
                                            'Added $name to cart',
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xE60A101C),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0x66E8D5A3),
                                          ),
                                        ),
                                        child: const NwsbIcon(
                                          NwsbMarks.cart,
                                          size: 16,
                                          color: Color(0xFFE8D5A3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: const Color(0x66FFFFFF),
                                  ),
                                  const SizedBox(width: 8),
                                  Semantics(
                                    button: true,
                                    container: true,
                                    excludeSemantics: true,
                                    label: 'Buy Now',
                                    child: GestureDetector(
                                      onTap: () {
                                        if (onBuyNow != null) {
                                          onBuyNow!();
                                        } else {
                                          storeBuyNow(context, _item);
                                        }
                                      },
                                      child: Container(
                                        height: 36,
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                          right: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF3E4B7),
                                              Color(0xFFC8A96E),
                                            ],
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Buy Now',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF060C18),
                                              ),
                                            ),
                                            SizedBox(width: 7),
                                            _BagMarkDisc(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}

class _CenteredPrice extends StatelessWidget {
  const _CenteredPrice({required this.price, this.originalPrice});
  final num price;
  final num? originalPrice;

  @override
  Widget build(BuildContext context) {
    final sale = localizedMoney(context, price);
    final original =
        originalPrice == null ? null : localizedMoney(context, originalPrice!);
    final showStrike = original != null && original != sale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStrike)
          Text(
            original,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0x88FFFFFF),
              decoration: TextDecoration.lineThrough,
              decorationColor: Color(0x88FFFFFF),
            ),
          ),
        Text(
          sale,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
            letterSpacing: -0.6,
          ),
        ),
      ],
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
        gradient: const LinearGradient(
          colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)],
        ),
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

class _BagMarkDisc extends StatelessWidget {
  const _BagMarkDisc();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const NwsbIcon(NwsbMarks.bag, size: 15, color: Color(0xFF060C18)),
    );
  }
}

class _SvgChip extends StatelessWidget {
  const _SvgChip({
    required this.mark,
    required this.color,
    this.onTap,
    this.label,
  });
  final String mark;
  final Color color;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xD1060C18),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: NwsbIcon(mark, size: 13, color: color),
        ),
      ),
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
    this.onAddCart,
    this.onBuyNow,
    this.onWishlist,
  });

  final String word;
  final String root;
  final String imgUrl;
  final num price;
  final bool signature;
  final VoidCallback? onTap;
  final VoidCallback? onAddCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onWishlist;

  BagItem get _item => meaningBagItem(
        word: word,
        root: root,
        img: imgUrl,
        price: price,
        signature: signature,
      );

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
              color:
                  signature ? const Color(0x55E8D5A3) : const Color(0x12FFFFFF),
            ),
            color: const Color(0x08FFFFFF),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: 0.42, child: StoreNetImage(url: imgUrl)),
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
                    _SvgChip(
                      mark: NwsbMarks.wishlist,
                      color: const Color(0xB3FFFFFF),
                      label: 'Wishlist',
                      onTap: () {
                        if (onWishlist != null) {
                          onWishlist!();
                          return;
                        }
                        CartBag.instance.addWishlist(_item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved $word to wishlist'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    _SvgChip(
                      mark: NwsbMarks.cart,
                      color: NwsbColors.goldLight,
                      label: 'Add to Cart',
                      onTap: () {
                        if (onAddCart != null) {
                          onAddCart!();
                          return;
                        }
                        storeAddToCart(context, _item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $word to cart'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 5),
                    _SvgChip(
                      mark: NwsbMarks.bag,
                      color: NwsbColors.goldLight,
                      label: 'Buy Now',
                      onTap: () {
                        if (onBuyNow != null) {
                          onBuyNow!();
                          return;
                        }
                        storeBuyNow(context, _item);
                      },
                    ),
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
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0x61C8E8F5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
    this.black = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool black;

  @override
  Widget build(BuildContext context) {
    final bg = black
        ? (selected ? const Color(0xFF000000) : const Color(0xE6000000))
        : Colors.white;
    final fg = black ? Colors.white : const Color(0xFF080A10);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: black ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF),
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: fg,
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
        color: const Color(0xE6090B10),
        border: Border.all(color: const Color(0x66FFFFFF)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/icons/search.webp',
            width: 18,
            height: 18,
            fit: BoxFit.contain,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
              cursorColor: NwsbColors.goldLight,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0x52FFFFFF),
                  fontSize: 14,
                ),
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
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(horizontal: 17),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: const Text(
                'GO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Color(0xFF080A10),
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
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NwsbColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.55,
              color: Color(0x73FFFFFF),
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'NowssB\n© 2026 Adv. Sanjaykumar Gadge · Shabdapathy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.6,
                color: Color(0x73FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreViewMoreTap extends StatelessWidget {
  const StoreViewMoreTap({
    super.key,
    required this.leftover,
    required this.onTap,
  });

  final int leftover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x330C0C0E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Row(
                children: [
                  const NwsbIcon(
                    NwsbMarks.bag,
                    size: 18,
                    color: Color(0xFFE8D5A3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View more · $leftover collections',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
