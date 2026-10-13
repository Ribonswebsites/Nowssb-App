/// Page-local data for the Store rebuild. Swap for the shared
/// `CatalogRepository` (spec 24) once Bug Hunter's data layer lands.
library;

import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/store_catalog.dart';

enum StoreDept { words, meanings, signature, ebooks }

/// One product on a rail. Money is integer minor units (spec 25).
@immutable
class StoreItem {
  const StoreItem({required this.id, required this.title, required this.subtitle, required this.priceMinor, required this.dept});
  final String id, title, subtitle;
  final int priceMinor;
  final StoreDept dept;
}

@immutable
class StoreRail {
  const StoreRail({required this.title, required this.dept, required this.items});
  final String title;
  final StoreDept dept;
  final List<StoreItem> items;
}

typedef StoreLoader = Future<List<StoreRail>> Function();

enum StorePhase { loading, ready, empty, error, offline }

String formatStorePrice(int minor, {String? locale, required String currency}) {
  final f = NumberFormat.simpleCurrency(locale: locale, name: currency);
  final major = minor ~/ 100;
  final cents = minor % 100;
  if (cents == 0) {
    return NumberFormat.simpleCurrency(locale: locale, name: currency, decimalDigits: 0).format(major);
  }
  return f.format(minor / 100);
}

int _minor(num major) => (major * 100).round();

/// Default loader: bundled catalogue (no network needed).
Future<List<StoreRail>> bundledStoreRails() async {
  final words = <StoreItem>[
    for (final c in kRmCategories)
      for (final w in c.words.take(2))
        StoreItem(id: 'w_${c.id}_${w.word}', title: w.word, subtitle: c.label, priceMinor: _minor(99), dept: StoreDept.words),
  ].take(10).toList();
  final meanings = [
    for (final m in kMsBaseMeanings.take(10))
      StoreItem(id: 'm_${m.key}', title: m.word, subtitle: m.category, priceMinor: _minor(m.price), dept: StoreDept.meanings),
  ];
  final books = [
    for (final b in kEbBooks)
      StoreItem(id: 'e_${b.key}', title: b.title, subtitle: b.sub, priceMinor: _minor(b.price), dept: StoreDept.ebooks),
  ];
  return [
    if (words.isNotEmpty) StoreRail(title: 'Words to own', dept: StoreDept.words, items: words),
    if (meanings.isNotEmpty) StoreRail(title: 'New meanings', dept: StoreDept.meanings, items: meanings),
    if (books.isNotEmpty) StoreRail(title: 'E-books', dept: StoreDept.ebooks, items: books),
  ];
}

class StoreFeed extends ChangeNotifier {
  StoreFeed({StoreLoader? loader}) : _loader = loader ?? bundledStoreRails;

  final StoreLoader _loader;
  StorePhase phase = StorePhase.loading;
  List<StoreRail> rails = const [];
  String message = '';
  bool _disposed = false;
  int _gen = 0;

  Future<void> load() async {
    final gen = ++_gen;
    phase = StorePhase.loading;
    _notify();
    try {
      final r = await _loader();
      if (_disposed || gen != _gen) return;
      rails = r.where((x) => x.items.isNotEmpty).toList();
      phase = rails.isEmpty ? StorePhase.empty : StorePhase.ready;
    } on SocketException {
      if (_disposed || gen != _gen) return;
      phase = StorePhase.offline;
      message = 'You are offline. Connect and try again.';
    } on TimeoutException {
      if (_disposed || gen != _gen) return;
      phase = StorePhase.offline;
      message = 'The store took too long. Check your connection.';
    } catch (e) {
      if (_disposed || gen != _gen) return;
      phase = StorePhase.error;
      message = 'We could not load the store. Tap to try again.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
