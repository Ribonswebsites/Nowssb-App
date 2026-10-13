// Banners, hero headers, tabs, top bar, bottom bar.
import 'package:flutter/material.dart';
import 'glass_core.dart';
import 'pills_chips.dart';
import 'tokens.dart';

/// B1 Split offer banner: text left, image fading in from right, "Link now >" CTA.
class SplitOfferBanner extends StatelessWidget {
  const SplitOfferBanner({super.key, required this.headline, this.eyebrow, this.image, this.cta = 'Link now', this.onTap, this.accent = NTokens.violet});
  final String headline; final String? eyebrow; final ImageProvider? image; final String cta; final VoidCallback? onTap; final Color accent;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: NGlass(radius: 26, accent: accent, onTap: onTap, padding: EdgeInsets.zero,
        child: SizedBox(height: 120, child: Stack(children: [
          if (image != null) Positioned.fill(left: 120, child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(colors: [Colors.transparent, Colors.white], stops: [0, .45]).createShader(r),
              blendMode: BlendMode.dstIn, child: Image(image: image!, fit: BoxFit.cover))),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (eyebrow != null) Text(eyebrow!, style: const TextStyle(color: NTokens.mint, fontSize: 11, fontWeight: FontWeight.w700)),
            SizedBox(width: 190, child: Text(headline, maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
            const Spacer(),
            GlassPill(label: cta, trailing: Icons.chevron_right, dense: true, onTap: onTap),
          ])),
        ]))));
}

/// B2 Voucher promo banner (e.g. "Redeem your coin voucher").
class VoucherBanner extends StatelessWidget {
  const VoucherBanner({super.key, required this.title, required this.cta, this.onTap});
  final String title, cta; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NGlass(radius: 26, blur: NTokens.blurLarge, accent: NTokens.pink, tint: NTokens.pink,
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            GlassPill(label: cta, style: PillStyle.white, dense: true, onTap: onTap),
          ])),
          Transform.rotate(angle: -.18, child: const _MiniTicket()),
        ])));
}

class _MiniTicket extends StatelessWidget {
  const _MiniTicket();
  @override
  Widget build(BuildContext context) => Container(width: 96, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [NTokens.pink, NTokens.violet]),
          border: Border.all(color: Colors.white54), boxShadow: [BoxShadow(color: NTokens.pink.withValues(alpha: .5), blurRadius: 18)]),
      child: const Center(child: CoinDot(size: 30)));
}

/// B3 Explore banner: text + arrow pill + 3D coin.
class ExploreBanner extends StatelessWidget {
  const ExploreBanner({super.key, required this.text, this.onTap});
  final String text; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: NGlass(radius: NTokens.rPill, onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10), child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        const CoinDot(size: 34), const SizedBox(width: 8),
        const GlassPill(label: '', icon: Icons.arrow_forward_rounded, style: PillStyle.white, dense: true),
      ])));
}

/// H1 Bold 3D-text hero with floating coins + countdown pill (Multiplier / Free Coins).
class Hero3DHeader extends StatelessWidget {
  const Hero3DHeader({super.key, required this.eyebrow, required this.title, this.countdown, this.pill});
  final String eyebrow, title; final Duration? countdown; final String? pill;
  @override
  Widget build(BuildContext context) => SizedBox(height: 240, child: Stack(alignment: Alignment.center, children: [
        const Positioned(left: 24, top: 30, child: CoinDot(size: 34)),
        const Positioned(right: 30, top: 60, child: CoinDot(size: 46)),
        const Positioned(right: 80, bottom: 40, child: CoinDot(size: 24)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(eyebrow, style: const TextStyle(color: NTokens.mint, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text3D(title),
          const SizedBox(height: 12),
          if (countdown != null) CountdownPill(remaining: countdown!),
          if (pill != null) ...[const SizedBox(height: 8), GlassPill(label: pill!, dense: true)],
        ]),
      ]));
}

/// Extruded metallic 3D text built from stacked shadows (no images).
class Text3D extends StatelessWidget {
  const Text3D(this.text, {super.key, this.size = 44});
  final String text; final double size;
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1);
    return Stack(children: [
      Text(text, textAlign: TextAlign.center, style: style.copyWith(color: const Color(0xFF3B1E8A), shadows: [
        for (var i = 1; i <= 6; i++) Shadow(color: const Color(0xFF2A1366), offset: Offset(0, i.toDouble())),
        Shadow(color: NTokens.pink.withValues(alpha: .6), blurRadius: 24, offset: const Offset(0, 8)),
      ])),
      ShaderMask(shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE9D8FF), Color(0xFFB794F6)]).createShader(r),
          child: Text(text, textAlign: TextAlign.center, style: style.copyWith(color: Colors.white))),
    ]);
  }
}

