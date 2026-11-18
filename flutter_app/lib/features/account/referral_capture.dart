/// Catches a friend's NowssB Reference code before and through sign-up, and
/// attaches it to the account exactly once.
///
/// Where a code can come from:
///   · Google Play Install Referrer (Android). The share page
///     (functions/w/[[path]].js) sends people to Play with
///     `referrer=utm_source=nowssb_ref&…&nwsb_ref=CODE`; Play hands that
///     string to the app on its first launch.
///   · A tapped link that opens the app: https://nowssb.com/w/<item>?r=CODE
///     (Android App Link / iOS universal link) or nowssb://ref?r=CODE.
///   · A code typed on the Complete your profile page.
///
/// The code waits on the phone (SharedPreferences) until someone is signed
/// in, then goes to the server's `attachReferral` once. The server is the
/// judge: it refuses your own link, a link from the same phone, and a
/// second code once one is attached. The app never credits anything itself.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../economy/coin_collect.dart';
import '../economy/economy_api.dart';

/// A code waiting to be attached.
class PendingReferral {
  const PendingReferral({required this.code, required this.source, required this.at, this.item = ''});
  final String code;

  /// 'install' (Play Install Referrer), 'link' (a tapped link) or 'typed'.
  final String source;
  final int at;

  /// The item slug the link was for ('app' for the general invite).
  final String item;
}

/// Result of an attach attempt, worded for people.
class ReferralOutcome {
  const ReferralOutcome({required this.attached, required this.message, this.welcomeCoins = 0, this.keep = false});
  final bool attached;
  final String message;

  /// Coins offered as a Collect card (0 when the server gave none).
  final int welcomeCoins;

  /// True when the code should stay pending (offline, slow network).
  final bool keep;
}

