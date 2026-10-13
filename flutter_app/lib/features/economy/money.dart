/// Local currency display. Amounts in Firestore are USD cents.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/firebase.dart';

/// The app's base currency: the server prices in it (functions/_lib/economy/config.js `currency`).
const kBaseCurrency = 'INR';

/// Fixed rule amounts, in the base currency. Source of truth is the server;
/// these only feed display copy.
abstract final class BaseAmounts {
  /// A commission line below this (after tax and fee) is not paid.
  static const minPaidLine = 15;

  /// config.js `coinsPerRupee`: coins worth one base unit in the catalogue.
  static const coinsPerUnit = 10;

  /// Shown in copy as "N coins ≈ X" so the local figure isn't a fraction of a cent.
  static const coinExampleCoins = 1000;

  /// The store's "Under X" chip.
  static const underChip = 499;
}

class FxBook extends ChangeNotifier {
  FxBook._();
  static final instance = FxBook._();

  Map<String, double> rates = const {
    'USD': 1,
    'INR': 83.5,
    'EUR': 0.92,
    'GBP': 0.78,
    'AED': 3.67,
    'SGD': 1.35,
    'AUD': 1.52,
    'CAD': 1.36,
    'JPY': 149,
  };

  bool started = false;

  Future<void> start() async {
    if (started || !NwsbFirebase.ready) return;
    started = true;
    FirebaseFirestore.instance.doc('config/fx').snapshots().listen((snap) {
      final raw = snap.data()?['rates'];
      if (raw is Map) {
        final next = <String, double>{'USD': 1};
        raw.forEach((key, value) {
          final n = value is num ? value.toDouble() : double.tryParse('$value');
          if (n != null && n > 0) next[key.toString().toUpperCase()] = n;
        });
        rates = next;
        notifyListeners();
      }
    });
  }

  String codeFor([String? locale]) {
    final loc = (locale ?? Platform.localeName).replaceAll('-', '_');
    final name = NumberFormat.simpleCurrency(locale: loc).currencyName;
    if (name == null || name.length != 3) return 'USD';
    return name.toUpperCase();
  }

  /// [cents] are USD cents.
  String formatCents(int cents, {String? locale}) {
    final loc = (locale ?? Platform.localeName).replaceAll('-', '_');
    final code = codeFor(loc);
    final rate = rates[code];
    if (rate == null) {
      return NumberFormat.simpleCurrency(name: 'USD', locale: loc).format(cents / 100);
    }
    final decimals = code == 'JPY' ? 0 : 2;
    return NumberFormat.simpleCurrency(name: code, locale: loc, decimalDigits: decimals)
        .format((cents / 100) * rate);
  }

  /// A fixed rule amount (base currency) as a clean local figure: $6, not
  /// $5.98. Display only — the server keeps enforcing the exact base value.
  String formatNice(num baseAmount, {String? locale}) {
    final loc = (locale ?? Platform.localeName).replaceAll('-', '_');
    final code = codeFor(loc);
    final base = rates[kBaseCurrency] ?? 83.5;
    final rate = rates[code];
    final outCode = rate == null ? 'USD' : code;
    final local = (baseAmount / base) * (rate ?? 1);
    final v = niceRound(local, wholeOnly: outCode == 'JPY');
    final whole = v == v.roundToDouble();
    return NumberFormat.simpleCurrency(name: outCode, locale: loc, decimalDigits: whole ? 0 : 2).format(v);
  }

  /// Rounds to a clean step by magnitude (never 0.18-style values).
  static double niceRound(double v, {bool wholeOnly = false}) {
    if (v <= 0) return 0;
    double step;
    if (v < 1) {
      step = v < .1 ? .01 : .05;
    } else if (v < 10) {
      step = v < 5 ? .5 : 1;
    } else if (v < 100) {
      step = v < 50 ? 1 : 5;
    } else if (v < 1000) {
      step = v < 500 ? 5 : 10;
    } else {
      step = 50;
    }
    if (wholeOnly && step < 1) step = 1;
    final r = (v / step).round() * step;
    return double.parse((r == 0 ? step : r).toStringAsFixed(2));
  }

  /// Legacy store amounts were written as rupees. Convert through the USD rate.
  String formatRupees(num rupees, {String? locale}) {
    final perDollar = rates[kBaseCurrency] ?? 83.5;
    final cents = ((rupees / perDollar) * 100).round();
    return formatCents(cents, locale: locale);
  }
}
