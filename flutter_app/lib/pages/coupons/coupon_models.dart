/// Coupon data for the rebuilt page. Page-local repo; swap to the shared
/// data layer (Bug Hunter) when it lands.
library;

import 'dart:io';

import '../../features/economy/coupon_tickets.dart';
import '../../features/economy/economy_api.dart';

enum CouponRarity { common, rare, epic, legendary }

enum CouponStatus { active, used, expired }

class NwCoupon {
  const NwCoupon({
    required this.id,
    required this.label,
    required this.offer,
    required this.scope,
    required this.code,
    required this.category,
    this.rarity = CouponRarity.common,
    this.isNew = false,
    this.status = CouponStatus.active,
    this.expiresInDays = 7,
  });

  final String id, label, offer, scope, code, category;
  final CouponRarity rarity;
  final bool isNew;
  final CouponStatus status;
  final int expiresInDays;
}

const kCouponCategories = ['Words', 'Meanings', 'Bundles', 'Subscriptions', 'Gifts', 'E-books'];

class CouponsOffline implements Exception {
  const CouponsOffline();
}

class CouponCodeResult {
  const CouponCodeResult(this.ok, this.message);
  final bool ok;
  final String message;
}

abstract class CouponsRepo {
  Future<List<NwCoupon>> load();
  Future<CouponCodeResult> addCode(String code);
}

/// Default: the catalogue tickets the app already ships, codes via Worker.
class DefaultCouponsRepo implements CouponsRepo {
  const DefaultCouponsRepo();

  static String _cat(WideCouponData w) {
    final k = '${w.kicker} ${w.foot}'.toUpperCase();
    if (k.contains('EBOOK')) return 'E-books';
    if (k.contains('MEAN')) return 'Meanings';
    if (k.contains('SUB') || k.contains('PASS')) return 'Subscriptions';
    return 'Words';
  }

  static CouponRarity _rar(WideCouponData w) {
    final k = w.kicker.toUpperCase();
    if (k.contains('EPIC')) return CouponRarity.epic;
    if (w.foot.contains('PREMIUM') || w.foot.contains('STANDARD')) return CouponRarity.rare;
    return CouponRarity.common;
  }

  @override
  Future<List<NwCoupon>> load() async => [
        for (var i = 0; i < kWideCoupons.length; i++)
          NwCoupon(
            id: kWideCoupons[i].code,
            label: _cat(kWideCoupons[i]) == 'Subscriptions' ? 'Special pass' : 'Special discount',
            offer: kWideCoupons[i].banner,
            scope: kWideCoupons[i].line,
            code: kWideCoupons[i].copy,
            category: _cat(kWideCoupons[i]),
            rarity: _rar(kWideCoupons[i]),
            isNew: i < 2,
          ),
      ];

  @override
  Future<CouponCodeResult> addCode(String code) async {
    try {
      final r = await EconomyApi.call('claimTicket', {'code': code});
      return CouponCodeResult(true, '${r['how'] ?? r['title'] ?? 'Coupon added'}');
    } on EconomyException catch (e) {
      return CouponCodeResult(false, e.message);
    } on SocketException {
      throw const CouponsOffline();
    }
  }
}
