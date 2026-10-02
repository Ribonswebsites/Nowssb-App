/// What this account may open — the one place every gate asks.
///
/// Sources, all written by the server or an admin only (firestore.rules):
///  * users/{uid}: `isPro`, `tier`, `subscriptionEndDate` — the Google Play
///    subscription that /api/play/verify (functions/_lib/play.js) confirmed,
///    kept current by RTDN, or an admin grant (Admin → People → plan).
///    `ebookPassUntil` (an ebook pass) is honoured too.
///  * users/{uid}/owned/{itemId} `status: active` — one-time purchases
///    (functions/_lib/play_content.js, and the economy checkout), admin
///    grants, gift redemptions.
///  * admins/{uid} — admins see everything.
///
/// Free content (price 0) is always open. What each plan opens follows its
/// benefits on the Subscription page: Resonance — every word for practice;
/// Frequency — + every meaning ("Advanced word meanings"); Frequency X —
/// + Signature pieces and ebooks ("Complete NowssB access"). The sentence
/// builder needs a plan or uses only the words you can open.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../admin/admin_state.dart';
import 'billing_config.dart';
import 'firebase.dart';
import 'models.dart';

/// Why something is locked, for the lock UI.
enum LockReason { none, signIn, purchase }

class Entitlements extends ChangeNotifier {
  Entitlements._() {
    _start();
  }
  static final Entitlements instance = Entitlements._();

  static const tierRank = {'resonance': 1, 'frequency': 2, 'frequencyX': 3};

  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownedSub;

  String? _uid;
  String? _tier;
  DateTime? _until;
  DateTime? _ebookPassUntil;
  final Set<String> _owned = {};
  bool _loaded = false;

  /// Test hook: pretend these values.
  @visibleForTesting
  void debugSet({String? uid, String? tier, DateTime? until, Set<String>? owned}) {
    _uid = uid;
    _tier = tier;
    _until = until;
    _owned
      ..clear()
      ..addAll(owned ?? const {});
    _loaded = true;
    notifyListeners();
  }

  bool get signedIn => _uid != null;
  bool get loaded => _loaded;
  bool get isAdmin => AdminState.instance.isAdmin;

  /// resonance / frequency / frequencyX while a plan is active, else null.
  String? get activeTier {
    if (_tier == null) return null;
    if (_until != null && _until!.isBefore(DateTime.now())) return null;
    return _tier;
  }

  int get _rank => tierRank[activeTier] ?? 0;
  bool hasTier(String tier) => isAdmin || _rank >= (tierRank[tier] ?? 99);

  Set<String> get owned => Set.unmodifiable(_owned);
  bool ownsItem(String itemId) => _owned.contains(ownedDocId(itemId));

  void _start() {
    AdminState.instance.addListener(notifyListeners);
    if (!NwsbFirebase.ready) return;
    try {
      _auth = FirebaseAuth.instance.authStateChanges().listen(_onUser);
    } catch (_) {}
  }

  void _onUser(User? u) {
    _userSub?.cancel();
    _ownedSub?.cancel();
    _userSub = null;
    _ownedSub = null;
    _uid = (u == null || u.isAnonymous) ? null : u.uid;
    _tier = null;
    _until = null;
    _ebookPassUntil = null;
    _owned.clear();
    _loaded = _uid == null;
    notifyListeners();
    final uid = _uid;
    if (uid == null) return;
    final db = FirebaseFirestore.instance;
    _userSub = db.doc('users/$uid').snapshots().listen((s) {
      final d = s.data() ?? const <String, dynamic>{};
      final tier = '${d['tier'] ?? ''}';
      _tier = d['isPro'] == true && tierRank.containsKey(tier) ? tier : null;
      _until = _date(d['subscriptionEndDate']);
      _ebookPassUntil = _date(d['ebookPassUntil']);
      _loaded = true;
      notifyListeners();
    }, onError: (Object e) => debugPrint('NowssB entitlements: $e'));
    _ownedSub = db.collection('users/$uid/owned').snapshots().listen((s) {
      _owned
        ..clear()
        ..addAll([
          for (final d in s.docs)
            if ('${d.data()['status'] ?? 'active'}' == 'active') d.id,
        ]);
      notifyListeners();
    }, onError: (Object e) => debugPrint('NowssB owned: $e'));
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return DateTime.tryParse('${v ?? ''}');
  }

  // ── The gates ───────────────────────────────────────────────────────

  /// Bag id of a library word (same as the Word Atelier card).
  static String wordItemId(String name, {bool signature = false}) =>
      '${signature ? 'signature' : 'word'}:${name.toLowerCase()}';

  /// A word in the library / player.
  bool canOpenWord(Word w) {
    if (w.price <= 0) return true;
    if (isAdmin || hasTier('resonance')) return true;
    return ownsItem(wordItemId(w.word)) || ownsItem(wordItemId(w.word, signature: true));
  }

  /// A Word Atelier / Signature store word by name.
  bool canOpenStoreWord(String name, {bool signature = false, num price = 1}) {
    if (price <= 0 || isAdmin) return true;
    if (signature) return hasTier('frequencyX') || ownsItem(wordItemId(name, signature: true));
    return hasTier('resonance') || ownsItem(wordItemId(name));
  }

  /// A meaning (Meaning Store / meanings reader).
  bool canOpenMeaning(String word, {num price = 1, bool signature = false}) {
    if (price <= 0 || isAdmin) return true;
    if (signature) return hasTier('frequencyX') || ownsItem('meaning:${word.toLowerCase()}');
    return hasTier('frequency') || ownsItem('meaning:${word.toLowerCase()}');
  }

  /// An ebook (Ebooks store / reader).
  bool canOpenEbook(String title, {num price = 1}) {
    if (price <= 0 || isAdmin) return true;
    if (hasTier('frequencyX')) return true;
    final pass = _ebookPassUntil;
    if (pass != null && pass.isAfter(DateTime.now())) return true;
    return ownsItem('ebook:${title.toLowerCase()}');
  }

  /// The sentence builder needs a plan; without one it works from the
  /// words you can open (free + owned).
  bool get sentenceBuilderUnlimited => isAdmin || hasTier('resonance');

  /// Any bag item (cart, wishlist, product detail).
  bool ownsOrIncluded(String itemId, {num price = 1}) {
    final i = itemId.indexOf(':');
    final kind = i > 0 ? itemId.substring(0, i) : '';
    final name = i > 0 ? itemId.substring(i + 1) : itemId;
    return switch (kind) {
      'word' => canOpenStoreWord(name, price: price),
      'signature' => canOpenStoreWord(name, signature: true, price: price),
      'meaning' => canOpenMeaning(name, price: price),
      'ebook' => canOpenEbook(name, price: price),
      _ => false,
    };
  }

  LockReason lockReason(bool open) =>
      open ? LockReason.none : (signedIn ? LockReason.purchase : LockReason.signIn);

  @override
  void dispose() {
    _auth?.cancel();
    _userSub?.cancel();
    _ownedSub?.cancel();
    super.dispose();
  }
}
