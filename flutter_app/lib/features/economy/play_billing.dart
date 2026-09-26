/// Google Play Billing. The purchase is completed only after the Cloud
/// Function accepts the receipt. A missing service account fails closed.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'economy_api.dart';

class PlayCheckout {
  static Future<void> buy({
    required String callable,
    required String productId,
    Map<String, dynamic> payload = const {},
  }) async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      throw EconomyException('Google Play Billing is not available on this device.');
    }
    final response = await iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      final missing = response.notFoundIDs.join(', ');
      throw EconomyException(
        'Play product $productId is not in the store yet${missing.isEmpty ? '' : ' ($missing)'}.',
      );
    }
    final details = response.productDetails.first;
    final completer = Completer<void>();
    late final StreamSubscription<List<PurchaseDetails>> sub;
    sub = iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != productId || completer.isCompleted) continue;
        if (purchase.status == PurchaseStatus.pending) continue;
        if (purchase.status == PurchaseStatus.canceled) {
          completer.completeError(EconomyException('Purchase cancelled.'));
          continue;
        }
        if (purchase.status == PurchaseStatus.error) {
          completer.completeError(
            EconomyException(purchase.error?.message ?? 'Play Billing failed.'),
          );
          continue;
        }
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          try {
            await EconomyApi.call(callable, {
              ...payload,
              'productId': productId,
              'purchaseToken': purchase.verificationData.serverVerificationData,
            });
            if (purchase.pendingCompletePurchase) {
              await iap.completePurchase(purchase);
            }
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            if (!completer.isCompleted) completer.completeError(e);
          }
        }
      }
    }, onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(EconomyException('$e'));
    });
    try {
      final started = await iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started) throw EconomyException('Play did not start the purchase.');
      await completer.future.timeout(const Duration(minutes: 3));
    } on TimeoutException {
      throw EconomyException('The Play purchase did not finish.');
    } finally {
      await sub.cancel();
    }
  }
}
