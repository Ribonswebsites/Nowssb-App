/// Local currency display for a global app.
///
/// Every price is shown in the user's own currency. The country comes from
/// the device location (only when location permission is already granted;
/// the app never prompts for it here), else the device locale region. No
/// third-party IP lookup. Exchange rates come from Firestore `config/fx` (`rates`: units per
/// 1 USD). Catalogue amounts are stored in "base units" (the Play price
/// tier values); `config/fx.baseCurrency` + its rate convert them to USD.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../data/firebase.dart';

class FxBook extends ChangeNotifier {
  FxBook._();
  static final instance = FxBook._();

  /// Units of each currency per 1 USD. Only a startup fallback: replaced
  /// live by `config/fx` as soon as it loads.
  Map<String, double> rates = const {
    'USD': 1, 'EUR': 0.92, 'GBP': 0.78, 'JPY': 150, 'CNY': 7.2, 'INR': 84,
    'AED': 3.67, 'SAR': 3.75, 'SGD': 1.35, 'AUD': 1.52, 'CAD': 1.37,
    'CHF': 0.88, 'BRL': 5.5, 'MXN': 18, 'ZAR': 18.5, 'KRW': 1380,
    'IDR': 16000, 'PHP': 57, 'NGN': 1550, 'PKR': 278, 'BDT': 120, 'TRY': 34,
  };

  /// Currency the stored catalogue amounts are written in (`config/fx`
  /// `baseCurrency`). The catalogue tiers were authored in the Play base
  /// tier currency; config can change it without an app update.
  String baseCurrency = 'INR';

  /// ISO country of the user (device region, refined by IP lookup).
  String? country;

  bool started = false;

  Future<void> start() async {
    country ??= PlatformDispatcher.instance.locale.countryCode;
    if (started) return;
    started = true;
    _lookupCountry();
    if (!NwsbFirebase.ready) return;
    FirebaseFirestore.instance.doc('config/fx').snapshots().listen((snap) {
      final data = snap.data() ?? const <String, dynamic>{};
      final raw = data['rates'];
      if (raw is Map) {
        final next = <String, double>{'USD': 1};
        raw.forEach((key, value) {
          final n = value is num ? value.toDouble() : double.tryParse('$value');
          if (n != null && n > 0) next[key.toString().toUpperCase()] = n;
        });
        rates = next;
      }
      final b = data['baseCurrency'];
      if (b is String && b.length == 3) baseCurrency = b.toUpperCase();
      notifyListeners();
    }, onError: (Object e) => debugPrint('NowssB fx: $e'));
  }

  Future<void> _lookupCountry() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) return;
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 8)));
      final marks = await Geocoding().placemarkFromCoordinates(pos.latitude, pos.longitude);
      final c = marks.isEmpty ? null : marks.first.isoCountryCode?.toUpperCase();
      if (c != null && RegExp(r'^[A-Z]{2}$').hasMatch(c) && c != country) {
        country = c;
        notifyListeners();
      }
    } catch (_) {}
  }

  String _locale([String? locale]) {
    if (locale != null) return locale.replaceAll('-', '_');
    final l = PlatformDispatcher.instance.locale;
    final c = country ?? l.countryCode;
    return c == null || c.isEmpty ? l.languageCode : '${l.languageCode}_$c';
  }

  /// ISO currency code for the user's country (or [locale]).
  String codeFor([String? locale]) {
    try {
      final name = NumberFormat.simpleCurrency(locale: _locale(locale)).currencyName;
      if (name != null && name.length == 3) return name.toUpperCase();
    } catch (_) {}
    return 'USD';
  }

  /// [cents] are USD cents, shown in local currency with its local symbol.
  String formatCents(int cents, {String? locale}) {
    final loc = _locale(locale);
    final code = codeFor(locale);
    final rate = rates[code];
    NumberFormat fmt(String c) {
      try {
        return NumberFormat.simpleCurrency(name: c, locale: loc);
      } catch (_) {
        return NumberFormat.simpleCurrency(name: c);
      }
    }
    if (rate == null) return fmt('USD').format(cents / 100);
    return fmt(code).format((cents / 100) * rate);
  }

  /// A stored catalogue amount (base units) shown in local currency.
  String formatPrice(num amount, {String? locale}) {
    final perUsd = rates[baseCurrency] ?? 1;
    return formatCents(((amount / perUsd) * 100).round(), locale: locale);
  }
}
