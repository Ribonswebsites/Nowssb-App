/// Payout methods per country, their fields and the checks the server makes
/// again. Nothing here stores or logs a number: the page sends the values to
/// the server once and only ever shows the masked copy it returns.
library;

/// One way to be paid.
enum PayoutMethod {
  upi('upi', 'UPI ID', 'Instant to any Indian bank app'),
  bankIn('bank_in', 'Bank account', 'Account number + IFSC'),
  usAch('us_ach', 'Bank account', 'Routing + account number (ACH)'),
  gbBank('gb_bank', 'Bank account', 'Sort code + account number'),
  iban('iban', 'Bank account', 'IBAN (SEPA and IBAN countries)'),
  paypal('paypal', 'PayPal', 'Paid to your PayPal email'),
  wise('wise', 'Wise', 'Paid to your Wise email');

  const PayoutMethod(this.id, this.label, this.sub);
  final String id;
  final String label;
  final String sub;

  static PayoutMethod? byId(String? id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}

/// IBAN lengths (ISO 13616 registry, SWIFT IBAN Registry).
const kIbanLengths = <String, int>{
  'AD': 24, 'AE': 23, 'AL': 28, 'AT': 20, 'AZ': 28, 'BA': 20, 'BE': 16, 'BG': 22, 'BH': 22, 'BR': 29,
  'BY': 28, 'CH': 21, 'CR': 22, 'CY': 28, 'CZ': 24, 'DE': 22, 'DK': 18, 'DO': 28, 'EE': 20, 'EG': 29,
  'ES': 24, 'FI': 18, 'FO': 18, 'FR': 27, 'GB': 22, 'GE': 22, 'GI': 23, 'GL': 18, 'GR': 27, 'GT': 28,
  'HR': 21, 'HU': 28, 'IE': 22, 'IL': 23, 'IQ': 23, 'IS': 26, 'IT': 27, 'JO': 30, 'KW': 30, 'KZ': 20,
  'LB': 28, 'LC': 32, 'LI': 21, 'LT': 20, 'LU': 20, 'LV': 21, 'MC': 27, 'MD': 24, 'ME': 22, 'MK': 19,
  'MR': 27, 'MT': 31, 'MU': 30, 'NL': 18, 'NO': 15, 'PK': 24, 'PL': 28, 'PS': 29, 'PT': 25, 'QA': 29,
  'RO': 24, 'RS': 22, 'SA': 24, 'SC': 31, 'SE': 24, 'SI': 19, 'SK': 24, 'SM': 27, 'ST': 25, 'SV': 28,
  'TL': 23, 'TN': 24, 'TR': 26, 'UA': 29, 'VA': 22, 'VG': 24, 'XK': 20,
};

/// Methods that make sense for [country], best first.
List<PayoutMethod> methodsForCountry(String country) {
  final c = country.toUpperCase();
  if (c == 'IN') return const [PayoutMethod.upi, PayoutMethod.bankIn];
  if (c == 'US') return const [PayoutMethod.usAch, PayoutMethod.paypal, PayoutMethod.wise];
  if (c == 'GB') return const [PayoutMethod.gbBank, PayoutMethod.paypal, PayoutMethod.wise];
  if (kIbanLengths.containsKey(c)) return const [PayoutMethod.iban, PayoutMethod.paypal, PayoutMethod.wise];
  return const [PayoutMethod.paypal, PayoutMethod.wise];
}

/// What the live server accepts. Older servers (no `methods` in the
/// payout account) take UPI for India and a Wise / PayPal email elsewhere.
List<PayoutMethod> availableMethods(String country, List<String>? serverMethods) {
  final all = methodsForCountry(country);
  if (serverMethods == null) {
    return country.toUpperCase() == 'IN' ? const [PayoutMethod.upi] : all.where((m) => m == PayoutMethod.paypal || m == PayoutMethod.wise).toList();
  }
  return all.where((m) => serverMethods.contains(m.id)).toList();
}

String _digits(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');

String? checkHolder(String v) {
  final t = v.trim();
  if (t.length < 3) return 'Enter the name exactly as on the account.';
  if (RegExp(r'[0-9@#$%^*_=+<>{}\[\]\\|~`]').hasMatch(t)) return 'Names can’t contain numbers or symbols.';
  return null;
}

String? checkUpi(String v) {
  if (!RegExp(r'^[a-zA-Z0-9._-]{2,256}@[a-zA-Z][a-zA-Z0-9.-]{1,64}$').hasMatch(v.trim())) return 'UPI IDs look like name@okhdfcbank.';
  return null;
}

String? checkPan(String v) {
  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v.trim().toUpperCase())) return 'PAN looks like ABCDE1234F.';
  return null;
}

String? checkIfsc(String v) {
  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.trim().toUpperCase())) return 'IFSC is 11 characters, like HDFC0001234.';
  return null;
}

String? checkIndianAccount(String v) {
  final d = _digits(v);
  if (d.length != v.replaceAll(' ', '').length || d.length < 9 || d.length > 18) return 'Indian account numbers are 9–18 digits.';
  return null;
}

/// ABA routing number: 9 digits with the 3-7-1 checksum.
String? checkRouting(String v) {
  final d = _digits(v);
  if (d.length != 9) return 'Routing numbers are 9 digits.';
  final n = d.split('').map(int.parse).toList();
  final sum = 3 * (n[0] + n[3] + n[6]) + 7 * (n[1] + n[4] + n[7]) + (n[2] + n[5] + n[8]);
  if (sum % 10 != 0) return 'That routing number doesn’t check out. Look at the bottom-left of a cheque.';
  return null;
}

String? checkUsAccount(String v) {
  final d = _digits(v);
  if (d.length < 4 || d.length > 17) return 'US account numbers are 4–17 digits.';
  return null;
}

String? checkSortCode(String v) {
  if (_digits(v).length != 6) return 'Sort codes are 6 digits, like 12-34-56.';
  return null;
}

String? checkGbAccount(String v) {
  if (_digits(v).length != 8) return 'UK account numbers are 8 digits.';
  return null;
}

String normalizeIban(String v) => v.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// ISO 13616 IBAN: country length + mod-97 check.
String? checkIban(String v) {
  final s = normalizeIban(v);
  if (s.length < 15 || !RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(s)) return 'Enter the full IBAN, starting with the country letters.';
  final len = kIbanLengths[s.substring(0, 2)];
  if (len != null && s.length != len) return '${s.substring(0, 2)} IBANs are $len characters.';
  final moved = s.substring(4) + s.substring(0, 4);
  var rem = 0;
  for (final ch in moved.codeUnits) {
    final part = ch >= 65 ? '${ch - 55}' : String.fromCharCode(ch);
    for (final c in part.codeUnits) {
      rem = (rem * 10 + (c - 48)) % 97;
    }
  }
  if (rem != 1) return 'That IBAN doesn’t check out. Copy it again from your bank app.';
  return null;
}

String? checkBic(String v) {
  final t = v.trim().toUpperCase();
  if (t.isEmpty) return null;
  if (!RegExp(r'^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(t)) return 'BIC / SWIFT is 8 or 11 characters.';
  return null;
}

String? checkEmail(String v) {
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) return 'Enter a valid email.';
  return null;
}

/// •••• plus the last four, for showing a number back.
String maskTail(String v, {int keep = 4}) {
  final s = v.replaceAll(RegExp(r'\s'), '');
  if (s.length <= keep) return '••••';
  return '•••• ${s.substring(s.length - keep)}';
}
