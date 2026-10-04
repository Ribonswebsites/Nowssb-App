/// District-style poster rail and the coupon ticket banner.
///
/// Layout only — NowssB posters, black / gold / white. No movie or card-brand art.
library;

import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../theme/tokens.dart';

/// Set from [ensureHypeRoutes] so this file does not import the screens.
typedef HypeOpener = void Function(BuildContext context, String id);

HypeOpener? openHypeCard;

class HypeCard {
  const HypeCard(this.id, this.asset, this.title, this.line);
  final String id;
  final String asset;
  final String title;
  final String line;
}

const kHypeCards = <HypeCard>[
  HypeCard('coupons', 'assets/gifts/coupon-hero.png', 'NowssB Coupons', 'Scratch today'),
  HypeCard('gifts', 'assets/gifts/gift-hero.png', 'NowssB Gifts', 'Daily spin'),
  HypeCard('earn', 'assets/banners/programs/earn.png', 'NowssB Earn', 'Coins on real sales'),
  HypeCard('rewards', 'assets/banners/programs/rewards.png', 'Rewards', 'Spend coins here'),
  HypeCard('signature', 'assets/hero-curve/banner-store.webp', 'Signature', 'The rarest words'),
  HypeCard('library', 'assets/hero-curve/banner-library.webp', 'Sound Library', 'Hear a word'),
];

/// Large portrait posters in a sideways row, with a rank behind each one.
class NowssbHypeRail extends StatelessWidget {
  const NowssbHypeRail({super.key, this.title = 'Most Hyped on NowssB'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: kHypeCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _HypeTile(rank: i + 1, card: kHypeCards[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HypeTile extends StatelessWidget {
  const _HypeTile({required this.rank, required this.card});
  final int rank;
  final HypeCard card;

  @override
  Widget build(BuildContext context) {
    final editing = editModeOn(context);
    final tile = SizedBox(
      width: 196,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 214,
            width: 196,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: -8,
                  bottom: -18,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 112,
                      height: 0.85,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 146,
                      height: 198,
                      child: EditableImage.asset(
                        card.asset,
                        fit: BoxFit.cover,
                        slot: 'hype_rail.${card.id}',
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 3),
          Text(
            card.line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE8A23A), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    if (editing) return tile;
    return GestureDetector(
      onTap: () => openHypeCard?.call(context, card.id),
      child: tile,
    );
  }
}

/// Wide ticket promo. Same layout as a weekend offer banner, NowssB colours.
class CouponTicketPromo extends StatelessWidget {
  const CouponTicketPromo({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF071018)),
          child: Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: _WavePainter())),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('NOWSSB', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        SizedBox(width: 8),
                        Text('✦', style: TextStyle(color: NwsbColors.goldLight, fontSize: 14)),
                        SizedBox(width: 8),
                        Text('COUPONS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipPath(
                      clipper: _TicketClip(),
                      child: ColoredBox(
                        color: const Color(0xFF0C0C0C),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text('NOWSSB COUPON', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 6),
                              const Text('LIMITED', style: TextStyle(color: Color(0xFFE23B3B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                              const Text(
                                '25% OFF',
                                style: TextStyle(color: Color(0xFFE8A23A), fontSize: 36, fontWeight: FontWeight.w900, height: 1.05),
                              ),
                              const Text(
                                'on a word or a meaning · not cash',
                                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: onPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A23A),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Scratch now', style: TextStyle(color: Color(0xFF1A1206), fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 18, color: Color(0xFF1A1206)),
                          ],
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
    );
  }
}

class _TicketClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 12.0;
    final mid = size.height / 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    path.addOval(Rect.fromCircle(center: Offset(0, mid), radius: notch));
    path.addOval(Rect.fromCircle(center: Offset(size.width, mid), radius: notch));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x33E8D5A3);
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final y = size.height * (0.15 + i * 0.16);
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width * 0.25, y - 28, size.width * 0.5, y);
      path.quadraticBezierTo(size.width * 0.75, y + 28, size.width, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Coupon page bar: home circle, title, subtitle, optional coins, avatar.
class CouponsPageHeader extends StatelessWidget {
  const CouponsPageHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33101828),
              border: Border.all(color: const Color(0x55FFFFFF)),
            ),
            child: const Icon(Icons.home_outlined, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NowssB Coupons',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Scratch · Tickets · Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 16, color: Color(0xB3FFFFFF)),
                ],
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => openHypeCard?.call(context, 'profile'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFFE8D5A3), width: 1.4),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}
