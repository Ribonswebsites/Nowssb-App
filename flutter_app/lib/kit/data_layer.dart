/// Shared data layer (spec §24): thin typed facades over the plumbing that
/// already exists. No new endpoints. Screens in rebuilt pages call these
/// instead of Firestore / EconomyApi / Play directly.
///
///   * Server actions → [EconomyApi.call] (`/api/economy/<action>`, already
///     gated by AppControl restrictions and flags).
///   * Live numbers → [EconomyMirror] (one shared listener set, reset on
///     account switch). The coin chip, wallet and checkout all read
///     [CoinsRepository.balance] so they always agree.
///   * Lists → [KitStreams.query]: one broadcast Firestore listener per
///     (collection, filter, uid), shared across screens.
///   * Money → [PlayCheckout] (one-time), [PlaySubscriptions] (plans),
///     [FxBook] (localized display).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/firebase.dart';
import '../data/play_subscriptions.dart';
import '../features/economy/economy_api.dart';
import '../features/economy/money.dart';
import '../features/economy/play_billing.dart';

typedef Json = Map<String, dynamic>;
typedef DocList = List<QueryDocumentSnapshot<Json>>;

/// Result wrapper so screens render loading / error / empty without try/catch.
sealed class KitResult<T> {
  const KitResult();
}

class KitOk<T> extends KitResult<T> {
  const KitOk(this.value);
  final T value;
}

class KitErr<T> extends KitResult<T> {
  const KitErr(this.message, {this.code});
  final String message;
  final String? code;
  bool get signedOut => code == 'unauthenticated';
}

/// Runs an economy action and turns failures into [KitErr].
Future<KitResult<Json>> economy(String action, [Json? data]) async {
  try {
    return KitOk(await EconomyApi.call(action, data));
  } on EconomyException catch (e) {
    return KitErr(e.message, code: e.code);
  } catch (e) {
    return const KitErr('Something went wrong. Try again in a moment.');
  }
}

/// Shared, cached broadcast listeners. Cleared on account change by
/// [KitStreams.reset] (call from your page's auth listener, or rely on uid
/// being part of the key).
abstract final class KitStreams {
  static final Map<String, Stream<DocList>> _cache = {};

  static Stream<DocList> query(String collection, {required String field, required String uid, int limit = 50}) {
    if (!NwsbFirebase.ready || uid.isEmpty) return Stream.value(const []);
    final key = '$collection|$field|$uid|$limit';
    return _cache.putIfAbsent(
      key,
      () => FirebaseFirestore.instance
          .collection(collection)
          .where(field, isEqualTo: uid)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs)
          .asBroadcastStream(),
    );
  }

  static Stream<DocList> sub(String path, {int limit = 60}) {
    if (!NwsbFirebase.ready || path.isEmpty) return Stream.value(const []);
    final key = 'sub|$path|$limit';
    return _cache.putIfAbsent(
      key,
      () => FirebaseFirestore.instance.collection(path).limit(limit).snapshots().map((s) => s.docs).asBroadcastStream(),
    );
  }

  static void reset() => _cache.clear();
  @visibleForTesting
  static int get cachedCount => _cache.length;
}

String? get _uid => EconomyMirror.instance.uid;

/// Coins: balance, ledger, spend.
abstract final class CoinsRepository {
  /// Listen to this; read [coins]. Same source as every coin chip.
  static Listenable get balance => EconomyMirror.instance;
  static int get coins => EconomyMirror.instance.coins;
  static Stream<DocList> ledger({int limit = 200}) => KitStreams.query('coinLedger', field: 'uid', uid: _uid ?? '', limit: limit);
  static Future<KitResult<Json>> spend(Json args) => economy('spendCoins', args);
  static Future<void> refresh() => EconomyMirror.instance.refresh();
}

abstract final class CouponsRepository {
  static Stream<DocList> scratchCards() => KitStreams.sub(_uid == null ? '' : 'users/$_uid/scratchCards');
  static Stream<DocList> coupons() => KitStreams.sub(_uid == null ? '' : 'users/$_uid/coupons');
  static Future<KitResult<Json>> redeemCode(String code) => economy('claimTicket', {'code': code});
  static Future<KitResult<Json>> claimTicket(Json args) => economy('claimTicket', args);
  static Future<KitResult<Json>> dailyScratch() => economy('dailyScratch');
  static Future<KitResult<Json>> scratchCoupon(Json args) => economy('scratchCoupon', args);
  static Future<KitResult<Json>> revealScratch(Json args) => economy('revealScratch', args);
  static Future<KitResult<Json>> buyScratchWithCoins(Json args) => economy('buyScratchWithCoins', args);
  static bool get scratchedToday => EconomyMirror.instance.scratchToday;
}

