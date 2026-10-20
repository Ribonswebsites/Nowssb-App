import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/app_control.dart';
import '../../data/content.dart';
import '../../data/entitlements.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../economy/money.dart';

/// Kill switch only: the rebuilt E-books page is ON for everyone unless the
/// console sets `newui_ebooks: false` (Ribon, Oct 13 5:39 PM rule).
bool ebooksV2On() => AppControl.instance.flags['newui_ebooks'] != false;

/// Page-local data access for E-books (no shared kit on this main).
abstract class EbooksData {
  Future<List<EbBook>> load();
  bool get offline;
  bool owns(EbBook b);
  int priceCents(EbBook b);
  Future<bool> guideSeen();
  Future<void> markGuideSeen();
  int progressOf(EbBook b); // last chapter index opened
  void saveProgress(EbBook b, int chapter);
}

/// Catalog prices are stored in their original unit (INR). Convert once to
/// USD cents with the app's FxBook rates; the UI only formats cents in the
/// user's local currency (no India-only pricing).
int catalogToCents(num catalogPrice) {
  final perUsd = FxBook.instance.rates['INR'] ?? 83.5;
  return ((catalogPrice / perUsd) * 100).round();
}

String money(int cents) => FxBook.instance.formatCents(cents);

class LiveEbooksData implements EbooksData {
  LiveEbooksData();
  static final Map<String, int> _progress = {};
  static const _guideKey = 'nwsb.ebooks.guide.v2';

  @override
  Future<List<EbBook>> load() async {
    final live = ContentStore.instance.books;
    if (live.isEmpty) return kEbBooks;
    final keys = {for (final b in kEbBooks) b.key};
    return [
      ...kEbBooks,
      for (final b in live)
        if (!keys.contains(b.key))
          EbBook(
            key: b.key,
            title: b.title,
            sub: b.sub,
            price: b.price,
            cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
            about: b.sub,
            contents: const ['Published from the NowssB studio'],
          ),
    ];
  }

  @override
  bool get offline => false;

  num _price(EbBook b) => StorePrices.instance.priceFor('ebook:${b.title.toLowerCase()}', shown: b.price);

  @override
  bool owns(EbBook b) => Entitlements.instance.canOpenEbook(b.title, price: _price(b));

  @override
  int priceCents(EbBook b) => catalogToCents(_price(b));

  @override
  Future<bool> guideSeen() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_guideKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> markGuideSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_guideKey, true);
    } catch (_) {}
  }

  @override
  int progressOf(EbBook b) => _progress[b.key] ?? 0;

  @override
  void saveProgress(EbBook b, int chapter) => _progress[b.key] = chapter;
}