/// H2 Curved hero header with ticket illustration + count pill ("COUPONS FOR YOU").
class CurvedHeroHeader extends StatelessWidget {
  const CurvedHeroHeader({super.key, required this.sparkle, required this.title, required this.countLabel});
  final String sparkle, title, countLabel;
  @override
  Widget build(BuildContext context) => ClipPath(clipper: _CurveBottom(), child: Container(height: 280,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [NTokens.violet.withValues(alpha: .55), NTokens.bgMid.withValues(alpha: .25)]),
          border: const Border(bottom: BorderSide(color: NTokens.border))),
      child: Column(children: [
        const SizedBox(height: 20),
        Text('✦ $sparkle ✦', style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text3D(title, size: 30),
        const SizedBox(height: 10),
        GlassPill(label: countLabel, dense: true),
        const SizedBox(height: 14),
        Transform.rotate(angle: -.1, child: const _MiniTicket()),
      ])));
}

class _CurveBottom extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()..lineTo(0, s.height - 40)
    ..quadraticBezierTo(s.width / 2, s.height + 20, s.width, s.height - 40)..lineTo(s.width, 0)..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Tier hero (Perks): tier name, progress, "X to next tier", badge.
class TierHero extends StatelessWidget {
  const TierHero({super.key, required this.tier, required this.progress, required this.toNext});
  final String tier, toNext; final double progress;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: NGlass(radius: NTokens.rHero,
      blur: NTokens.blurLarge, accent: NTokens.gold, child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tier, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: progress, minHeight: 8,
              backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(NTokens.gold))),
          const SizedBox(height: 6),
          Text(toNext, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
        ])),
        const SizedBox(width: 12), const CoinDot(size: 64),
      ])));
}

/// Glass top app bar (blur, sticky).
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassTopBar({super.key, required this.title, this.actions = const []});
  final String title; final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: NGlass(radius: NTokens.rPill, blur: NTokens.blurBar, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(children: [
          IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
          ...actions,
        ]))));
}

/// Segmented glass tab bar (Earn | Use | Perks).
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.tabs, required this.index, required this.onChanged});
  final List<String> tabs; final int index; final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: NGlass(
      radius: NTokens.rPill, blur: NTokens.blurBar, padding: const EdgeInsets.all(4),
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++) Expanded(child: GestureDetector(onTap: () => onChanged(i),
            child: AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
                    gradient: i == index ? const LinearGradient(colors: [Colors.white, Color(0xFFE6E0FF)]) : null),
                child: Text(tabs[i], textAlign: TextAlign.center, style: TextStyle(
                    color: i == index ? NTokens.bgBottom : Colors.white, fontWeight: FontWeight.w800))))),
      ])));
}

/// Bottom two-button bar (All rewards / Scratch cards).
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({super.key, required this.left, required this.right, this.onLeft, this.onRight});
  final String left, right; final VoidCallback? onLeft, onRight;
  @override
  Widget build(BuildContext context) => SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12),
      child: NGlass(radius: NTokens.rPill, blur: NTokens.blurBar, padding: const EdgeInsets.all(6), child: Row(children: [
        Expanded(child: GlassPill(label: left, icon: Icons.card_giftcard, onTap: onLeft)),
        const SizedBox(width: 8),
        Expanded(child: GlassPill(label: right, icon: Icons.auto_awesome, style: PillStyle.white, onTap: onRight)),
      ]))));
}

/// Weekly prize / list row with Claim pill.
class ClaimRow extends StatelessWidget {
  const ClaimRow({super.key, required this.title, required this.sub, this.expires, this.enabled = true, this.onClaim});
  final String title, sub; final String? expires; final bool enabled; final VoidCallback? onClaim;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rBox, padding: const EdgeInsets.all(12), child: Row(children: [
        const CoinDot(size: 44), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          Text(sub, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          if (expires != null) Text('⏳ $expires', style: const TextStyle(color: NTokens.coral, fontSize: 11)),
        ])),
        Opacity(opacity: enabled ? 1 : .4, child: GlassPill(label: 'Claim', style: PillStyle.outlined, dense: true, onTap: enabled ? onClaim : null)),
      ]));
}
