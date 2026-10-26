/// Local currency display for a global app.
///
/// Every price is shown in the user's own currency: Google Play's quoted
/// currency when known, else the country from the network time zone and
/// the device locales (no location, no IP lookup), else INR. Exchange rates come from Firestore `config/fx` (`rates`: units per
/// 1 USD). Catalogue amounts are stored in "base units" (the Play price
/// tier values); `config/fx.baseCurrency` + its rate convert them to USD.
library;

import 'dart:io' as io;
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// Located country, else the device's (zone/locales), live each read.
  String? get region => country ?? _deviceCountry();

  /// Currency Google Play itself quotes this account in (from any
  /// ProductDetails the app has loaded). The most trustworthy signal: it is
  /// the currency the user will actually be charged in.
  String? playCurrency;

  /// Records the currency of a Play [ProductDetails] price.
  void notePlayCurrency(String? code) {
    final c = code?.trim().toUpperCase();
    if (c == null || !RegExp(r'^[A-Z]{3}$').hasMatch(c) || c == playCurrency) return;
    playCurrency = c;
    notifyListeners();
  }

  /// Time-zone offsets that belong to exactly one market. The phone's zone
  /// is set by the mobile network, so this is the SIM/network region even
  /// when the language is English (United States). +05:30 is India (Sri
  /// Lanka shares it; a phone whose locale says LK keeps LK).
  static const _zoneCountry = {330: 'IN'};

  /// The user's country, from (in order) the network time zone, then any preferred locale that names a region. Null = unknown.
  ///
  /// Root cause of '\$1.18' on India phones: this used to read only
  /// `PlatformDispatcher.locale.countryCode`, and most Indian phones run
  /// English (United States), so the region came back 'US'.
  static String? resolveCountry({
    required List<Locale> locales,
    required Duration tzOffset,
    String? platformLocale,
  }) {
    final regions = [
      for (final l in locales)
        if ((l.countryCode ?? '').isNotEmpty) l.countryCode!.toUpperCase(),
    ];
    // Android's java default locale (Platform.localeName, e.g. 'en_IN' or
    // 'en-IN.UTF-8') can carry the region when PlatformDispatcher's list
    // is a bare 'en'.
    final m = RegExp(r'^[a-zA-Z]{2,3}[_-]([a-zA-Z]{2})\b').firstMatch(platformLocale ?? '');
    if (m != null && !regions.contains(m.group(1)!.toUpperCase())) {
      regions.add(m.group(1)!.toUpperCase());
    }
    final zone = _zoneCountry[tzOffset.inMinutes];
    if (zone != null && !(zone == 'IN' && regions.contains('LK'))) return zone;
    return regions.isEmpty ? null : regions.first;
  }

  String? _deviceCountry() => resolveCountry(
        locales: PlatformDispatcher.instance.locales,
        tzOffset: DateTime.now().timeZoneOffset,
        platformLocale: _platformLocaleName(),
      );

  static String? _platformLocaleName() {
    if (kIsWeb) return null;
    try {
      return io.Platform.localeName;
    } catch (_) {
      return null;
    }
  }

  bool started = false;

  Future<void> start() async {
    if (started) return;
    started = true;
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

  String _locale([String? locale]) {
    if (locale != null) return locale.replaceAll('-', '_');
    final l = PlatformDispatcher.instance.locale;
    final c = country ?? _deviceCountry();
    return c == null || c.isEmpty ? l.languageCode : '${l.languageCode}_$c';
  }

  /// Currency of a region code like 'IN' (null when intl has no data).
  static String? currencyOfCountry(String country, {String language = 'en'}) {
    for (final loc in ['${language}_$country', 'en_$country']) {
      try {
        final name = NumberFormat.simpleCurrency(locale: loc).currencyName;
        if (name != null && name.length == 3) return name.toUpperCase();
      } catch (_) {}
    }
    return null;
  }

  /// ISO currency code for the user (or for an explicit [locale] such as
  /// 'en_IN'). Order: Google Play's own currency, then the region. With no
  /// region at all ('en' alone) it falls back to [baseCurrency] (INR): the
  /// catalogue is authored in it, so the number is exact, never converted.
  String codeFor([String? locale]) {
    if (locale == null && playCurrency != null) return playCurrency!;
    final loc = _locale(locale).split('_');
    final region = loc.length > 1 ? loc.last.toUpperCase() : null;
    if (region == null || region.isEmpty) return baseCurrency;
    return currencyOfCountry(region, language: loc.first) ?? baseCurrency;
  }

  /// [cents] are USD cents, shown in local currency with its local symbol.
  ///
  /// [whole]: a whole amount drops its minor units (₹99, not ₹99.00); an
  /// amount that really has paise / cents keeps them (₹99.50).
  String formatCents(int cents, {String? locale, bool whole = false}) {
    final loc = _locale(locale);
    final code = codeFor(locale);
    final rate = rates[code];
    _Money fmt(String c) => _Money(c, loc, whole);
    if (rate == null) {
      // No rate for the local currency: show the exact base amount rather
      // than a guessed conversion.
      final perUsd = rates[baseCurrency];
      if (perUsd != null) return fmt(baseCurrency).format((cents / 100) * perUsd);
      return fmt('USD').format(cents / 100);
    }
    return fmt(code).format((cents / 100) * rate);
  }

  /// A stored catalogue amount (base units) shown in local currency.
  ///
  /// [whole]: see [formatCents] — ₹99 rather than ₹99.00, paise kept when
  /// the amount really has them.
  String formatPrice(num amount, {String? locale, bool whole = false}) {
    // Same currency as the catalogue: show the stored amount exactly (no
    // round trip through USD cents, which turned ₹99 into ₹99.12).
    if (codeFor(locale) == baseCurrency) {
      return _Money(baseCurrency, _locale(locale), whole).format(amount);
    }
    final perUsd = rates[baseCurrency] ?? 1;
    return formatCents(((amount / perUsd) * 100).round(), locale: locale, whole: whole);
  }

  static NumberFormat _fmt(String code, String loc, {int? decimalDigits}) {
    try {
      return NumberFormat.simpleCurrency(name: code, locale: loc, decimalDigits: decimalDigits);
    } catch (_) {
      return NumberFormat.simpleCurrency(name: code, decimalDigits: decimalDigits);
    }
  }

  /// A store-provided price label (Google Play's localized string) with an
  /// all-zero minor part dropped: '₹99.00' → '₹99', '€1.234,00' → '€1.234'.
  /// '₹99.50' and grouping like '₹1,00,000' are left exactly as Play sent.
  static String wholeLabel(String label) =>
      label.replaceFirst(RegExp(r'[.,]00(?=[^0-9]*$)'), '');
}

/// One currency format; [whole] drops the minor digits of whole amounts only.
class _Money {
  const _Money(this.code, this.loc, this.whole);
  final String code, loc;
  final bool whole;
  String format(num n) => FxBook._fmt(code, loc, decimalDigits: whole && n == n.roundToDouble() ? 0 : null).format(n);
}