/// Upper-case letters and digits only, 4–20 long; null when it cannot be a code.
String? normalizeReferralCode(String? raw) {
  final c = (raw ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (c.length < 4 || c.length > 20) return null;
  return c;
}

/// The code in a NowssB link, or null. Accepts
/// https://nowssb.com/w/<slug>?r=CODE (also www., ?ref=, ?nwsb_ref=) and
/// nowssb://ref?r=CODE / nowssb://ref/CODE.
({String code, String item})? referralFromUri(Uri uri) {
  final host = uri.host.toLowerCase();
  final web = (uri.scheme == 'https' || uri.scheme == 'http') && (host == 'nowssb.com' || host == 'www.nowssb.com');
  final app = uri.scheme == 'nowssb';
  if (!web && !app) return null;
  String? raw = uri.queryParameters['r'] ?? uri.queryParameters['ref'] ?? uri.queryParameters['nwsb_ref'];
  if (raw == null && app && host == 'ref' && uri.pathSegments.isNotEmpty) raw = uri.pathSegments.first;
  final code = normalizeReferralCode(raw);
  if (code == null) return null;
  var item = 'app';
  if (web && uri.pathSegments.length >= 2 && uri.pathSegments.first == 'w') item = uri.pathSegments[1];
  return (code: code, item: item);
}

/// The code in a Google Play install referrer string, or null. Play gives
/// the `referrer` parameter URL-decoded once, e.g.
/// `utm_source=nowssb_ref&utm_medium=link&nwsb_ref=AB12CD34&nwsb_item=app`.
({String code, String item})? referralFromInstallReferrer(String? referrer) {
  final s = (referrer ?? '').trim();
  if (s.isEmpty) return null;
  Map<String, String> q;
  try {
    q = Uri.splitQueryString(s.contains('%3D') || s.contains('%26') ? Uri.decodeComponent(s) : s);
  } catch (_) {
    return null;
  }
  final code = normalizeReferralCode(q['nwsb_ref'] ?? q['r'] ?? q['ref']);
  if (code == null) return null;
  final item = q['nwsb_item'] ?? '';
  return (code: code, item: item.isEmpty ? 'app' : item);
}

class ReferralCapture extends ChangeNotifier {
  ReferralCapture._();
  static final instance = ReferralCapture._();

  static const _kCode = 'nwsb_ref_pending_code';
  static const _kSource = 'nwsb_ref_pending_source';
  static const _kAt = 'nwsb_ref_pending_at';
  static const _kItem = 'nwsb_ref_pending_item';
  static const _kInstallRead = 'nwsb_ref_install_read';
  static String _kDone(String uid) => 'nwsb_ref_done_$uid';
  static String _kDoneCode(String uid) => 'nwsb_ref_done_code_$uid';

  PendingReferral? pending;

  /// Last message from an attach (shown on the profile page).
  String lastMessage = '';
  bool busy = false;

  StreamSubscription<Uri>? _links;
  bool _started = false;

  /// Tests: replace the platform sources.
  @visibleForTesting
  static Stream<Uri>? debugLinks;
  @visibleForTesting
  static Future<String?> Function()? debugInstallReferrer;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _loadPending();
    try {
      final links = debugLinks ?? (kIsWeb ? const Stream<Uri>.empty() : AppLinks().uriLinkStream);
      _links = links.listen((uri) => unawaited(captureUri(uri)), onError: (_) {});
    } catch (e) {
      debugPrint('NowssB referral links: unavailable');
    }
    unawaited(_readInstallReferrerOnce());
  }

  @visibleForTesting
  Future<void> debugReset() async {
    await _links?.cancel();
    _links = null;
    _started = false;
    pending = null;
    lastMessage = '';
    busy = false;
  }

  Future<void> _loadPending() async {
    try {
      final p = await SharedPreferences.getInstance();
      final code = p.getString(_kCode);
      if (code != null && code.isNotEmpty) {
        pending = PendingReferral(code: code, source: p.getString(_kSource) ?? 'link', at: p.getInt(_kAt) ?? 0, item: p.getString(_kItem) ?? 'app');
      }
    } catch (_) {}
  }

  Future<void> _readInstallReferrerOnce() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_kInstallRead) == true) return;
      String? raw;
      final fake = debugInstallReferrer;
      if (fake != null) {
        raw = await fake();
      } else {
        if (kIsWeb || !Platform.isAndroid) return;
        final details = await PlayInstallReferrer.installReferrer.timeout(const Duration(seconds: 10));
        raw = details.installReferrer;
      }
      // Read once per install: Play keeps answering for 90 days and a
      // later, unrelated launch must not re-attach anything.
      await p.setBool(_kInstallRead, true);
      final hit = referralFromInstallReferrer(raw);
      if (hit != null) await _setPending(hit.code, 'install', hit.item, override: false);
    } catch (_) {
      // No Play Store (sideloaded build, emulator) — nothing to read.
    }
  }

  /// A link opened the app. A tapped link is newer intent than an install
  /// referrer, so it replaces a code that is still only waiting.
  Future<void> captureUri(Uri uri) async {
    final hit = referralFromUri(uri);
    if (hit == null) return;
    await _setPending(hit.code, 'link', hit.item, override: true);
  }

  Future<void> _setPending(String code, String source, String item, {required bool override}) async {
    if (pending != null && !override) return;
    pending = PendingReferral(code: code, source: source, at: DateTime.now().millisecondsSinceEpoch, item: item);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kCode, code);
      await p.setString(_kSource, source);
      await p.setInt(_kAt, pending!.at);
      await p.setString(_kItem, item);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _clearPending() async {
    pending = null;
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in [_kCode, _kSource, _kAt, _kItem]) {
        await p.remove(k);
      }
    } catch (_) {}
    notifyListeners();
  }

  /// The code this account already joined with on this phone ('' if none).
  Future<String> attachedCode(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_kDone(uid)) == true) return p.getString(_kDoneCode(uid)) ?? '';
    } catch (_) {}
    return '';
  }

  /// Signed in: attach a waiting code (no-op when there is none, or when
  /// this account already has a referrer).
  Future<ReferralOutcome?> onSignedIn(String uid) async {
    await _loadPendingIfNeeded();
    final p = pending;
    if (p == null) return null;
    if ((await attachedCode(uid)).isNotEmpty || EconomyMirror.instance.referredBy.isNotEmpty) {
      await _clearPending();
      return null;
    }
    return attach(uid, p.code, source: p.source);
  }

  Future<void> _loadPendingIfNeeded() async {
    if (pending == null) await _loadPending();
  }

  /// Sends [rawCode] to the server once for [uid].
  Future<ReferralOutcome> attach(String uid, String rawCode, {String source = 'typed'}) async {
    final code = normalizeReferralCode(rawCode);
    if (code == null) return const ReferralOutcome(attached: false, message: 'Enter the full code: letters and numbers, 4 to 20 long.', keep: true);
    final already = await attachedCode(uid);
    if (already.isNotEmpty) {
      return ReferralOutcome(attached: false, message: already == code ? 'You already joined with this code.' : 'Your account already has a friend’s code. It can’t be changed.');
    }
    busy = true;
    notifyListeners();
    try {
      final r = await EconomyApi.call('attachReferral', {
        'code': code,
        'source': source,
        'installId': await EconomyApi.installId(),
      });
      final attached = r['attached'] == true;
      if (!attached) {
        final note = '${r['note'] ?? ''}';
        await _clearPending();
        lastMessage = note.isNotEmpty ? note : 'That code could not be added.';
        return ReferralOutcome(attached: false, message: lastMessage);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDone(uid), true);
      await prefs.setString(_kDoneCode(uid), code);
      await _clearPending();
      // Coins are offered, never dropped in silently: the server's
      // welcome coins wait behind a Collect card.
      final offer = r['welcomeOffer'];
      var coins = 0;
      if (offer is Map) {
        coins = (offer['coins'] as num?)?.toInt() ?? 0;
        if (coins > 0) unawaited(PendingCoins.instance.offer('referral_welcome'));
      }
      // Older server builds credit the welcome set inside attachReferral
      // and return it as `welcome` items; say what arrived, honestly.
      var legacyCoins = 0;
      final legacy = r['welcome'];
      if (legacy is List) {
        for (final it in legacy) {
          if (it is Map && it['type'] == 'coins') legacyCoins += (it['coins'] as num?)?.toInt() ?? 0;
        }
      }
      lastMessage = coins > 0
          ? 'Code added. Your $coins welcome coins are waiting — tap Collect.'
          : legacyCoins > 0
              ? 'Code added. Your welcome set ($legacyCoins coins) is in your wallet.'
              : 'Code added. Your friend earns only when you buy for real on Google Play.';
      unawaited(EconomyMirror.instance.refresh());
      return ReferralOutcome(attached: true, message: lastMessage, welcomeCoins: coins);
    } on EconomyException catch (e) {
      final keep = e.code == 'offline' || e.code == 'timeout' || e.code == 'not-configured' || e.code == 'unauthenticated';
      if (!keep && source != 'typed') await _clearPending();
      lastMessage = e.message;
      return ReferralOutcome(attached: false, message: e.message, keep: keep);
    } catch (_) {
      lastMessage = 'Could not reach NowssB. Your code is saved and will be added when you are online.';
      return ReferralOutcome(attached: false, message: lastMessage, keep: true);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
