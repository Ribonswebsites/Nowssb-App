/// Coupons in NowssB Home's style: the "Today's offer" section pattern
/// (black inner box with round icon + gold title, purple-dot timeline,
/// bottom row with a cream Shop Now pill), Home's top bar for sub-pages and
/// the same background video as Home (NAppBackdrop → AppBackdrop).
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../nowssb_ui/app_video_backdrop.dart';
import '../../theme/tokens.dart';
import '../economy/coupon_tickets.dart';

const kHomeGold = NwsbColors.goldLight;
const kHomeGrey = Color(0x99FFFFFF);
const kHomePurple = Color(0xFF7E57C2);
const kHomePurpleLight = Color(0xFFB794F6);

/// Home's dark-glass section: big rounded translucent container, thin light
/// border; children spaced 10 apart.
class HomeDarkSection extends StatelessWidget {
  const HomeDarkSection({super.key, required this.children, this.margin = const EdgeInsets.only(bottom: 16)});
  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x8C000000),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x24FFFFFF)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 10), children[i]],
              ]),
            ),
          ),
        ),
      );
}

/// Solid near-black inner box.
class HomeBlackBox extends StatelessWidget {
  const HomeBlackBox({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(NwsbRadius.tile)),
        child: child,
      );
}

Widget homeRoundIcon(IconData icon, {double size = 44, Color color = kHomeGold}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0x17FFFFFF), shape: BoxShape.circle, border: Border.all(color: const Color(0x26FFFFFF))),
      child: Icon(icon, size: size * 0.43, color: color),
    );

/// Header box: round icon, gold title, grey subtitle.
class HomeHeaderBox extends StatelessWidget {
  const HomeHeaderBox({super.key, required this.icon, required this.title, required this.subtitle, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => HomeBlackBox(
        child: Row(children: [
          homeRoundIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kHomeGold, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: kHomeGrey, fontSize: 12.5, height: 1.35)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// One timeline row: purple dot + line, uppercase title, grey subtitle.
class HomeTimelineRow extends StatelessWidget {
  const HomeTimelineRow({super.key, required this.title, required this.subtitle, this.trailing, this.active = false, this.last = false, this.onTap});
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool active;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 24,
              child: Column(children: [
                const SizedBox(height: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [kHomePurpleLight, kHomePurple]),
                    boxShadow: active ? const [BoxShadow(color: Color(0x667E57C2), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                ),
                if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.only(top: 3), color: const Color(0x887E57C2))),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0x1FFFFFFF)))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13.5, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(color: kHomeGrey, fontSize: 12, height: 1.35)),
                    ]),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ]),
              ),
            ),
          ]),
        ),
      );
}

/// Home's cream "Shop Now" pill.
class HomeShopPill extends StatelessWidget {
  const HomeShopPill({super.key, this.label = 'Shop Now', this.icon = Icons.shopping_cart_outlined, this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: kHomeGold, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: NwsbColors.ink),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: NwsbColors.ink)),
          ]),
        ),
      );
}

/// Home's white round-arrow "Enter ->" pill.
class HomeEnterPill extends StatelessWidget {
  const HomeEnterPill({super.key, this.label = 'Enter', this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NwsbColors.ink)),
            const SizedBox(width: 8),
            Container(width: 26, height: 26, decoration: const BoxDecoration(color: NwsbColors.ink, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white)),
          ]),
        ),
      );
}

/// Bottom black row: small icon, eyebrow, title, then a pill.
class HomeActionRow extends StatelessWidget {
  const HomeActionRow({super.key, required this.icon, required this.eyebrow, required this.title, required this.pill, this.onTap});
  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget pill;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: HomeBlackBox(
          child: Row(children: [
            homeRoundIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(eyebrow.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, letterSpacing: 1.4, color: kHomeGrey)),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 34, color: const Color(0x1FFFFFFF)),
            const SizedBox(width: 12),
            pill,
          ]),
        ),
      );
}

/// The coupon list as Home's "Today's offer" section.
class CouponOfferSection extends StatelessWidget {
  const CouponOfferSection({super.key, required this.onDetail, required this.onShop, this.coupons = kWideCoupons});
  final void Function(WideCouponData) onDetail;
  final VoidCallback onShop;
  final List<WideCouponData> coupons;

  @override
  Widget build(BuildContext context) => HomeDarkSection(children: [
        const HomeHeaderBox(icon: Icons.local_offer_outlined, title: 'Today’s coupons', subtitle: 'Tap one for its code and terms. A coupon is not cash.'),
        HomeBlackBox(
          padding: const EdgeInsets.fromLTRB(12, 4, 14, 4),
          child: Column(children: [
            for (var i = 0; i < coupons.length; i++)
              HomeTimelineRow(
                key: Key('details_${coupons[i].code}'),
                title: coupons[i].banner,
                subtitle: coupons[i].line,
                active: i == 0,
                last: i == coupons.length - 1,
                onTap: () => onDetail(coupons[i]),
                trailing: const Icon(Icons.chevron_right, color: kHomeGrey, size: 20),
              ),
          ]),
        ),
        HomeActionRow(icon: Icons.storefront_outlined, eyebrow: 'Coupon shop', title: 'Paid cards', onTap: onShop, pill: HomeShopPill(key: const Key('coupons_shop_now'), onTap: onShop)),
      ]);
}

/// Sub-page frame: Home's background video + Home-style top bar (back arrow
/// + title) in a black glass pill.
class CouponSubPage extends StatelessWidget {
  const CouponSubPage({super.key, required this.title, required this.body, this.actions = const [], this.bottom});
  final String title;
  final Widget body;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) => NAppBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x24FFFFFF))),
                      child: Row(children: [
                        IconButton(key: const Key('sub_back'), onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white)),
                        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))),
                        for (var i = 0; i < actions.length; i++) ...[
                          Container(width: 1, height: 20, color: const Color(0x24FFFFFF)),
                          actions[i],
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
              if (bottom != null) bottom!,
              Expanded(child: body),
            ]),
          ),
        ),
      );
}
