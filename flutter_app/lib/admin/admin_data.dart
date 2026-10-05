/// One door for every console read and write.
///
/// First choice is the admin server (`/api/admin/<action>`, service account,
/// Firebase Auth details, FCM). When that server is not switched on yet —
/// a 501 naming the missing Cloudflare secret, or not deployed — the same
/// action runs here, straight against Firestore as the signed-in admin, so
/// `firestore.rules isAdmin()` is the gate. What only the server can do
/// (disable a Firebase Auth account, send push, list R2) says so instead of
/// pretending. Every change writes adminLog + activity, like the server.
library;

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_api.dart';

const kDay = 86400000;
const kOnlineMs = 5 * 60 * 1000;
const kTiers = {'resonance': 'Resonance', 'frequency': 'Frequency', 'frequencyX': 'Frequency X'};
const kRestrictions = {
  'community': 'Muted in community (posts, comments, Echo Wall)',
  'referrals': 'No invites or referral rewards',
  'payouts': 'Payouts paused',
  'gifting': 'Cannot send or open gifts',
  'earning': 'Cannot earn coins or rewards',
  'requests': 'Cannot send word requests',
};
const kGiftItems = {
  'word': 'A word',
  'meaning': 'A meaning',
  'bundle': '10-word bundle',
  'resonance': 'Resonance · 1 month',
  'frequency': 'Frequency · 1 month',
  'frequency_x': 'Frequency X · 1 month',
};

class AdminData {
  AdminData._();

  /// Last known server state: null = unknown, true = live, false = off.
  static bool? serverLive;
  static List<String> serverMissing = const [];

  static Future<Map<String, dynamic>> run(String action, [Map<String, dynamic> body = const {}]) async {
    if (serverLive != false) {
      try {
        final r = await AdminApi.call(action, body);
        serverLive = true;
        final cfg = r['config'];
        if (cfg is Map && cfg['missing'] is List) serverMissing = (cfg['missing'] as List).map((e) => '$e').toList();
        return r;
      } on AdminApiException catch (e) {
        if (!(e.notConfigured || e.code == 'not_deployed') || !_local.containsKey(action)) rethrow;
        // Only the base secret switches to in-app mode; FCM-only 501s are real answers.
        if (e.code != 'not_deployed' && !e.missing.contains('FIREBASE_SERVICE_ACCOUNT')) rethrow;
        serverLive = false;
        serverMissing = e.missing.isEmpty ? const ['FIREBASE_SERVICE_ACCOUNT'] : e.missing;
      }
    }
    final fn = _local[action];
    if (fn == null) throw AdminApiException('This needs the admin server.', status: 501, code: 'not_configured', missing: serverMissing);
    final out = await fn(body);
    return {...out, 'local': true};
  }

  /// Forget the cached server state (pull-to-refresh retries the server).
  static void retryServer() => serverLive = null;

  static final _local = <String, Future<Map<String, dynamic>> Function(Map<String, dynamic>)>{
    'stats': _stats,
    'users': _users,
    'user': _user,
    'grant-sub': _grantSub,
    'extend-sub': _extendSub,
    'revoke-sub': _revokeSub,
    'adjust-coins': _adjustCoins,
    'block': _block,
    'restrict': _restrict,
    'reset-streak': _resetStreak,
    'message': _message,
    'helper': _helper,
    'fulfil-request': _fulfil,
    'broadcast': (_) async => throw AdminApiException(
        'Push needs the admin server with FCM_SERVICE_ACCOUNT (and FIREBASE_SERVICE_ACCOUNT) in Cloudflare Production. In-app banners still work.',
        status: 501, code: 'not_configured', missing: {...serverMissing, 'FCM_SERVICE_ACCOUNT'}.toList()),
    'payout-decide': _payout,
    'gift-codes': _giftCodes,
    'gift-void': _giftVoid,
    'earn': _earn,
    'network': _network,
    'feed': _feed,
    'ui-assets': _uiAssets,
    'today': _today,
    'grant-item': _grantItem,
    'send-gift': (_) async => throw AdminApiException(
        'Sending a gift needs the admin server (FIREBASE_SERVICE_ACCOUNT in Cloudflare Production). Gift codes can still be made in Money → Gift codes.',
        status: 501, code: 'not_configured', missing: serverMissing),
    'alerts': _alerts,
  };
}

/* ───────────────────────── helpers ───────────────────────── */

/// The product's day is India time (UTC+5:30); the app writes
/// presenceDays/{yyyy-mm-dd} with the same key (data/presence.dart).
const kDayTzMin = 330;
String dayKeyOf(int ms, [int tzMin = kDayTzMin]) =>
    DateTime.fromMillisecondsSinceEpoch(ms + tzMin * 60000, isUtc: true).toIso8601String().substring(0, 10);
int dayStartOf(int ms, [int tzMin = kDayTzMin]) {
  final l = ms + tzMin * 60000;
  return l - (l % kDay) - tzMin * 60000;
}

FirebaseFirestore get _db => FirebaseFirestore.instance;
User get _me {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null) throw AdminApiException('Sign in first.', status: 401);
  return u;
}

String get _by => _me.email ?? _me.uid;

num _num(dynamic v, [num d = 0]) => v is num ? v : (num.tryParse('${v ?? ''}') ?? d);

int toMsAny(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is Timestamp) return v.millisecondsSinceEpoch;
  if (v is DateTime) return v.millisecondsSinceEpoch;
  return DateTime.tryParse('$v')?.millisecondsSinceEpoch ?? (int.tryParse('$v') ?? 0);
}

String _uid(dynamic v) {
  final s = '${v ?? ''}'.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{6,128}$').hasMatch(s)) throw AdminApiException('That is not a user id.', status: 400);
  return s;
}

Map<String, dynamic> planOf(Map<String, dynamic> u, int now) {
  final tier = kTiers.containsKey(u['tier']) ? '${u['tier']}' : '';
  final until = toMsAny(u['subscriptionEndDate']);
  final active = u['isPro'] == true && tier.isNotEmpty && (until == 0 || until > now);
  return {
    'active': active,
    'tier': tier,
    'name': active ? kTiers[tier] : (tier.isNotEmpty ? '${kTiers[tier]} (ended)' : 'Free'),
    'billing': u['subscriptionBilling'] ?? '',
    'until': until,
    'since': toMsAny(u['subscriptionStartDate']),
    'source': u['subscriptionSource'] ?? '',
    'expired': (tier.isNotEmpty || u['subscriptionEndDate'] != null) && !active && until > 0 && until <= now,
    'autoRenew': u['subscriptionAutoRenew'] == true,
    'productId': u['subscriptionProductId'] ?? '',
  };
}