abstract final class RewardsRepository {
  static Json get summary => EconomyMirror.instance.summary;
  static int get streak => EconomyMirror.instance.streak;
  static Future<KitResult<Json>> claimDailyLogin() => economy('claimDailyLogin');
  static Future<KitResult<Json>> claimQuest(Json args) => economy('claimQuest', args);
  static Future<KitResult<Json>> claimMilestone(Json args) => economy('claimMilestone', args);
  static Future<KitResult<Json>> claimSeason(Json args) => economy('claimSeason', args);
  static Future<KitResult<Json>> league([Json? args]) => economy('league', args);
  static Future<KitResult<Json>> claimLeague(Json args) => economy('claimLeague', args);
  static Future<KitResult<Json>> claimWeeklyChest() => economy('claimWeeklyChest');
  static Future<KitResult<Json>> restoreStreak([Json? args]) => economy('restoreStreak', args);
  static Future<KitResult<Json>> spin([Json? args]) => economy('spin', args);
}

abstract final class GiftsRepository {
  static Future<KitResult<Json>> openDailyBox() => economy('openDailyBox');
  static Future<KitResult<Json>> openBox(Json args) => economy('openBox', args);
  static Future<KitResult<Json>> claimTimeStep(Json args) => economy('claimTimeStep', args);
  static Future<KitResult<Json>> claimWeeklyGift() => economy('claimWeeklyGift');
  static Future<KitResult<Json>> claimMonthlyGift() => economy('claimMonthlyGift');
  static Future<KitResult<Json>> peekGift(Json args) => economy('peekGift', args);
  static Future<KitResult<Json>> redeemGift(Json args) => economy('redeemGift', args);
  static Future<KitResult<Json>> cancelGift(Json args) => economy('cancelGift', args);

  /// Real-money gift (Play one-time `nowssb_gift_*`), via the server checkout.
  static Future<KitResult<Json>> buy(Json checkout) => CheckoutRepository.purchase({'kind': 'giftcard', ...checkout});
}

abstract final class EarnRepository {
  static Future<KitResult<Json>> summary() => economy('earnSummary');
  static Future<KitResult<Json>> appoint(Json args) => economy('appoint', args);
  static Future<KitResult<Json>> answerAppointment(Json args) => economy('answerAppointment', args);
  static Future<KitResult<Json>> applyReferralCode(String code) => economy('applyReferralCode', {'code': code});
  static Stream<DocList> referralLedger({int limit = 40}) => KitStreams.query('referralLedger', field: 'referrerUid', uid: _uid ?? '', limit: limit);
}

abstract final class EarningsRepository {
  static int get cashCents => EconomyMirror.instance.cash;
  static Stream<DocList> cashLedger({int limit = 40}) => KitStreams.query('cashLedger', field: 'uid', uid: _uid ?? '', limit: limit);
  static Stream<DocList> commissionLedger({int limit = 40}) => KitStreams.query('commissionLedger', field: 'uid', uid: _uid ?? '', limit: limit);
  static Stream<DocList> payoutRequests({int limit = 20}) => KitStreams.query('payoutRequests', field: 'uid', uid: _uid ?? '', limit: limit);
  static Future<KitResult<Json>> savePayoutAccount(Json args) => economy('savePayoutAccount', args);
  static Future<KitResult<Json>> requestPayout(Json args) => economy('requestPayout', args);
}

abstract final class PartnerRepository {
  static Future<KitResult<Json>> summary() => economy('partnerSummary');
  static Future<KitResult<Json>> claimLevel(Json args) => economy('claimPartnerLevel', args);
}

abstract final class ReferenceRepository {
  static String get code => EconomyMirror.instance.code;
  static Future<KitResult<Json>> getLink([Json? args]) => economy('getLink', args);
  static Future<KitResult<Json>> linkHub() => economy('linkHub');
  static Future<KitResult<Json>> attachReferral(Json args) => economy('attachReferral', args);
  static Future<KitResult<Json>> claimSharerStep(Json args) => economy('claimSharerStep', args);
}

/// Store checkout: server quote → server checkout → Play → server verify.
abstract final class CheckoutRepository {
  /// Price + coupon + coin-cap preview (server enforces 30/35/40% bands).
  static Future<KitResult<Json>> quote(Json args) => economy('quote', args);

  static Future<KitResult<Json>> purchase(Json checkout) async {
    try {
      return KitOk(await PlayCheckout.purchase(checkout));
    } on EconomyException catch (e) {
      return KitErr(e.message, code: e.code);
    } catch (e) {
      return KitErr('$e'.replaceFirst('Exception: ', ''));
    }
  }

  static Future<bool> playAvailable() => PlayCheckout.available();
  static Future<String> priceLabel(String productId) => PlayCheckout.priceLabel(productId);
}

abstract final class SubscriptionRepository {
  static PlaySubscriptions get play => PlaySubscriptions.instance;
  static Future<PlayResult> buy(String tier, {required bool yearly}) => play.buy(tier, yearly: yearly);
  static Future<PlayResult> restore() => play.restore();
}

/// Localized money display (integer minor units in, string out).
abstract final class KitMoney {
  static String cents(int cents, {String? locale}) => FxBook.instance.formatCents(cents, locale: locale);
  static String rupees(num rupees, {String? locale}) => FxBook.instance.formatRupees(rupees, locale: locale);
}
