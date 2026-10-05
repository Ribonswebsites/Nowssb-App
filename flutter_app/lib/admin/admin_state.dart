/// Who is an admin, decided by the server — never by a flag on the phone.
///
/// Two server-side marks count, the same two the security rules accept:
///   * a document at `admins/{uid}` (what the web studio already uses), or
///   * a custom claim `admin: true` on the sign-in token, set with the
///     Admin SDK (tools/firebase/mark-admin.sh).
///
/// This class only decides what the app SHOWS. What the account can actually
/// WRITE is decided by firestore.rules and storage.rules, which check the
/// same two marks. Hiding a button is a courtesy; the rules are the lock.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/firebase.dart';

class AdminState extends ChangeNotifier {
  AdminState._();
  static final AdminState instance = AdminState._();

  bool _isAdmin = false;
  bool _resolved = false;
  String? _cachedAdminUid;
  String? _cachedMemberUid;
  String? _uid;
  String? _email;
  String _how = '';
  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _doc;

  bool get isAdmin => _isAdmin;

  /// True once the server's answer for the signed-in account is in (or there
  /// is no account). Until then [likelyAdmin] says what the last launch knew,
  /// so an admin never sees the member app flash while `admins/{uid}` loads.
  bool get resolved => _resolved;

  /// The last answer this phone saw for [uid]: true / false, or null if this
  /// account has never been checked here.
  bool? cachedFor(String? uid) {
    if (uid == null) return false;
    if (uid == _cachedAdminUid) return true;
    if (uid == _cachedMemberUid) return false;
    return null;
  }

  /// Member nudges and promotions an admin's phone never shows: today's
  /// offer, the daily-words / streak nudges and broadcast promos.
  static const promoKinds = {'offers', 'routine', 'streak', 'broadcast', 'promo', 'marketing'};

  /// True for a promo kind on an admin's phone (known or cached admin).
  bool mutes(String type) {
    if (!promoKinds.contains(type)) return false;
    if (_isAdmin) return true;
    String? uid = _uid;
    if (uid == null) {
      try {
        uid = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser?.uid : null;
      } catch (_) {}
    }
    return uid != null && cachedFor(uid) == true;
  }

  static const _kAdminUid = 'nwsb_admin_uid';
  static const _kMemberUid = 'nwsb_member_uid';

  /// Read the cached answer before the first frame (main.dart).
  Future<void> loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      _cachedAdminUid = p.getString(_kAdminUid);
      _cachedMemberUid = p.getString(_kMemberUid);
    } catch (_) {}
  }

  Future<void> _remember(String uid, bool admin) async {
    if (admin) {
      _cachedAdminUid = uid;
      if (_cachedMemberUid == uid) _cachedMemberUid = null;
    } else {
      _cachedMemberUid = uid;
      if (_cachedAdminUid == uid) _cachedAdminUid = null;
    }
    try {
      final p = await SharedPreferences.getInstance();
      if (admin) {
        await p.setString(_kAdminUid, uid);
        if (p.getString(_kMemberUid) == uid) await p.remove(_kMemberUid);
      } else {
        await p.setString(_kMemberUid, uid);
        if (p.getString(_kAdminUid) == uid) await p.remove(_kAdminUid);
      }
    } catch (_) {}
  }
  String? get uid => _uid;
  String? get email => _email;

  /// 'admins list', 'sign-in claim' or both — shown on the admin home.
  String get how => _how;

  void start() {
    if (!NwsbFirebase.ready) {
      _resolved = true;
      return;
    }
    if (_auth != null) return;
    _auth = FirebaseAuth.instance.idTokenChanges().listen(_onUser);
  }

  Future<void> _onUser(User? user) async {
    await _doc?.cancel();
    _doc = null;
    _uid = user?.uid;
    _email = user?.email;
    if (user == null || user.isAnonymous) {
      _resolved = true;
      _set(false, '', force: true);
      return;
    }
    if (_resolvedUid != user.uid) {
      _resolved = false;
      notifyListeners();
    }
    var claim = false;
    try {
      final token = await user.getIdTokenResult();
      claim = token.claims?['admin'] == true;
    } catch (_) {}
    _doc = FirebaseFirestore.instance
        .doc('admins/${user.uid}')
        .snapshots()
        .listen((snap) {
      final listed = snap.exists;
      // A cache-only "missing" on a cold offline start is not an answer.
      if (!listed && snap.metadata.isFromCache && cachedFor(user.uid) == true) return;
      _resolvedUid = user.uid;
      _resolved = true;
      unawaited(_remember(user.uid, listed || claim));
      _set(
        listed || claim,
        [if (listed) 'admins list', if (claim) 'sign-in claim'].join(' + '),
      );
    }, onError: (_) {
      // The rules refuse the read for anyone who is not on the list.
      _resolvedUid = user.uid;
      _resolved = true;
      unawaited(_remember(user.uid, claim));
      _set(claim, claim ? 'sign-in claim' : '', force: true);
    });
  }

  String? _resolvedUid;

  void _set(bool v, String how, {bool force = false}) {
    if (v == _isAdmin && how == _how) {
      if (force || _resolved) notifyListeners();
      return;
    }
    _isAdmin = v;
    _how = how;
    if (!v) EditMode.instance._reset();
    notifyListeners();
  }
}

/// The live template editor's switches. Both are meaningless unless
/// [AdminState.isAdmin] is true, and both reset when it stops being true.
class EditMode extends ChangeNotifier {
  EditMode._();
  static final EditMode instance = EditMode._();

  static const _kFab = 'nwsb_admin_edit_fab';

  bool _on = false;
  bool _fab = true;

  /// Pencil badges on every editable element of the live screen.
  bool get on => _on && AdminState.instance.isAdmin;

  /// The floating "Edit layout" button over the app.
  bool get fabVisible => _fab && AdminState.instance.isAdmin;
  bool get fabPreference => _fab;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _fab = p.getBool(_kFab) ?? true;
    } catch (_) {}
  }

  void toggle() => setOn(!_on);

  void setOn(bool v) {
    if (v && !AdminState.instance.isAdmin) return;
    _on = v;
    notifyListeners();
  }

  Future<void> setFab(bool v) async {
    _fab = v;
    if (!v) _on = false;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kFab, v);
    } catch (_) {}
  }

  void _reset() {
    if (!_on) return;
    _on = false;
    notifyListeners();
  }
}