Map<String, dynamic> _row(String uid, Map<String, dynamic> u, int now) {
  final seen = math.max(toMsAny(u['lastSeenAt']), toMsAny(u['lastSeen']));
  final r = u['restrictions'];
  return {
    'uid': uid,
    'name': u['displayName'] ?? u['name'] ?? u['username'] ?? '',
    'email': u['email'] ?? '',
    'phone': u['phone'] ?? u['phoneNumber'] ?? '',
    'photo': u['photoURL'] ?? '',
    'providers': (u['providers'] is List) ? List<String>.from((u['providers'] as List).map((e) => '$e')) : <String>[],
    'createdAt': math.max(toMsAny(u['authCreatedAt']), toMsAny(u['createdAt'])),
    'lastLoginAt': toMsAny(u['lastLogin']),
    'lastSeen': seen,
    'online': seen > now - kOnlineMs,
    'disabled': false,
    'blocked': u['blocked'] == true,
    'helper': u['roles'] is List && (u['roles'] as List).contains('helper'),
    'restrictions': r is Map ? r.entries.where((e) => e.value == true).map((e) => '${e.key}').toList() : <String>[],
    'plan': planOf(u, now),
    'platform': u['lastPlatform'] ?? '',
    'build': '${u['lastBuild'] ?? ''}',
    'hasProfile': u.isNotEmpty,
  };
}

Future<int> _count(Query q) async {
  try {
    final s = await q.count().get();
    return s.count ?? 0;
  } catch (_) {
    return 0;
  }
}

