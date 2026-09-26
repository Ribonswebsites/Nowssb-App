/// Local currency display. Amounts in Firestore are USD cents.
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/firebase.dart';

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

  /// Legacy store amounts were written as rupees. Convert through the USD rate.
  String formatRupees(num rupees, {String? locale}) {
    final perDollar = rates['INR'] ?? 83.5;
    final cents = ((rupees / perDollar) * 100).round();
    return formatCents(cents, locale: locale);
  }
}
