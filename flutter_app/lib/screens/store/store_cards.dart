/// Shared Store card widgets — mirror website `.rm-word-card`, `.ms-card`,
/// `.rm-cat-banner`, ebook rows, and gold Signature tags.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';

String inr(num value) {
  if (value <= 0) return 'Included';
  final n = value is int ? value : value.round();
  return '₹$n';
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

/// Plain black `.rm-cat-banner` — logo + divider + title/sub.
/// Matches part010/part026: no photo/character collection banners.
class RmCatBanner extends StatelessWidget {
  const RmCatBanner({
    super.key,
    required this.title,
    required this.sub,
    this.badge,
    this.labelColor,
    this.logoAsset = 'assets/icons/collection-icon.webp',
    this.logoUrl,
  });

  final String title;
  final String sub;
  final String? badge;
  final Color? labelColor;

  /// Bundled collection disc (Word Atelier / web `./assets/icons/collection-icon.webp`).
  final String logoAsset;

  /// Optional remote logo (Meaning Store MS_CAT_LOGO). Wins over [logoAsset].
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final titleColor = labelColor ?? NwsbColors.goldLight;
    final Widget logo = logoUrl != null
        ? Image.network(
            logoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(logoAsset, fit: BoxFit.cover),
          )
        : Image.asset(
            logoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.auto_awesome, size: 16, color: NwsbColors.goldLight),
          );
    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x33E8D5A3)),
                color: const Color(0x14E8D5A3),
              ),
              child: logo,
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0x26FFFFFF),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
                            border: Border.all(color: titleColor.withOpacity(0.45)),
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
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
                  ),
                ],
              ),
            ),
          ],
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4, bottom: 8),
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
  });

  final String name;
  final String root;
  final String imgUrl;
  final bool signature;
  final num? price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: signature ? const Color(0x55E8D5A3) : const Color(0x2EFFFFFF),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x7A000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: StoreNetImage(url: imgUrl),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                  color: const Color(0xD9040A18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                          color: Color(0x8CC8E8F5),
                        ),
                      ),
                      if (price != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          inr(price!),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NwsbColors.goldLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (signature)
              const Positioned(
                top: 8,
                left: 8,
                child: _SignatureTag(),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  _MiniChip(icon: Icons.favorite_border, color: const Color(0xB3FFFFFF)),
                  const SizedBox(height: 6),
                  _MiniChip(icon: Icons.shopping_bag_outlined, color: NwsbColors.goldLight),
                ],
              ),
            ),
          ],
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
