/// The details a NowssB account needs after sign-up: name, phone with its
/// country code, country, and (optionally) date of birth. They live on the
/// person's own users/{uid} document (fields the Firestore rules already let
/// the owner write) and are never logged.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/firebase.dart';
import 'countries.dart';

class ProfileDetails {
  const ProfileDetails({this.name = '', this.country = '', this.phoneCountry = '', this.phoneNational = '', this.dob, this.completed = false});

  final String name;

  /// ISO country the person lives in.
  final String country;

  /// ISO country of the phone's calling code (may differ from [country]).
  final String phoneCountry;

  /// Digits after the calling code.
  final String phoneNational;
  final DateTime? dob;
  final bool completed;

  String get phoneE164 {
    final c = countryByCode(phoneCountry);
    if (c == null || phoneNational.isEmpty) return '';
    return '+${c.dial}$phoneNational';
  }

  static ProfileDetails fromUserDoc(Map<String, dynamic> d, {String fallbackName = '', String fallbackPhone = ''}) {
    final name = '${d['displayName'] ?? d['name'] ?? ''}'.trim();
    final country = '${d['country'] ?? ''}'.toUpperCase();
    var phoneCountry = '${d['phoneCountry'] ?? ''}'.toUpperCase();
    var national = '${d['phoneNational'] ?? ''}';
    final e164 = '${d['phone'] ?? ''}'.isNotEmpty ? '${d['phone']}' : fallbackPhone;
    if (national.isEmpty && e164.startsWith('+')) {
      final split = splitE164(e164, preferCountry: phoneCountry.isNotEmpty ? phoneCountry : country);
      if (split != null) {
        phoneCountry = split.$1;
        national = split.$2;
      }
    }
    DateTime? dob;
    final rawDob = '${d['dob'] ?? ''}';
    if (rawDob.length == 10) dob = DateTime.tryParse(rawDob);
    return ProfileDetails(
      name: name.isNotEmpty ? name : fallbackName,
      country: country,
      phoneCountry: phoneCountry,
      phoneNational: national,
      dob: dob,
      completed: d['profileCompletedAt'] != null,
    );
  }

  /// True when the account still needs the Complete your profile page.
  bool get missing => !completed && (name.trim().length < 2 || country.isEmpty || phoneNational.isEmpty);
}

/// Splits +<dial><national> into (ISO, national digits). The longest
/// matching calling code wins; [preferCountry] breaks ties (+1 is shared by
/// the US, Canada and others).
(String, String)? splitE164(String e164, {String preferCountry = ''}) {
  final digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  for (var len = 3; len >= 1; len--) {
    if (digits.length <= len) continue;
    final dial = int.tryParse(digits.substring(0, len));
    final hits = kNwsbCountries.where((c) => c.dial == dial).toList();
    if (hits.isEmpty) continue;
    final pick = hits.firstWhere((c) => c.code == preferCountry,
        orElse: () => hits.firstWhere((c) => c.code == 'US' || c.code == 'RU' || c.code == 'GB', orElse: () => hits.first));
    return (pick.code, digits.substring(len));
  }
  return null;
}

// ── Validation (the page shows these under the fields) ──

String? validateName(String v) {
  final t = v.trim();
  if (t.length < 2) return 'Enter your name (at least 2 letters).';
  if (t.length > 60) return 'Keep your name under 60 characters.';
  if (RegExp(r'[0-9@#$%^&*_=+<>{}\[\]\\/|~`]').hasMatch(t)) return 'Use letters only — no numbers or symbols.';
  return null;
}

String? validatePhone(String national, NwsbCountry? c) {
  if (c == null) return 'Pick the country code.';
  final d = national.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return 'Enter your phone number.';
  if (c.code == 'IN' && !RegExp(r'^[6-9][0-9]{9}$').hasMatch(d)) return 'Indian mobile numbers have 10 digits and start with 6–9.';
  if ((c.code == 'US' || c.code == 'CA') && !RegExp(r'^[2-9][0-9]{9}$').hasMatch(d)) return 'Enter the 10-digit number without the leading 1.';
  // E.164 allows 15 digits in total including the calling code.
  final total = '${c.dial}'.length + d.length;
  if (d.length < 6 || total > 15) return 'That number looks too ${d.length < 6 ? 'short' : 'long'} for +${c.dial}.';
  return null;
}

String? validateDob(DateTime? dob, {DateTime? now}) {
  if (dob == null) return null;
  final n = now ?? DateTime.now();
  var age = n.year - dob.year;
  if (n.month < dob.month || (n.month == dob.month && n.day < dob.day)) age--;
  if (dob.isAfter(n)) return 'That date is in the future.';
  if (age < 13) return 'You need to be at least 13 to use NowssB.';
  if (age > 120) return 'Check the year.';
  return null;
}

String? validateReferralInput(String v) {
  final t = v.trim();
  if (t.isEmpty) return null;
  final c = t.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (c.length < 4 || c.length > 20 || c.length != t.replaceAll(' ', '').length) return 'Codes are 4–20 letters and numbers.';
  return null;
}

String dobString(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ProfileDetailsStore {
  ProfileDetailsStore._();
  static final instance = ProfileDetailsStore._();

  /// Tests: answer loads and saves without Firebase.
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String uid)? debugLoad;
  @visibleForTesting
  static Future<void> Function(String uid, Map<String, dynamic> data)? debugSave;

  static String _snoozeKey(String uid) => 'nwsb_profile_snooze_$uid';

  Future<ProfileDetails?> load(String uid) async {
    final fake = debugLoad;
    if (fake != null) {
      final d = await fake(uid);
      return d == null ? null : ProfileDetails.fromUserDoc(d);
    }
    if (!NwsbFirebase.ready) return null;
    try {
      final snap = await FirebaseFirestore.instance.doc('users/$uid').get().timeout(const Duration(seconds: 8));
      final u = FirebaseAuth.instance.currentUser;
      return ProfileDetails.fromUserDoc(snap.data() ?? const {}, fallbackName: u?.displayName ?? '', fallbackPhone: u?.phoneNumber ?? '');
    } catch (_) {
      return null; // offline: never block the app on this
    }
  }

  Future<void> save(String uid, ProfileDetails d) async {
    final data = <String, dynamic>{
      'displayName': d.name.trim(),
      'country': d.country,
      'phone': d.phoneE164,
      'phoneCountry': d.phoneCountry,
      'phoneNational': d.phoneNational,
      'dob': d.dob == null ? null : dobString(d.dob!),
    };
    final fake = debugSave;
    if (fake != null) {
      await fake(uid, {...data, 'profileCompletedAt': 'now'});
      return;
    }
    await FirebaseFirestore.instance
        .doc('users/$uid')
        .set({...data, 'profileCompletedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    final u = FirebaseAuth.instance.currentUser;
    if (u != null && u.uid == uid && (u.displayName ?? '') != d.name.trim()) {
      try {
        await u.updateDisplayName(d.name.trim());
      } catch (_) {}
    }
  }

  /// "Not now" hides the page for three days.
  Future<bool> snoozed(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      final until = p.getInt(_snoozeKey(uid)) ?? 0;
      return DateTime.now().millisecondsSinceEpoch < until;
    } catch (_) {
      return false;
    }
  }

  Future<void> snooze(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_snoozeKey(uid), DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch);
    } catch (_) {}
  }
}