Future<num> _sum(Query q, String field) async {
  try {
    final s = await q.aggregate(sum(field)).get();
    return s.getSum(field) ?? 0;
  } catch (_) {
    return 0;
  }
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _list(Query<Map<String, dynamic>> q) async {
  try {
    return (await q.get()).docs;
  } catch (_) {
    return const [];
  }
}

List<Map<String, dynamic>> _rows(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, [String f = 'at']) {
  final out = docs.map((d) => <String, dynamic>{'id': d.id, ...d.data(), 'at': toMsAny(d.data()[f])}).toList();
  out.sort((a, b) => (b['at'] as int).compareTo(a['at'] as int));
  return out;
}

/// Plain JSON-ish values for the UI (Timestamps → ms).
Map<String, dynamic> _plain(Map<String, dynamic> m) => m.map((k, v) => MapEntry(k, v is Timestamp ? v.millisecondsSinceEpoch : v));

void _log(WriteBatch b, String action, String target, Map<String, dynamic> detail, String summary) {
  final me = _me;
  b.set(_db.collection('adminLog').doc(), {
    'action': action, 'target': target, 'detail': detail, 'uid': me.uid, 'email': me.email ?? '', 'via': 'console-app', 'summary': summary,
    'at': FieldValue.serverTimestamp(),
  });
}

void _notify(WriteBatch b, String uid, String title, String body, {String kind = 'admin', Map<String, dynamic> extra = const {}}) {
  final now = DateTime.now();
  b.set(_db.collection('users').doc(uid).collection('notifications').doc(), {
    'title': title, 'body': body, 'kind': kind, 'type': kind, 'read': false, 'at': Timestamp.fromDate(now),
    'createdAt': FieldValue.serverTimestamp(), ...extra,
  });
}

Future<Map<String, dynamic>> _userDoc(String uid) async => (await _db.collection('users').doc(uid).get()).data() ?? {};

/* ───────────────────────── dashboard ───────────────────────── */

Future<Map<String, dynamic>> _stats(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final tz = _num(body['tzOffsetMin'], 330).toInt();
  final local = now + tz * 60000;
  final dayStart = local - (local % kDay) - tz * 60000;
  final users = _db.collection('users');
  Timestamp ts(int ms) => Timestamp.fromMillisecondsSinceEpoch(ms);
  final r = await Future.wait<Object>([
    _count(users),
    _count(users.where('lastSeenAt', isGreaterThanOrEqualTo: ts(dayStart))),
    _count(users.where('lastSeenAt', isGreaterThanOrEqualTo: ts(now - 7 * kDay))),
    _count(users.where('lastSeenAt', isGreaterThanOrEqualTo: ts(now - kOnlineMs))),
    _count(users.where('blocked', isEqualTo: true)),
    _count(users.where('roles', arrayContains: 'helper')),
    _list(users.where('isPro', isEqualTo: true).limit(5000)),
    _count(users.where('subscriptionEndDate', isLessThan: DateTime.fromMillisecondsSinceEpoch(now).toUtc().toIso8601String())),
    _count(_db.collection('payments')),
    _count(_db.collection('payments').where('at', isGreaterThanOrEqualTo: ts(now - 30 * kDay))),
    _count(_db.collection('requests').where('status', isEqualTo: 'new')),
    _count(_db.collection('requests')),
    _count(_db.collection('requests').where('status', isEqualTo: 'done')),
    _sum(_db.collection('coinLedger').where('delta', isGreaterThan: 0), 'delta'),
    _sum(_db.collection('coinLedger').where('delta', isLessThan: 0), 'delta'),
    _count(_db.collection('coinLedger')),
    _count(_db.collection('gifts')),
    _count(_db.collection('gifts').where('status', isEqualTo: 'redeemed')),
    _count(_db.collection('couponLedger')),
    _count(_db.collection('payoutRequests').where('status', isEqualTo: 'pending_review')),
    _count(_db.collection('payoutRequests').where('status', isEqualTo: 'queued')),
    _count(_db.collection('payoutRequests').where('status', isEqualTo: 'paid')),
    // Sign-up days from the profile mirror (authCreatedAt), last 30 days.
    _list(users.where('authCreatedAt', isGreaterThanOrEqualTo: dayStart - 29 * kDay).limit(5000)),
  ]);
  final plans = <String, Map<String, dynamic>>{
    for (final t in kTiers.keys) t: {'name': kTiers[t], 'monthly': 0, 'yearly': 0, 'other': 0, 'active': 0},
  };
  var active = 0, lapsed = 0;
  final bySource = <String, int>{};
  for (final d in r[6] as List<QueryDocumentSnapshot<Map<String, dynamic>>>) {
    final p = planOf(d.data(), now);
    if ('${p['tier']}'.isEmpty) continue;
    if (p['active'] != true) {
      lapsed++;
      continue;
    }
    active++;
    final b = (p['billing'] == 'monthly' || p['billing'] == 'yearly') ? '${p['billing']}' : 'other';
    final m = plans[p['tier']]!;
    m[b] = (m[b] as int) + 1;
    m['active'] = (m['active'] as int) + 1;
    final src = '${p['source']}'.isEmpty ? 'unknown' : '${p['source']}';
    bySource[src] = (bySource[src] ?? 0) + 1;
  }
  final days = <Map<String, dynamic>>[];
  for (var i = 29; i >= 0; i--) {
    days.add({'day': DateTime.fromMillisecondsSinceEpoch(dayStart - i * kDay + tz * 60000, isUtc: true).toIso8601String().substring(0, 10), 'n': 0});
  }
  var signToday = 0, sign7 = 0;
  for (final d in r[22] as List<QueryDocumentSnapshot<Map<String, dynamic>>>) {
    final t = toMsAny(d.data()['authCreatedAt']);
    final idx = ((t - (dayStart - 29 * kDay)) / kDay).floor();
    if (idx >= 0 && idx < 30) days[idx]['n'] = (days[idx]['n'] as int) + 1;
    if (t >= dayStart) signToday++;
    if (t >= now - 7 * kDay) sign7++;
  }
  int n(int i) => (r[i] as num).toInt();
  return {
    'ok': true,
    'at': now,
    'users': {
      'accounts': null, 'profiles': n(0), 'signedInToday': n(1), 'signedIn7d': n(2), 'online': n(3),
      'blocked': n(4), 'helpers': n(5), 'signupsToday': signToday, 'signups7d': sign7,
    },
    'signups': days,
    'signupsSource': 'profiles',
    'subscriptions': {'active': active, 'lapsedFlagged': lapsed, 'expired': n(7), 'plans': plans, 'bySource': bySource},
    'payments': {'total': n(8), 'last30d': n(9)},
    'requests': {'open': n(10), 'total': n(11), 'done': n(12)},
    'coins': {'issued': n(13), 'spent': n(14).abs(), 'entries': n(15)},
    'gifts': {'codes': n(16), 'opened': n(17), 'coupons': n(18)},
    'payouts': {'pending': n(19), 'queued': n(20), 'paid': n(21)},
    'errors': {},
  };
}

/* ───────────────────────── people ───────────────────────── */

Future<Map<String, dynamic>> _users(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final q = '${body['q'] ?? ''}'.trim().toLowerCase();
  final filter = '${body['filter'] ?? 'all'}';
  final tier = '${body['tier'] ?? ''}';
  final from = toMsAny(body['joinedFrom']);
  final to = toMsAny(body['joinedTo']);
  final limit = _num(body['limit'], 40).toInt().clamp(1, 100);
  final offset = _num(body['offset'], 0).toInt();
  Query<Map<String, dynamic>> base = _db.collection('users');
  Timestamp ts(int ms) => Timestamp.fromMillisecondsSinceEpoch(ms);
  switch (filter) {
    case 'plan':
      base = base.where('isPro', isEqualTo: true);
    case 'blocked':
      base = base.where('blocked', isEqualTo: true);
    case 'online':
      base = base.where('lastSeenAt', isGreaterThanOrEqualTo: ts(now - kOnlineMs));
    case 'today':
      base = base.where('lastSeenAt', isGreaterThanOrEqualTo: ts(dayStartOf(now)));
    case 'seen24h':
      base = base.where('lastSeenAt', isGreaterThanOrEqualTo: ts(now - kDay));
    case 'helper':
      base = base.where('roles', arrayContains: 'helper');
    case 'expired':
      base = base.where('subscriptionEndDate', isLessThan: DateTime.now().toUtc().toIso8601String());
  }
  final docs = await _list(base.limit(2000));
  var rows = docs.map((d) => _row(d.id, d.data(), now)).toList();
  if (filter == 'plan') rows = rows.where((r) => (r['plan'] as Map)['active'] == true && (tier.isEmpty || (r['plan'] as Map)['tier'] == tier)).toList();
  bool hit(Map<String, dynamic> r) {
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    return [r['uid'], r['email'], r['name'], r['phone']].any((v) => '${v ?? ''}'.toLowerCase().contains(q)) ||
        (digits.length >= 5 && '${r['phone']}'.replaceAll(RegExp(r'[^0-9]'), '').contains(digits));
  }
  rows = rows.where((r) => hit(r) && (from == 0 || (r['createdAt'] as int) >= from) && (to == 0 || (r['createdAt'] as int) <= to)).toList();
  if (q.isNotEmpty && rows.isEmpty && RegExp(r'^[A-Za-z0-9_-]{20,128}$').hasMatch(body['q'] ?? '')) {
    final u = await _db.collection('users').doc('${body['q']}'.trim()).get();
    if (u.exists) rows = [_row(u.id, u.data() ?? {}, now)];
  }
  rows.sort((a, b) {
    final c = (b['createdAt'] as int).compareTo(a['createdAt'] as int);
    return c != 0 ? c : (b['lastSeen'] as int).compareTo(a['lastSeen'] as int);
  });
  return {
    'ok': true, 'total': rows.length, 'offset': offset, 'limit': limit,
    'rows': rows.skip(offset).take(limit).toList(), 'source': 'firestore', 'truncated': false,
    'note': 'Admin server is off, so this list is Firestore profiles only (people who opened the app). Accounts that never opened it, and sign-in providers, appear when FIREBASE_SERVICE_ACCOUNT is set.',
  };
}

Future<Map<String, dynamic>> _user(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final uid = _uid(body['uid']);
  final u = await _db.collection('users').doc(uid).get();
  if (!u.exists) throw AdminApiException('No profile with that id.', status: 404);
  final d = u.data() ?? {};
  Future<Map<String, dynamic>?> sub(String c) async {
    try {
      return (await _db.collection('users').doc(uid).collection(c).doc('main').get()).data();
    } catch (_) {
      return null;
    }
  }

  final res = await Future.wait<Object?>([
    sub('wallet'), sub('referral'), sub('payout'), sub('partner'),
    _list(_db.collection('coinLedger').where('uid', isEqualTo: uid).limit(200)),
    _list(_db.collection('cashLedger').where('uid', isEqualTo: uid).limit(100)),
    _list(_db.collection('referrals').where('referrerUid', isEqualTo: uid).limit(200)),
    _db.collection('referrals').doc(uid).get().then((s) => s.data()).catchError((_) => null),
    _list(_db.collection('gifts').where('senderUid', isEqualTo: uid).limit(50)),
    _list(_db.collection('gifts').where('redeemedBy', isEqualTo: uid).limit(50)),
    _list(_db.collection('couponLedger').where('uid', isEqualTo: uid).limit(50)),
    _list(_db.collection('users').doc(uid).collection('owned').limit(200)),
    _list(_db.collection('payments').where('uid', isEqualTo: uid).limit(50)),
    _list(_db.collection('requests').where('uid', isEqualTo: uid).limit(50)),
    _list(_db.collection('adminLog').where('target', isEqualTo: uid).limit(100)),
    _list(_db.collection('payoutRequests').where('uid', isEqualTo: uid).limit(30)),
    _list(_db.collection('activity').where('uid', isEqualTo: uid).limit(60)),
    _list(_db.collection('pushSubs').where('uid', isEqualTo: uid).limit(10)),
    _list(_db.collection('users').doc(uid).collection('days').orderBy(FieldPath.documentId, descending: true).limit(60)),
  ]);
  L(int i) => res[i] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
  final w = res[0] as Map<String, dynamic>?;
  final ref = res[1] as Map<String, dynamic>?;
  final pay = res[2] as Map<String, dynamic>?;
  final up = res[7] as Map<String, dynamic>?;
  List<Map<String, dynamic>> pl(List<Map<String, dynamic>> l) => l.map(_plain).toList();
  return {
    'ok': true,
    'row': _row(uid, d, now),
    'auth': null,
    'authNote': 'Sign-in providers and the Auth account state need the admin server (FIREBASE_SERVICE_ACCOUNT). Shown from the profile mirror where the app recorded it.',
    'user': {
      'displayName': d['displayName'] ?? '', 'username': d['username'] ?? '', 'createdAt': math.max(toMsAny(d['authCreatedAt']), toMsAny(d['createdAt'])),
      'lastSeen': math.max(toMsAny(d['lastSeenAt']), toMsAny(d['lastSeen'])),
      'lastPlatform': d['lastPlatform'] ?? '', 'lastApp': d['lastApp'] ?? '', 'lastBuild': '${d['lastBuild'] ?? ''}', 'lastDevice': d['lastDevice'] ?? '', 'lastOs': d['lastOs'] ?? '',
      'country': d['country'] ?? '', 'blocked': d['blocked'] == true, 'blockedReason': d['blockedReason'] ?? '', 'blockedAt': toMsAny(d['blockedAt']), 'blockedBy': d['blockedBy'] ?? '',
      'restrictions': d['restrictions'] is Map ? d['restrictions'] : {}, 'roles': d['roles'] is List ? d['roles'] : [], 'verifyTier': d['verifyTier'] ?? '',
    },
    'plan': planOf(d, now),
    'wallet': w == null
        ? null
        : {
            'coins': _num(w['coins']), 'streak': _num(w['streak']), 'longestStreak': _num(w['longestStreak']), 'lifetimeEarned': _num(w['lifetimeEarned']),
            'freezesOwned': _num(w['freezesOwned']), 'wordCredits': _num(w['wordCredits']), 'meaningCredits': _num(w['meaningCredits']), 'lastLoginYmd': w['lastLoginYmd'] ?? '',
          },
    'days': [for (final x in L(res.length - 1)) {'day': x.id, ..._plain(x.data())}],
    'coinLedger': pl(_rows(L(4)).take(80).toList()),
    'cashLedger': pl(_rows(L(5)).take(40).toList()),
    'referral': ref == null
        ? null
        : {
            'code': ref['code'] ?? '', 'tier': ref['tier'] ?? '', 'unitsSold': _num(ref['unitsSold']), 'signups': _num(ref['signups']), 'subscribers': _num(ref['subscribers']),
            'paidReferralCount': _num(ref['paidReferralCount']), 'referredBy': ref['referredBy'] ?? '', 'referredByUid': ref['referredByUid'] ?? '',
          },
    'invitedBy': up == null ? null : {'uid': up['referrerUid'] ?? '', 'at': toMsAny(up['at'] ?? up['createdAt']), 'subscribed': up['subscribed'] == true},
    'invited': _rows(L(6)).map((r) => {'uid': r['id'], 'at': r['at'], 'subscribed': r['subscribed'] == true, 'rewarded': r['rewarded'] == true}).toList(),
    'payout': pay == null
        ? null
        : {
            'cashBalance': _num(pay['cashBalance']), 'pendingCents': _num(pay['pendingCents']), 'paidCents': _num(pay['paidCents']), 'lifetimeCents': _num(pay['lifetimeCents']),
            'upi': pay['upi'] ?? '', 'country': pay['country'] ?? '', 'rail': pay['payoutRail'] ?? '',
          },
    'payouts': pl(_rows(L(15))),
    'partner': res[3] == null ? null : _plain(res[3] as Map<String, dynamic>),
    'gifts': {'sent': pl(_rows(L(8), 'createdAt')), 'opened': pl(_rows(L(9), 'redeemedAt'))},
    'coupons': pl(_rows(L(10))),
    'owned': pl(_rows(L(11))),
    'payments': pl(_rows(L(12))),
    'requests': pl(_rows(L(13))),
    'adminLog': pl(_rows(L(14))),
    'activity': pl(_rows(L(16))),
    'devices': L(17).map((s) => {'platform': s.data()['platform'] ?? '', 'country': s.data()['country'] ?? '', 'updatedAt': toMsAny(s.data()['updatedAt'])}).toList(),
  };
}

/* ───────────────────────── actions on a person ───────────────────────── */

Future<Map<String, dynamic>> _grantSub(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final uid = _uid(body['uid']);
  final tier = '${body['tier'] ?? ''}';
  if (!kTiers.containsKey(tier)) throw AdminApiException('Pick Resonance, Frequency or Frequency X.', status: 400);
  final billing = ['monthly', 'yearly', 'custom'].contains(body['billing']) ? '${body['billing']}' : 'custom';
  int end;
  if (body['until'] != null && '${body['until']}'.isNotEmpty) {
    end = toMsAny(body['until']);
    if (end <= now) throw AdminApiException('Pick an end date in the future.', status: 400);
  } else {
    final days = _num(body['days']).round();
    if (days < 1 || days > 3660) throw AdminApiException('Days must be 1 to 3660.', status: 400);
    end = now + days * kDay;
  }
  final u = await _userDoc(uid);
  final before = planOf(u, now);
  final endIso = DateTime.fromMillisecondsSinceEpoch(end).toUtc().toIso8601String();
  final fields = <String, dynamic>{
    'isPro': true, 'tier': tier, 'subscriptionBilling': billing, 'subscriptionEndDate': endIso, 'subscriptionSource': 'admin',
    'subscriptionGrantedBy': _by, 'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
  };
  if (before['active'] != true || u['subscriptionStartDate'] == null) fields['subscriptionStartDate'] = DateTime.now().toUtc().toIso8601String();
  final b = _db.batch();
  b.set(_db.collection('users').doc(uid), fields, SetOptions(merge: true));
  _log(b, 'sub.grant', uid, {'tier': tier, 'billing': billing, 'until': endIso, 'reason': body['reason'] ?? ''}, 'Granted ${kTiers[tier]}');
  if (body['notify'] != false) _notify(b, uid, '${kTiers[tier]} is on', 'Your ${kTiers[tier]} plan is active until ${endIso.substring(0, 10)}.', kind: 'plan');
  await b.commit();
  return {
    'ok': true, 'plan': planOf({...u, ...fields}, now),
    'warning': before['active'] == true && before['source'] == 'play' ? 'This person also has a Google Play subscription; Play renewals will overwrite this grant.' : '',
  };
}

Future<Map<String, dynamic>> _extendSub(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final uid = _uid(body['uid']);
  final days = _num(body['days']).round();
  if (days < 1 || days > 3660) throw AdminApiException('Days must be 1 to 3660.', status: 400);
  final u = await _userDoc(uid);
  final p = planOf(u, now);
  final tier = '${p['tier']}'.isNotEmpty ? '${p['tier']}' : '${body['tier'] ?? ''}';
  if (!kTiers.containsKey(tier)) throw AdminApiException('This person has no plan to extend. Grant one first.', status: 400);
  final end = math.max(p['until'] as int == 0 ? now : p['until'] as int, now) + days * kDay;
  final endIso = DateTime.fromMillisecondsSinceEpoch(end).toUtc().toIso8601String();
  final fields = <String, dynamic>{'isPro': true, 'tier': tier, 'subscriptionEndDate': endIso, 'subscriptionUpdatedAt': FieldValue.serverTimestamp()};
  if ('${p['source']}'.isEmpty || p['active'] != true) fields['subscriptionSource'] = 'admin';
  final b = _db.batch();
  b.set(_db.collection('users').doc(uid), fields, SetOptions(merge: true));
  _log(b, 'sub.extend', uid, {'days': days, 'until': endIso, 'reason': body['reason'] ?? ''}, 'Extended by $days days');
  _notify(b, uid, 'Plan extended', 'Your ${kTiers[tier]} plan now runs until ${endIso.substring(0, 10)}.', kind: 'plan');
  await b.commit();
  return {'ok': true, 'plan': planOf({...u, ...fields}, now)};
}

Future<Map<String, dynamic>> _revokeSub(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final uid = _uid(body['uid']);
  final u = await _userDoc(uid);
  final p = planOf(u, now);
  final fields = <String, dynamic>{
    'isPro': false, 'tier': null, 'subscriptionEndDate': DateTime.now().toUtc().toIso8601String(), 'subscriptionSource': 'admin_revoked',
    'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
  };
  final b = _db.batch();
  b.set(_db.collection('users').doc(uid), fields, SetOptions(merge: true));
  _log(b, 'sub.revoke', uid, {'before': p['tier'], 'source': p['source'], 'reason': body['reason'] ?? ''}, 'Plan revoked');
  await b.commit();
  return {
    'ok': true, 'plan': planOf({...u, ...fields}, now),
    'warning': p['source'] == 'play' ? 'This was a Google Play subscription. Revoking here does not cancel billing in Play; cancel or refund it in Play Console.' : '',
  };
}

Future<Map<String, dynamic>> _adjustCoins(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final delta = _num(body['delta']).round();
  var reason = '${body['reason'] ?? ''}'.trim();
  if (reason.length > 140) reason = reason.substring(0, 140);
  if (delta == 0 || delta.abs() > 1000000) throw AdminApiException('Enter a coin amount (not zero).', status: 400);
  if (reason.isEmpty) throw AdminApiException('Say why — it is shown in their coin history.', status: 400);
  final me = _me;
  final wRef = _db.collection('users').doc(uid).collection('wallet').doc('main');
  final entry = _db.collection('coinLedger').doc();
  var balance = 0;
  await _db.runTransaction((tx) async {
    final w = (await tx.get(wRef)).data() ?? {};
    final next = _num(w['coins']).toInt() + delta;
    if (next < 0) throw AdminApiException('They only have ${_num(w['coins'])} coins.', status: 409);
    balance = next;
    tx.set(entry, {
      'uid': uid, 'delta': delta, 'balanceAfter': next, 'reason': 'Admin: $reason', 'refId': 'admin:${me.uid}', 'by': me.email ?? '',
      'at': FieldValue.serverTimestamp(),
    });
    final patch = <String, dynamic>{'coins': next, 'updatedAt': DateTime.now().millisecondsSinceEpoch};
    if (delta > 0) patch['lifetimeEarned'] = _num(w['lifetimeEarned']).toInt() + delta;
    tx.set(wRef, patch, SetOptions(merge: true));
  });
  final b = _db.batch();
  _log(b, 'coins.adjust', uid, {'delta': delta, 'reason': reason, 'balance': balance, 'entry': entry.id}, '${delta > 0 ? '+' : ''}$delta coins');
  if (body['notify'] != false) _notify(b, uid, delta > 0 ? '$delta coins added' : '${-delta} coins removed', reason, kind: 'coins');
  await b.commit();
  return {'ok': true, 'balance': balance, 'entry': entry.id};
}

Future<Map<String, dynamic>> _block(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final on = body['blocked'] != false;
  if (on && uid == _me.uid) throw AdminApiException('You cannot block yourself.', status: 400);
  if (on) {
    final adm = await _db.collection('admins').doc(uid).get().then((s) => s.exists).catchError((_) => false);
    if (adm) throw AdminApiException('That account is an admin. Remove it from admins first.', status: 400);
  }
  final reason = '${body['reason'] ?? ''}'.trim();
  final b = _db.batch();
  b.set(
      _db.collection('users').doc(uid),
      on
          ? {'blocked': true, 'blockedAt': FieldValue.serverTimestamp(), 'blockedBy': _by, 'blockedReason': reason}
          : {'blocked': false, 'blockedReason': '', 'unblockedAt': FieldValue.serverTimestamp(), 'unblockedBy': _by},
      SetOptions(merge: true));
  _log(b, on ? 'user.block' : 'user.unblock', uid, {'reason': reason, 'auth': 'needs FIREBASE_SERVICE_ACCOUNT'}, on ? 'Blocked' : 'Unblocked');
  await b.commit();
  return {
    'ok': true, 'blocked': on, 'auth': 'not changed',
    'warning': on ? 'The app now shows them the blocked screen and the rules stop their posts and requests. Their Firebase sign-in is disabled too once FIREBASE_SERVICE_ACCOUNT is set and you block again.' : '',
  };
}

Future<Map<String, dynamic>> _restrict(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final want = body['restrictions'] is Map ? body['restrictions'] as Map : const {};
  final r = <String, bool>{for (final k in kRestrictions.keys) if (want[k] == true) k: true};
  final b = _db.batch();
  b.set(_db.collection('users').doc(uid), {'restrictions': r, 'restrictionsUpdatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  _log(b, 'user.restrict', uid, {'on': r.keys.join(',').isEmpty ? 'none' : r.keys.join(','), 'reason': body['reason'] ?? ''}, 'Restrictions');
  await b.commit();
  return {'ok': true, 'restrictions': r};
}

Future<Map<String, dynamic>> _resetStreak(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final ref = _db.collection('users').doc(uid).collection('wallet').doc('main');
  final w = (await ref.get()).data() ?? {};
  final b = _db.batch();
  b.set(ref, {'streak': 0, 'lastLoginYmd': '', 'streakResetAt': DateTime.now().millisecondsSinceEpoch, 'lastBrokenStreak': _num(w['streak']).toInt()}, SetOptions(merge: true));
  _log(b, 'streak.reset', uid, {'was': _num(w['streak']), 'reason': body['reason'] ?? ''}, 'Streak reset');
  await b.commit();
  return {'ok': true, 'was': _num(w['streak'])};
}

Future<Map<String, dynamic>> _message(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final title = '${body['title'] ?? ''}'.trim();
  if (title.isEmpty) throw AdminApiException('A title is required.', status: 400);
  final b = _db.batch();
  _notify(b, uid, title, '${body['body'] ?? ''}'.trim(), extra: {'from': 'NowssB'});
  _log(b, 'user.message', uid, {'title': title, 'push': false}, 'Message: $title');
  await b.commit();
  return {
    'ok': true, 'inApp': true,
    'push': {'sent': 0, 'devices': 0, 'skipped': true},
    'warning': body['push'] == false ? '' : 'Delivered in the app (bell + inbox). Phone push needs FCM_SERVICE_ACCOUNT and FIREBASE_SERVICE_ACCOUNT on Cloudflare.',
  };
}

Future<Map<String, dynamic>> _helper(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final on = body['on'] != false;
  final b = _db.batch();
  b.set(_db.collection('users').doc(uid), {'roles': on ? FieldValue.arrayUnion(['helper']) : FieldValue.arrayRemove(['helper'])}, SetOptions(merge: true));
  _log(b, on ? 'role.helper.add' : 'role.helper.remove', uid, {}, on ? 'Marked helper' : 'Helper removed');
  await b.commit();
  return {'ok': true};
}

/* ───────────────────────── requests ───────────────────────── */

Future<Map<String, dynamic>> _fulfil(Map<String, dynamic> body) async {
  final id = '${body['id'] ?? ''}';
  final ref = _db.collection('requests').doc(id);
  final r = (await ref.get()).data();
  if (r == null) throw AdminApiException('That request is gone.', status: 404);
  final wordKey = '${body['wordKey'] ?? ''}';
  final word = '${body['word'] ?? r['word'] ?? wordKey}';
  final b = _db.batch();
  b.set(ref, {'status': 'done', 'doneAt': DateTime.now().millisecondsSinceEpoch, 'fulfilledWord': wordKey, 'fulfilledBy': _by, 'adminNote': '${body['note'] ?? ''}'}, SetOptions(merge: true));
  _log(b, 'request.done', id, {'word': word, 'wordKey': wordKey, 'uid': r['uid'] ?? ''}, 'Request fulfilled');
  final uid = r['uid'] is String ? r['uid'] as String : '';
  if (uid.isNotEmpty) {
    final msg = '${body['message'] ?? ''}'.trim();
    _notify(b, uid, '“$word” is ready', msg.isNotEmpty ? msg : 'The word you asked for is now in NowssB. Open it from your notifications.',
        kind: 'request_done', extra: {'word': word, 'wordKey': wordKey, 'requestId': id});
  }
  await b.commit();
  return {'ok': true, 'told': uid.isNotEmpty, 'push': {'sent': 0, 'devices': 0}};
}

/* ───────────────────────── earn & gifts ───────────────────────── */

Future<Map<String, dynamic>> _payout(Map<String, dynamic> body) async {
  final id = '${body['id'] ?? ''}';
  final decision = '${body['decision'] ?? ''}';
  final note = '${body['note'] ?? ''}'.trim();
  final utr = '${body['utr'] ?? ''}'.trim();
  if (!['approve', 'paid', 'reject'].contains(decision)) throw AdminApiException('Decision must be approve, paid or reject.', status: 400);
  if (decision == 'paid' && utr.isEmpty) throw AdminApiException('Enter the UPI reference (UTR) of the transfer.', status: 400);
  if (decision == 'reject' && note.isEmpty) throw AdminApiException('Say why, so the person knows.', status: 400);
  final ref = _db.collection('payoutRequests').doc(id);
  late String owner;
  late int amt;
  await _db.runTransaction((tx) async {
    final p = (await tx.get(ref)).data();
    if (p == null) throw AdminApiException('That payout request is gone.', status: 404);
    final st = '${p['status'] ?? ''}';
    if (!['pending_review', 'queued', 'approved'].contains(st)) throw AdminApiException('Already $st.', status: 409);
    if (decision == 'approve' && st == 'approved') throw AdminApiException('Already approved.', status: 409);
    owner = '${p['uid']}';
    amt = _num(p['amountBase']).toInt();
    final payRef = _db.collection('users').doc(owner).collection('payout').doc('main');
    final pay = (await tx.get(payRef)).data() ?? {};
    final now = DateTime.now();
    if (decision == 'approve') {
      tx.set(ref, {'status': 'approved', 'approvedAt': Timestamp.fromDate(now), 'approvedBy': _by, 'note': note}, SetOptions(merge: true));
    } else if (decision == 'paid') {
      tx.set(ref, {'status': 'paid', 'paidAt': Timestamp.fromDate(now), 'paidBy': _by, 'utr': utr, 'note': note}, SetOptions(merge: true));
      tx.set(payRef, {'pendingCents': math.max(0, _num(pay['pendingCents']).toInt() - amt), 'paidCents': _num(pay['paidCents']).toInt() + amt, 'updatedAt': now.millisecondsSinceEpoch}, SetOptions(merge: true));
    } else {
      final next = _num(pay['cashBalance']).toInt() + amt;
      tx.set(ref, {'status': 'rejected', 'rejectedAt': Timestamp.fromDate(now), 'rejectedBy': _by, 'note': note}, SetOptions(merge: true));
      tx.set(_db.collection('cashLedger').doc(), {'uid': owner, 'delta': amt, 'balanceAfter': next, 'reason': 'Payout returned', 'refId': id, 'at': Timestamp.fromDate(now)});
      tx.set(payRef, {'cashBalance': next, 'pendingCents': math.max(0, _num(pay['pendingCents']).toInt() - amt), 'updatedAt': now.millisecondsSinceEpoch}, SetOptions(merge: true));
    }
  });
  final msg = {
    'approve': ['Payout approved', 'Your payout is approved and will be sent to your UPI id.'],
    'paid': ['Payout sent', 'Your payout was sent to your UPI id. Reference $utr.'],
    'reject': ['Payout not approved', 'Your balance is back in NowssB Earn. $note'],
  }[decision]!;
  final b = _db.batch();
  _log(b, 'payout.$decision', id, {'uid': owner, 'amountCents': amt, 'utr': utr, 'note': note}, 'Payout $decision');
  _notify(b, owner, msg[0], msg[1], kind: 'payout', extra: {'refId': id});
  await b.commit();
  return {'ok': true, 'id': id, 'status': {'approve': 'approved', 'paid': 'paid', 'reject': 'rejected'}[decision], 'uid': owner, 'amount': amt};
}

String _giftCode() {
  const abc = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = math.Random.secure();
  return 'GFT${List.generate(6, (_) => abc[r.nextInt(abc.length)]).join()}';
}

Future<Map<String, dynamic>> _giftCodes(Map<String, dynamic> body) async {
  final item = '${body['item'] ?? ''}';
  if (!kGiftItems.containsKey(item)) throw AdminApiException('Pick what the gift holds.', status: 400);
  final count = _num(body['count'], 1).round();
  if (count < 1 || count > 50) throw AdminApiException('Make 1 to 50 codes at a time.', status: 400);
  final days = _num(body['expiresDays'], 90).round();
  if (days < 1 || days > 730) throw AdminApiException('Expiry must be 1 to 730 days.', status: 400);
  final now = DateTime.now().millisecondsSinceEpoch;
  final me = _me;
  final campaign = '${body['campaign'] ?? ''}'.trim();
  final b = _db.batch();
  final codes = <String>[];
  for (var i = 0; i < count; i++) {
    final code = _giftCode();
    codes.add(code);
    b.set(_db.collection('gifts').doc(code), {
      'code': code, 'item': item, 'itemId': item, 'label': kGiftItems[item], 'note': '${body['note'] ?? ''}', 'senderUid': me.uid, 'senderName': 'NowssB',
      'source': 'admin', 'campaign': campaign, 'recipientEmail': '${body['recipientEmail'] ?? ''}'.toLowerCase(), 'status': 'unredeemed',
      'createdAt': now, 'expiresAt': now + days * kDay,
    });
    b.set(_db.collection('giftLedger').doc(), {'code': code, 'senderUid': me.uid, 'itemId': item, 'cents': 0, 'status': 'issued', 'source': 'admin', 'campaign': campaign, 'at': FieldValue.serverTimestamp()});
  }
  _log(b, 'gift.codes', campaign.isEmpty ? item : campaign, {'item': item, 'count': count, 'days': days}, '$count gift codes');
  await b.commit();
  return {'ok': true, 'codes': codes, 'item': item, 'expiresAt': now + days * kDay};
}

Future<Map<String, dynamic>> _giftVoid(Map<String, dynamic> body) async {
  final code = '${body['code'] ?? ''}'.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final ref = _db.collection('gifts').doc(code);
  final g = (await ref.get()).data();
  if (g == null) throw AdminApiException('No such code.', status: 404);
  if (g['status'] != 'unredeemed') throw AdminApiException('Already ${g['status']}.', status: 409);
  final b = _db.batch();
  b.update(ref, {'status': 'void', 'voidedBy': _by, 'voidedAt': DateTime.now().millisecondsSinceEpoch});
  _log(b, 'gift.void', code, {'label': g['label'] ?? ''}, 'Gift code voided');
  await b.commit();
  return {'ok': true};
}

Future<Map<String, dynamic>> _earn(Map<String, dynamic> body) async {
  final res = await Future.wait<Object?>([
    _list(_db.collection('referrals').limit(2000)),
    _list(_db.collection('referralLedger').orderBy('at', descending: true).limit(60)),
    _list(_db.collection('payoutRequests').orderBy('at', descending: true).limit(150)),
    _list(_db.collection('gifts').orderBy('createdAt', descending: true).limit(150)),
    _list(_db.collection('couponLedger').orderBy('at', descending: true).limit(60)),
    _db.doc('config/economy').get().then((s) => s.data()).catchError((_) => null),
    _list(_db.collection('partnerLedger').orderBy('at', descending: true).limit(40)),
  ]);
  L(int i) => res[i] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
  final byRef = <String, Map<String, dynamic>>{};
  for (final r in L(0)) {
    final k = '${r.data()['referrerUid'] ?? ''}';
    if (k.isEmpty) continue;
    final e = byRef.putIfAbsent(k, () => {'uid': k, 'invited': 0, 'subscribed': 0});
    e['invited'] = (e['invited'] as int) + 1;
    if (r.data()['subscribed'] == true) e['subscribed'] = (e['subscribed'] as int) + 1;
  }
  final top = byRef.values.toList()
    ..sort((a, b) {
      final c = (b['subscribed'] as int).compareTo(a['subscribed'] as int);
      return c != 0 ? c : (b['invited'] as int).compareTo(a['invited'] as int);
    });
  if (top.isNotEmpty) {
    final names = await Future.wait(top.take(25).map((t) => _userDoc('${t['uid']}').catchError((_) => <String, dynamic>{})));
    for (var i = 0; i < names.length; i++) {
      top[i]['name'] = names[i]['displayName'] ?? '';
      top[i]['email'] = names[i]['email'] ?? '';
    }
  }
  List<Map<String, dynamic>> pl(List<Map<String, dynamic>> l) => l.map(_plain).toList();
  return {
    'ok': true,
    'network': {'referrals': L(0).length, 'referrers': byRef.length, 'subscribed': L(0).where((r) => r.data()['subscribed'] == true).length, 'top': top.take(25).toList()},
    'referralLedger': pl(_rows(L(1))),
    'payouts': pl(_rows(L(2))),
    'gifts': pl(_rows(L(3), 'createdAt')),
    'coupons': pl(_rows(L(4))),
    'partner': pl(_rows(L(6))),
    'config': res[5] == null ? null : _plain(res[5] as Map<String, dynamic>),
    'now': DateTime.now().millisecondsSinceEpoch,
  };
}

Future<Map<String, dynamic>> _network(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final l1 = await _list(_db.collection('referrals').where('referrerUid', isEqualTo: uid).limit(300));
  final up = await _db.collection('referrals').doc(uid).get().then((s) => s.data()).catchError((_) => null);
  final l1ids = l1.map((d) => d.id).toList();
  final l2 = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (var i = 0; i < l1ids.length; i += 30) {
    l2.addAll(await _list(_db.collection('referrals').where('referrerUid', whereIn: l1ids.sublist(i, math.min(i + 30, l1ids.length))).limit(500)));
  }
  Future<Map<String, dynamic>> who(String id) async {
    final d = await _userDoc(id).catchError((_) => <String, dynamic>{});
    return {'uid': id, 'name': d['displayName'] ?? '', 'email': d['email'] ?? ''};
  }

  return {
    'ok': true,
    'me': await who(uid),
    'upline': up != null && '${up['referrerUid'] ?? ''}'.isNotEmpty ? await who('${up['referrerUid']}') : null,
    'level1': await Future.wait(l1.map((r) async => {...await who(r.id), 'subscribed': r.data()['subscribed'] == true, 'at': toMsAny(r.data()['at'] ?? r.data()['createdAt'])})),
    'level2': await Future.wait(l2.map((r) async => {...await who(r.id), 'via': r.data()['referrerUid'], 'subscribed': r.data()['subscribed'] == true, 'at': toMsAny(r.data()['at'] ?? r.data()['createdAt'])})),
  };
}

/* ───────────────────────── activity ───────────────────────── */

Future<Map<String, dynamic>> _feed(Map<String, dynamic> body) async {
  final n = _num(body['limit'], 40).toInt().clamp(10, 60);
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> L(String c, [String f = 'at']) => _list(_db.collection(c).orderBy(f, descending: true).limit(n));
  final r = await Future.wait([L('activity'), L('adminLog'), L('payments'), L('requests'), L('payoutRequests'), L('gifts', 'createdAt'), L('couponLedger')]);
  final out = <Map<String, dynamic>>[];
  for (final d in r[0]) {
    final x = d.data();
    out.add({'id': 'a_${d.id}', 'type': x['type'] == 'admin' ? 'admin' : (x['type'] ?? 'event'), 'title': x['summary'] ?? x['type'] ?? '', 'uid': x['uid'] ?? '', 'by': x['by'] ?? '', 'detail': '${x['platform'] ?? x['build'] ?? ''}', 'at': toMsAny(x['at'])});
  }
  for (final d in r[1]) {
    final x = d.data();
    final det = x['detail'] is Map ? (x['detail'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' · ') : '';
    out.add({'id': 'l_${d.id}', 'type': '${x['action'] ?? ''}'.startsWith('payment') ? 'purchase' : 'admin', 'title': x['action'] ?? '', 'uid': x['target'] ?? '', 'by': x['email'] ?? x['uid'] ?? '', 'detail': det.length > 160 ? det.substring(0, 160) : det, 'at': toMsAny(x['at'])});
  }
  for (final d in r[2]) {
    final x = d.data();
    out.add({'id': 'p_${d.id}', 'type': 'purchase', 'title': '${kTiers[x['tier']] ?? x['productId'] ?? 'Purchase'} ${x['billing'] ?? ''}'.trim(), 'uid': x['uid'] ?? '', 'by': x['source'] ?? 'play', 'detail': x['orderId'] ?? '', 'at': toMsAny(x['at'])});
  }
  for (final d in r[3]) {
    final x = d.data();
    out.add({'id': 'r_${d.id}', 'type': 'request', 'title': 'Request: ${x['word'] ?? ''}', 'uid': x['uid'] ?? '', 'by': x['email'] ?? x['name'] ?? '', 'detail': x['status'] ?? '', 'at': toMsAny(x['at'])});
  }
  for (final d in r[4]) {
    final x = d.data();
    out.add({'id': 'o_${d.id}', 'type': 'payout', 'title': 'Payout ${(_num(x['amountBase']) / 100).toStringAsFixed(2)} ${x['currency'] ?? 'USD'}', 'uid': x['uid'] ?? '', 'by': x['upi'] ?? '', 'detail': x['status'] ?? '', 'at': toMsAny(x['at'])});
  }
  for (final d in r[5]) {
    final x = d.data();
    out.add({'id': 'g_${d.id}', 'type': 'gift', 'title': 'Gift ${x['label'] ?? x['item'] ?? ''} (${x['status'] ?? ''})', 'uid': x['senderUid'] ?? '', 'by': x['senderName'] ?? '', 'detail': x['code'] ?? d.id, 'at': toMsAny(x['redeemedAt'] ?? x['createdAt'])});
  }
  for (final d in r[6]) {
    final x = d.data();
    out.add({'id': 'c_${d.id}', 'type': 'coupon', 'title': 'Coupon ${x['rarity'] ?? ''} ${x['coins'] != null ? '+${x['coins']} coins' : ''}'.trim(), 'uid': x['uid'] ?? '', 'by': '', 'detail': '', 'at': toMsAny(x['at'])});
  }
  out.sort((a, b) => (b['at'] as int).compareTo(a['at'] as int));
  return {'ok': true, 'rows': out.take(n * 3).toList()};
}

Future<Map<String, dynamic>> _uiAssets(Map<String, dynamic> body) async {
  final docs = await _list(_db.collection('ui_overrides').limit(1000));
  final urls = docs.map((d) => d.data()['url']).whereType<String>().where((u) => u.startsWith('http')).toSet().toList();
  return {'ok': true, 'items': const [], 'overrides': urls, 'missing': AdminData.serverMissing};
}

/* ───────────────────────── who signed in today ───────────────────────── */

Future<Map<String, dynamic>> _today(Map<String, dynamic> body) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final tz = _num(body['tzOffsetMin'], kDayTzMin).toInt();
  final day = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch('${body['day'] ?? ''}') ? '${body['day']}' : dayKeyOf(now, tz);
  final start = DateTime.parse('${day}T00:00:00Z').millisecondsSinceEpoch - tz * 60000;
  final end = start + kDay;
  final res = await Future.wait([
    _list(_db.collection('presenceDays').doc(day).collection('people').limit(2000)),
    _list(_db.collection('users').where('lastSeenAt', isGreaterThanOrEqualTo: Timestamp.fromMillisecondsSinceEpoch(start)).limit(2000)),
  ]);
  final by = <String, Map<String, dynamic>>{};
  for (final p in res[0]) {
    final d = p.data();
    by[p.id] = {
      'uid': p.id, 'first': toMsAny(d['first']), 'last': toMsAny(d['last']), 'opens': _num(d['opens'], 1).toInt(),
      'platform': d['platform'] ?? '', 'build': '${d['build'] ?? ''}', 'os': d['os'] ?? '', 'email': d['email'] ?? '', 'name': d['name'] ?? '',
    };
  }
  for (final u in res[1]) {
    final d = u.data();
    final last = toMsAny(d['lastSeenAt']);
    if (last >= end) continue;
    final r = by[u.id] ?? {'uid': u.id, 'first': last, 'last': last, 'opens': 1, 'platform': '', 'build': '', 'os': '', 'email': '', 'name': ''};
    r['last'] = math.max(r['last'] as int, last);
    if ((r['first'] as int) == 0) r['first'] = last;
    if ('${r['platform']}'.isEmpty) r['platform'] = d['lastPlatform'] ?? '';
    if ('${r['build']}'.isEmpty) r['build'] = '${d['lastBuild'] ?? ''}';
    if ('${r['os']}'.isEmpty) r['os'] = d['lastOs'] ?? '';
    if ('${r['email']}'.isEmpty) r['email'] = d['email'] ?? '';
    if ('${r['name']}'.isEmpty) r['name'] = d['displayName'] ?? '';
    r['photo'] = d['photoURL'] ?? '';
    r['plan'] = planOf(d, now);
    r['blocked'] = d['blocked'] == true;
    by[u.id] = r;
  }
  final rows = by.values.toList()..sort((a, b) => (b['last'] as int).compareTo(a['last'] as int));
  for (final r in rows) {
    r['online'] = (r['last'] as int) > now - kOnlineMs;
  }
  return {'ok': true, 'day': day, 'tzOffsetMin': tz, 'total': rows.length, 'online': rows.where((r) => r['online'] == true).length, 'rows': rows};
}

/* ───────────────────────── free items ───────────────────────── */

const kItemKinds = {'word': 'Word', 'meaning': 'Meaning', 'ebook': 'E-book', 'signature': 'Signature'};

Future<Map<String, dynamic>> _grantItem(Map<String, dynamic> body) async {
  final uid = _uid(body['uid']);
  final kind = '${body['kind'] ?? ''}';
  if (!kItemKinds.containsKey(kind)) throw AdminApiException('Pick a word, meaning, e-book or signature item.', status: 400);
  final name = '${body['id'] ?? ''}'.trim().replaceFirst(RegExp(r'^[a-z]+:'), '');
  if (name.isEmpty) throw AdminApiException('Pick the item to give.', status: 400);
  final itemId = '$kind:$name';
  final title = '${body['title'] ?? ''}'.trim().isEmpty ? name : '${body['title']}'.trim();
  final revoke = body['revoke'] == true;
  var docId = itemId.replaceAll(RegExp(r'[^A-Za-z0-9_.@-]'), '_').replaceFirst(RegExp(r'^\.+'), '_');
  if (docId.length > 300) docId = docId.substring(0, 300);
  final b = _db.batch();
  b.set(_db.doc('users/$uid/owned/$docId'), {
    'id': itemId, 'kind': kind, 'title': title, 'source': 'admin', 'status': revoke ? 'revoked' : 'active',
    'grantedBy': _by, 'at': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  _log(b, revoke ? 'owned.revoke' : 'owned.grant', uid, {'item': itemId, 'title': title}, '${revoke ? 'Took back' : 'Gave'} ${kItemKinds[kind]} “$title”');
  if (!revoke && body['notify'] != false) {
    b.set(_db.collection('users/$uid/notifications').doc(), {
      'title': 'A free ${kItemKinds[kind]!.toLowerCase()} for you', 'body': '“$title” is now yours in NowssB. Open it any time.',
      'kind': 'gift', 'type': 'gift', 'read': false, 'at': DateTime.now(), 'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await b.commit();
  return {'ok': true, 'item': itemId, 'status': revoke ? 'revoked' : 'active', 'push': {'sent': 0, 'devices': 0, 'skipped': true}};
}

/* ───────────────────────── admin inbox ───────────────────────── */

Future<Map<String, dynamic>> _alerts(Map<String, dynamic> body) async {
  final res = await Future.wait<Object>([
    _list(_db.collection('adminAlerts').orderBy('at', descending: true).limit(80)),
    _count(_db.collection('requests').where('status', isEqualTo: 'new')),
    _count(_db.collection('payoutRequests').where('status', whereIn: ['pending_review', 'queued'])),
  ]);
  return {
    'ok': true,
    'alerts': [for (final r in res[0] as List<QueryDocumentSnapshot<Map<String, dynamic>>>) {'id': r.id, ...r.data(), 'at': toMsAny(r.data()['at'])}],
    'openRequests': res[1],
    'pendingPayouts': res[2],
  };
}
