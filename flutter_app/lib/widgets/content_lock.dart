/// The one lock for paid content — words, meanings, Signature pieces and
/// ebooks. Asks [Entitlements] (server-verified Play purchases and plans,
/// admin grants); when the item is not open it shows a glass sheet with a
/// real way in: buy this item on Google Play (Checkout) or see the plans
/// that include it. Free content (price 0) never reaches the sheet, and
/// admins see everything.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../data/cart_bag.dart';
import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/word_private.dart';
import '../data/store_catalog.dart';
import '../data/store_prices.dart';
import '../screens/nwsb_sign_in_sheet.dart';
import '../screens/store/cart_pages.dart';
import '../screens/store/store_cards.dart' show inr;
import '../screens/subscription.dart';
import '../theme/tokens.dart';

/// The bag item a library word sells as.
BagItem wordItemFor(Word w) => BagItem(
      id: Entitlements.wordItemId(w.word),
      title: w.word,
      subtitle: w.origin,
      image: w.img.isNotEmpty ? w.img : kRmWordImg,
      price: StorePrices.instance.priceFor(Entitlements.wordItemId(w.word)),
      kind: 'Word',
    );

/// True when [w] may be practised; otherwise shows the lock sheet and
/// answers again after it closes (true if the person bought it there).
/// On success, prefetches paid fields from /api/content/word into
/// [WordPrivateStore] (no-op when the API is offline or the word is free).
Future<bool> ensureWordOpen(BuildContext context, Word w) async {
  final e = Entitlements.instance;
  if (!e.canOpenWord(w)) {
    await showContentLock(context, item: wordItemFor(w), planNote: 'Every word is included in every plan.');
  }
  if (!e.canOpenWord(w)) return false;
  await WordPrivateStore.instance.prefetch(w);
  return true;
}

/// Like [ensureWordOpen], then returns [w] with paid fields merged from
/// wordsPrivate (via the content API). Null when the lock sheet did not unlock.
Future<Word?> ensureWordResolved(BuildContext context, Word w) async {
  if (!await ensureWordOpen(context, w)) return null;
  return WordPrivateStore.instance.resolve(w);
}

/// Ebook gate for the Reader.
Future<bool> ensureEbookOpen(
  BuildContext context, {
  required String title,
  required String sub,
  required String img,
  required num price,
}) async {
  final e = Entitlements.instance;
  final id = 'ebook:${title.toLowerCase()}';
  final real = StorePrices.instance.priceFor(id, shown: price);
  if (e.canOpenEbook(title, price: real)) return true;
  await showContentLock(
    context,
    item: BagItem(id: id, title: title, subtitle: sub, image: img, price: real, kind: 'Ebook'),
    planNote: 'Frequency X includes every ebook.',
  );
  return e.canOpenEbook(title, price: real);
}

/// Meaning gate (Meaning Store detail / meanings reader).
Future<bool> ensureMeaningOpen(
  BuildContext context, {
  required String word,
  required String root,
  required String img,
}) async {
  final e = Entitlements.instance;
  final id = 'meaning:${word.toLowerCase()}';
  final real = StorePrices.instance.priceFor(id);
  if (e.canOpenMeaning(word, price: real)) return true;
  await showContentLock(
    context,
    item: BagItem(id: id, title: word, subtitle: root, image: img, price: real, kind: 'Meaning'),
    planNote: 'Frequency and Frequency X include every meaning.',
  );
  return e.canOpenMeaning(word, price: real);
}

Future<void> showContentLock(
  BuildContext context, {
  required BagItem item,
  required String planNote,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB8060C18),
    isScrollControlled: true,
    builder: (_) => _LockSheet(item: item, planNote: planNote),
  );
}

class _LockSheet extends StatelessWidget {
  const _LockSheet({required this.item, required this.planNote});
  final BagItem item;
  final String planNote;

  @override
  Widget build(BuildContext context) {
    final signedIn = Entitlements.instance.signedIn;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xCC0B1424),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0x33E8D5A3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_rounded, color: NwsbColors.goldLight, size: 18),
                      SizedBox(width: 8),
                      EditableLabel('content_lock.LockSheet',
                        'LOCKED',
                        style: TextStyle(fontSize: 10, letterSpacing: 2.4, fontWeight: FontWeight.w700, color: NwsbColors.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.kind} · ${inr(item.price)} on Google Play. $planNote',
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  _SheetBtn(
                    label: signedIn ? 'Buy on Google Play' : 'Sign in to buy',
                    filled: true,
                    onTap: () async {
                      final nav = Navigator.of(context);
                      if (!Entitlements.instance.signedIn) {
                        final ok = await NwsbSignInPage.open(context);
                        if (!ok) return;
                      }
                      await nav.push(MaterialPageRoute<void>(builder: (_) => CheckoutPage(items: [item])));
                      if (nav.mounted && nav.canPop()) nav.pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetBtn(
                    label: 'See plans',
                    filled: false,
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
                    },
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

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled ? const LinearGradient(colors: [Color(0xF2E8D5A3), Color(0xE6C8A96E)]) : null,
          color: filled ? null : const Color(0x14FFFFFF),
          border: filled ? null : Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: EditableLabel('content_lock.SheetBtn',
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: filled ? NwsbColors.ink : Colors.white,
          ),
        ),
      ),
    );
  }
}
