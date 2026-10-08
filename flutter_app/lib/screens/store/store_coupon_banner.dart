/// Store coupons banner. A still poster — no wave, no auto-slide.
library;

import 'package:flutter/material.dart';

import '../../shell/nwsb_links.dart';

class StoreCouponBanner extends StatelessWidget {
  const StoreCouponBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        color: const Color(0xFF07080C),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => NwsbLinks.cta(context, 'coupons'),
          child: Image.asset(
            'assets/gifts/coupon-hero.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}
